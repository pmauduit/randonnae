require 'find'
require 'nokogiri'
require 'elevationparser'

class Trek < ActiveRecord::Base
  belongs_to :user
  validates :title, :presence => true

  @@gpx_namespace =  {"gpx" => "http://www.topografix.com/GPX/1/1"}

  # find all treks for a user,
  # given the user id as argument
  # Params:
  # +id+:: the user unique identifier
  def self.find_by_user (id)
    return self.find(:all, :conditions => ["user_id = ?", id ], :order => "id DESC")
  end

  # Gets images informations, by parsing the GPX file corresponding to the
  # current trek
  def get_images_info
    ret = Array.new
    gpxFile = self.get_gpx
    if gpxFile
      @doc = Nokogiri::XML(File.open(gpxFile))
      wayPts = @doc.xpath '//gpx:wpt', @@gpx_namespace
      wayPts.each do |wpt|
        nameNodes = wpt.xpath './gpx:name', @@gpx_namespace
        isPicture = nameNodes.children.first.inner_text == 'Photographier'
        if isPicture
          elem = Hash.new
          filename = wpt.xpath('./gpx:link/gpx:text', @@gpx_namespace).first.inner_text
          datetime = wpt.xpath('./gpx:time', @@gpx_namespace).first.inner_text
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
    return ret
  end

  # Gets the elevation details, from the GPX file
  # and returns an array of hashes containing
  # the elevation (ele) and the timestamp (time)
  def get_elevation_details
    ret = Array.new
    gpxFile = self.get_gpx
    if gpxFile
      eleparser = ElevationParser.new
      parser = XML::SAX::Parser.new(eleparser)
      parser.parse_file(gpxFile)
      return eleparser.elevation_table
    end
    return ret
  end




  # Gets the picture path, given its filename
  def get_img_path (fname)
     Find.find(self.get_path) do |path|
      if File.basename(path) == fname
        return path
      end
    end
  end

  # Returns the thumbnail path, given its filename
  def get_thumbnail (fname)
     Find.find(self.get_processed_path) do |path|
      if File.basename(path) == fname
        return path
      end
    end
  end

  # Returns the minified image path (900px), given its filename
  def get_min_image (fname)
     Find.find(self.get_processed_path) do |path|
      if File.basename(path) == fname
        return path
      end
    end
  end

  # Returns the GPX path, given its filename
  def get_gpx
    Find.find(self.get_path) do |path|
      if File.basename(path).end_with?(".gpx")
        return path
      end
    end
  end

  # Returns the base URL of the current trek
  def base_url
    return "/treks/%d" % [self.id]
  end

  # Returns the number of pictures that the
  # current trek contains
  def nb_images
    ret = 0
    gpxFile = self.get_gpx
    if gpxFile
      @doc = Nokogiri::XML(File.open(gpxFile))
      wayPts = @doc.xpath '//gpx:wpt', @@gpx_namespace
      ret = wayPts.length
    end
    return ret
  end

  # Returns the directory path of the files
  # associated with the current trek
  def get_path
    File.join(Rails.root, "uploads", self.user_id.to_s, self.id.to_s)
  end

  # Returns the directory path of the cropped images
  # from the pictures belonging to the current 
  # trek
  def get_processed_path
    path = File.join(Rails.root, "processed", self.user_id.to_s, self.id.to_s)
    unless File.exists? path
      FileUtils.mkdir_p path
    end
    path
  end

  # Returns the base URL of the current trek
  def base_url
    "/treks/%d" % [self.id]
  end

  # Returns the URL of the GPX for the current
  # trek
  def gpx_url
    self.base_url + "/gpx"
  end

end
