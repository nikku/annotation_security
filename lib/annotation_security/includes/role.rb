#
# = lib/annotation_security/includes/user.rb
#
# This module should be included by all role classes
# to enable full support of all features.
#
# A role class is a domain class that represent user roles
# and does not extend the user class. It should have the method #user that
# returns the user object it belongs to.
#
module AnnotationSecurity::Role

  # Returns true if this belongs to the user given as parameter
  #
  # Required to have a common interface with AnnotationSecurity::User.
  #
  def is_user?(user)
    self.user == user
  end

  # If +obj+ is a UserWrapper, extract the role before comparing
  #
  def ==(obj)
    obj = obj.__role__ if obj.is_a? AnnotationSecurity::UserWrapper
    super(obj)
  end

end