require "pipeline"

class Go::SystemIntegrationPipeline < Go::Pipeline
  def initialize
    super
  end

  def aws_twitter_feed_artifact
    artifact_location "APP", "rpms"
  end

  def configuration_master_artifact
    artifact_location "CONFIGURATION", "build"
  end
end
