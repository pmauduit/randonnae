class User < ActiveRecord::Base
  has_many :treks
  def self.create_with_omniauth(auth)
    create! do |user|
      user.uid = auth["uid"]
      user.name = auth["info"]["name"]
      user.avatarurl = auth["info"]["image_url"]
    end
  end
end
