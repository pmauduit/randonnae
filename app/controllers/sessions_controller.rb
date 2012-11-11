class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    user = User.find_by_uid(auth["uid"]) || User.create_with_omniauth(auth)
    session[:user_id] = user.id
    redirect_to root_url, :notice => t(:signed_in)
  end
  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => t(:signed_out)
  end

end

