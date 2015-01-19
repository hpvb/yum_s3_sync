#!/usr/bin/env ruby

require 'yum_s3_sync'
require 'parallel'

module YumS3Sync
  class RepoSyncer
    def initialize(source_base, target_bucket, target_base, keep = false, dry_run = false)
      @source_base = source_base
      @target_bucket = target_bucket
      @target_base = target_base
      @keep = keep
      @dry_run = dry_run
    end

    def sync
      http_downloader = YumS3Sync::HTTPDownloader.new(@source_base)
      source_repository = YumS3Sync::YumRepository.new(http_downloader)

      s3_downloader = YumS3Sync::S3Downloader.new(@target_bucket, @target_base)
      dest_repository = YumS3Sync::YumRepository.new(s3_downloader)

      s3_uploader = YumS3Sync::S3Uploader.new(@target_bucket, @target_base, http_downloader, @dry_run)

      s3_file_lister = YumS3Sync::S3FileLister.new(@target_bucket, @target_base)
      s3_deleter = YumS3Sync::S3Deleter.new(@target_bucket, @target_base, @dry_run)

      new_packages = source_repository.compare(dest_repository)

      metadata = []
      source_repository.metadata.each do |_type, file|
        metadata.push file[:href]
      end

      new_packages.each do |package|
        s3_uploader.upload(package, @keep)
      end

      if !dest_repository.exists? || !new_packages.empty?
        metadata.each do |file|
          s3_uploader.upload(file, true)
        end
      end

      file_names, file_names_sizes = s3_file_lister.list

      puts "Locating removed files"
      file_names.each do |filename|
        if !source_repository.packages[filename] && !metadata.include?(filename)
          s3_deleter.delete(filename)
        end
      end

      puts "Locating missing files"
      source_repository.packages.each do |package, data|
        unless file_names_sizes.include? "#{package}-#{data[:size]}"
          s3_uploader.upload(package, true)
        end
      end

    end
  end
end
