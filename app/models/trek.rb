require 'find'

class Trek < ActiveRecord::Base
  belongs_to :user
  validates :title, :presence => true


  def nb_images
    ret = 0
    Find.find(self.get_path) do |path|
      filename = File.basename(path).downcase
      if filename.end_with?(".jpg") || filename.end_with?(".png")
        ret += 1
      end
    end
    return ret
  end

  def get_path
    return File.join(Rails.root, "uploads", self.user_id.to_s,
                     self.id.to_s)

  end


  def gpx_url
    return "/treks/%d/gpx" % [self.id]
  end


end
