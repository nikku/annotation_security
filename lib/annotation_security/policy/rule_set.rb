#
# = lib/annotation_security/policy/rule_set.rb
#

# = AnnotationSecurity::RuleSet
# Contains all rule objects for a policy
#
class AnnotationSecurity::RuleSet # :nodoc:

  # Initializes the rule set
  # * +pclass+ Policy class this rule set belongs to
  #
  def initialize(pclass)
    super()
    @pclass = pclass
    @rights = {}
    @static = {}
    @dynamic = {}
  end

  def to_s
    "<RuleSet of #@pclass>"
  end

  # Returns a rule object or nil if the rule does not exist.
  # * +symbol+ name of the rule
  # * +static+ boolean specifing whether the rule is static or dynamic
  def get_rule(symbol,static)
    static ? get_static_rule(symbol) : get_dynamic_rule(symbol)
  end

  # Returns a dynamic rule or nil if the rule does not exist.
  # * +symbol+ name of the rule
  def get_dynamic_rule(symbol)
    # If no rule is available, maybe there is a right that can be used
    @dynamic[symbol] ||= get_dynamic_right(symbol)
  end

  # Returns a static rule or nil if the rule does not exist.
  # * +symbol+ name of the rule
  def get_static_rule(symbol)
    # If no rule is available, maybe there is a right that can be used
    @static[symbol] ||= get_static_right(symbol)
  end

  # Copies a rule from another rule set.
  # Returns the newly created rule or nil if the operation had no effect.
  # * +symbol+ name of the rule
  # * +source+ rule set to copy from
  # * +static+ boolean specifing whether the rule is static or dynamic
  def copy_rule_from(symbol,source,static)
    add_copy(source.get_rule(symbol,static))
  end

  # Creates a dynamic rule that redirects to a static rule with the same name.
  # Returns the newly created rule or nil if the operation had no effect.
  # * +symbol+ name of the rule
  def create_dynamic_copy(symbol)
    rule = get_static_rule(symbol)
    if rule
      add_rule(symbol,
          "static_policy.#{symbol}(*args)",
          :resource,
          :require_credential => rule.requires_credential?)
    end
  end

  # Adds a new rule to this rule set. The rule will be classified either
  # as dynamic, static, both or right.
  # Returns the newly create rule.
  # For an explainition of the parameters see AnnotationSecurity::Rule#initialize.
  def add_rule(symbol,*args,&block)
    __add__ AnnotationSecurity::Rule.new(symbol,@pclass,*args,&block)
  end

  private

  # Copies a rule object to this rule set.
  # Returns the newly created rule or nil.
  # * +rule+ rule object to copy or nil.
  def add_copy(rule)
    __add__(rule.copy(@pclass)) if rule
  end

  # Adds a new rule to this rule set. The rule will be classified either
  # as dynamic, static, both or right.
  # * +rule+ rule object
  def __add__(rule)
    if rule.right?
      # if the rule is a right, its not clear yet whether
      # it is static or dynamic. These rules will be analyzed later.
      raise_if_forbidden_name 'right', rule
      raise_if_exists 'right', @rights[rule.name]
      @rights[rule.name] = rule
    else
      raise_if_forbidden_name 'relation', rule
      if rule.dynamic?
        raise_if_exists 'dynamic relation', @dynamic[rule.name]
        @dynamic[rule.name] = rule
      end
      if rule.static?
        raise_if_exists 'static relation', @static[rule.name]
        @static[rule.name] = rule
      end
    end
    rule
  end

  # Raises an error if +rule+ is not nil.
  # * +type+ type of rule, like 'right' or 'dynamic relation'
  # * +rule+ existing rule object or nil
  def raise_if_exists(type,rule)
    raise AnnotationSecurity::RuleError.defined_twice(type,rule) if rule
  end

  # Raises an error if +rule+ has a forbidden name.
  # * +type+ type of rule, like 'right' or 'relation'
  # * +rule+ rule object
  def raise_if_forbidden_name(type,rule)
    if AnnotationSecurity::AbstractPolicy.forbidden_rule_names.include? rule.name.to_s
      raise AnnotationSecurity::RuleError.forbidden_name(type,rule)
    end
  end

  # Returns a dynamic rule that was defined as right
  # * +symbol+ name of the rule
  def get_dynamic_right(symbol)
    r = @rights[symbol]
    r and r.dynamic? ? r : nil
  end

  # Returns a static rule that was defined as right
  # * +symbol+ name of the rule
  def get_static_right(symbol)
    r = @rights[symbol]
    r and r.static? ? r : nil
  end

end