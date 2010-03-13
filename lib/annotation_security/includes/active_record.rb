#
# = lib/annotation_security/includes/active_record.rb
#

# = AnnotationSecurity::ActiveRecord
# 
# Included by model classes if they are used as resources.
# Includes AnnotationSecurity::Resource and sets up the model observer.
#
module AnnotationSecurity::ActiveRecord # :nodoc:

  def self.included(base)
    base.class_eval do
      include ::AnnotationSecurity::Resource
    end
    base.extend(ClassMethods)
    AnnotationSecurity::ModelObserver.observe base.name.underscore.to_sym
    AnnotationSecurity::ModelObserver.instance.reload_model_observer
  end
  
  module ClassMethods # :nodoc:
    def get_resource(object)
      return object if object.is_a? self
      # Object.const_get(name) needed because of a bug in Rails
      Object.const_get(name).find(object)
    end
  end
end