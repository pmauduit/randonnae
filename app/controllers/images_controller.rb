
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


  def get_image_infos
    image = Image.find(params[:image_id])
    js_info = {
      :name => image.name,
      :min_url => image.min_url,
      :thumbnail_url => image.thumbnail_url,
      :raw_url => image.image_url,
      :latitude => image.latitude,
      :longitude => image.longitude
    }
    render :json => js_info
  end
end

