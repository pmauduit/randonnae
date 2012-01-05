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
          elem['filename'] = '/treks/' + self.id.to_s + '/picture/' + filename
          elem['lat'] = wpt['lat']
          elem['lon'] = wpt['lon']
          ret.push elem
        end
      end

    end

    return ret
  end

  def get_gpx
    trekPath =  File.join(Rails.root, "uploads", self.user_id.to_s, self.id.to_s)

    Find.find(trekPath) do |path|
      if File.basename(path).end_with?(".gpx")
        return path
      end
    end
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


  def gpx_url
    return "/treks/%d/gpx" % [self.id]
  end


end
