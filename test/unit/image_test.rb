require 'test_helper'

class ImageTest < ActiveSupport::TestCase

  def setup
    puts "Into startup"
    @@sample_trek = Trek.create_from_archive(users(:one).id,
                                             "Sample trek",
                                             "test/resources/sample.zip")
    puts @@sample_trek
  end

  def teardown
    # deletes the sample trek
    #@@sample_trek.destroy
  end


  def test_get_image_path

  end

  def test_get_thumbnail

  end

  def test_get_min_image # (fname)

  end


end
