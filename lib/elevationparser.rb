require 'rubygems'
require 'nokogiri'
include Nokogiri

class ElevationParser < XML::SAX::Document
  attr_reader :elevation_table

  def initialize
    super
    @into_trkpt = false
    @into_ele = false
    @into_time = false
    @elevation_table = []
    @current_element = {}
  end

  def start_element(element, attributes)
    if element == 'trkpt'
      @into_trkpt = true
    elsif element == 'ele' && @into_trkpt
      @into_ele = true
    elsif element == 'time' && @into_trkpt
      @into_time = true
    end
  end
  def characters(str)
    if @into_trkpt
      if @into_ele
        @current_element[:ele] = str
      elsif @into_time
        @current_element[:time] = str
      end
    end
  end
  def end_element(element)
    if element == 'trkpt'
      @into_trkpt = false
      @into_time = false
      @into_ele = false
      if @current_element[:ele] && @current_element[:time]
        @elevation_table << @current_element
        @current_element = {}
      end
    elsif element == 'ele'
      @into_ele = false
    elsif element == 'time'
      @into_time = false
    end
  end
end


