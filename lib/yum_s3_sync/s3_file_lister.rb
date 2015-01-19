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

      s3_objects.map do |file|
        basename = file.key.sub(/#{@prefix}\/*/, '')
        basename
      end
    end
  end
end
