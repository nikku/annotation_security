#
# = lib/security_context.rb
#
# Contains the SecurityContext
require 'active_support'

# = SecurityContext
#
# The SecurityContext provides methods for all security concerns of
# the current request.
#
# For every request, it has to be initialized using #current_user=. It is
# recommended to do this in a security filter, which can be used to catch
# AnnotationSecurityExceptions as well.
#
# The SecurityContext is implemented as a singleton for the current thread.
# Thus, all instance methods can be send to the class as well.
#
class SecurityContext

  # Returns current security context
  #
  def self.current
    Thread.current[:security_context]
  end

  # At the begin of a request, the security context will be initialized for the
  # current controller.
  #
  def self.initialize(controller) # :nodoc:
     load(new(controller))
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

  if Rails.env == 'development'
    # Disables all security checkings.
    # Is only available in development mode.
    def self.ignore_security!
      security_methods.each do |method|
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

    # initialize rule

    # rules that are not bound to any source,
    # will be triggered by model observer
    @context_rules = new_rules_hash
    @valid_objects = new_valid_objects_hash

    # rules bound to request param
    @param_rules = new_bound_rules_hash
    @param_valid_objects = new_bound_valid_objects_hash

    # rules bound to variable
    @var_rules = new_bound_rules_hash
    @var_valid_objects = new_bound_valid_objects_hash

    # Hash with all required policies
    @policies = new_policy_hash
  end

  # Sets the current user. This has to be done in a before or around filter,
  # *before* entering the action. Elsewise, the user will be interpreted as
  # not being logged in. Once set, the current user cannot be changed.
  #
  def credential=(user)
    if @cred_set
      raise AnnotationSecurity::AnnotationSecurityError,
            "Credential already set for this request"
    end
    @cred_set = true
    @credential = user
  end

  # Get the current credential
  def credential
    @credential
  end

  alias current_credential= credential=
  alias current_credential credential

  # Creates a copy of the current security context.
  # See #load for more information.
  def copy
    self.class.new(@controller).tap { |sc| sc.credential = credential }
  end

  # Will be set if an security exception was catched by the security filter
  def security_exception=(ex) # :nodoc:
    @security_exception = ex
    @controller.security_exception = ex
  end

  # If the action was aborted due to a security exception, this returns the
  # exception that was raised. Returns nil if no exception occurred.
  #
  def security_exception
    @security_exception
  end

  # See eval_with_security.
  def send_with_security(rules, obj, msg, *args, &proc)
    eval_with_security(rules) { obj.send(msg, *args, &proc) }
  end

  # Evaluates the given block, additionally using the given rules.
  #  rules == [ { :action => action, :resource => res_type, :source => binding  }, ...]
  # action and res_type should be symbols, binding is optional
  #
  def eval_with_security(rules)
    install_rules(rules)

    apply_rules_before_action

    result = yield

    apply_rules_after_action

    result
  rescue AnnotationSecurity::SecurityError
    SecurityContext.security_exception = $!
    raise $!
  ensure
    uninstall_rules(rules)
    result
  end

  def apply_rules_before_action # :nodoc:
    # apply static rules before entering the action
    apply_static_rules
    # bindings may apply to parameters, try to check them too
    apply_param_rules
    apply_var_rules
  end

  def apply_rules_after_action # :nodoc:
    # check again, bindings may have been changed
    apply_var_rules
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
  def allowed?(*policy_args)
    policy_args = AnnotationSecurity::Utils.parse_policy_arguments(policy_args)
    __allowed?(*policy_args)
  end

  # Equivalent to allowed?; is? is provided for better readability.
  #
  #  SecurityContext.allowed? :logged_in
  # vs
  #  SecurityContext.is? :logged_in
  #
  alias is? allowed?

  # Raises a SecurityViolationError if the rule defined by +policy_args+ is not
  # allowed. See allowed? for details.
  #
  def apply_rule(*args)
    self.class.raise_access_denied(*args) unless allowed?(*args)
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
  def allow_action?(*args) # :nodoc:

    controller, action, objects, params =
        AnnotationSecurity::Utils.parse_action_args(args)

    # var rules are ignored here
    context_rules, param_rules, _ = get_rule_set(controller, action)

    # check static rules
    evaluate_statically(context_rules)

    # check context rules for all objects
    objects.each do |o|
      res_type = o.resource_type
      evaluate_context_rules(context_rules, res_type, o)
    end

    evaluate_bound_rules_for_params(param_rules, params)

    true
  rescue SecurityViolationError
    return false
  end

  # Applies all system and pretest rules of the current action.
  # Raises a SecurityViolationError if a rule is violated.
  #
  def apply_static_rules # :nodoc:
    evaluate_statically(@context_rules)
  end

  def apply_param_rules # :nodoc:
    evaluate_bound_rules(@param_rules, @param_valid_objects)
  end

  def apply_var_rules # :nodoc:
    evaluate_bound_rules(@var_rules, @var_valid_objects)
  end

  # Applies all rules of the current action to the resource defined by
  # +resource_args+. Raises a SecurityViolationError if a rule is
  # violated.
  #
  def apply_context_rules(*res_args) # :nodoc:
    restype, res = AnnotationSecurity::Utils.parse_resource_arguments(res_args)
    evaluate_context_rules(@context_rules, restype, res)
  end

  alias apply_rules apply_context_rules # :nodoc:

  # Call if a resource object was touched during an action. Will be called
  # automatically for model objects.
  #
  # Applies all rules that are currently active to the resource defined by
  # +resource_args+. Raises a SecurityViolationError if a rule is
  # violated.
  #
  # ==== Usage
  #  observe :resource, @resource
  # where <tt>:resource</tt> is the resource type @resource belongs to, or
  #  observe @resource
  # which is equivalent if <tt>@resource.resource_name == :resource</tt>
  #
  def observe(*resource_args)
    apply_context_rules(*resource_args)
  end

  # Raise a SecurityViolationError.
  # See allowed? for details on +policy_args+.
  #
  def self.raise_access_denied(*policy_args)
    log_access_denied(policy_args)
    raise SecurityViolationError.access_denied(credential,*policy_args)
  end

  # Activates access logging for the current request.
  #
  def log!(&proc)
    @enable_logging = true
    @log = proc || Proc.new do |result, action, res_type, resource|
      result = result ? 'ALLOWED' : 'REFUSED' unless result.is_a? String
      msg = "%-8s %-10s %-16s %s" % [result, action, res_type, resource]
      puts msg
    end
  end

  def log_access_denied(policy_args) # :nodoc:
    @log.call('DENIED!', *policy_args) if @enable_logging
  end

  protected

  def log_access_check(*policy_args)
    @log.call(*policy_args) if @enable_logging
  end

  private

# data =========================================================================

  # { binding => { :res_type1 => [:action1, ...], ... }, ... }
  def new_bound_rules_hash() # :nodoc:
    Hash.new { |h,k| h[k] = new_rules_hash }
  end

  # { :res_type1 => [:action1, ...], ... }
  def new_rules_hash() # :nodoc:
    Hash.new { |h,k| h[k] = [] }
  end

  # { binding => [object1, ...], ...}
  def new_bound_valid_objects_hash() # :nodoc:
    Hash.new { |h,k| h[k] = [] }
  end

  # { :res_type1 => { :action1 => [object1, ...], ...}, ...}
  def new_valid_objects_hash() # :nodoc:
    Hash.new { |h,k| h[k] = Hash.new { |h2,k2| h2[k2] = [] } }
  end

  # {:res_type1 => policy1, ...}
  def new_policy_hash() # :nodoc:
    Hash.new { |h,k| h[k] = new_policy(k) }
  end

  def new_policy(resource_type) # :nodoc:
    AnnotationSecurity::PolicyManager.create_policy(resource_type, credential)
  end

  # Get the policy for a resource type from the cache
  def policy(res_type) # :nodoc:
    @policies[res_type]
  end

# rules management =============================================================

  def install_rules(rules, rule_set=nil, controller=@controller.class)
    rules.each { |rule| install_rule rule, rule_set, controller }
  end

  def install_rule(rule, rule_set, controller)
    rule_list(rule, rule_set, controller) << rule[:action]
  end

  def uninstall_rules(rules, rule_set=nil, controller=@controller.class)
    rules.each { |rule| uninstall_rule rule, rule_set, controller }
  end

  def uninstall_rule(rule, rule_set, controller)
    list = rule_list(rule, rule_set, controller)
    i = list.index(rule[:action])
    list.delete_at(i) if i
  end

  def rule_list(rule, rule_set, controller)
    rule_set ||= [@context_rules, @param_rules, @var_rules]
    resource = rule[:resource] || controller.default_resource
    source = rule[:source]
    if source.nil?
      list = rule_set.first[resource]
    elsif source.is_a? Symbol
      list = rule_set.second[source][resource]
    else
      list = rule_set.third[source][resource]
    end
    list
  end

  # returns rule set for other controller actions
  def get_rule_set(controller, action) # :nodoc:
    @rule_sets ||= Hash.new { |h,k| h[k] = {} }
    rule_set = @rule_sets[controller][action]
    unless rule_set
      rule_set = [new_rules_hash, new_bound_rules_hash, new_bound_rules_hash]
      rules = controller.descriptions_of action
      install_rules rules, rule_set, controller
      @rule_sets[controller][action] = rule_set
    end
    rule_set
  end

# rule evaluation ==============================================================

  # Evaluate the rules statically, skips all rules that are static only.
  # * +rules+ a Hash like {:resource_type => [:right1, :right2]}
  def evaluate_statically(rules) # :nodoc:
    # rules == { :resource1 => [:right1, ...], ... }
    rules.each_pair do |resource_type,rights|
      policy(resource_type).evaluate_statically(rights)
    end
  end

  # Checks bound rules. Evaluates the bindings, on success adds objects
  # to valid objects.
  #  rules == { binding1 => { :res_type1 => [:action1, ...], ... }, ... }
  #  valid_objects == { binding1 => [object1, ...], ... }
  def evaluate_bound_rules(rules, valid_objects) # :nodoc:
    evaluate_bound_rules_with_binding(rules, valid_objects) do |binding|
      @controller.values_of_source(binding)
    end
  end

  # Checks bound rules using the values from params
  #  rules == { binding1 => { :res_type1 => [:action1, ...], ... }, ... }
  #  params == { binding1 => object1, ... }
  def evaluate_bound_rules_for_params(rules, params) # :nodoc:
    valid_objects = new_bound_valid_objects_hash
    evaluate_bound_rules_with_binding(rules, valid_objects) do |binding|
      values = params[binding]
      values.is_a?(Array) ? values : [values]
    end
  end

  def evaluate_bound_rules_with_binding(rules, valid_objects, &proc) # :nodoc:
    rules.each_key do |binding|
      value_ids = proc.call(binding)
      rules[binding].each_key do |res_type|
        values = value_ids.collect do |id|
          AnnotationSecurity::ResourceManager.get_resource res_type, id
        end
        values.compact!
        values_of_res_type = values - valid_objects[binding]
        values_of_res_type.each do |resource|
          evaluate_rules(rules[binding][res_type],
                         res_type,
                         resource)
          valid_objects[binding] << resource
        end
      end
    end
  end

  # Checks context rules for given resource
  #  rules == { :res_type1 => [:action1, ...], ... }
  def evaluate_context_rules(rules, res_type, res) # :nodoc:
    evaluate_rules(rules[res_type], res_type, res)
  end

  # Checks if actions on resource are allowed. If true, adds to valid objects.
  # Returns true
  #  actions == [:action1, ...]
  #  valid_objects == { :action1 => [object1, ...], ... }
  def evaluate_rules(actions, res_type, resource) # :nodoc:
    valid_objects = @valid_objects[res_type]
    actions.each do |action|
      unless valid_objects[action].index(resource)
        __apply_rule(action, res_type, resource)
        valid_objects[action] << resource
      end
    end
    true
  end

  # Usage:
  #  __allowed? :show, :assignment, an_assignment
  def __allowed?(action, res_type, resource=nil) # :nodoc:

    block = lambda do
      if resource
        policy(res_type).allowed?(action, resource)
      else
        policy(res_type).static_policy.allowed?(action, nil)
      end
    end

    block.call.tap do |r|
      log_access_check r, action, res_type, resource
    end
  end

  # Raises a SecurityViolationError if the rule defined by +policy_args+ is not
  # allowed. See __allowed? for details.
  #
  def __apply_rule(*args) # :nodoc:
    self.class.raise_access_denied(*args) unless __allowed?(*args)
  end

  #=============================================================================
  # Singleton

  def self.security_methods
    instance_methods(false).delete_if { |m| [:enabled?].member? m.to_sym }
  end

  #=============================================================================
  # Without security block implementation

  class SecurityContextDummy
    attr_accessor :credential

    def initialize(credential)
      self.credential = credential
    end

    def method_missing(symbol, *args)
      # puts "#{self.class}##{symbol}(#{args})"
    end

    def enabled?
      false
    end
  end

  public

  def enabled?
    true
  end

  # Runs a given block with security disabled. Inside the block, the context
  # will be disabled for the current thread.
  #
  def self.without_security!(&block)
    old_current = current

    credential = old_current.credential if old_current
    load SecurityContextDummy.new(credential)
    return_value = yield
    load old_current
    return_value
  end

  # create singleton methods
  security_methods.each do |method|
    if method.to_s.end_with? '='
      # setters need a different handling
      class_eval %{
        def self.#{method}(value)
          current.#{method}(value) if current
        end }
    else
      class_eval %{
        def self.#{method}(*args,&proc)
          current.#{method}(*args,&proc) if current
        end }
    end
  end
end
