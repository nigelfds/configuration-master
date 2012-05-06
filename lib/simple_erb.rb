require "erb"
require "ostruct"

def erb(template, parameters)
  namespace = OpenStruct.new(parameters)
  ERB.new(template).result(namespace.instance_eval { binding })
end
