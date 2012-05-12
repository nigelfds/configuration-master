require "go/pipeline"

module Go
  class SystemIntegrationPipeline < Pipeline
    def initialize
      super
    end

    def aws_twitter_feed_artifact
      artifact_location "APP", "package", "rpms"
    end

    def configuration_master_artifact
      artifact_location "CONFIGURATION", "package", "build"
    end
  end
end
