require 'aws_settings'
require 'cloud_formation_template'
require 'stacks'

namespace :aws do
  SETTINGS = AWSSettings.prepare
  STACK_NAME = "twitter-stream-ci"
  SCRIPTS_DIR = "#{File.dirname(__FILE__)}/../../scripts"

  desc "creates the CI environment"
  task :ci_start => "package:puppet" do
    role = "buildserver"
    boot_package_url = setup_bootstrap
    buildserver_boot_script = ERB.new(File.read("#{SCRIPTS_DIR}/boot.erb")).result(binding)

    template = CloudFormationTemplate.new(:from => "ci-cloud-formation-template",
                                          :with_vars => {"boot_script" => buildserver_boot_script})

    Stacks.new(:named => STACK_NAME,
               :using_template => template.as_json_obj,
               :with_settings => SETTINGS).create do |stack|

      instance = stack.outputs.find { |output| output.key == "PublicIP" }
      puts "your CI server's address is #{instance.value}"
    end
  end

  desc "stops the CI environment"
  task :ci_stop do
    Stacks.new(:named => STACK_NAME).delete!
  end

  def setup_bootstrap
    s3 = AWS::S3.new
    bucket_name = "#{STACK_NAME}-bootstrap-bucket"
    bucket = s3.buckets[bucket_name]
    unless bucket.exists?
      puts "creating S3 bucket".cyan
      bucket = s3.buckets.create(bucket_name)
      puts "uploading bootstrap package...".cyan
      bucket.objects[BOOTSTRAP_FILE].write(File.read("#{BUILD_DIR}/#{BOOTSTRAP_FILE}"))
    end
    bucket.objects[BOOTSTRAP_FILE].url_for(:read)
  end
end
