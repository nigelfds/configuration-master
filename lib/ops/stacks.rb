require "json"
require "base64"
require "aws-sdk"
require "ops/instance"

module Ops
  class Stacks
    TEMPLATES_DIR = "#{File.dirname(__FILE__)}/../../templates"

    def initialize(name, variables = {})
      @name = name
      @variables = variables
    end

    def create
      cloud_formation = AWS::CloudFormation.new
      stack = cloud_formation.stacks[@name]
      (puts("environment already exists") and return) if stack.exists?

      stack = cloud_formation.stacks.create(@name, template, parameters)
      while ((status = stack.status) != "CREATE_COMPLETE")
        raise "error creating stack!" if status == "ROLLBACK_COMPLETE"
        sleep 5
      end
      puts "environment successfully provisioned"
      yield stack if block_given?
    end

    def create_or_update
      cloud_formation = AWS::CloudFormation.new
      stack = cloud_formation.stacks[@name]
      if stack.exists?
        puts "updating environment"
        begin
          stack.update :template => template, :parameters => parameters[:parameters]
        rescue Exception => e
          if e.message.eql? "no updates are to be performed"
            puts e.message
            return
          else
            raise
          end
        end
      else
        create
      end
    end

    def delete!
      stack = AWS::CloudFormation.new.stacks[@name]
      (puts "couldn't find stack" and return) unless stack.exists?

      stack.delete
      sleep 30 while stack.exists?
      puts "environment delete successful"
    end

    def instances
      stack = AWS::CloudFormation.new.stacks[@name]
      stack_instances = stack.resources.select { |resource| resource.resource_type == "AWS::EC2::Instance" }
      stack_instances.map { |stack_instance| Ops::Instance.new(stack_instance.physical_resource_id) }
    end

    private
    def template
      JSON.parse(File.read("#{TEMPLATES_DIR}/#{@name}.json"))
    end

    def parameters
      if @variables.has_key? "BootScript"
        @variables["BootScript"] = Base64.encode64(@variables["BootScript"]).strip
      end
      {:parameters => @variables}
    end
  end
end
