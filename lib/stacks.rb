require "json"
require "aws-sdk"

class Stacks
  TEMPLATES_DIR = "#{File.dirname(__FILE__)}/../templates"

  def initialize data
    @data = data
    @data[:variables] ||= {}
  end

  def create(&block)
    cloud_formation = AWS::CloudFormation.new
    stack = cloud_formation.stacks[@data[:using_template]]
    (puts("the CI environment exists already. Nothing to do") and return) if stack.exists?

    stack = cloud_formation.stacks.create(@data[:using_template], template, parameters)
    sleep 1 until stack.status == "CREATE_COMPLETE"
    while ((status = stack.status) != "CREATE_COMPLETE")
        raise "error creating stack!".red if status == "ROLLBACK_COMPLETE"
    end
    puts "the CI environment has been provisioned successfully".white
    yield stack
  end

  def create_or_update
    cloud_formation = AWS::CloudFormation.new
    stack = cloud_formation.stacks[@data[:using_template]]
    if stack.exists?
      puts "updating production environment with the new version"
      begin
        stack.update :template => template, :parameters => parameters[:parameters]
      rescue Exception => e
        if e.message.eql? "No updates are to be performed."
          puts e.message
          return
        else
          raise
        end
      end
    else
      create { |stack| }
    end
  end

  def delete!
    stack = AWS::CloudFormation.new.stacks[@data[:using_template]]
    (puts "couldn't find stack. Nothing to do" and return) unless stack.exists?

    stack.delete
    puts "shutdown command successful"
  end

  private
  def template
    JSON.parse(File.read("#{TEMPLATES_DIR}/#{@data[:using_template]}.erb"))
  end

  def parameters
    #todo: get rid of erb replacement
    values = {"KeyName" => @data[:with_settings].aws_ssh_key_name}
    values.merge! @data[:variables]
    if values.has_key? "BootScript"
      require "base64"
      values["BootScript"] = Base64.encode64(values["BootScript"]).strip
    end
    {:parameters => values}
  end
end
