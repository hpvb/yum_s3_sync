require 'aws-sdk'

module YumS3Sync
  class S3Uploader
    def initialize(bucket, prefix, dry_run = false)
      @bucket = bucket
      @prefix = prefix
      @dry_run = dry_run
      @s3 = AWS::S3.new
    end

    def file_exists?(source_url)
        target = "#{@prefix}/#{source_url}"
        target.gsub!(/\/+/, '/')
        dest_obj = @s3.buckets[@bucket].objects[target]

        if dest_obj.exists? 
          return true
        end

        return false
    end

    def upload(source_url, file)
      retries = 0

      begin
        target = "#{@prefix}/#{source_url}"
        target.gsub!(/\/+/, '/')
        dest_obj = @s3.buckets[@bucket].objects[target]

        if @dry_run 
          puts "Dry-run: Uploading #{@bucket}::#{target}"
        else
          puts "Uploading #{@bucket}::#{target}"
          dest_obj.delete if dest_obj.exists?
          dest_obj.write(:file => file)
        end
      rescue StandardError => e
        if retries < 10
          retries += 1
          puts "Error uploading #{@bucket}::#{target} : #{e.message} retry ##{retries}"
          sleep(1)
          retry
        else
          puts "Error uploading #{@bucket}::#{target} : #{e.message} giving up"
          raise e
        end
      end
    end
  end
end
