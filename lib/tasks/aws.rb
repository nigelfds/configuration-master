require "erb"
require "json"
require "aws-sdk"

namespace :aws do
  AWS.config(:access_key_id     => "0C4XBKRVDWJBJZ8D5282",
             :secret_access_key => "VxWnFP/KY4pTqFZVCyM6GqYOhDDsrdzOJ39N7P1A")
  TEMPLATES_DIR = "#{File.dirname(__FILE__)}"
  BOOTSTRAP_FILE = "ci-bootstrap.tar.gz"
  STACK_NAME = "twitter-stream-ci"

  directory BUILD_DIR

  desc "creates the project's infrastructure in the Amazon cloud"
  task :provision => :upload_bootstrap_files do
    template_body = contents("#{TEMPLATES_DIR}/ci-cloud_formation_template.erb")
    boot_script = ERB.new(contents("#{TEMPLATES_DIR}/bootstrap.erb")).result(binding)

    puts "creating aws stack, this might take a while... ".white
    cloud = cloud_formation
    cloud.create_stack(STACK_NAME,
                       "TemplateBody" => ERB.new(template_body).result(binding),
                       "Parameters" => { "KeyName" => SETTINGS["aws_ssh_key_name"],
                                         "Password" => "hotbubbles",
                                         "PSK" => "W3lcom3%1"})
    stack = nil
    until stack
      sleep 1
      stack = find_stack(cloud)
    end
    puts "your servers have been provisioned successfully".white
  end

  {"admin_server" => "ManagementConsole", "test_server" => "TestServer"}.each do |file_name, key_name|
    file "#{BUILD_DIR}/#{file_name}" => ["aws:settings", BUILD_DIR] do
      cloud = cloud_formation
      stack = find_stack(cloud)
      fail "could not find stack... did you provision your aws resources?".red if stack.nil?
      puts "discovering #{file_name} address...".white
      address = stack["Outputs"].find { |output| output["OutputKey"] == key_name }["OutputValue"]
      puts "#{file_name} address: #{address}".green
      File.open("#{BUILD_DIR}/#{file_name}", "w") do |file|
        file.write address
      end
    end
  end

  desc "stops all instances and releases all Amazon resources"
  task :shutdown => :settings do
    cloud_formation.delete_stack STACK_NAME
    puts "shutdown command successful".green
  end

  task :upload_bootstrap_files => [:package] do
    s3 = AWS::S3.new
    bucket_name = "#{STACK_NAME}-bootstrap-bucket"
    bucket = s3.buckets[bucket_name]
    unless bucket.exists?
      puts "creating S3 bucket".cyan
      bucket = s3.buckets.create(bucket_name)
    end
    puts bucket.methods.sort
    puts "uploading bootstrap package...".cyan
    bucket.objects[BOOTSTRAP_FILE].write(File.read("#{BUILD_DIR}/#{BOOTSTRAP_FILE}"))
  end

  task :package => [:clean, BUILD_DIR] do
    mkdir_p "#{BUILD_DIR}/package"
    cp_r "puppet", "#{BUILD_DIR}/package/puppet"
    puts "packaging boostrap files in #{BOOTSTRAP_FILE}"
    %x[cd #{BUILD_DIR}/package; tar -zcf ../#{BOOTSTRAP_FILE} *]
  end

  task :settings do
    SETTINGS = YAML::parse(open("conf/settings.yaml")).transform
    BUCKET_NAME = "#{SETTINGS['aws_s3_bucket_name']}"
  end

  def find_stack(cloud)
    cloud.describe_stacks.body["Stacks"].find do |stack|
      stack["StackName"] == STACK_NAME && stack["StackStatus"] == "CREATE_COMPLETE"
    end
  end

  def contents(file)
    contents = ""
    File.open(file) { |f| contents << f.read }
    contents
  end
end
