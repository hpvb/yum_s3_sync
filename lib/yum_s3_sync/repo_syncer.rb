#!/usr/bin/env ruby

require 'yum_s3_sync'

module YumS3Sync
  class RepoSyncer
    def initialize(source_base, target_bucket, target_base)
      @source_base = source_base
      @target_bucket = target_bucket
      @target_base = target_base
    end

    def sync
      http_downloader = YumS3Sync::HTTPDownloader.new(@source_base)
      source_repository = YumS3Sync::YumRepository.new(http_downloader)

      s3_downloader = YumS3Sync::S3Downloader.new(@target_bucket, @target_base)
      dest_repository = YumS3Sync::YumRepository.new(s3_downloader)

      new_packages = source_repository.compare(dest_repository)
      s3_uploader = YumS3Sync::S3Uploader.new(@target_bucket, @target_base, http_downloader)

      metadata = []
      source_repository.metadata.each do |_type, file|
        metadata.push file[:href]
      end

      new_packages.each do |package|
        s3_uploader.upload(package)
      end

      if !dest_repository.exists? || !new_packages.empty?
        metadata.each do |file|
          s3_uploader.upload(file, true)
        end
      end

      unless new_packages.empty?
        s3_file_lister = YumS3Sync::S3FileLister.new(@target_bucket, @target_base)
        s3_deleter = YumS3Sync::S3Deleter.new(@target_bucket, @target_base)

        s3_file_lister.list.each do |file|
          if !source_repository.packages[file] && !metadata.include?(file)
            s3_deleter.delete(file)
          end
        end
      end
    end
  end
end
