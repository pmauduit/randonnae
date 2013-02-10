require 'find'

class Image < ActiveRecord::Base

  belongs_to :trek
  attr_accessible :filename, :latitude, :longitude

  MIN_IMAGE_DIMENSION = 600
  THUMBNAIL_DIMENSION = 75

  def image_url
      @image_url ||= "/treks/#{trek.id}/picture/#{id}"
  end

  def thumbnail_url
      @image_url ||= "/treks/#{trek.id}/thumbnail/#{id}"
  end

  def min_url
      @image_url ||= "/treks/#{trek.id}/min/#{id}"
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
    thumb_path
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
   min_path
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
