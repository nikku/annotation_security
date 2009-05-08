#
# = lib/security_context.rb
#
# The SecurityContext singleton provides methods for all security concerns of
# the current request.
#
# For every request, it has to be initialized using current_user=. It is
# recommended to do this in an around filter, which be used to catch
# AnnotationSecurityExceptions as well
#
#  around_filter :security_filter
#
#  def security_filter
#    SecurityFilter.current_user = session[:user]
#    # or SecurityFilter.current_user = User.find(session[:user_id])
#    # depending on your session management
# 
#    yield
#  rescue SecurityValidationException
#    render :template => "welcome/not_allowed"
#  end
#
# The security context is unique for each thread, if you want to use
# multi threading, see load for details.
#
class SecurityContext

  # Returns current security context
  #
  def self.current # :nodoc:
    Thread.current[:security_context]
  end

  # At the begin of a request, the security context will be initialized for the
  # current controller.
  #
  def self.initialize(controller) # :nodoc:
     load(new(controller))
  end

  # Sets the current user. This has to be done in a before or around filter,
  # *before* entering the action. Elsewise, the user will be interpreted as
  # not being logged in. Once set, the current user cannot be changed.
  #
  def self.current_user=(user)
    current.user = user
  end

  def self.current_user
    current.user
  end

  # As the security context is a singleton bound to the current thread,
  # it will not be available in other threads. The following example shows
  # how to use the security context inside of a spawn block
  #
  #  copy = SecurityContext.copy
  #  spawn do
  #    SecurityContext.load(copy)
  #    begin
  #      # ...
  #    rescue SecurityViolationError
  #      puts 'Security was violated'
  #    end
  #  end
  #
  def self.load(sec_context)
    Thread.current[:security_context] = sec_context
  end

  # Creates a copy of the current security context.
  # See load for more information.
  def self.copy
    current.copy
  end

  # If the action was aborted due to a security exception, this returns the
  # exception that was raised. Returns nil if no exception occurred.
  #
  def self.security_exception
    current.security_exception
  end

  # Sets the security exception that is responsible for aborting the action.
  #
  def self.security_exception=(ex) # :nodoc:
    current.security_exception = ex
  end

  # Returns true iif the operation defined by +policy_args+ is allowed.
  #
  # The following calls to \#allowed? are allowed:
  #
  #   allowed? :show, :resource, @resource
  #   # => true if the current user has the right to show @resource,
  #   #    which belongs to the :resource resource-class
  #
  # In case of model objects or other classes which implement a #resource_type
  # method the the second argument may be ommited
  #
  #   allowed? :show, @resource
  #   # equivalent to the above call if @resource.resource_type == :resource
  #
  # A policy description used as a controller annotation may also be to check
  # a right
  #
  #   allowed? "show resource", @resource
  #   # => true if the current user has the right "show resource" for @resource
  #
  # A policy may also be applied without an object representing the context:
  #
  #   allowed? :show, :resource
  #   # => true if the current may show resources. 
  #
  # This will only check system and pretest rules. The result +true+ does not
  # mean that the user may show all resources. However, a +false+ indicates
  # that the user is not allowed to show any resources.
  #
  # If the resource type is omitted as well, only rules defined for all
  # resources can be tested. See RelationLoader#all_resources for details.
  #
  #  allowed? :administrate
  #  # => true if the user is allowed to administrate all resources.
  #
  def self.allowed?(*policy_args)
    current.allowed?(*policy_args)
  end

  # Equivalent to allowed?; is? is provided for better readability.
  #
  #  SecurityContext.allowed? :logged_in
  # vs
  #  SecurityContext.is? :logged_in
  #
  def self.is?(*policy_args)
    current.allowed?(*policy_args)
  end

  # Checks the rules of an other action. Note that rules that are bound to a
  # variable can not be checked.
  #
  # ==== Parameters
  # * +controller+ Symbol representing the controller, like :resource
  # * +action+ The called action, like :update
  # * +objects+ (optional) List of objects that will be relevant for that action.
  # * +params+ (optional) Hash of the passed parameters, like :id => 1.
  # 
  # ==== Examples
  #
  # Checks static and pretest rules.
  #  allow_action? :resource, :create
  #  # => true if the current user may execute ResourcesController#create
  #
  # Checks static, pretest and context rules
  #  allow_action? :resource, :edit, [@resource]
  #  # => true if the current user may execute ResourcesController#edit,
  #  #    assuming that @resource will be used in that action
  #
  # Checks static, pretest and context rules and all rules that are bound
  # to :id.
  #  allow_action? :resource, :edit, [@resource], {:id => 4}
  #  # => true if the current user may execute ResourcesController#edit,
  #  #    assuming that @resource will be used in that action
  #
  def self.allow_action?(controller, action, objects = [], params = {})
    current.allow_action?(controller, action, objects, params)
  end

  # Raises a SecurityViolationError if the rule defined by +policy_args+ is not
  # allowed. See allowed? for details.
  #
  def self.apply_rule(*policy_args)
    current.apply_rule(*policy_args)
  end

  # Applies all rules of the current action to the resource defined by
  # +resource_args+. Raises a SecurityViolationError if a rule is
  # violated.
  #
  # ==== Usage
  #  apply_rules :resource, @resource
  # where <tt>:resource</tt> is the resource type @resource belongs to, or
  #  apply_rules @resource
  # which is equivalent if <tt>@resource.resource_name == :resource</tt>
  #
  def self.apply_rules(*resource_args)
    current.apply_rules(*resource_args)
  end

  # Call if a resource object was touched during an action. Will be called
  # automatically for model objects.
  # The class of +object+ must include AnnotationSecurity::Resource.
  #
  def self.observe(object)
    current.apply_rules(object)
  end

  # Applies all system and pretest rules of the current action.
  # Raises a SecurityViolationError if a rule is violated.
  #
  def self.apply_static_rules # :nodoc:
    current.apply_static_rules
  end

  # Applies all rules that are not bound to a variable or a parameter.
  # Raises a SecurityViolationError if a rule is violated.
  # See apply_rules for details.
  #
  def self.apply_context_rules(*resource_args) # :nodoc:
    current.apply_context_rules(*resource_args)
  end

  # Applies all rules that are not bound to a variable or a parameter.
  # Raises a SecurityViolationError if a rule is violated.
  #
  def self.apply_bounded_rules # :nodoc:
    current.apply_bounded_rules
  end

  # Raises a SecurityViolationError.
  # See SecurityContext.allowed? for details on +policy_args+
  #
  def self.raise_access_denied(*policy_args)
    current.raise_access_denied(*policy_args)
  end

  # Sometimes this security stuff can be annoying,
  # so you can disable it in development mode
  if RAILS_ENV == 'development'
    def self.ignore_security!
      methods(false).each do |method|
        class_eval "def self.#{method}(*args); true; end"
      end
    end
  end

  ## ===========================================================================
  ## Instance

  # Initialize context for the given controller
  #
  def initialize(controller) # :nodoc:
    super()
    
    @controller = controller

    # Get all rules for the current action
    @rules = @controller.class.context_rules_for(controller.action_name)
    @bindings = @controller.class.bounded_rules_for(controller.action_name)

    # Hash with all required policies
    @policies = Hash.new { |h,k| h[k] = AnnotationSecurity::PolicyManager.create_policy(k, @user) }

    # For each resource type, a list of objects that were already checked
    @valid_objects = Hash.new { |h,k| h[k] = [] }
  end

  # Set the current user
  def user=(user) # :nodoc:
    raise AnnotationSecurity::AnnotationSecurityError, "User already set for this request" if @user_set
    @user_set = true
    @user = user
  end

  # Get the current user
  def user # :nodoc:
    @user
  end

  def copy #:nodoc:
    returning self.class.new(@controller) do |sc|
      sc.user = user
    end
  end

  # Will be set if an security exception was catched by the security filter
  def security_exception=(ex) # :nodoc:
    @security_exception = ex
    @controller.security_exception = ex
  end

  # If the action was aborted due to a security exception, this returns the
  # exception that was raised. Returns nil if no exception occurred.
  #
  def security_exception # :nodoc:
    @security_exception
  end

  # Returns true iif the operation defined by +policy_args+ is allowed.
  # See class method for details.
  #
  def allowed?(*policy_args) # :nodoc:
    policy_args = AnnotationSecurity::Utils.parse_policy_arguments(policy_args)
    __allowed?(*policy_args)
  end

  # Checks the rules of an other action.
  # See class method for details.
  #
  # ==== Parameters
  # * +controller+ Symbol representing the controller, like :resource
  # * +action+ The called action, like :update
  # * +objects+ (optional) List of objects that will be relevant for that action.
  # * +params+ (optional) Hash of the passed parameters, like :id => 1.
  #
  def allow_action?(controller, action, objects = [], params = {}) # :nodoc:

    controller = parse_controller(controller)
    rules = controller.context_rules[action.to_sym]
    bindings = controller.bounded_rules[action.to_sym]

    # check static rules
    evaluate_statically(rules,bindings)

    # check involved objects
    objects = [objects] unless objects.is_a? Array
    return false unless objects.all? do |object|
      allow_action_for_param?(rules,bindings,object)
    end

    # chech param bindings
    return false unless params.all? do |param,value|
      allow_action_for_param?(rules,bindings,value,param)
    end
    
    true
  rescue SecurityViolationError
    return false
  end

  # Raises a SecurityViolationError if the rule defined by +policy_args+ is not
  # allowed. See allowed? for details.
  #
  def apply_rule(*args) # :nodoc:
    raise_access_denied(*args) unless allowed?(*args)
  end

  # Applies all rules of the current action to the resource defined by
  # +resource_args+. Raises a SecurityViolationError if a rule is violated.
  # See class method for details.
  def apply_rules(*resource_args) # :nodoc:
    apply_context_rules(*resource_args)
    apply_bounded_rules
  end

  # Applies all system and pretest rules of the current action.
  # Raises a SecurityViolationError if a rule is violated.
  #
  def apply_static_rules # :nodoc:
    evaluate_statically(@rules,@bindings)
  end

  # Applies all rules that are not bound to a variable or a parameter.
  # Raises a SecurityViolationError if a rule is violated.
  # See apply_rules for details.
  #
  def apply_context_rules(*res_args) # :nodoc:
    _, res_type, obj = AnnotationSecurity::Utils.parse_policy_arguments([:r]+res_args)

    # can be skipped if the object was already tested
    unless valid?(res_type, obj)
      # dont evaluate static rules again
      evaluate_dynamically(@rules,res_type,obj)
      set_valid(res_type,obj)
    end
  end

  # Applies all rules that are not bound to a variable or a parameter.
  # Raises a SecurityViolationError if a rule is violated.
  #
  def apply_bounded_rules # :nodoc:
    # The evaluation of bounded rules may fetch model objects from the database,
    # which in turn triggers the evaluation of security rules.
    # This guard is to prevent endless recursion.
    return true if @checking_bindings

    # Bounded rules are applied before rendering and redirecting. To enable
    # redirecting to an error page, skip the evaluation if there already was
    # an error in the action.
    return true if @security_exception
    
    evaluate_bounded_rules
  end

  # Raise a SecurityViolationError.
  # See allowed? for details on +policy_args+.
  #
  def raise_access_denied(*policy_args) # :nodoc:
    raise SecurityViolationError.access_denied(user,*policy_args)
  end

  private

  # A hash in the form
  # { :resource_type1 => [:right1_a, :right1_b],
  #   :resource_type2 => [:right2_a, :right2_b] }
  # Where +rightX_Y+ are the rights required to access
  # objects of +resource_typeX+
  ## rules

  # Usage:
  #  __allowed? :show, :assignment, an_assignment
  def __allowed?(rule, res_type, resource=nil) # :nodoc:
    if resource
      policy(res_type).allowed?(rule, resource)
    else
      policy(res_type).static_policy.allowed?(rule, nil)
    end
  end

  # Evaluate dynamic rules for an object, skips all rules that are static only.
  # * +rules+ a Hash like {:resource_type => [:right1, :right2]}
  # * +resource_type+
  # * +object+
  def evaluate_dynamically(rules,resource_type,object) # :nodoc:
    if resource_type == :__all__
      # Used for evaluating parameters (like :id => 1) This means +object+
      # probably is a number or a string and has to be converted to a
      # corresponding resource object first
      rules.each_pair do |res_type,rules|
        o = AnnotationSecurity::ResourceManager.get_resource(res_type, object)
        eval_dyn(res_type,rules,o)
      end
    elsif resource_type
      eval_dyn(resource_type,rules[resource_type],object)
    else
      raise ArgumentError, "No resource type given"
    end
  end

  # Evaluate the +rights+ for an +object+ of a +resource_type+,
  # skips all rules that are static only.
  def eval_dyn(resource_type,rights,object) # :nodoc:
    policy(resource_type).with_resource(object).evaluate_dynamically(rights)
  end

  # Evaluates the rules statically, skips all rules that are dynamic only.
  # * +c_rules+ context rules
  # * +b_rules+ bounded rules
  def evaluate_statically(c_rules,b_rules) # :nodoc:
    eval_stat(c_rules)
    b_rules.each_value { |rules| eval_stat(rules) }
  end

  # Evaluate the rules statically, skips all rules that are static only.
  # * +rules+ a Hash like {:resource_type => [:right1, :right2]}
  def eval_stat(rules) # :nodoc:
    rules.each_pair do |resource_type,rights|
      policy(resource_type).evaluate_statically(rights)
    end
  end

  # Try to find the controller class from a name.
  # Looks for [name](s)Controller.
  #
  #  parse_controller :welcome #=> WelcomeController
  #  parse_controller :user # => UsersController
  #
  def parse_controller(controller) # :nodoc:
    begin
      "#{controller.to_s.camelize}Controller".constantize
    rescue NameError
      "#{controller.to_s.pluralize.camelize}Controller".constantize
    end
  rescue NameError
    raise NameError, "Controller '#{controller}' was not found"
  end

  # Return true iif the object is allowed in an action.
  # * +rules+ context rules defined for that action
  # * +bindings+ bounded rules defined for that action
  # * +object+ the object that will be used
  # * +param+ (optional) if the object was passed as a parameter, this is
  #           is the parameter name. Note that in this case +object+ might be
  #           a string of the object's ID and not the object itself.
  #
  def allow_action_for_param?(rules,bindings,object,param=nil) # :nodoc:
    if object.__is_resource?
      # Now we know the resource type of the object, so we can evaluate
      # the context rules.
      res_type = object.resource_type
      evaluate_dynamically(rules, res_type, object)
    end

    if param      
      # If we don't know the resource type, we have to test the rules for
      # all resource types for the current binding. However, in most cases
      # only one resource type should be possible per binding.
      res_type ||= :__all__
      # Evaluate the rules bound to this parameter
      evaluate_dynamically(bindings[param], res_type, object)
    end
    
    true
  rescue SecurityViolationError
    false
  end

  # Get the policy for a resource type from the cache
  def policy(res_type) # :nodoc:
    @policies[res_type]
  end

  # Returns true if the resource was already succesfully validated.
  # +category+ is either a resource type, if the resource was approved for a
  # context rule, or a binding, if the resource was approved for a bounded rule.
  def valid?(category,resource) # :nodoc:
    valid_objects(category).include? resource
  end

  # Returns all objects approved for +category+
  def valid_objects(category) # :nodoc:
    @valid_objects[category]
  end

  # Sets the resources as valid.
  def set_valid(category,*resources) # :nodoc:
    @valid_objects[category] += resources
  end

  # Checks all resources that are newly associated to a binding.
  #
  def evaluate_bounded_rules # :nodoc:
    # Activate the guard to prevent endless recursion
    @checking_bindings = true
    
    @bindings.each_pair do |binding,rules|
      # Get all objects associated with the binding and remove those objects
      # that have been validated for this binding already.
      values = @controller.values_of_binding(binding) - valid_objects(binding)

      # Check the new objects
      values.each { |obj| evaluate_dynamically(rules,get_res_type(obj),obj) }

      set_valid(binding, *values)
    end
  ensure
    @checking_bindings = false
  end

  # Tries to determine the resource type of +obj+. If this is not possible,
  # :__all__ is returned, indicating that the rules of all resources have to be
  # checked.
  #
  def get_res_type(obj) # :nodoc:
    obj.__is_resource? ? obj.resource_type : :__all__
  end
  
end
