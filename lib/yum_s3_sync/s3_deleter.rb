require 'aws-sdk-v1'

module YumS3Sync
  class S3Deleter
    def initialize(bucket, prefix, dry_run = false)
      @bucket = bucket
      @prefix = prefix
      @dry_run = dry_run
    end

    def delete(file)
      s3 = AWS::S3.new

      target = "#{@prefix}/#{file}"
      target.gsub!(/\/+/, '/')

      dest_obj = s3.buckets[@bucket].objects[target]

      if dest_obj.exists?
        if @dry_run
          puts "Dry-run: Deleting #{@bucket}::#{target}"
        else
          puts "Deleting #{@bucket}::#{target}"
          dest_obj.delete
        end
      end
    end
  end
end
