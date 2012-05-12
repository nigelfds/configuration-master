require "aws_settings"
require "stacks"
require "go/system_integration_pipeline"
require "go/production_deploy_pipeline"
require "puppet_bootstrap"
require "net/http"
require "uri"

namespace :aws do
  SETTINGS = AWSSettings.prepare

  desc "creates the CI environment"
  task :ci_start => ["clean", "package:puppet"] do
    puppet_bootstrap = PuppetBootstrap.new(:role => "buildserver",
                                           :facter_variables => "",
                                           :boot_package_url => setup_bootstrap)
    stacks = Stacks.new("ci-cloud-formation-template",
                        "KeyName" => SETTINGS.aws_ssh_key_name,
                        "BootScript" => puppet_bootstrap.script)

    puts "booting the CI environment"
    stacks.create do |stack|
      instance = stack.outputs.find { |output| output.key == "PublicIP" }
      puts "your CI server's address is #{instance.value}"
    end
  end

  desc "stops the CI environment"
  task :ci_stop do
    Stacks.new("ci-cloud-formation-template").delete!
  end

  task :build_appserver => BUILD_DIR do
    ec2 = AWS::EC2.new
    pipeline = Go::SystemIntegrationPipeline.new
    puppet_bootstrap = PuppetBootstrap.new(:role => "appserver",
                                           :facter_variables => "export FACTER_ARTIFACT=#{pipeline.aws_twitter_feed_artifact}\n",
                                           :boot_package_url => pipeline.configuration_master_artifact)

    Stacks.new("appserver-creation-template",
               "KeyName" => SETTINGS.aws_ssh_key_name,
               "BootScript" => puppet_bootstrap.script).create
  end

  task :create_image do
    stack = Stacks.new("appserver-creation-template")
    image_id = stack.instances.first.create_image(ENV["GO_PIPELINE_COUNTER"])

    File.open("#{BUILD_DIR}/image", "w") { |file| file.write(image_id) }

    stack.delete!
  end

  task :deploy_to_production do
    image_id = Go::ProductionDeployPipeline.new.upstream_artifact
    puts "updating production configuration with image '#{image_id}'"

    stack = Stacks.new("production-environment",
                       "KeyName" => SETTINGS.aws_ssh_key_name,
                       "ImageId" => image_id)
    stack.create_or_update
  end

  task :roll_new_version do
    image_id = Go::ProductionDeployPipeline.new.upstream_artifact
    puts "rolling image #{image_id} into production"

    auto_scaling = AWS::AutoScaling.new
    instances_to_retire = auto_scaling.instances.select { |i| not i.ec2_instance.image_id.eql?(image_id) }
    puts "#{instances_to_retire.size} instances have to be updated with the new configuration"

    instances_to_retire.each do |instance|
      puts "terminating instance '#{instance.instance_id}'"
      instance.terminate(false)
      sleep 10
      while true
        break if auto_scaling.instances.select { |i| i.ec2_instance.status.eql? :running }.count == 2
        sleep 5
      end
    end
    puts "all instances updated successfuly"
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
    bucket_name = "aws-twitter-stream-bootstrap-bucket-#{AWSSettings.prepare.aws_ssh_key_name}"
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
