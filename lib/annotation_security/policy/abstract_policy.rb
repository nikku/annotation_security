#
# = lib/annotation_security/policy/abstract_policy.rb
#

# Abstract superclass for all policies
#
# For each resource type there is a corresponding policy class.
# In its entire lifetime, a policy object is responsible for a single user.
# A policy object can validate the rights for only one resource
# object at a time (it is not thread safe!).
#
class AnnotationSecurity::AbstractPolicy

  # Creates a new policy class for a resource type.
  #
  def self.new_subclass(resource_type) #:nodoc:
    Class.new(self).tap do |c|
      c.initialize(resource_type)
    end
  end

  # Initializes a subclass of AbstractPolicy
  #
  def self.initialize(resource_type) #:nodoc:
    @resource_type = resource_type.to_s.underscore.to_sym
    
    # register the class as constant
    name = resource_type.to_s.camelize + classname_suffix
    Object.const_set name, self

    unless static?
      # Each policy has a static partner
      @static_policy_class = AnnotationSecurity::AbstractStaticPolicy.new_subclass(@resource_type)
      @static_policy_class.belongs_to self
      reset
    end
  end

  # Suffix that is appended to the camlized resource type to
  # generate a class name.
  #
  def self.classname_suffix # :nodoc:
    static? ? 'StaticPolicy' : 'Policy'
  end

  # (Re-)Initializes the policy class.
  # Removes all generated methods and clears the rule set.
  #
  def self.reset # :nodoc:
    instance_methods(false).each { |m| remove_method m }
    @has_rule = Hash.new {|h,k| h[k] = !get_rule(k).nil?}
    @my_rules = Hash.new {|h,k| h[k] = load_rule(k)}
    unless static?
      # set of all rule objects available for this policy
      @rule_set = AnnotationSecurity::RuleSet.new(self)
      # {:rule => boolean} if true, the rule can be evaluated statically only
      @static_only = Hash.new(false)
      # {:rule => boolean} if true, the rule can be evaluated dynamically
      @has_dynamic = Hash.new {|h,k| h[k] = has_rule?(k) && !@static_only[k]}
      @static_policy_class.reset
    end
  end

  # List of strings that are not allowed as rule names (maybe incomplete).
  #
  def self.forbidden_rule_names # :nodoc:
    instance_methods
  end

  # Rules that are defined for all resource types can be found here.
  # (Overwritten by static policy)
  def self.all_resources_policy # :nodoc:
    AllResourcesPolicy
  end

  # Symbol representing the resource type this policy is responsible for.
  #
  def self.resource_type # :nodoc:
    @resource_type
  end

  # The corresponding static policy class.
  #
  def self.static_policy_class # :nodoc:
    @static_policy_class
  end

  # Returns true iif this is policy class is responsible for static rules.
  #
  def self.static? # :nodoc:
    false
  end

  # Rule set for this classes resource type
  #
  def self.rule_set # :nodoc:
    @rule_set
  end

  # Returns true iif this policy can evaluate the rule
  # * +symbol+ Name of the rule
  def self.has_rule?(symbol) # :nodoc:
    @has_rule[symbol]
  end

  # Returns true iif the rule can be evaluated statically
  # * +symbol+ Name of the rule
  def self.has_static_rule?(symbol) # :nodoc:
    static_policy_class.has_rule? symbol
  end

  # Return true iif the rule can be evaluated dynamically
  # * +symbol+ Name of the rule
  def self.has_dynamic_rule?(symbol) # :nodoc:
    @has_dynamic[symbol]
  end

  # Get a rule object
  # * +symbol+ Name of the rule
  def self.get_rule(symbol) #:nodoc:
    @my_rules[symbol]
  end

  # The rule +symbol+ was requested, try to find and load it.
  # Returns a rule object or nil.
  def self.load_rule(symbol) #:nodoc:
    # 1. Have a look in the rule set
    # 2. Maybe the rule is defined for all resources
    # 3. Redirect the rule to the static side
    r = rule_set.get_rule(symbol,static?) ||
        copy_rule_from(symbol,all_resources_policy) ||
        use_static_rule(symbol)
    # Create a method for the rule
    r.extend_class(self) if r
    r
  end

  # If possible, copies a rule from another policy class.
  # * +symbol+ Name of the rule
  # * +source_policy+ policy class to copy from
  # Returns a rule object or nil.
  def self.copy_rule_from(symbol,source_policy) # :nodoc:
    rule_set.copy_rule_from(symbol,source_policy.rule_set,static?)
  end

  # If possible, redirects the rule to the static side.
  # Returns a rule object or nil.
  def self.use_static_rule(symbol) #:nodoc:
    if has_static_rule?(symbol)
      @static_only[symbol] = true
      rule_set.create_dynamic_copy(symbol)
    end
  end

  # Add a rule
  # * +symbol+ rule name
  # * +args+ additional arguments
  # * +block+ code block
  # See AnnotationSecurity::Rule#initialize for details
  #
  def self.add_rule(symbol,*args,&block) #:nodoc:    
    rule_set.add_rule(symbol,*args,&block)
  end

  # Initialize the instance for a user
  # * +user+ user object this policy object is responsible for
  # * +resource+ (optional) usually the resource object will be set using
  #              #allowed? or #with_resource
  def initialize(user,resource=nil)
    @user = user
    @resource = resource
  end

  # Static policy object to evaluate the static rules
  def static_policy # :nodoc:
    @static_policy ||= self.class.static_policy_class.new(@user)
  end

  # Symbol representing the resource type this policy is responsible for.
  #
  def resource_type # :nodoc:
    self.class.resource_type
  end

  # Returns true iif the user has the +right+ for +resource_obj+
  # * +right+ symbol
  # * +resource_obj+ resource object to test the right for
  # * +args+ (optional) additional arguments passed when evaluating the right
  # This is not thread safe! Don't share policy objects between different
  # threads (should be no problem though).
  # ==== Example
  #  policy.allowed? :show, obj #=> true or false
  def allowed?(right,resource_obj,*args)
    @resource = resource_obj
    __send__(right,*args)
#  rescue
#    raise "#{$!} in #{resource_type} policy " +
#      "during rule #{right} of #{resource_obj} with args [#{args.join(", ")}]"
  end

  # Sets the resource object and returns self
  # ==== Example
  #  policy.with_resource(obj).show? #=> true or false
  def with_resource(resource_obj)
    @resource = resource_obj
    self
  end

  # Evaluate the rules in static mode.
  # Rules that cannot be evaluated are skipped.
  # * +rules+ array of symbols
  # Throws a SecurityViolationError if a rule fails,
  # returns true if all rules succeed.
  def evaluate_statically(rules) #:nodoc:
    static_policy.evaluate_statically(rules)
  end

  # Evaluate the rules in dynamic mode.
  # Rules that cannot be evaluated are skipped.
  # * +rules+ array of symbols
  # Throws a SecurityViolationError if a rule fails,
  # returns true if all rules succeed.
  def evaluate_dynamically(rules) #:nodoc:
    rules.each do |rule|
      if self.class.has_dynamic_rule?(rule) && !__send__(rule)
        raise_access_denied(rule)
      end
    end
    true
  end

  # Evalutates all rules.
  # * +rules+ array of symbols
  # Throws a SecurityViolationError if a rule fails,
  # returns true if all rules succeed.
  def evaluate(rules) #:nodoc:
    rules.each do |rule|
      unless __send__(rule)
        raise_access_denied(rule)
      end
    end
    true
  end

  # Returns true iif this policy can evaluate this rule
  # * +symbol+ Name of the rule
  def has_rule?(symbol)
    self.class.has_rule? symbol
  end

  # Returns a rule object or raises an exception.
  # * +symbol+ Name of the rule
  def get_rule!(symbol) # :nodoc:
    get_rule(symbol) or raise_rule_missing(symbol)
  end

  # Returns a rule object or nil if it does not exist
  # * +symbol+ Name of the rule
  def get_rule(symbol) # :nodoc:
    self.class.get_rule(symbol)
  end

  # Returns a list of user wrappers for a role.
  # See #all_for_role for details.
  # * +symbol+ Name of the role
  # * +require_user+ (boolean) Indicating if the rule that requested the roles
  #   requires a user for evaluation. If @user is nil and +require_user+ is
  #   true, an empty array is returned, which will make the rule fail 
  #   immediately. If +require_user+ is false, an array containing nil is
  #   returned and the rule will be evaluated once (with +nil+ as current user).
  def user_roles(symbol,require_user) # :nodoc:
    return [nil] if @user.nil? && !require_user
    # AnnotationSecurity::UserWrapper.all_for_role(@user,symbol)
    all_for_role(@user,symbol)
  end

  # Return objects for the requested role. The role(s) will be
  # determined with sending user.as_'role'.
  # (Normally a user has a role only once, however it will work when he
  # has many roles of the same kind as well)
  def all_for_role(user,role_name) # :nodoc:
    return [] if user.nil?
    # is it possible that user is a role? if so, implement conversion to user
    return [user] if role_name.nil?
    roles = user.__send__("as_#{role_name}")
    return [] if roles.blank?
    roles = [roles] unless roles.is_a?(Array)
    roles.compact
  end

  # Evaluate a rule that is defined with a proc
  # * +symbol+ Name of the rule
  # * +user+ user object that has to fulfill the rule
  # * +args+ List of additional arguments
  def evaluate_rule(symbol,user,args) # :nodoc:
    get_rule!(symbol).evaluate(self,user,@resource,*args)
  end

  # Invoked by ruby when this object recieved a message it cannot handle.
  # * +symbol+ Name of the method
  # * +args+ Any arguments that were passed
  def method_missing(symbol,*args) # :nodoc:

    # If possible, create the missing method and send it again
    if add_method_for_rule(symbol)
      # method was created, try again
      return __send__(symbol,*args)
    end
    
    # this will fail and an exception will be raised
    get_rule!(symbol)
  end

  # Return true if it was possible to create a method for the rule
  # * +symbol+ Name of the method
  def add_method_for_rule(symbol) # :nodoc:
    # Check if symbol is a known rule. If available, it will be loaded and
    # a method will be created automatically.
    if has_rule?(symbol)
      # method was created
      return true
    else
      # Remove prefix or suffix if available
      cleaned = AnnotationSecurity::Utils.method_body(symbol)
      if cleaned
        # Redirect to the cleaned method
        self.class.class_eval "def #{symbol}(*args); #{cleaned}(*args); end"
        return true
      end
    end
    # Hopeless
    false
  end

  # Raises an error saying that a rule could not be found this policy class
  # * +symbol+ Name of the rule
  def raise_rule_missing(symbol) # :nodoc:
    raise AnnotationSecurity::RuleNotFoundError.for_rule(symbol,self.class)
  end

  def raise_access_denied(rule) #:nodoc:
    SecurityContext.raise_access_denied(rule,resource_type,@resource)
  end
  
end