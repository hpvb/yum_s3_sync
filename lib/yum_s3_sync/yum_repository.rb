#!/usr/bin/env ruby

require 'zlib'
require 'stringio'
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
        repomd = StringIO.new(repomd_file.read())

        doc = Nokogiri::XML(repomd)
        doc.xpath("//xmlns:data").each do |file|
          href = file.xpath('xmlns:location')[0]['href']
          f = @downloader.download(href)
          if f
            metadata[file['type']] = {
              :href => href,
              :checksum => file.xpath('xmlns:checksum')[0].child.to_s,
              :file => StringIO.new(f.read())
            }
          end
        end

        repomd.rewind()
        @metadata['repomd'] = { :href => 'repodata/repomd.xml', :file => repomd }
      else
        @metadata = { 'primary' => nil }
      end
    end

    def parse_packages
      return {} unless @metadata['primary']

      puts "Parsing #{@metadata['primary'][:href]}"
      gzstream = Zlib::GzipReader.new(@metadata['primary'][:file])

      doc = Nokogiri::XML(gzstream)
      packages = {}
      doc.xpath("//xmlns:package").each do |package|
        packages[package.xpath("xmlns:location")[0]['href']] = package.xpath("xmlns:checksum")[0].child.to_s
      end

      @metadata['primary'][:file].rewind()
      packages
    end

    def packages
      @parsed_packages ||= parse_packages
    end

    def compare(other)
      diff_packages = []

      if !other.metadata['primary'] || metadata['primary'][:checksum] != other.metadata['primary'][:checksum]
        packages.each do |package, checksum|
          if other.packages[package] != checksum
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
