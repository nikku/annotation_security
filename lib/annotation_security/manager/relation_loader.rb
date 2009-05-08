#
# = lib/annotation_security/manager/relation_loader.rb
#
# Contains the relation loader class, which is responsible for loading
# the relation definitions for resources.
#
# == Defining a relation for a resource
#
# This example defines the owner relation between a picture and a user.
# A relation definition is a proc that returns true if the relation exists.
# All three examples are equivalent. However, in most cases the first way is
# the way you want to use.
#  AnnotationSecurity.define_relations do
#    resource :picture do
#      owner { |user,picture| picture.user == user }
#    end
#  end
#
# If you need only one relation for a resource class, use this example:
#  AnnotationSecurity.define_relations do
#    picture.owner { |user,picture| picture.user == user }
#  end
#
# If the entire file contains definitions for only one resource class,
# you might try this:
#  AnnotationSecurity.define_relations :picture do
#    owner { |user,picture| picture.user == user }
#  end
#
# === Defining a relation for many resources
#
# Use +resources+ to define a relation once for more than one resource class.
#  AnnotationSecurity.define_relations do
#    resources(:picture, :comment) do
#      owner { |user,res| res.user == user }
#    end
#  end
# As for one resource, you can also use
#  AnnotationSecurity.define_relations do
#    resources(:picture, :comment).owner { |user,res| res.user == user }
#  end
# or
#  AnnotationSecurity.define_relations(:picture, :comment) do
#    owner { |user,res| res.user == user }
#  end
# 
# It is also possible to define relations for all resources:
#  AnnotationSecurity.define_relations do
#    all_resources do
#      related { owner or friend_of_owner }
#    end
#  end
# or
#  AnnotationSecurity.define_relations do
#    all_resources.related { owner or friend_of_owner }
#  end
#
# Notice that +owner+ and +friend_of_owner+ are relations that can be defined
# individually for each resource. The 2 parameters +user+ and +resource_object+
# dont need to be specified if they are not used.
#
# == Details on defining a relation
#
# As you have seen, the default way to define a relation is using a proc,
# like
#  owner { |user,picture| picture.user == user }
#  related { owner or friend_of_owner }
#
# If the condition is simple and uses only other relations,
# it also can be specified by a string:
#  related 'if owner or friend_of_owner'
#
# === Implicit conditions
# Besides a string or a proc, a rule definition can contain a list of flags
# and an options-hash.
#
# ==== The :is option
#
# A Relation to which the <tt>:is => symbol</tt> option is passed as a parameter
# only exists if the relation exists and <tt>is_symbol?</tt> invoked on the
# current user evaluates to true.
#
# Let the user class have a method <tt>is_super_user?</tt>, which returns true
# or false, depending on wheter the user is a super user. This method can be
# used for defining a relation +super_owner+, that is true if the user is the
# owner and a super user.
# 
#  super_owner(:is => :super_user) { |user,picture| picture.user == user }
#  super_owner(:is => :super_user) "if owner"
# 
#  super_user(:system, :is => :super_user)
#
# ==== The :as option
# 
# For a relation to which the <tt>:as => symbol</tt> option is passed as a
# parameter the current user is replaced by the invocation of
# <tt>current_user.as_symbol</tt>. The method invocation may return +nil+
# indicating that the transformation failed. In this case the relation for
# which <tt>:as => ..</tt> was specified does not exist.
# 
# ==== :require_user
# By default, a relation requires a user to be executed. Therefore, rights will
# always fail if the user is nil. To enable rights like 'unless logged_in', the
# :require_user option can be set to false.
#  logged_in(:system, :require_user => false) { |user| not user.nil? }
#
#
class AnnotationSecurity::RelationLoader

  # Load relations of the +block+
  # * +resources+ (optional) list of resources
  # * +block+ block with relation definitions
  def self.define_relations(*resources, &block)
    if resources.blank?
      class_eval(&block)
    else
      resources(*resources,&block)
    end
  end

  #
  def self.method_missing(symbol,*args,&block) #:nodoc:
    return super unless args.empty?
    resources(symbol,&block)
  end

  # Defines relations for a resource
  # * +block+ (optional) proc with relation definitions
  def self.resource(resource,&block)
    resources(resource,&block)
  end

  # Defines relations for a list of resources
  # * +block+ (optional) proc with relation definitions
  def self.resources(*resources,&block)
    new(resources,&block)
  end

  # Defines relations for all resources
  # * +block+ (optional) proc with relation definitions
  def self.all_resources(&block)
    resources(:all_resources,&block)
  end

  ## ===========================================================================
  ## Instance

  # An instance of RelationLoader is responsible for loading the relations
  # for a set of resources.
  def initialize(resources,&block) #:nodoc:
    @factories = get_factories_for(resources)
    instance_eval(&block) if block
  end

  # if a method is missing this will be a new relation for the resource class
  def method_missing(symbol,*args,&block) #:nodoc:
    define_relation(symbol,*args,&block)
  end

  # Defines a new relation for the current resources. However, instead of using
  #  define_relation(:relation_name,args) { |user,res| some_condition }
  # it is recommended to use
  #  relation_name(args) { |user,res| some_condition }
  #
  # ==== Parameters
  # * +symbol+ name of the relation
  # * +args+ additonal arguments, see AnnotationSecurity::Rule for details
  # * +block+ (optional) The condition can be passed either as string or as proc
  #
  def define_relation(symbol,*args,&block)
    @factories.each do |factory|
      factory.add_rule(symbol,*args,&block)
    end
  end

  private

  def get_factories_for(resources)
    resources.collect{ |res| AnnotationSecurity::PolicyManager.policy_factory(res) }
  end

end