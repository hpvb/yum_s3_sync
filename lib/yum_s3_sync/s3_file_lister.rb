require 'aws-sdk'
require 'parallel'

module YumS3Sync
  class S3FileLister
    def initialize(bucket, prefix)
      @bucket = bucket
      @prefix = prefix
    end

    def list
      s3 = AWS::S3.new

      puts "Listing all files in #{@bucket}:#{@prefix}"
      s3_objects = s3.buckets[@bucket].objects.with_prefix(@prefix)

      files = Parallel.map(s3_objects, :in_threads => 50) do |file|
        basename = file.key.sub(/#{@prefix}\/*/, '')
        size = file.content_length

        { :name => basename, :size => size }
      end

      puts "Processing files"
      filenames = []
      filenames_sizes = []
      files.each do |file|
        filenames.push file[:name]
        filenames_sizes.push "#{file[:name]}-#{file[:size]}"
      end

      return filenames, filenames_sizes
    end
  end
end
