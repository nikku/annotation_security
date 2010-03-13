#
# = lib/annotation_security/manager/right_loader.rb
#

# = AnnotationSecurity::RightLoader
# Contains the right loader class, which is responsible for loading
# right definitions for resources. Load rights from a yaml file or a hash.
#
# == Example YAML
#
# The file <tt>config/security/rights.yml</tt> inside a rails app
# might look like this:
#  picture:
#    # a user may show a picture if he fulfils the 'related'-relation
#    show: if related
#  comment:
#    # you have to be logged in to view comments
#    show: if logged_in
#  user:
#    # like in ruby, 'unless' is equivalent to 'if not'
#    register: unless logged_in
#    delete: if administrator # comments are also possible behind a line
#  user_content:
#    # all rights of 'user_content' are defined for 'picture' and 'comment' too
#    applies_to: picture, comment
#    create: if logged_in
#    edit: if owner
#    delete: if owner or administrator
# The file can be loaded via <code>AnnotationSecurity#load_rights('rights')</code>.
#
# A right's condition can use the keywords +if+, +unless+, +and+, +or+ and
# +not+, brackets, other rights and all of the resource's relations
# (see AnnotationSecurity::RelationLoader). For better readability you may
# add the prefixes +may+, +is+, +can+ or +has+,
# or append one of the suffixes +for+, +in+, +of+ or +to+.
#
#  user_content:
#    edit: if is_owner_of
#    delete: if may_edit or is_administrator
#
# However, it is recommended to use this feature sparingly.
#
class AnnotationSecurity::RightLoader

  # Goes through all resources of +hash+ and load the defined rights.
  #
  def self.define_rights(hash) # :nodoc:
    if hash
      hash.each_pair do |resource_class, rights|
        new(resource_class).define_rights(rights)
      end
    end
  end

  # An instance of RightLoader is responsible for loading the rights of a
  # resource class.
  #
  def initialize(resource) # :nodoc:
    @factory = AnnotationSecurity::PolicyManager.policy_factory(resource)
  end

  # Goes through all rights in +hash+ and creates rules for all policies these
  # rights apply to.
  #
  def define_rights(hash) # :nodoc:
    factories = extract_applies_to(hash) << @factory
    hash.each_pair do |right,condition|
      # Important: set the :right-flag to activate automatic detection of
      # the other flags (static,dynamic,require_user)
      factories.each { |f| f.add_rule(right,:right,condition) }
    end
  end

  private

  # Looks for the key 'applies_to', which is no right but a command to apply
  # all rights of the current resource class to the resource classes listed
  # in the value.
  #
  def extract_applies_to(hash)
    applies_to = hash.delete('applies_to') || hash.delete(:applies_to)
    return [] if applies_to.blank?
    applies_to = [applies_to] if applies_to.is_a? String
    applies_to.collect{ |r| r.split(',') }.flatten.
               collect{ |r| AnnotationSecurity::PolicyManager.policy_factory(r.strip) }
  end

end