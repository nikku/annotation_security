#
# = lib/security/filter.rb
#
# AnnotationSecurity Filter which filters current requests, sets up security context and
# applies security rules.
# 
#

require "active_record"

module AnnotationSecurity # :nodoc:

  # This filter is a before filter and is executed as the first filter in the
  # filter chain.
  #
  class InitializeSecurityFilter # :nodoc:

    # Initialize current security context depending on logged_in user
    #
    def self.filter(controller)
      SecurityContext.initialize(controller)
    end
  end

  # This filter is an around filter and is executed as the last filter before
  # execution of action.
  #
  class ApplySecurityFilter # :nodoc:

    # Initialize current security context depending on logged_in user
    #
    def self.filter(controller)

      ::ActiveRecord::Base.transaction do

        # apply static rules before entering the action
        SecurityContext.apply_static_rules

        # bindings may apply to parameters, try to check them too
        SecurityContext.apply_bounded_rules

        # Trigger invocation of action
        yield
      end
    rescue AnnotationSecurity::SecurityError
      SecurityContext.security_exception = $!
      raise $!
    end
  end
end