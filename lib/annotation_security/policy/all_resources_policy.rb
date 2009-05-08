#
# = lib/security/policy/all_resources_policy.rb
#
# The all_resources policy provides roles and rights that are available for all
# policies, unless they are overwritten.
#
AnnotationSecurity.define_relations :all_resources do

  # can be used as "self" in a right definition
  # success if the accessed resource is the user himself or one of his roles
  __self__ { |user, resource| resource.is_user?(user) }
  
  logged_in(:system, :require_user => false) {|u| not u.nil?}

end