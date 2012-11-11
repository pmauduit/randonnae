class HomeController < ApplicationController
  def index
    @last_ten_treks = Trek.last_ten
  end

end
