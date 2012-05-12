require "aws-sdk"

module Ops
  class BootstrapPackage
    def initialize(package, bucket_name)
      @package = package
      @bucket_name = bucket_name
    end

    def url
      s3 = AWS::S3.new
      bucket = s3.buckets[bucket_name]
      unless bucket.exists?
        puts "creating S3 bucket"
        bucket = s3.buckets.create(bucket_name)
      end
      puts "uploading bootstrap package..."
      bucket.objects[BOOTSTRAP_FILE].write(File.read("#{BUILD_DIR}/#{BOOTSTRAP_FILE}"))
      bucket.objects[BOOTSTRAP_FILE].url_for(:read, :expires => 10 * 60)
    end
  end
end
