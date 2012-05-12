require "erb"
require "ostruct"

module Ops
  class PuppetBootstrap
    BOOT_SCRIPT = "#{File.dirname(__FILE__)}/../../scripts/boot.erb"

    def initialize(options)
      @options = options
      setup_facter_variables
    end

    def setup_facter_variables
      if @options.has_key? :facter
        facter_variables = @options[:facter].map { |key, value| "export FACTER_#{key.to_s.upcase}=#{value}\n" }
        @options[:facter_variables] = facter_variables.join
        @options.delete :facter
      else
        @options[:facter_variables] = ""
      end
    end

    def script
      namespace = OpenStruct.new(@options)
      template = File.read(BOOT_SCRIPT)
      ERB.new(template).result(namespace.instance_eval { binding })
    end
  end
end
