require 'test_helper'

class TrekTest < ActiveSupport::TestCase


 ##
 # This trick allows to create a sample
 # trek for the whole testsuite, instead
 # of using setup / teardown which would
 # be called before / after each defined
 # method.
 ##
 class << self
    def startup
      # Loads a sample trek
    end
    def shutdown
      # deletes the sample trek
    end
    def suite
      mysuite = super
      def mysuite.run(*args)
        TrekTest.startup()
        super
        TrekTest.shutdown()
      end
      mysuite
    end
  end

  def test_trek_find_by_user
    invalid_user_treklist =  Trek.find_by_user(-1)
    # must be an array
    assert_instance_of Array, invalid_user_treklist
    # and of course, it must be empty
    assert invalid_user_treklist.empty?
  end


  def test_last_ten
    last_ten = Trek.last_ten
    # must be an array
    assert_instance_of Array, last_ten
    # and must contain from 0 to 10 elements
    assert last_ten.length <= 10
  end

  def test_create_by_archive

  end


  def test_get_images_info
    # TODO: implies loading a trek test
    assert false, "Test not implemented yet"
  end

  def test_get_elevation_details
    # TODO: same remark
    assert false, "Test not implemented yet"
  end

end
