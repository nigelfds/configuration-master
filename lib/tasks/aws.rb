require 'aws_settings'
require 'cloud_formation_template'
require 'stacks'
require "system_integration_pipeline"

namespace :aws do
  SETTINGS = AWSSettings.prepare
  STACK_NAME = "twitter-stream-ci"
  SCRIPTS_DIR = "#{File.dirname(__FILE__)}/../../scripts"

  desc "creates the CI environment"
  task :ci_start => ["clean", "package:puppet"] do
    buildserver_boot_script = erb(File.read("#{SCRIPTS_DIR}/boot.erb"),
                                  :role => "buildserver",
                                  :facter_variables => "",
                                  :boot_package_url => setup_bootstrap)
    template = CloudFormationTemplate.new("ci-cloud-formation-template",
                                          :boot_script => buildserver_boot_script)
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

  task :build_appserver => BUILD_DIR do
    ec2 = AWS::EC2.new
    pipeline = SystemIntegrationPipeline.new
    boot_script = erb(File.read("#{SCRIPTS_DIR}/boot.erb"),
                      :role => "appserver",
                      :facter_variables => "export FACTER_ARTIFACT=#{pipeline.aws_twitter_feed_artifact}\n",
                      :boot_package_url => pipeline.configuration_master_artifact)

    template = CloudFormationTemplate.new("appserver-creation-template", :boot_script => boot_script)
    stacks = Stacks.new(:named => "appserver-creation",
                        :using_template => template.as_json_obj,
                        :with_settings => SETTINGS)
    begin
      stacks.create do |stack|
        instance = stack.resources.find { |resource| resource.resource_type == "AWS::EC2::Instance" }

        test_application ec2.instances[instance.physical_resource_id].public_dns_name

        # add build number to the image name
        image = ec2.images.create(:instance_id => instance.physical_resource_id,
                                  :name => "aws-twitter-feed-#{ENV['GO_PIPELINE_COUNTER']}")
        sleep 1 until image.state.to_s.eql? "available"
        File.open("#{BUILD_DIR}/image", "w") { |file| file.write(image.id) }
      end
    ensure
      stacks.delete!
    end
  end

  def test_application(host)
    puts "testing... #{host}"
    (1..10).each do |n|
      puts n
      sleep 1
    end
    puts "all good!"
  end

  def setup_bootstrap
    s3 = AWS::S3.new
    bucket_name = "#{STACK_NAME}-bootstrap-bucket"
    bucket = s3.buckets[bucket_name]
    unless bucket.exists?
      puts "creating S3 bucket".cyan
      bucket = s3.buckets.create(bucket_name)
    end
    puts "uploading bootstrap package...".cyan
    bucket.objects[BOOTSTRAP_FILE].write(File.read("#{BUILD_DIR}/#{BOOTSTRAP_FILE}"))
    bucket.objects[BOOTSTRAP_FILE].url_for(:read, :expires => 10 * 60)
  end
end
