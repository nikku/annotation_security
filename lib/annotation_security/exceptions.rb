#
# = lib/annotation_security/exceptions.rb
#
# Provides some Exceptions used within AnnotationSecurity

module AnnotationSecurity

  # Superclass of all security related errors thrown by anno sec
  class SecurityError < StandardError # :nodoc:
  end

end

# Exception indicating that some rights were violated.
#
class SecurityViolationError < AnnotationSecurity::SecurityError

  def self.access_denied(user,*args) # :nodoc:
    new(user,*args)
  end

  def initialize(user=nil,*args) # :nodoc:
    if user == nil || args.empty?
      super "Access denied"
    else
      super load_args(user,args)
    end
  end

  def load_args(user,args) # :nodoc:
    @user = user
    @action,@resclass,@res = AnnotationSecurity::Utils.parse_policy_arguments(args)
    "You (#@user) are missing the right '#@action' for #@resclass" +
        (@res.blank? ? '' : " '#@res'")
  end

  # user that violated the right
  #
  def user
    @user
  end

  # the action that should have been performed on the resource object
  #
  def action
    @action
  end

  # the resource type
  #
  def resource_class
    @resclass
  end

  # the resource that was accessed
  #
  def resource
    @res
  end
end

module AnnotationSecurity

  # = AnnotationSecurity::RuleError
  #
  # Will be raised if a right or relation is defined twice
  # or has an invalid name.
  #
  class RuleError < SecurityError
    def self.defined_twice(type,rule) # :nodoc:
      new "The #{type} #{rule} is defined twice"
    end

    def self.forbidden_name(type,rule) # :nodoc:
      new "#{rule} is not allowed as #{type} name"
    end
  end

  # = AnnotationSecurity::RuleExecutionError
  #
  # Will be raised if an error occured while evaluation a right or relation.
  #
  class RuleExecutionError < RuleError

    def initialize(rule, proc=false, ex = nil) # :nodoc:
      if ex
        log_backtrace(proc,ex)
        super("An error occured while evaluating #{rule}: \n" +
              ex.class.name + ": " + ex.message)
      else
        super("An error occured while evaluating #{rule}")
      end
    end

    def set_backtrace(array) # :nodoc:
      super((@bt || []) + array[1..-1])
    end

    private

    # Select all lines of the backtrace above "rule.rb evaluate".
    # so they can be appended to the backtrace
    def log_backtrace(proc,ex)
      return unless proc
      backtrace = ex.backtrace
      stop = backtrace.find { |l| l =~ /rule\.rb(.*)`evaluate'/ }
      stop = backtrace.index(stop) || 5
      backtrace = backtrace.first(stop)
      @bt = backtrace.reject { |l| l =~ /annotation_security|active_support/ }
    end

  end

  # = AnnotationSecurity::RuleNotFoundError
  #
  # Will be raised when attempting to acces a right or relation that was not
  # defined.
  #
  class RuleNotFoundError < RuleError
    def self.for_rule(rname,policy_class)
      new("Unknown #{policy_class.static? ? 'static' : 'dynamic'} " +
          "rule '#{rname}' for #{policy_class.name}")
    end
  end
end