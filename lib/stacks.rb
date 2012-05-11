require "aws-sdk"

class Stacks
  def initialize data
    @data = data
    @data[:variables] ||= {}
  end

  def create(&block)
    cloud_formation = AWS::CloudFormation.new
    stack = cloud_formation.stacks[name]
    (puts("the CI environment exists already. Nothing to do") and return) if stack.exists?

    puts "creating aws stack, this might take a while... ".white
    stack = cloud_formation.stacks.create(name, template, parameters)
    sleep 1 until stack.status == "CREATE_COMPLETE"
    while ((status = stack.status) != "CREATE_COMPLETE")
        raise "error creating stack!".red if status == "ROLLBACK_COMPLETE"
    end
    puts "the CI environment has been provisioned successfully".white
    yield stack
  end

  def update
    cloud_formation = AWS::CloudFormation.new
    stack = cloud_formation.stacks[name]
    if stack.exists?
      stack.update :template => template
    else
      create
    end
    #roll in new servers
  end

  def delete!
    stack = AWS::CloudFormation.new.stacks[name]
    (puts "couldn't find stack. Nothing to do" and return) unless stack.exists?

    stack.delete
    puts "shutdown command successful".green
  end

  private
  def name
    @data[:named]
  end

  def template
    @data[:using_template]
  end

  def parameters
    #todo: get rid of erb replacement
    values = {"KeyName" => @data[:with_settings].aws_ssh_key_name}
    values.merge @data[:variables]
    {:parameters => values}
  end
end
