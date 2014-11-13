require 'aws-sdk'

module YumS3Sync
  class S3Downloader
    def initialize(bucket, prefix)
      @bucket = bucket
      @prefix = prefix
    end

    def download(relative_url)
      target = "#{@prefix}/#{relative_url}"
      target.gsub!(/\/+/, '/')

      puts "Downloading #{@bucket}::#{target}"

      s3 = AWS::S3.new
      file = s3.buckets[@bucket].objects[target]

      begin
        return StringIO.new(file.read)
      rescue AWS::S3::Errors::NoSuchKey
      end

      nil
    end
  end
end
