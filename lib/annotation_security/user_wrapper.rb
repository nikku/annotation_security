#
# = lib/annotation_security/user_wrapper.rb
#

# = AnnotationSecurity::UserWrapper
#
# This class is not in use!
#
# Needed for evaluating relations, especially if the :as-option is used.
# 
# Merges a user and a role. If a role is given,
#
class AnnotationSecurity::UserWrapper # :nodoc:

  # Return user wrappers for the requested role. The role(s) will be
  # determined with sending user.as_'role'.
  # (Normally a user has a role only once, however it will work when he
  # has many roles of the same kind as well)
  def self.all_for_role(user,role_name)
    return [] if user.nil?
    user = user.__user__ if user.is_a? AnnotationSecurity::UserWrapper
    return [new(user)] if role_name.nil?
    roles = user.__send__("as_#{role_name}")
    return [] if roles.blank?
    roles = [roles] unless roles.is_a?(Array)
    roles.compact.collect { |role| new(user,role) }
  end

  def initialize(user,role=nil)
    @user = user
    @role = role
  end

  def id
    @role? @role.id : @user.id
  end

  def __user__
    @user
  end

  def __role__
    @role
  end

  def ==(obj)
    @user == obj or (!@role.nil? and @role == obj)
  end

  # Try to send to role, user and policy of args[0]
  #
  def method_missing(symbol,*args,&block)
    if @role && (@role.respond_to? symbol)
      @role.__send__(symbol,*args,&block)
    elsif @user.respond_to? symbol
      @user.__send__(symbol,*args,&block)
    elsif args.first.respond_to? :policy_for
      args.first.policy_for(@user).__send__(symbol,*args[1..-1])
    else
      # This will raise a NoMethodError
      @user.__send__(symbol,*args,&block)
    end
  end

  def is_a?(klass)
    return true if super(klass)
    if @role
      @role.is_a?(klass)
    else
      @user.is_a?(klass)
    end
  end

end