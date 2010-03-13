#
# = lib/annotation_security/policy/rule.rb
#

# = AnnotationSecurity::Rule
# A right or a relation that belongs to a policy.
#
# Rules can be static or dynamic or both.
# If the rule is a right, these values will be evaluated lazily.
#
class AnnotationSecurity::Rule # :nodoc:

  # Initialize a rule
  #
  def initialize(name,policy_class,*args,&block) # :nodoc:
    super()
    @name = name.to_sym
    @policy_class = policy_class
    @proc = block
    read_flags(args)
    read_options(args)
    if @proc
      initialize_for_proc(args)
    else
      initialize_for_string(args)
    end
    raise ArgumentError,
        "#{self}: Unexpected Arguments: #{args.join ','}" unless args.blank?
    #puts self
  end

  def to_s # :nodoc:
    "<#{full_name}[#{flag_s}]>"
  end

  def full_name # :nodoc:
    "#@policy_class##@name"
  end

  def flag_s # :nodoc:
    (@right ? 'r' : '-') +
    (@static.nil? ? '?' : (@static ? 's' : '-')) +
    (@dynamic.nil? ? '?' : (@dynamic ? 'd' : '-')) +
    (@req_user.nil? ? '?' : (@req_user ? 'u' : '-'))
  end

  # Return if this rule was defined as right
  #
  def right? # :nodoc:
    @right
  end

  # Return if this rule can be evaluated without a resource
  #
  def static? # :nodoc:
    return @static unless @static.nil?
    lazy_initialize
    @static
  end

  # Return if this rule can be evaluated with a resource
  #
  def dynamic? # :nodoc:
    return @dynamic unless @dynamic.nil?
    lazy_initialize
    @dynamic
  end

  def requires_credential? # :nodoc:
    return @req_user unless @req_user.nil?
    lazy_initialize
    @req_user
  end

  # Creates a method for a policy class that evaluates this rule
  # * +klass+ either @policy_class or its static partner
  #
  def extend_class(klass) # :nodoc:

    # Arguments passed to AbstractPolicy#user_roles
    # * +role+ symbol identifying the role a user must have (or nil)
    # * +user_required+ if false, the rule will also be
    #                   evaluated if the user is nil
    user_args = "#{@as ? ":#@as" : 'nil'},#{requires_credential?}"

    # Actual logic of the rule
    rule_code = @proc ? code_for_proc : code_for_string

    # Arguments passed to RuleExecutionError#new if an error occured
    # while evaluating the rule
    # * +rule+ full name of the rule
    # * +proc+ true iif this rule is defined with a proc
    # * +ex+ the original exeption
    ex_args = "'#{full_name}',#{@proc ? true : false},$!"

    code = "def #@name(*args) \n"

    # If parameter :is is given, @user.is_{@is}? has to return true.
    # 
    code << "return false if @user.nil? || !@user.is_#@is?\n" if @is
    code << %{
      # __resource__ = @resource
      return user_roles(#{user_args}).any? do |__user__|
        #{rule_code}
      end
    rescue StandardError
      raise $! if $!.is_a? AnnotationSecurity::SecurityError
      raise AnnotationSecurity::RuleExecutionError.new(#{ex_args})
    end}
    klass.class_eval(code)
    self
  end
  
  # Evaluate proc for policy
  def evaluate(policy,*args) # :nodoc:
    raise AnnotationSecurity::RuleError, "#{self}: This rule has no proc" unless @proc
    if @arity == 0
      policy.instance_exec(&@proc)
    elsif @arity > 0
      policy.instance_exec(*(args[0..@arity-1]),&@proc)
    else
      policy.instance_exec(*args,&@proc)
    end
  end

  # Creates a copy for policy class
  #
  def copy(policy_class) # :nodoc:
    args = [name, policy_class,flag,options,@condition].compact
    self.class.new(*args,&@proc)
  end

  def name # :nodoc:
    @name
  end

  private

  def read_flags(args)
    @right = false
    @static = false
    @dynamic = true
    @req_user = true
    if args.delete :right
      @right = true
      @req_user = @static = @dynamic = nil
    elsif args.delete :system
      @static = true
      @dynamic = false
    elsif args.delete :pretest
      @static = true
    else
      args.delete :resource # default
    end
  end

  def flag
    return :right if right?
    if static?
      return :pretest if dynamic?
      return :system
    else
      return :resource
    end
  end

  def read_options(args)
    hash = args.detect {|h| h.is_a? Hash}
    args.delete hash
    return if hash.blank?
    @as = hash.delete(:as)
    @is = hash.delete(:is)
    @req_user = hash.delete(:require_credential)
    @req_user = true if @req_user.nil? && !right?
    if (@as || @is) && !@req_user
      raise ArgumentError, "Options :as and :is always require a user!"
    end
    unless hash.empty?
      raise ArgumentError, "Unexpected keys [#{hash.keys.join(', ')}]"
    end
  end

  def options
    {:is => @is, :as => @as, :require_credential => (right? ? nil : requires_credential?)}
  end

  # Check for the optional parameter :as => :role
  def initialize_for_proc(args)
    @arity = @proc.arity    
  end

  def initialize_for_string(args)
    @condition = args.detect {|s| s.is_a? String } || 'true'
    args.delete @condition
  end

  # Find out if this rule can be evaluated statically
  def lazy_initialize
    raise_evil_recursion if @initialize_static
    @initialize_static = true
    if @proc
      # rules with proc must be defined as static explicitly
      @static = false
      @dynamic = true
      @req_user = true
    else
      # parse string to find out more
      if @condition =~ /:|self/
        # this only works with resources
        @static = false
        @dynamic = true
        @req_user = true
      else
        @static = true   # a right is static if it uses only static rules
        @dynamic = false # a right is dynamic if it uses at least one dynamic rule
        @req_user = false # unless at least one rule requires a user
        @condition.gsub(/\(|\)/,' ').split.each do |token|
          unless token =~ /\A(if|unless|or|and|not|true|false|nil)\Z/
            token = validate_token!(token)
            @static &= can_be_static?(token)
            @dynamic |= can_be_dynamic?(token)
            @req_user |= needs_user?(token)
          end
        end
      end
    end
    raise AnnotationSecurity::RuleError,
        "#{self} is neither static nor dynamic!" unless @static || @dynamic
  end

  def validate_token!(token)
    return token.to_sym if @policy_class.has_rule?(token.to_sym)
    body = AnnotationSecurity::Utils.method_body(token)
    return validate_token!(body) if body
    raise AnnotationSecurity::RuleNotFoundError, "Unknown rule '#{token}' in #{full_name}"
  end

  def can_be_static?(token)
    @policy_class.has_static_rule?(token)
  end

  def can_be_dynamic?(token)
    @policy_class.has_dynamic_rule?(token)
  end

  def needs_user?(token)
    @policy_class.get_rule(token).requires_credential?
  end

  def raise_evil_recursion
    raise AnnotationSecurity::RuleError,
        "Forbidden recursion in #{@policy_class.resource_class}: #{self}"
  end

  def code_for_proc
    "evaluate_rule(:#{name},__user__,args)"
  end

  def code_for_string
    condition = @condition.dup

    # Apply special role 'self'
    condition.gsub!('self', '__self__')

    apply_resource_notation(condition)
    apply_may_property_notation(condition)

    if condition =~ /\A(\s*)(if|unless)/
      # multilines in case +condition+ contains comments
      "#{condition} \n true \n else \n false \n end"
    else
      condition
    end
  end

  # Apply replacements for :resource notation:
  # Rules of the form prefix(:resource.res_suffix, additional_args) are
  # rewritten to @resource.res_suffix.policy_for(@user).prefix(additional_args)
  #
  # They are per definition dynamic!
  # Other rules which contain :resource are per se dynamic, too!
  #
  def apply_resource_notation(condition)
    regex = /([^\s\(]+)\(:resource(?:\.([^\s,]*))?(?:,\s*([^\(]*))?\)/

    condition.gsub!(regex) do |match|
      parse_expr(match.scan(regex).first)
    end
    #condition.gsub!(/:resource/, "@resource")
  end

  def parse_expr(expr)
    prefix = expr.at(0)
    res_suffix = expr.at(1)
    additional_args = expr.at(2)

    case prefix
    when /^(if|unless|or|and|not)$/
      # Should not be matched by regex
      raise ArgumentError, "Invalid syntax."
    else
      res_class, right = parse_right(prefix)
      if res_class
        "(PolicyManager.get_policy("+
            ":#{res_class},@user,@resource.#{res_suffix}).#{right})"
      else
        call = "(!(res = @resource"
        call <<  ".#{res_suffix}" if res_suffix
        call <<  ").nil? &&"
        call << "res.policy_for(@user).#{prefix}"
        call << "(#{additional_args})" if additional_args
        call << ')'
        call
      end
    end
  end

  # Apply replacements for 'may: property' notation
  def apply_may_property_notation(condition)
    rx_may_prop = /(\S+):\s*(\S+)/
    condition.gsub!(rx_may_prop) do |match|
      right, resource = match.scan(rx_may_prop).first
      res_class, right = parse_right(right)
      if res_class
        "(PolicyManager.get_policy("+
            ":#{res_class},@user,@resource.#{resource}).#{right})"
      else
        "(!(res = @resource.#{resource}).nil? &&" +
        " res.policy_for(@user).#{right})"
      end
    end
  end

  # Returns [res_class, right] if +right+ has the form "res_class.right",
  # else it returns [nil, right].
  def parse_right(right)
    rx_class_right = /(\S*)\.(\S*)/
    (right.scan(rx_class_right).first) || [nil,right]
  end
end
