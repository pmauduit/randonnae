require 'find'
require 'nokogiri'
require 'elevation_parser'

class Trek < ActiveRecord::Base
  belongs_to :user
  validates :title, :presence => true

  has_many :images

  before_destroy :remove_files

  # the official GPX XML namespace
  GPX_NAMESPACE =  { "gpx" => "http://www.topografix.com/GPX/1/1" }

  # Array for the expected image file extensions
  JPEG_EXT = [ ".jpg", ".JPG", ".JPEG", ".jpeg" ]

  # Array for the expected extensions into the ZIP archive
  AUTHORIZED_EXT =  [".gpx", ".GPX" ].concat JPEG_EXT

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
  # Creates a trek from a ZIP file
  ##
  def self.create_from_archive(user_id, trek_title, zip_path)
    trek = Trek.new
    trek.title = trek_title
    trek.user_id = user_id

    gpx_img_infos = get_images_info_from_gpx

    newDir = get_path
    newpDir = get_processed_path
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
          # creates the underlying image objects
          if JPEG_EXT.include? File.extname(curfile)
            begin
              Magick::Image::read(curfile)
              matched = gpx_img_infos.select { |i| i.filename == File.basename(curfile) }
              next if matched.nil?
              matched = matched.first

              img = Image.new( :filename => matched.filename,
                               :latitude => matched.latitude,
                               :longitude => matched.longitude,
                               :trek_id => id )
              img.save
            rescue Magick::ImageMagickError
              log.info "Skipping bad image file"
              FileUtils.rm curfile
            end
          end
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
    gpxFile = self.get_gpx
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
          elem['filename']  = self.base_url + '/picture/' + filename
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
  # Gets image info
  ##
  def get_images_info
    img_json = get_processed_path + "/img.json"
    unless File.exists? img_json
      ret = get_images_info_from_gpx
      # TODO: adds here the logic to scan
      # the images without info into the GPX
      processed_img = File.new(img_json, "w")
      processed_img.write ret.to_json
      processed_img.close
    end
    img_json
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
    ele_json = get_processed_path + "/ele.json"
    unless File.exists? ele_json
      ele_details = Array.new
      gpxFile = get_gpx
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
  # Returns the GPX path, given its filename
  ##
  def get_gpx
    Find.find(get_path) do |path|
      if File.basename(path).end_with?(".gpx")
        return path
      end
    end
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
  def get_path
    path = File.join(Rails.root, "uploads", user_id.to_s, id.to_s)
  end

  ##
  # Returns the directory path of the processed contents
  # for the current trek
  #
  # These files are stored into processed/[user_id]/[trek_id]/
  ##
  def get_processed_path
    File.join(Rails.root, "processed", user_id.to_s, id.to_s)
  end

  ##
  # Returns the base URL of the current trek
  ##
  def base_url
    "/treks/%d" % [id]
  end

  ##
  # Returns the URL of the GPX for the current
  # trek
  ##
  def gpx_url
    self.base_url + "/gpx"
  end

  ##
  # Removes the files associated with the current trek
  ##
  def remove_files
    FileUtils.rm_rf get_path
    FileUtils.rm_rf get_processed_path
  end

end
