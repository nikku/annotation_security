#
# = lib/annotation_security/includes/action_controller.rb
#

# Provides security extensions for rails controllers.
# Is included in ActionController::Base.
#
# See AnnotationSecurity::ActionController::ClassMethods.
#
module AnnotationSecurity::ActionController

  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send :include, InstanceMethods
  end

  # Provides security extensions for rails controllers on the class side.
  # 
  module ClassMethods

    # Filters are not affected by the security settings of the action.
    # If you want security checkings in your filters, activate them with
    # +apply_security+.
    #
    #  apply_security :get_user
    #
    #  private
    #
    #  desc "shows a user"
    #  def get_user
    #    @user = User.find params[:id]
    #  end
    #
    # You can use +apply_security+ to secure any methods, not only filters.
    # Notice that these rules are *not* taken into account when evaluating
    # AnnotationSecurity::Helper#link_to_if_allowed and similar methods.
    #
    def apply_security(*symbols)
      symbols.each { |s| pending_security_wrappers << s.to_sym }
    end

    # Filters are not affected by the security settings of the action.
    # If you want the security settings of the action applied to your filter,
    # use this method. It can be combined with #apply_security
    def apply_action_security(*symbols)
      symbols.each { |s| pending_action_security_wrappers << s.to_sym }
    end

    # AnnotationSecurity is using the +method_added+ callback. If this method
    # is overwritten without calling +super+, +apply_security+ will not work.
    #
    def method_added(method)
      super(method)
      if pending_security_wrappers.delete method
        build_security_wrapper(method)
      end
      if pending_action_security_wrappers.delete method
        build_action_security_wrapper(method)
      end
    end

    # If no resource type is provided in a description, the default resource
    # will be used. Once set the value cannot be changed.
    #
    # This is still experimental. You should not use it unless you have a
    # reason. It might be usefull for inheritance.
    #
    def default_resource(value=nil)
      @default_resource ||= value || compute_default_resource
    end

    # Creates a new security filter.
    #
    # Security filters are around filters that are evaluated before the first
    # before filter. Use security filters to set the credentials and to react
    # to security violations.
    #  class ApplicationController < ActionController::Base
    #
    #    security_filter :security_filter
    #
    #    private
    #
    #    def security_filter
    #      SecurityContext.current_credential = session[:user]
    #      yield
    #    rescue SecurityViolationError
    #      if SecurityContext.is? :logged_in
    #        render :template => "welcome/not_allowed"
    #      else
    #        render :template => "welcome/please_login"
    #      end
    #    end
    #
    # See SecurityContext#current_credential= and SecurityViolationError.
    #
    def security_filter(symbol, &block)
      filter_chain.append_filter_to_chain([symbol], :security, &block)
    end

    private

    def pending_security_wrappers
      @pending_security_wrappers ||= []
    end

    def pending_action_security_wrappers
      @pending_action_security_wrappers ||= []
    end

    def build_security_wrapper(method)
      no_security = "#{method}_without_security".to_sym
      class_eval %{
        alias :#{no_security} :#{method}
        def #{method}(*args, &proc)
          rules = self.class.descriptions_of(:#{method})
          SecurityContext.current.send_with_security(rules, self, :#{no_security}, *args, &proc)
        end
      }
    end

    def build_action_security_wrapper(method)
      no_security = "#{method}_without_action_security".to_sym
      class_eval %{
        alias :#{no_security} :#{method}
        def #{method}(*args, &proc)
          rules = self.class.descriptions_of(action_name)
          SecurityContext.current.send_with_security(rules, self, :#{no_security}, *args, &proc)
        end
      }
    end

    def compute_default_resource
      name.first(-"Controller".length).singularize.underscore.to_sym
    end

  end

  module InstanceMethods # :nodoc:

    def security_exception=(ex)
      @security_exception = ex
    end
  end
end