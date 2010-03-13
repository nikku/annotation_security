#
# = lib/annotation_security/utils.rb
#
# Provides some methods that are needed at several locations in the plug-in.
#

class AnnotationSecurity::Utils # :nodoc:

  PREFIXES = /\A(may|is|can|has)_/
  SUFFIXES = /(_(for|in|of|to)|\?)\Z/

  # Removes pre- and suffixes from +method+,
  # returns +nil+ if no change was made.
  #
  def self.method_body(method)
    body = method.to_s.gsub(PREFIXES,'').gsub(SUFFIXES,'')
    method.to_s == body ? nil : body
  end

  # Parses a description string
  # * +description+ description of a controller action
  # * +allow_binding+ if false, an exception is raised if the description
  #                   contains a variable
  # Returns right, resource and binding
  #
  def self.parse_description(description,allow_binding=false)
    ActionAnnotation::Utils.parse_description(description,allow_binding)
  end

  # Parses arguments provided to #apply_policy or #allowed? and returns
  # [ [:action, :resource_type, resource || nil], ... ]
  #
  # See SecurityContext#allowed? for details.
  #
  # Each element of the result can be send to a policy using
  #  policy_of_res_type.allowed?(rule, resource)
  # or
  #   policy_of_res_type.static_policy.allowed?(rule, nil)
  #
  # Raises ArgumentError if args could not be parsed.
  #
  def self.parse_policy_arguments(args)
    if args.first.is_a? String
      hash = AnnotationSecurity::Utils.parse_description(args.first)
    elsif args.first.is_a? Hash
      hash = args.first
    end
    if hash
      action = hash.delete(:action) || hash.delete('action')
      resource = hash.delete(:resource) || hash.delete('resource')
      unless resource.__is_resource?
        resource_type = resource
        resource = nil
      end
      resource_type ||= hash.delete(:resource_type) 
      resource_type ||= resource ? resource.resource_type : nil
      a = [action, resource_type]
      a << resource if resource
      args = a + args[1..-1]
    end

    args << :all_resources unless args.size > 1

    action, resource = args

    if resource.__is_resource?
      args = [action, resource.resource_type] + args[1..-1]
    end
#      if args.size > 2 && args.third == nil
#        raise ArgumentError, "Did not expect nil as resource"
#      end
    args
  end

  # returns resource type and resource object without action
  # expects [resource object], [resource type], or both
  def self.parse_resource_arguments(args)
    parse_policy_arguments([:r]+args)[1..2]
  end

  # Returns controller, action, objects and parameters
  def self.parse_action_args(args)
    controller = parse_controller(args.first)
    action = args.second.to_sym

    objects = args.third || []
    objects = [objects] unless objects.is_a? Array
    prepare_objects_resources(controller, objects)

    params = args.fourth || {}
    prepare_params_resources(controller, params)

    objects += params.values

    objects = objects.select { |o| o and o.__is_resource? }
    return [controller, action, objects, params]
  end

  # Try to find the controller class from a name.
  # Looks for [name](s)Controller.
  #
  #  parse_controller :welcome #=> WelcomeController
  #  parse_controller :user # => UsersController
  #
  def self.parse_controller(controller) # :nodoc:
    begin
      "#{controller.to_s.camelize}Controller".constantize
    rescue NameError
      "#{controller.to_s.pluralize.camelize}Controller".constantize
    end
  rescue NameError
    raise NameError, "Controller '#{controller}' was not found"
  end

  # if there are non-resources in objects, use the values to get resources
  # from the controllers default resource type
  #
  def self.prepare_objects_resources(controller, objects)
    res_type = controller.default_resource
    objects.collect! do |o|
      if o.__is_resource?
        o
      else
        AnnotationSecurity::ResourceManager.get_resource(res_type, o)
      end
    end
  end

  # if there are non-resources in objects, use the values to get resources
  # assuming the keys are the resource types (:id is defalut resource)
  #
  def self.prepare_params_resources(controller, params)
    params.each do |k, v|
      unless v.__is_resource?
        res_type = k == :id ? controller.default_resource : k
        v = AnnotationSecurity::ResourceManager.get_resource(res_type, v)
        params[k] = v
      end
    end
  end

end