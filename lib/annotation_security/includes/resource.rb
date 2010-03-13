#
# = lib/annotation_security/includes/resource.rb
#

# Must be included by all classes that are resource classes and do not extend
# ActiveRecord::Base.
#
#   class MailDispatcher
#     include AnnotationSecurity::Resource
#     resource_type = :email
#     ...
#
# See AnnotationSecurity::Resource::ClassMethods.
#
module AnnotationSecurity::Resource

  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
    end
  end

  # Provides class side methods for resource classes.
  module ClassMethods

    # Registers the class as a resource.
    #
    def resource_type=(symbol)
      @resource_type = symbol
      AnnotationSecurity::ResourceManager.add_resource_class(symbol,self)
      symbol
    end

    def resource_type # :nodoc:
      @resource_type || (self.resource_type = name.underscore.to_sym)
    end

    def policy_for(user,obj=nil) # :nodoc:
      policy_factory.create_policy(user,obj)
    end

    # If required, overwrite this method to return a resource object identified
    # by the argument.
    #
    # This might be necessary if you change the to_param method of an
    # ActiveRecord class.
    #
    #  class Course < ActiveRecord::Base
    #    ...
    #    # each course has a unique name --> make better urls
    #    def to_param
    #      name
    #    end
    #
    #    def self.get_resource(name)
    #      find_by_name(name)
    #    end
    #
    def get_resource(arg)
      raise NoMethodError, "#{self} does not implement #get_resource"
    end

    private

    def policy_factory # :nodoc:
      @policy_factory ||= AnnotationSecurity::PolicyManager.policy_factory(resource_type)
    end

  end

  module InstanceMethods # :nodoc:
    def resource_type
      self.class.resource_type
    end

    def __is_resource?
      true
    end

    def policy_for(user)
      self.class.policy_for(user,self)
    end
  end
end