#!/usr/bin/env ruby

require 'zlib'
require 'nokogiri'
require 'rexml/document'
require 'rexml/streamlistener'

module YumS3Sync
  class YumRepository
    attr_accessor :metadata

    def initialize(downloader)
      @metadata = {}
      @downloader = downloader

      repomd_file = @downloader.download('repodata/repomd.xml')
      if repomd_file
        doc = Nokogiri::XML(repomd_file)
        doc.xpath("//xmlns:data").each do |file|
          metadata[file['type']] = {
            :href => file.xpath('xmlns:location')[0]['href'],
            :checksum => file.xpath('xmlns:checksum')[0].child.to_s
          }
        end

        @metadata['repomd'] = { :href => 'repodata/repomd.xml' }
      else
        @metadata = { 'primary' => nil }
      end
    end

    def parse_packages
      return {} unless @metadata['primary']

      primary_file = @downloader.download(@metadata['primary'][:href])
      return {} unless primary_file

      puts "Parsing #{@metadata['primary'][:href]}"
      gzstream = Zlib::GzipReader.new(primary_file)

      doc = Nokogiri::XML(gzstream)
      packages = {}
      doc.xpath("//xmlns:package").each do |package|
        packages[package.xpath("xmlns:location")[0]['href']] = { 
          :checksum => package.xpath("xmlns:checksum")[0].child.to_s,
          :size => package.xpath("xmlns:size")[0]['package'].to_i
        }
      end

      packages
    end

    def packages
      @parsed_packages ||= parse_packages
    end

    def compare(other)
      diff_packages = []

      if !other.metadata['primary'] || metadata['primary'][:checksum] != other.metadata['primary'][:checksum]
        packages.each do |package, data|
          if !other.packages[package] || other.packages[package][:checksum] != data[:checksum]
            diff_packages.push package
          end
        end
      end

      diff_packages
    end

    def exists?
      @metadata['primary']
    end
  end

end
