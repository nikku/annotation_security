#
# = init.rb
#
# Initializes AnnotationSecurity plugin.
#

require "annotation_security"
require "extensions"

require "action_controller/dispatcher"
require "action_controller/base"

# Add AnnotationSecurity::ModelObserver to observe changes in models.
# See http://riotprojects.com/2009/1/18/active-record-observers-in-gems-plugins
#
config.after_initialize do
  ActiveRecord::Base.observers << AnnotationSecurity::ModelObserver
  
  # In development mode, the models we observe get reloaded with each request. Using
  # this hook allows us to reload the observer relationships each time as well.
  ActionController::Dispatcher.to_prepare(:cache_advance_reload) do
    AnnotationSecurity.reset
    AnnotationSecurity::ModelObserver.instance.reload_model_observer
  end
end