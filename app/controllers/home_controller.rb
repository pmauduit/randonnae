class HomeController < ApplicationController
  def index
    @last_ten_treks = Trek.find(:all, :order => "id desc", :limit => 5).reverse
  end

end
