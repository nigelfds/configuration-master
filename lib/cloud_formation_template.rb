require "erb"
require "json"

class CloudFormationTemplate
  TEMPLATES_DIR = "#{File.dirname(__FILE__)}/../templates"
  SCRIPTS_DIR = "#{File.dirname(__FILE__)}/../scripts"

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
    @data[:with_vars].each do |var_name|
      instance_variable_set("@#{var_name}", ERB.new(File.read("#{SCRIPTS_DIR}/#{var_name}.erb")).result)
    end
    ERB.new(template_body).result(binding)
  end
end
