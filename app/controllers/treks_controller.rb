require 'zipruby'
require 'find'
require 'RMagick'

class TreksController < ApplicationController

  before_filter :check_logged_in, :only => [:create, :destroy, :modify]

  ##
  # Retrieves every treks from the database
  # TODO: pagination when the list will grow up
  ##
  def index
    @treks = Trek.all
  end

  ##
  # Retrieves every treks given a user id in argument
  ##
  def index_by_user
    @user = User.find_by_id params[:id]
    if @user.nil?
      redirect_to root_url, :alert => tr(:user_not_found)
    end
  end

  ##
  # Creates a new trek (entry in the database, and
  # inflating the provided zip file into the uploads/
  # subdirectory)
  ##
  def create
    if current_user == nil
    end
    trek = Trek.create_from_archive(current_user.id, params["trek"]["title"], params["trek"]["asset"].path)
    if trek.save
      flash[:notice] = tr(:trek_created)
      redirect_to trek
    else
      # TODO: more info about the error ? Catching exceptions ?
      render :action => 'new'
    end
  end

  ##
  # Shows a specific trek given its id
  ##
  def show
    @trek = Trek.find_by_id(params[:id])
    unless @trek.nil?
      if @trek.user.nil?
        redirect_to treks_path,
                    :alert => tr(:user_not_found_for_trek) + trek.title
      end
    else
      redirect_to treks_path, :alert => tr(:trek_not_found)
    end
  end

  ##
  # Gets the gpx (XML) from the trek
  # the first file with ".gpx" extension is returned
  ##
  def get_gpx
    trek = Trek.find_by_id(params[:id])
    unless trek.nil?
      send_file trek.get_gpx(), :type => "text/xml", :disposition => "inline"
    end
  end

  ##
  # Returns JSON infos about the pictures
  # that accompagny the trek.
  ##
  def get_images_info
    trek = Trek.find_by_id(params[:id])
    unless trek.nil?
      send_file(trek.get_images_infos,
                {:type => "application/json", :disposition => "inline"})
    end
  end

  ##
  # Gets the elevation details of a trek (elevation w/ timestamp)
  # and returns it as JSON to the browser
  ##
  def get_elevation_details
    trek = Trek.find_by_id(params[:id])
    unless trek.nil?
      send_file(trek.get_elevation_details,
                {:type => "application/json", :disposition => "inline"})
    end
  end

  ##
  # Deletes the trek which id is given as argument
  ##
  def destroy
   @trek = Trek.find(params[:id])
    if @trek.user_id != current_user.id
      redirect_to :action => "index",
        :alert => tr(:trek_not_owned)
    end
    @trek.destroy
    flash[:notice] = tr(:trek_successfully_removed)
    redirect_to :action => "index"
  end
end
