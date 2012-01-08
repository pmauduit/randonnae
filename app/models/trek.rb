require 'find'
require 'nokogiri'

class Trek < ActiveRecord::Base
  belongs_to :user
  validates :title, :presence => true

  def get_images_info
    ret = Array.new
    gpxFile = self.get_gpx
    if gpxFile
      @doc = Nokogiri::XML(File.open(gpxFile))
      wayPts = @doc.xpath '//dummy:wpt', {"dummy" => "http://www.topografix.com/GPX/1/1"}
      wayPts.each do |wpt|
        nameNodes = wpt.xpath './dummy:name', {"dummy" => "http://www.topografix.com/GPX/1/1"}
        isPicture = nameNodes.children.first.inner_text == 'Photographier'
        if isPicture
          elem = Hash.new
          filename = wpt.xpath('./dummy:link/dummy:text', {"dummy" => "http://www.topografix.com/GPX/1/1"}).first.inner_text
          datetime = wpt.xpath('./dummy:time', {"dummy" => "http://www.topografix.com/GPX/1/1"}).first.inner_text
          elem['filename'] = '/treks/' + self.id.to_s + '/picture/' + filename
          elem['thumbnail'] = '/treks/' + self.id.to_s + '/thumbnail/' + filename
          elem['lat'] = wpt['lat']
          elem['lon'] = wpt['lon']
          elem['datetime'] = datetime
          ret.push elem
        end
      end
    end
    return ret
  end

  def get_img_path (fname)
     Find.find(self.get_path) do |path|
      if File.basename(path) == fname
        return path
      end
    end
  end


  def get_gpx
    Find.find(self.get_path) do |path|
      if File.basename(path).end_with?(".gpx")
        return path
      end
    end
  end

  def base_url
    return "/treks/%d" % [self.id]
  end

  def nb_images
    ret = 0
    Find.find(self.get_path) do |path|
      filename = File.basename(path).downcase
      if filename.end_with?(".jpg")
        ret += 1
      end
    end
    return ret
  end

  def get_path
    return File.join(Rails.root, "uploads", self.user_id.to_s,
                     self.id.to_s)
  end

  def base_url
    return "/treks/%d" % [self.id]
  end



  def gpx_url
    return self.base_url + "/gpx"
  end


end
