require 'aws_settings'
require 'cloud_formation_template'
require 'stacks'

namespace :aws do
  STACK_NAME = "twitter-stream-ci"

  desc "creates the CI environment"
  task :ci_start do
    template = CloudFormationTemplate.new(:from => "ci-cloud-formation-template", :with_vars => ["boot_script"])

    Stacks.new(:named => STACK_NAME,
               :using_template => template.as_json_obj,
               :with_settings => AWSSettings.prepare).create do |stack|

      instance = stack.outputs.find { |output| output.key == "PublicIP" }
      puts "your CI server's address is #{instance.value}"
    end
  end

  desc "stops the CI environment"
  task :ci_stop do
    AWSSettings.prepare
    Stacks.new(:named => STACK_NAME).delete!
  end
end
