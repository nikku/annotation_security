#
# = lib/annotation_security/policy_factory.rb
#
# Builds the policy classes.
#
#
class AnnotationSecurity::PolicyFactory # :nodoc:

  def initialize(resource_class)
    @klass = AnnotationSecurity::AbstractPolicy.new_subclass(resource_class)
  end

  def policy_class
    @klass
  end

  def add_rule(symbol,*args,&block)
    @klass.add_rule(symbol,*args,&block)
  end

  def create_policy(*args)
    @klass.new(*args)
  end

  def reset
    @klass.reset
  end

end