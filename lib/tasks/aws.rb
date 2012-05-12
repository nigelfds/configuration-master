require "uri"
require "net/http"
require "lib/ops/aws_settings"
require "lib/ops/stacks"
require "lib/ops/puppet_bootstrap"
require "lib/ops/rolling_upgrade"
require "lib/ops/bootstrap_package"
require "lib/go/system_integration_pipeline"
require "lib/go/production_deploy_pipeline"

namespace :aws do
  SETTINGS = Ops::AWSSettings.load

  desc "creates the CI environment"
  task :ci_start => ["clean", "package:puppet"] do
    puppet_bootstrap = Ops::PuppetBootstrap.new(:role => "buildserver",
                                                :facter_variables => "",
                                                :boot_package_url => setup_bootstrap)
    stacks = Ops::Stacks.new("ci-environment",
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
    Ops::Stacks.new("ci-environment").delete!
  end

  task :build_appserver do
    pipeline = Go::SystemIntegrationPipeline.new
    puppet_bootstrap = Ops::PuppetBootstrap.new(:role => "appserver",
                                                :facter_variables => "export FACTER_ARTIFACT=#{pipeline.aws_twitter_feed_artifact}\n",
                                                :boot_package_url => pipeline.configuration_master_artifact)

    stack = Ops::Stacks.new("appserver-validation",
                            "KeyName" => SETTINGS.aws_ssh_key_name,
                            "BootScript" => puppet_bootstrap.script)
    stack.delete!
    stack.create
  end

  task :create_image => BUILD_DIR do
    stack = Ops::Stacks.new("appserver-validation")
    image_name = ENV["GO_PIPELINE_COUNTER"]+"-"+ENV["GO_REVISION"]+"-#{rand(999)}"
    image_id = stack.instances.first.create_image(image_name)

    File.open("#{BUILD_DIR}/image", "w") { |file| file.write(image_id) }

    stack.delete!
  end

  task :deploy_to_production do
    image_id = Go::ProductionDeployPipeline.new.upstream_artifact
    puts "updating production configuration with image '#{image_id}'"

    stack = Ops::Stacks.new("production-environment",
                            "KeyName" => SETTINGS.aws_ssh_key_name,
                            "ImageId" => image_id)
    stack.create_or_update
  end

  task :roll_new_version do
    image_id = Go::ProductionDeployPipeline.new.upstream_artifact
    puts "rolling image #{image_id} into production"

    upgrade = Ops::RollingUpgrade.new(image_id)
    upgrade.run

    puts "new version updated successfuly"
  end

  def setup_bootstrap
    bucket_name = "aws-twitter-stream-bootstrap-bucket-#{SETTINGS.aws_ssh_key_name}"
    Ops::BootstrapPackage.new("#{BUILD_DIR}/#{BOOTSTRAP_FILE}", bucket_name).url
  end
end
