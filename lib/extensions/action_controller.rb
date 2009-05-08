module ActionController # :nodoc:
  #
  # = lib/extensions/action_controller.rb
  #
  # Extends ActionController::Base for security.
  #
  # See AnnotationSecurity::ActionController for details on how to
  # secure your controllers.
  #
  class Base # :nodoc:
    include AnnotationSecurity::ActionController

    alias render_without_security render

    # Before rendering, evaluates the bounded rules of the current action.
    #
    def render(*args, &block)
      SecurityContext.apply_bounded_rules
      render_without_security(*args, &block)
    end

    alias redirect_to_without_security redirect_to

    # Before redirecting, evaluates the bounded rules of the current action.
    #
    def redirect_to(*args, &block)
      SecurityContext.apply_bounded_rules
      redirect_to_without_security(*args, &block)
    end
  end

end