require 'find'

class Image < ActiveRecord::Base

  belongs_to :trek
  attr_accessible :filename, :latitude, :longitude

  MIN_IMAGE_DIMENSION = 600
  THUMBNAIL_DIMENSION = 75

  def image_url
      @image_url ||= "/image/raw/#{id}"
  end

  def thumbnail_url
      @thumbnail_url ||= "/image/thumbnail/#{id}"
  end

  def min_url
      @min_url ||= "/image/min/#{id}"
  end

  def name
    @name ||= File.basename(filename, File.extname(filename))
  end
  ##
  # Returns the path to thumbnail of the image (75x75 sized).
  #
  # The thumbnail is generated on the fly into processed/ subdirectory if it
  # does not exist yet.
  ##
  def thumbnail
    # TODO: how to handle multiple formats here ? for now, only jpeg
    @thumbnail ||= File.join(self.trek.processed_path, "#{self.id}-thumb.jpg")
    unless File.exist?(@thumbnail)
      generate_miniature(@thumbnail, THUMBNAIL_DIMENSION)
    end
    @thumbnail
  end

  ##
  # Returns the path to miniature version of the image (600x600 sized)
  #
  # the miniature is generated on the fly into processed/ subdirectory if it
  # does not exist yet
  ##
  def min_image
    # TODO: same comment
    @min_image ||= File.join(self.trek.processed_path, "#{self.id}-min.jpg")
    unless File.exist?(@min_image)
      generate_miniature(@min_image, MIN_IMAGE_DIMENSION)
   end
   @min_image
  end

  private
  ##
  # Generates a miniature (thumbnail or miniature) of the image
  ##
  def generate_miniature(path, dimension)
      img = Magick::Image.read(self.filename).first
      min = img.resize_to_fill(dimension, dimension)
      min.write(path)
  end

end
