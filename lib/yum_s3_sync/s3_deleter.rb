require 'aws-sdk'

module YumS3Sync
class S3Deleter
  def initialize(bucket, prefix)
    @bucket = bucket
    @prefix = prefix
  end

  def delete(file)
    s3 = AWS::S3.new

    target = "#{@prefix}/#{file}"
    target.gsub!(/\/+/, "/")
    
    dest_obj = s3.buckets[@bucket].objects[target]
    
    if dest_obj.exists?
      puts "Deleting #{@bucket}::#{target}"
      dest_obj.delete
    end
  end
end
end
