require "aws-sdk"

module Ops
  class RollingUpgrade
    def initialize(new_image_id)
      @image_id = new_image_id
    end

    def run
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
    end
  end
end
