require 'zipruby'
require 'find'
require 'RMagick'

class TreksController < ApplicationController

  def index
    @treks = Trek.all
  end

  def indexbyuser
    @treks = Trek.find(:all, :conditions => "user_id = %d" [params["id"].to_s], :order => "id DESC")
    render :index
  end

  def getimage
    @trek = Trek.find(params[:id])
    if @trek == nil
      redirect_to treks_path, :alert => "Trek not found."
    end
   send_file @trek.get_img_path(params[:name] + "." + params[:format]),
        :type => "image/jpeg",
        :disposition => "inline"
  end

  def getthumbnail
    @trek = Trek.find(params[:id])
    if @trek.nil?
      redirect_to treks_path, :alert => "Trek not found."
    end
    fname = params["name"]+"."+params["format"]
    thumb_path = @trek.get_thumbnail(fname)
    if thumb_path.nil?
      img = Magick::Image.read(@trek.get_img_path(fname)).first
      thumb = img.resize_to_fill(75, 75)
      thumb.write(@trek.get_thumbnail_path + "/" + fname)
      send_data thumb.to_blob, :type => "image/jpeg", :disposition => "inline"
    else
      send_file thumb_path, :type => "image/jpeg", :disposition => "inline"
    end
  end



  def new
    if current_user.nil?
      redirect_to root_url, :alert => "You need to log in before
                  trying to add a trek !"
    end
    @trek = Trek.new
  end

  def create
    if current_user == nil
      redirect_to root_url, :alert => "You need to log in before
                  trying to add a trek !"
    end
    @trek = Trek.new
    @trek.user_id = current_user.id
    @trek.title   = params["trek"]["title"]
    if @trek.save
      flash[:notice] = "Successfully created the trek."
      # save ZIP file somewhere
      begin
        newDir = File.join(Rails.root, "uploads", @trek.user_id.to_s,
                                    @trek.id.to_s)
        FileUtils.mkdir_p newDir
        begin
          Zip::Archive.open(params["trek"]["asset"].path) do |ar|
            ar.each do |zf|
              curfile = File.join newDir, zf.name
              if zf.directory?
                FileUtils.mkdir_p(curfile)
              else
                dirname = File.dirname(curfile)
                FileUtils.mkdir_p(dirname) unless File.exist?(dirname)
                open(curfile, 'wb') do |f|
                  f << zf.read
                end
              end
            end
          end
      end
      rescue ex
        puts ex
      end
      redirect_to @trek
    else
      render :action => 'new'
    end
  end

  def show
    @trek = Trek.find_by_id(params[:id])
    if @trek
      @user = User.find_by_id(@trek.user_id)
    else
      redirect_to treks_path, :alert => "Trek not found."
    end
  end

  def getgpx
    trek = Trek.find_by_id(params[:id])
    send_file trek.get_gpx(), :type => "text/xml", :disposition => "inline"
  end

  def getimagesinfo
    trek = Trek.find_by_id(params[:id])
    send_data trek.get_images_info.to_json, :disposition => "inline"
  end


  def destroy
    if current_user == nil
      redirect_to root_url, :alert => "You need to log in before
                  trying to destroy a trek !"
    end
    @trek = Trek.find(params[:id])

    if @trek.user_id != current_user.id
      redirect_to :action => "index",
        :alert => "You cannot remove this trek because it does not belong to you."
    end
    @trek.destroy
    begin
      FileUtils.rm_rf File.join(Rails.root, "uploads", @trek.user_id.to_s,
                                    @trek.id.to_s)
    rescue Error

    end
    flash[:notice] ="Trek successfully removed."
    redirect_to :action => "index"
  end
end
