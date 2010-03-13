#
# = lib/annotation_security/filters.rb
#

require "active_record"

module AnnotationSecurity # :nodoc:
  
  # Contains filters of the security layer which filter current requests,
  # set up security context and apply security rules.
  module Filters
    # This filter is a before filter and is executed as the first filter in the
    # filter chain. It initializes the security layer.
    class InitializeSecurity
      
      # Initialize current security context depending on logged_in user
      def self.filter(controller)
        SecurityContext.initialize(controller)
        yield
      end
    end

    # This filter is an around filter and is executed as the last filter before
    # execution of action. It applies the security mechanisms.
    class ApplySecurity
      # Applies security policies based on current user.
      def self.filter(controller)
        ::ActiveRecord::Base.transaction do
          rules = controller.class.descriptions_of(controller.action_name)
          SecurityContext.current.eval_with_security(rules){ yield }
        end
      rescue AnnotationSecurity::SecurityError
        SecurityContext.security_exception = $!
        raise $!
      end
    end
  end
end