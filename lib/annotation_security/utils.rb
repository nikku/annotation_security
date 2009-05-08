#
# = libs/security/utils.rb
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

  # Parse arguments provided to #apply_policy or #allowed? and returns
  # [:action, :resource_type, resource || nil]
  #
  # See SecurityContext#allowed? for details.
  #
  # Raises ArgumentError if args could not be parsed.
  #
  def self.parse_policy_arguments(args)
    
    args << :all_resources unless args.size > 1

    if args.first.is_a? String
      args = AnnotationSecurity::Utils.parse_description(args.first) + args[1..-1]
    end

    action, resource = args

    if resource.__is_resource?
      [action, resource.resource_type] + args[1..-1]
    else
#      if args.size > 2 && args.third == nil
#        raise ArgumentError, "Did not expect nil as resource"
#      end
      args
    end
  end

end