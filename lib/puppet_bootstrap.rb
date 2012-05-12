require "erb"
require "ostruct"

class PuppetBootstrap
  BOOT_SCRIPT = "#{File.dirname(__FILE__)}/../scripts/boot.erb"

  def initialize(options)
    @options = options
  end

  def script
    namespace = OpenStruct.new(@options)
    template = File.read(BOOT_SCRIPT)
    ERB.new(template).result(namespace.instance_eval { binding })
  end
end
