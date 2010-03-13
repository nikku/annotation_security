#
# = lib/annotation_security/manager/relation_loader.rb
#

# Class responsible for loading the relation definitions for resources.
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
#  owner { |user,picture| picture.user == user }
#  super_owner(:is => :super_user) "if owner"
# 
#  super_user(:system, :is => :super_user)
#
# ==== The :as option
# 
# For a relation to which the <tt>:as => symbol</tt> option is passed as a
# parameter the current user is replaced by the invocation of
# <tt>current_credential.as_[symbol]</tt>. The method invocation may return +nil+
# indicating that the transformation failed. In this case the relation for
# which <tt>:as => ..</tt> was specified does not exist.
# 
# ==== :require_credential
# By default, a relation requires a user to be executed. Therefore, rights will
# always fail if the user is nil. To enable rights like 'unless logged_in', the
# :require_credential option can be set to false.
#  logged_in(:system, :require_credential => false) { |user| not user.nil? }
#
# === Evaluation time
# While most relations are between the user and a resource object, some are
# beween the user and an entire class of objects. This means that no instance of
# a resource is required to tell whether the user has that relation or not.
#
# ==== The :resource flag
# This flag is set by default. It is set for relations that need a resource.
# 
#  owner { |user,picture| picture.user == user }
#  # is short for
#  # owner(:resource) { |user,picture| picture.user == user }
#
# ==== The :system flag
# You can use the :system flag to denote that a relation does not
# require a resource object.
#
#  all_resources do
#    super_user(:system, :is => :super_user)
#  end
#
# It is possible to define system relations only for certain resources, and they
# do not conflict with resource relations.
#
#  resource :present do
#    receiver(:system) { |user| user.was_good? }
#    receiver { |user,present| present.receiver == user }
#  end
#
# The advantage of system relations is that they improve the rights evaluation.
# Consider the right
#  present:
#    receive: if receiver
#
# If an action is invoked requiring the receive-present right,
# AnnotationSecurity will evaluate the system relation before even entering the
# action, thus improving the fail fast behavior and avoiding unnecessary
# operations.
#
# Once a present object is observed during the action, the resource relation
# will be evaluated as well.
#
# ==== The :pretest flag
#
# Using the :pretest flag, it is possible to define both resource and system
# relations in one block.
#
#  resource :present do
#    receiver(:pretest) do |user, present|
#      if present
#        present.receiver == user
#      else
#        user.was_good?
#      end
#    end
#  end
#
# This can be helpfull if your relation depends on other relations, where a
# resource and a system version is available.
#
#  all_resources do
#    responsible(:pretest) { lecturer or corrector }
#    lecturer(:system, :as => :lecturer)
#    corrector(:system, :as => :corrector)
#  end
#
#  resource :course do
#    lecturer(:as => :lecturer) { |lecturer, course| course.lecturers.include? lecturer }
#    corrector(:as => :corrector) { |corrector, course| course.correctors.include? corrector }
#  end
#  # For other resources, lecturer and corrector are defined differently
#
# === Defining relations as strings
#
# Instead of a block, a string can be used to define the relation.
#  responsible :pretest, "if lecturer or corrector"
#
# The string syntax provides more simplifications, like referring to relations
# of other resources.
#
# This example will evaluate the course-correction relation for the course
# property of an assignment resource.
#  resource :assignment do
#    corrector "if course.corrector: course"
#  end
#
# As the course class includes AnnotationSecurity::Resource, the resource type
# is not explicitly needed.
#  resource :assignment_result do
#    corrector "if corrector: assignment.course"
#  end
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