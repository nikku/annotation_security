#
# = lib/annotation_security/includes/user.rb
#
# This module should be included by the user domain class to
# enable full support of all features.
#
module AnnotationSecurity::User

  # Returns true if this is the user given as parameter
  #
  # Required to have a common interface with AnnotationSecurity::Role.
  #
  def is_user?(user)
    self == user
  end

  # If +obj+ is a UserWrapper, extract the user before comparing
  #
  def ==(obj)
    obj = obj.__user__ if obj.is_a? AnnotationSecurity::UserWrapper
    super(obj)
  end

end