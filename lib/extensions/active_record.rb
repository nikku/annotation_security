
module ActiveRecord # :nodoc:
 
  #
  # = lib/extensions/active_record.rb
  #
  # Extends ActiveRecord::Base so that model classes 
  # can be tagged as resources.
  #
  # To associate a model class with a resource type, use #resource in the class
  # definition.
  #
  #  class MyResource < ActiveRecord::Base
  #    resource :my_resource
  #
  #    # ...
  #  end
  #
  # If you don't pass an argument to #resource, the resource name will be
  # the underscored class name.
  #
  # See AnnotationSecurity::Resource if you want to use non-model classes as resources.
  #
  class Base

    # Declares a model class to be a resource.
    # * +resource_type+ (optional) Symbol of the resource type (like :course)
    def self.resource(resource_type = nil)
      include ::AnnotationSecurity::ActiveRecord
      self.resource_type = resource_type if resource_type
      self.resource_type
    end
  end

end