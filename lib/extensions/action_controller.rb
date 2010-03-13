#
# = lib/extensions/action_controller.rb
#

module ActionController # :nodoc:
  
  # Extends ActionController::Base for security.
  #
  class Base # :nodoc:

    # Include required security functionality
    include AnnotationSecurity::ActionController

    alias render_without_security render

    # Before rendering, evaluates the bounded rules of the current action.
    #
    def render(*args, &block)
      SecurityContext.apply_rules_after_action
      render_without_security(*args, &block)
    end

    alias redirect_to_without_security redirect_to

    # Before redirecting, evaluates the bounded rules of the current action.
    #
    def redirect_to(*args, &block)
      SecurityContext.apply_rules_after_action
      redirect_to_without_security(*args, &block)
    end
  end

end