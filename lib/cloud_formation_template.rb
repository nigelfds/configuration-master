require "erb"
require "json"

class CloudFormationTemplate
  TEMPLATES_DIR = "#{File.dirname(__FILE__)}/../templates"

  def initialize data
    @data = data
  end

  def as_json_obj
    JSON.parse(merged_template)
  end

  private
  def template_body
    File.read("#{TEMPLATES_DIR}/#{@data[:from]}.erb")
  end

  def merged_template
    @data[:with_vars].each do |name, value|
      instance_variable_set("@#{name}", value)
    end
    ERB.new(template_body).result(binding)
  end
end
