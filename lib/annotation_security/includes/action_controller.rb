#
# = lib/annotation_security/includes/action_controller.rb
#
# Provides security extensions for rails controllers.
# Is included by ActionController::Base.
#
# == How to secure your controller
# 
# To apply security rules to an action, the class method describe has to be
# used to describe the activity done by the action:
#
#  class PictureController < ActionController::Base
#
#    describe :download, "show a picture"
#   
#    def download
#      @path = Picture.find(params[:id]).path
#    end
#  end
#
# Now the right 'show' for the 'picture'-resource will be applied for every
# picture object that is fetched from the database.
#
# See ClassMethods for more information about descriptions.
#
# To find out more about right definitions, see AnnotationSecurity::RightLoader
# and AnnotationSecurity::RelationLoader.
# 
# Don't forget to initialize the SecurityContext.
#
module AnnotationSecurity::ActionController # :nodoc:

  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send :include, InstanceMethods
  end

  #
  # = lib/annotation_security/includes/action_controller.rb
  #
  # == Add some useful information about descriptions here
  module ClassMethods # :nodoc:

    def default_resource
      @default_resource ||=
          name.first(-"Controller".length).singularize.underscore.to_sym
    end

  end

  module InstanceMethods # :nodoc:
    def security_exception=(ex)
      @security_exception = ex
    end
  end
end