require "aws-sdk"

module Ops
  class Instance
    def initialize(instance_id)
      @instance_id = instance_id
    end

    def create_image(name)
      ec2 = AWS::EC2.new
      image = ec2.images.create(:instance_id => @instance_id, :name => "aws-twitter-feed-#{name}")
      sleep 1 until image.state.to_s.eql? "available"
      image.id
    end

    def url
      ec2 = AWS::EC2.new
      ec2.instances[@instance_id].public_dns_name
    end
  end
end
