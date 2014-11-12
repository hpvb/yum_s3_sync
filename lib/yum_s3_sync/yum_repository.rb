#!/usr/bin/env ruby

require 'zlib'
require 'rexml/document'
require 'rexml/streamlistener'

module YumS3Sync
class YumRepository
  attr_accessor :metadata

  def initialize(downloader)
    @downloader = downloader

    repomd_parser = RepModListener.new
    repomd_file = @downloader.download('repodata/repomd.xml')
    if repomd_file 
       REXML::Document.parse_stream(repomd_file, repomd_parser)
       @metadata = repomd_parser.metadata
       @metadata['repomd'] = 'repodata/repomd.xml'
    else
       @metadata = { 'primary' => nil }
    end
  end

  def parse_packages
    return {} if ! @metadata['primary']

    primary_file = @downloader.download(@metadata['primary'])
    return {} if ! primary_file

    gzstream = Zlib::GzipReader.new(primary_file)
    package_parser = PackageListener.new

    REXML::Document.parse_stream(gzstream, package_parser)
    package_parser.packages
  end

  def packages
    @parsed_packages ||= parse_packages
  end

  def compare(other)
    diff_packages = []

    packages.each do |package, checksum| 
      if other.packages[package] != checksum 
        diff_packages.push package
      end
    end

    diff_packages
  end
end

class PackageListener
  attr_accessor :packages
  include REXML::StreamListener

  def initialize
    self.packages = {}
  end

  def tag_start(name, *attrs)
    @current_tag = name
    case name
    when 'metadata'
      puts "Parsing #{attrs[0]['packages']} packages"
    when 'package'
      @package = {}
    when 'location'
      @package['href'] = attrs[0]['href']
    end
  end

  def tag_end(name)
    case name
    when 'package'
      if @package
        self.packages[@package['href']] = @package['checksum']
        @package = nil
      else
        fail "Unmatched <package> tag"
      end
    end
  end

  def text(data)
    return if data =~ /^\s+$/
    if @current_tag == 'checksum'
       @package['checksum'] = data
    end
  end
end

class RepModListener
  attr_accessor :metadata
  include REXML::StreamListener

  def initialize
    self.metadata = {}
  end

  def tag_start(name, *attrs)
    @current_tag = name
    case name
    when 'data'
      @data = {}
      @data['type'] = attrs[0]['type']
    when 'location'
      @data['location'] = attrs[0]['href']
    end
  end

  def tag_end(name)
    case name
    when 'data'
      if @data
        self.metadata[@data['type']] = @data['location']
        @data = nil
      else
        fail "Unmatched <data> tag"
      end
    end
  end
end
end
