#
# = lib/annotation_security/model_observer.rb
#
# Contains SecurityObserver which implements constraint checking for model
# classes.
#

module AnnotationSecurity

  # Observes changes in models and applies security policy to them
  #
  class ModelObserver < ::ActiveRecord::Observer # :nodoc:

    # Sets the observed model classes
    #
    observe # will be set automatically. However, observe must not be removed
    
    def before_validation_on_create(record)
      SecurityContext.observe record
    end
    
    def before_validation_on_update(record)
      SecurityContext.observe record
    end

    # after_find is removed in favour of after_initialize

    def after_initialize(record)      
      if record.new_record?
        # The record is new
      else
        # The record came out of database
        SecurityContext.observe record
      end
    end

    def before_destroy(record)
      SecurityContext.observe record
    end

    # Re-register on classes you are observing
    # See http://riotprojects.com/2009/1/18/active-record-observers-in-gems-plugins
    #
    def reload_model_observer
      observed_classes.each do |klass|
        add_observer!(klass.name.constantize)
      end
    end

    protected

    def add_observer!(klass)
      klass.delete_observer(self)      
      super
      
      if respond_to?(:after_initialize) && !klass.method_defined?(:after_initialize)
        klass.class_eval 'def after_initialize() end'
      end
    end
  end
end
