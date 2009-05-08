#
# Must be included by all classes that are resource classes and do not extend
# ActiveRecord::Base.
#
module AnnotationSecurity::Resource

  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.class_eval do
      include InstanceMethods
    end
  end

  module ClassMethods
    def resource_type=(symbol) # :nodoc:
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