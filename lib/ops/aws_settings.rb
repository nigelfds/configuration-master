require "aws-sdk"

module Ops
  class AWSSettings
    attr_accessor :settings

    def self.prepare
      begin
        settings_file = ENV["SETTINGS_FILE"] || File.expand_path("#{File.dirname(__FILE__)}/../conf/settings.yaml")

        settings = AWSSettings.new
        settings.settings = YAML::parse(open(settings_file)).transform
        settings.setup_cred
      rescue
        raise "Error loading settings. Make sure you provide a configuration file at #{settings_file}"
      end
      return settings
    end

    def method_missing(symbol, *args)
      @settings[symbol.to_s]
    end

    def setup_cred
      AWS.config(:access_key_id => @settings["aws_access_key"], :secret_access_key => @settings["aws_secret_access_key"])
    end
  end
end
