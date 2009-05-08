#
# = lib/security/abstract_static_policy.rb
#
# Abstract superclass for all static policies
#
# For each policy there is a static policy that is responsible for evaluating
# static rules.
#
class AnnotationSecurity::AbstractStaticPolicy < AnnotationSecurity::AbstractPolicy # :nodoc:

  # Rules that are defined for all resource types can be found here.
  def self.all_resources_policy # :nodoc:
    AllResourcesPolicy.static_policy_class
  end

  # Sets the dynamic policy class this policy class belongs to
  def self.belongs_to(dynamic_policy_class) #:nodoc:
    @dynamic_policy_class = dynamic_policy_class
  end

  # A static policy class has no other corresponding static policy class.
  # This should never be called.
  def self.static_policy_class #:nodoc:
    method_missing(:static_policy_class)
  end

  # The corresponding dynamic policy class.
  #
  def self.dynamic_policy_class #:nodoc:
    @dynamic_policy_class
  end

  # Returns true iif this is policy class is responsible for static rules.
  #
  def self.static? # :nodoc:
    true
  end

  # Rule set for this classes resource type
  #
  def self.rule_set # :nodoc:
    # Each dynamic and static policy pair shares one rule set.
    dynamic_policy_class.rule_set
  end

  # If possible, redirects the rule to the static side.
  # Returns a rule object or nil.
  def self.use_static_rule(symbol) #:nodoc:
    nil # This is not possible
  end

  # Evaluate the rules in static mode.
  # Rules that cannot be evaluated are skipped.
  # * +rules+ array of symbols
  # Throws a SecurityViolationError if a rule fails,
  # returns true if all rules succeed.
  def evaluate_statically(rules) #:nodoc:
    rules.each do |rule|
      if has_rule?(rule) && !__send__(rule)
        raise_access_denied(rule)
      end
    end
    true
  end

  # Evaluate a rule that is defined with a proc
  # * +symbol+ Name of the rule
  # * +user+ AnnotationSecurity::UserWrapper object that has to fulfill the rule
  # * +args+ List of additional arguments
  def evaluate_rule(rule,user,args) #:nodoc:
    # In contrast to AbstractPolicy#evaluate_rule,
    # no resource is passed as argument
    get_rule!(rule).evaluate(self,user,*args)
  end

end