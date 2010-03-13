#
# = lib/annotation_security/policy/all_resources_policy.rb
#
# By default, two relations are provided for all resources.
#
# The system relation +logged_in+ evaluates to true if the provided
# credentials are not nil.
#  logged_in(:system, :require_credential => false) {|u| not u.nil?}
#
# The relation +self+ is true when the accessed resource is the current user
# himself or a role that belongs to the current user.
#  __self__ { |user, resource| resource.is_user?(user) }
#
AnnotationSecurity.define_relations :all_resources do

  # can be used as "self" in a right definition
  # success if the accessed resource is the user himself or one of his roles
  __self__ { |user, resource| resource.is_user?(user) }
  
  logged_in(:system, :require_credential => false) {|u| not u.nil?}
end