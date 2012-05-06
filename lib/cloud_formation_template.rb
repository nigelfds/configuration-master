require "json"

class CloudFormationTemplate
  TEMPLATES_DIR = "#{File.dirname(__FILE__)}/../templates"

  def initialize(template_file, data)
    @template_file = template_file
    @data = data
  end

  def as_json_obj
    JSON.parse(merged_template)
  end

  private
  def merged_template
    erb(File.read("#{TEMPLATES_DIR}/#{@template_file}.erb"), @data)
  end
end
