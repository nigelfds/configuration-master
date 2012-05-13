require "aws-sdk"
require "socket"
require "timeout"

module Ops
  class RollingUpgrade
    def initialize(new_image_id)
      @image_id = new_image_id
    end

    def run
      auto_scaling = AWS::AutoScaling.new
      instances_to_retire = auto_scaling.instances.select { |i| not i.ec2_instance.image_id.eql?(@image_id) }
      puts "#{instances_to_retire.size} instances have to be updated with the new configuration"

      instances_to_retire.each do |instance|
        puts "terminating instance '#{instance.instance_id}'"
        instance.terminate(false)
        sleep 10
        while true
          break if all_ready?(auto_scaling.instances)
          sleep 5
        end
      end
    end

    def all_ready?(instances)
      running_instances = instances.select { |i| i.ec2_instance.status.eql? :running }
      servicing_requests = running_instances.select { |i| accepting_requests?(i.ec2_instance.ip_address) }
      servicing_requests.count == 2
    end

    def accepting_requests?(ip)
      begin
        Timeout::timeout(2) do
          begin
            TCPSocket.new(ip, 8080).close
            true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            false
          end
        end
      rescue Timeout::Error
        false
      end
    end
  end
end
