require "erb"
require "json"
require "aws-sdk"

namespace :aws do
  begin
    settings_file = File.expand_path("#{File.dirname(__FILE__)}/../../conf/settings.yaml")
    SETTINGS = YAML::parse(open(settings_file)).transform
  rescue
    puts "Error loading settings. Make sure you provide a configuration file at #{settings_file}".red
    exit
  end

  AWS.config(:access_key_id     => SETTINGS["aws_access_key"],
             :secret_access_key => SETTINGS["aws_secret_access_key"])
  TEMPLATES_DIR = "#{File.dirname(__FILE__)}"
  BOOTSTRAP_FILE = "ci-bootstrap.tar.gz"
  STACK_NAME = "twitter-stream-ci"

  directory BUILD_DIR

  desc "creates the CI environment"
  task :ci_start do
    template_body = File.read("#{TEMPLATES_DIR}/ci-cloud-formation-template.erb")
    boot_script = ERB.new(File.read("#{TEMPLATES_DIR}/bootstrap.erb")).result(binding)

    cloud_formation = AWS::CloudFormation.new
    stack = cloud_formation.stacks[STACK_NAME]
    unless stack.exists?
      puts "creating aws stack, this might take a while... ".white
      stack = cloud_formation.stacks.create(STACK_NAME,
                                            ERB.new(template_body).result(binding),
                                            :parameters => { "KeyName" => SETTINGS["aws_ssh_key_name"] })
      sleep 1 until stack.status == "CREATE_COMPLETE"
      while ((status = stack.status) != "CREATE_COMPLETE")
        if status == "ROLLBACK_COMPLETE"
          raise "error creating stack!".red
        end
      end
      puts "the CI environment has been provisioned successfully".white
    else
      puts "the CI environment exists already. Nothing to do"
    end
  end

  desc "stops the CI environment"
  task :ci_stop do
    stack = AWS::CloudFormation.new.stacks[STACK_NAME]
    if stack.exists?
      stack.delete
      puts "shutdown command successful".green
    else
      puts "couldn't find stack. Nothing to do"
    end
  end

  task :upload_bootstrap_files => [:package] do
    s3 = AWS::S3.new
    bucket_name = "#{STACK_NAME}-bootstrap-bucket"
    bucket = s3.buckets[bucket_name]
    unless bucket.exists?
      puts "creating S3 bucket".cyan
      bucket = s3.buckets.create(bucket_name)
    end
    puts "uploading bootstrap package...".cyan
    bucket.objects[BOOTSTRAP_FILE].write(File.read("#{BUILD_DIR}/#{BOOTSTRAP_FILE}"))
  end

  task :package => [:clean, BUILD_DIR] do
    mkdir_p "#{BUILD_DIR}/package"
    cp_r "puppet", "#{BUILD_DIR}/package/puppet"
    puts "packaging boostrap files in #{BOOTSTRAP_FILE}"
    %x[cd #{BUILD_DIR}/package; tar -zcf ../#{BOOTSTRAP_FILE} *]
  end
end
