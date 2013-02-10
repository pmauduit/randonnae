require 'zipruby'
require 'find'
require 'RMagick'

class TreksController < ApplicationController

  before_filter :check_logged_in, :only => [ :new, :create ]
  before_filter :check_logged_in_and_owner, :only => [ :destroy, :modify ]

    def check_logged_in_and_owner
      check_logged_in
      trek = Trek.find(params[:id])
      if trek.user.id != current_user.id
        redirect_to root_url, :alert => t(:trek_not_owned)
      end
    end

  def new
    @trek = Trek.new
  end

  ##
  # Retrieves every treks from the database
  ##
  def index(offset = 0)
    @treks = Trek.limit(10).offset(offset)
  end

  ##
  # Retrieves every treks given a user id in argument
  ##
  def index_by_user
    @user = User.find_by_id params[:id]
    if @user.nil?
      redirect_to root_url, :alert => t(:user_not_found)
    end
  end

  ##
  # Creates a new trek (entry in the database, and
  # inflating the provided zip file into the uploads/
  # subdirectory)
  ##
  def create
    trek = Trek.create_from_archive(current_user.id, params["trek"]["title"], params["trek"]["asset"].path)
    if trek.save
      flash[:notice] = t(:trek_created)
      redirect_to trek
    else
      flash[:error] = t(:error_occured)
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
                    :alert => "#{t(:user_not_found_for_trek)} #{trek.title}"
      end
    else
      redirect_to treks_path, :alert => t(:trek_not_found)
    end
  end

  ##
  # Gets the gpx (XML) from the trek
  # the first file with ".gpx" extension is returned
  ##
  def get_gpx
    trek = Trek.find_by_id(params[:id])
    unless trek.nil?
      send_file trek.gpx, :type => "text/xml", :disposition => "inline"
    end
  end

  ##
  # Returns JSON infos about the pictures
  # that accompagny the trek.
  ##
  def get_images_info
    trek = Trek.find_by_id(params[:id])
    unless trek.nil?
      render :json => trek.images_info
    else
      render :json => []
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
   @trek.destroy
   flash[:notice] = t(:trek_successfully_removed)
   redirect_to :action => "index"
  end

end
