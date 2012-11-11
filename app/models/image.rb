class Image < ActiveRecord::Base
  belongs_to :trek
  attr_accessible :filename, :latitude, :longitude

  ##
  # Gets the picture path, given its filename
  ##
  def get_image_path
      trek.get_path
     Find.find(trek.get_path) do |path|
      if File.basename(path) == fname
        return path
      end
    end
  end

  ##
  # Returns the thumbnail path, given its filename
  ##
  def get_thumbnail
     Find.find(trek.get_processed_path) do |path|
      if File.basename(path) == fname
        return path
      end
    end
  end

  ##
  # Returns the minified image path (900px), given its filename
  ##
  def get_min_image (fname)
     Find.find(self.get_processed_path) do |path|
      if File.basename(path) == fname
        return path
      end
    end
  end


  ##
  # Sends the raw image to the browser
  # TODO: into the Image controller instead ?
  ##
  def raw_get
    send_file get_img_path(filename),
        :type => "image/jpeg",
        :disposition => "inline"
  end

  ##
  # Sends a thumbnail of the image which filename
  # is given in argument (75x75 sized)
  # the thumbnail is generated on the fly into
  # processed/ subdirectory if it does not exist
  # yet, else it is sent as stored into the previous
  # directory
  ##
  def raw_thumbnail
    thumb_path = get_thumbnail(filename)
    if thumb_path.nil?
      img = Magick::Image.read(@trek.get_img_path(fname)).first
      thumb = img.resize_to_fill(75, 75)
      thumb.write(@trek.get_processed_path + "/" + fname)
      send_data thumb.to_blob, :type => "image/jpeg", :disposition => "inline"
    else
      send_file thumb_path, :type => "image/jpeg", :disposition => "inline"
    end
  end

  def getminimage
    @trek = Trek.find params[:id]
    if @trek.nil?
      redirect_to treks_path, :alert => "Trek not found."
    end
    fname = params["name"]+"."+params["format"]
    min_fname = params["name"]+".min."+params["format"]
    min_path = @trek.get_min_image(min_fname)
    if min_path.nil?
      img = Magick::Image.read(@trek.get_img_path(fname)).first
      min = img.resize_to_fill(600, 600)
      min.write(@trek.get_processed_path + "/" + min_fname)
      send_data min.to_blob, :type => "image/jpeg", :disposition => "inline"
    else
      send_file min_path, :type => "image/jpeg", :disposition => "inline"
    end
  end



end
