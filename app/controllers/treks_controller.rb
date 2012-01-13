require 'zipruby'
require 'find'
require 'RMagick'

class TreksController < ApplicationController

  # retrieves every treks from the database
  # TODO: pagination when the list will grow up
  def index
    @treks = Trek.all
  end

  # retrieves every treks given a user id in argument
  def indexbyuser
    @user = User.find_by_id params[:id]
    unless @user.nil?
      @treks = Trek.find_by_user params[:id]
    else
      redirect_to root_url, :alert => "User not found"
    end
  end

  # Sends the raw image
  def getimage
    @trek = Trek.find params[:id]
    if @trek == nil
      redirect_to treks_path, :alert => "Trek not found."
    end
    filename = params[:name] + "." + params[:format]
    send_file @trek.get_img_path(filename),
        :type => "image/jpeg",
        :disposition => "inline"
  end

  # Sends a thumbnail of the image which filename
  # is given in argument (75x75 sized)
  # the thumbnail is generated on the fly into
  # processed/ subdirectory if it does not exist
  # yet, else it is sent as stored into the previous
  # directory
  def getthumbnail
    @trek = Trek.find params[:id]
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

  # Prepares the creation of a trek
  def new
    if current_user.nil?
      redirect_to root_url, :alert => "You need to log in before
                  trying to add a trek !"
    end
    @trek = Trek.new
  end

  # Creates a new trek (entry in the database, and
  # inflating the provided zip file into the uploads/
  # subdirectory)
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
      # saves the ZIP file
      begin
        newDir = @trek.get_path
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
      rescue
      end
      redirect_to @trek
    else
      render :action => 'new'
    end
  end

  # Show a specific trek given its id
  def show
    @trek = Trek.find_by_id(params[:id])
    unless @trek.nil?
      @user = User.find_by_id(@trek.user_id)
      if @user.nil?
        redirect_to treks_path,
                    :alert => "User not found for trek #{@trek.title}."
      end
    else
      redirect_to treks_path, :alert => "Trek not found."
    end
  end

  # Gets the gpx (XML) from the trek
  # the first file with ".gpx" extension is returned
  def getgpx
    trek = Trek.find_by_id(params[:id])
    send_file trek.get_gpx(), :type => "text/xml", :disposition => "inline"
  end

  # Returns JSON infos about the pictures
  # that accompagny the trek.
  # Note: it is possible to provide more picture files
  # but only the ones that are georeferenced into the GPX
  # file are taken into account
  def getimagesinfo
    trek = Trek.find_by_id(params[:id])
    send_data trek.get_images_info.to_json, :disposition => "inline"
  end

  # Deletes the trek which id is given as argument
  # It removes also the files provided in the ZIP file
  # that has been uploaded during the trek creation
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
      # removes files associated to the trek
      FileUtils.rm_rf @trek.get_path
      FileUtils.rm_rf @trek.get_thumbnail_path
    rescue Error

    end
    flash[:notice] ="Trek successfully removed."
    redirect_to :action => "index"
  end
end
