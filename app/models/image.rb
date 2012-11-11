class Image < ActiveRecord::Base
  belongs_to :trek
  attr_accessible :filename, :latitude, :longitude
end
