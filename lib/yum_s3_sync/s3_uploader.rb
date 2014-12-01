require 'aws-sdk'

module YumS3Sync
  class S3Uploader
    def initialize(bucket, prefix, downloader)
      @bucket = bucket
      @prefix = prefix
      @downloader = downloader
    end

    def upload(file, overwrite = false)
      retries = 0
      s3 = AWS::S3.new

      begin
        target = "#{@prefix}/#{file}"
        target.gsub!(/\/+/, '/')
        dest_obj = s3.buckets[@bucket].objects[target]

        if dest_obj.exists? && ! overwrite
          puts "Already exists: skipping #{@bucket}::#{target}" 
          return
        end

        dest_obj.delete if dest_obj.exists?
        source_file = @downloader.download(file)

        puts "Uploading #{@bucket}::#{target}"
        dest_obj.write(:file => source_file)
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
