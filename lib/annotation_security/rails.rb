#
# = annotation_security/rails/init.rb
#
# Loads the annotation security layer for a rails app

require "action_controller/dispatcher"
require "action_controller/base"

module AnnotationSecurity

  # Contains rails specific initializer
  class Rails
    def self.init!(config)
      
      # Policy files are situated under RAILS_ROOT/config/security
      # Default policy file is internal, load it
      ::AnnotationSecurity.load_relations(File.dirname(__FILE__) + '/policy/all_resources_policy')

      # Add AnnotationSecurity::ModelObserver to observe changes in models.
      # See http://riotprojects.com/2009/1/18/active-record-observers-in-gems-plugins
      #
      config.after_initialize do
        # Set up a dummy security context that does not interfer with script
        ::SecurityContext.initialize nil

        ::ActiveRecord::Base.observers << ::AnnotationSecurity::ModelObserver

        # In development mode, the models we observe get reloaded with each request. Using
        # this hook allows us to reload the observer relationships each time as well.
        ::ActionController::Dispatcher.to_prepare(:cache_advance_reload) do
          ::AnnotationSecurity.reset
          ::AnnotationSecurity::ModelObserver.instance.reload_model_observer
        end
      end

      puts "Security layer initialized"
    end
  end
end