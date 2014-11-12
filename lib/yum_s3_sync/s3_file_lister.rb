require 'aws-sdk'

module YumS3Sync
class S3FileLister
  def initialize(bucket, prefix)
    @bucket = bucket
    @prefix = prefix
  end

  def list
    files = []

    s3 = AWS::S3.new
    s3.buckets[@bucket].objects.with_prefix(@prefix).each do |file|
      basename = file.key.sub(/#{@prefix}\/*/, "")

      files.push basename
    end

    files
  end
end
end
