#!/usr/bin/env ruby

require 'fileutils'
require 'rss/2.0'
require 'open-uri'
require 'cgi'

class Trailer
  TRAILERS_URL    = 'http://feeds.feedburner.com/Feed-For-Trailer-Freaks?format=xml'
  VIDEO_FORMAT    = '480P'
  VALID_FILE_SIZE = 1048576 # 1 megabyte

  attr_accessor :title, :description

  def initialize(rss)
    self.title = rss.title
    self.description = rss.description
  end

  class << self
    attr_accessor :all

    def parse_trailers
      @all = []
      open(TRAILERS_URL) do |http|
        response = http.read
        rss = RSS::Parser.parse(response, false)
        rss.items.each { |trailer| @all.push(new(trailer)) }
      end
    end

    def check_all
      parse_trailers
      @all.each { |trailer| trailer.download_if_not_exists_or_invalid }
    end
  end

  def download_if_not_exists_or_invalid
    if exist? && ( file_size < VALID_FILE_SIZE )
      delete; download
    elsif !exist?
      download
    end
  end

  private

  def filename
    CGI::escape(title) + '.mov'
  end

  def url
    description.scan(/<a href="(.*?)">#{VIDEO_FORMAT}<\/a>/).to_s
  end

  def exist?
    File.exists?(filename)
  end

  def file_size
    File.size(filename)
  end

  def download
    return if exist?
    puts "Downloading '#{title}' trailer"

    trailer = open(filename, 'wb')
    trailer.write(open(url).read)
    trailer.close
  end

  def delete
    File.delete(filename) if exist?
    puts "Deleted broken trailer '#{title}'"
  end
end

Trailer.check_all
