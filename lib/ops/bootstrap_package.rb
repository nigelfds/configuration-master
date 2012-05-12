require "aws-sdk"

module Ops
  class BootstrapPackage
    def initialize(package, bucket_name)
      @package = package
      @bucket_name = bucket_name
      @object_name = File.basename(package)
    end

    def url
      s3 = AWS::S3.new
      bucket = s3.buckets[@bucket_name]
      unless bucket.exists?
        puts "creating S3 bucket '#{@bucket_name}'"
        bucket = s3.buckets.create(@bucket_name)
      end
      puts "uploading bootstrap package..."
      bucket.objects[@object_name].write(File.read(@package))
      bucket.objects[@object_name].url_for(:read, :expires => 10 * 60)
    end
  end
end
