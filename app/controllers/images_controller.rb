
class ImagesController < ApplicationController


  def get_image
      image = Image.find(params[:image_id])
      send_file image.filename,
        :type => "image/jpeg",
        :disposition => "inline"
  end

  def get_thumbnail
    image = Image.find(params[:image_id])
    send_file image.thumbnail,
        :type => "image/jpeg",
        :disposition => "inline"
  end

  def get_min_image
    image = Image.find(params[:image_id])
    send_file image.min_image,
        :type => "image/jpeg",
        :disposition => "inline"
  end


end

