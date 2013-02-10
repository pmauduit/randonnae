require 'find'
require 'nokogiri'
require 'elevation_parser'

class Trek < ActiveRecord::Base
  belongs_to :user
  validates :title, :presence => true

  has_many :images, :dependent => :destroy

  before_destroy :remove_files

  # the official GPX XML namespace
  GPX_NAMESPACE =  { "gpx" => "http://www.topografix.com/GPX/1/1" }

  # Array for the expected image file extensions
  JPEG_EXT = [ ".jpg", ".JPG", ".JPEG", ".jpeg" ]

  # Array for the expected GPX extensions
  GPX_EXT = [ ".gpx", ".GPX" ]
  # Array for the expected extensions into the ZIP archive
  AUTHORIZED_EXT =  GPX_EXT.concat JPEG_EXT

  ##
  # Finds all treks for a user,
  # given the user id as argument
  # Params:
  # +id+:: the user unique identifier
  ##
  def self.find_by_user(id)
    find(:all, :conditions => ["user_id = ?", id ], :order => "id DESC")
  end

  ##
  # Finds the last ten uploaded treks
  ##
  def self.last_ten
    find(:all, :order => "created_at desc", :limit => 10)
  end

  ##
  # Gets the GPX path
  ##
  def gpx
    @gpx ||= compute_gpx_path
  end

  ##
  # Creates a trek from a ZIP file
  ##
  def self.create_from_archive(user_id, trek_title, zip_path)
    trek = Trek.new
    trek.title = trek_title
    trek.user_id = user_id

    # Pre-saves the trek so that we have an identifier
    trek.save!


    newDir = trek.path
    newpDir = trek.processed_path
    FileUtils.mkdir_p newDir
    FileUtils.mkdir_p newpDir
    Zip::Archive.open(zip_path) do |ar|
      ar.each do |zf|
        curfile = File.join newDir, zf.name
        if zf.directory?
          FileUtils.mkdir_p(curfile)
        # TODO: weak file detection:
        # Only checking by file extension
        elsif AUTHORIZED_EXT.include? File.extname(curfile)
          dirname = File.dirname(curfile)
          FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
          open(curfile, 'wb') do |f|
            f << zf.read
          end
        end
      end
    end

    # Parsing every image files
    gpx_img_infos = trek.get_images_info_from_gpx

    Find.find(trek.path) do |path|
      if JPEG_EXT.include? File.extname(path)
        begin
          Magick::Image::read(path)
          puts "file.path: #{path}"
          matched = gpx_img_infos.select { |i| File.basename(i['filename']) == File.basename(path) }
          # TODO: add them anyway but with unknown lat/lon ?
          if matched.nil? || matched.empty?
            img = Image.new(:filename => path)
            img.trek_id = trek.id
            img.save!
          else
            matched = matched.first
            img = Image.new( :filename => path,
                            :latitude => matched['lat'],
                            :longitude => matched['lon']
                           )
            img.trek_id = trek.id
            img.save!
          end
        rescue Magick::ImageMagickError
          log.info "Skipping bad image file"
          FileUtils.rm curfile
        end
      end
    end

    trek
  end

  ##
  # Gets images informations, by parsing the GPX file corresponding to the
  # current trek
  ##
  def get_images_info_from_gpx
    ret = Array.new
    gpxFile = gpx
    if gpxFile
      @doc = Nokogiri::XML(File.open(gpxFile))
      wayPts = @doc.xpath '//gpx:wpt', GPX_NAMESPACE
      wayPts.each do |wpt|
        nameNodes = wpt.xpath './gpx:name', GPX_NAMESPACE
        isPicture = nameNodes.children.first.inner_text == 'Photographier'
        if isPicture
          elem = Hash.new
          filename = wpt.xpath('./gpx:link/gpx:text', GPX_NAMESPACE).first.inner_text
          datetime = wpt.xpath('./gpx:time', GPX_NAMESPACE).first.inner_text
          elem['filename']  = filename
          elem['thumbnail'] = self.base_url + '/thumbnail/' + filename
          elem['minimage']  = self.base_url + '/min/' + filename
          elem['lat'] = wpt['lat']
          elem['lon'] = wpt['lon']
          elem['datetime'] = datetime
          ret.push elem
        end
      end
    end
    ret
  end

  ##
  # Gets the images info for the current trek
  ##
  def images_info
      ret = []
      images.each do |i|
        # <Image id: 99, 
        # filename: "/treks/44/picture/2011-12-11_10-44-36.jpg",
        # latitude: 45.40352712,
        # longitude: 5.90387236,
        # trek_id: 44,
        # created_at: "2013-01-19 23:16:44",
        # updated_at: "2013-01-19 23:16:44">
        # to_add['filename'] = "#{self.base_url}/picture/#{i.filename}
        current_img = {}
        current_img['filename'] = i.image_url
        current_img['thumbnail'] = i.thumbnail_url
        current_img['minimage'] = i.min_url
        current_img['lat'] = i.latitude
        current_img['lon'] = i.longitude
        ret << current_img
      end
      ret
  end
  ##
  # Gets the elevation details from the GPX file
  # and returns an array of hashes containing
  # the elevation (ele) and the timestamp (time)
  #
  # The result is cached into a JSON file (into
  # the processed/ directory)
  ##
  def get_elevation_details
    ele_json = processed_path + "/ele.json"
    unless File.exists? ele_json
      ele_details = Array.new
      gpxFile = gpx
      if gpxFile
        eleparser = ElevationParser.new
        parser = XML::SAX::Parser.new(eleparser)
        parser.parse_file(gpxFile)
        ele_details = eleparser.elevation_table.to_json
      end
      processed_ele = File.new(ele_json, "w")
      processed_ele.write ele_details
      processed_ele.close
    end
    ele_json
  end

  ##
  # Returns the number of pictures that the
  # current trek contains
  ##
  def images_count
    images.length
  end

  ##
  # Returns the directory path of the files
  # associated with the current trek.
  #
  # they are stored into uploads/[user_id]/[trek_id]/
  ##
  def path
    @path ||= File.join(Rails.root, "uploads", user_id.to_s, id.to_s)
  end

  ##
  # Returns the directory path of the processed contents
  # for the current trek
  #
  # These files are stored into processed/[user_id]/[trek_id]/
  ##
  def processed_path
    @processed_path ||= File.join(Rails.root, "processed", user_id.to_s, id.to_s)
  end

  ##
  # Returns the base URL of the current trek
  ##
  def base_url
    @base_url ||= "/treks/%d" % [id]
  end

  ##
  # Returns the URL of the GPX for the current
  # trek
  ##
  def gpx_url
    @gpx_url ||= "#{base_url}/gpx"
  end

  ##
  # Removes the files associated with the current trek
  ##
  def remove_files
    FileUtils.rm_rf path
    FileUtils.rm_rf processed_path
  end

  private

  ##
  # Returns the GPX path, given its filename
  ##
  def compute_gpx_path
    Find.find(path) do |p|
      if GPX_EXT.include? File.extname(p)
        return p
      end
    end
  end

end
