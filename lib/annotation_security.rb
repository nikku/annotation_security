#
# = lib/annotation_security.rb
#
# This modul provides a 
#
module AnnotationSecurity

  # Load the file specified by +fname+.
  # The file will be reloaded automatically if reset is called.
  #
  # See AnnotationSecurity::RightLoader for details.
  #
  def self.load_rights(fname, ext = 'yml')
    # The file is expected to be a yaml file.
    # However, it is also possible to use a ruby file that uses
    # AnnotationSecurity.define_rights. In this case, ext should be 'rb'.
    PolicyManager.add_file(fname, ext)
  end

  # Load the file specified by +fname+.
  # The file will be reloaded automatically if reset is called.
  #
  # See AnnotationSecurity::RelationLoader for details.
  #
  def self.load_relations(fname)
    PolicyManager.add_file(fname, 'rb')
  end

  # Defines relations specified in +block+.
  # 
  # See AnnotationSecurity::RelationLoader for details
  #
  def self.define_relations(*resources,&block)
    RelationLoader.define_relations(*resources,&block)
  end

  # Defines rights specified in +hash+.
  #
  # See AnnotationSecurity::RightLoader for details
  #
  def self.define_rights(hash)
    RightLoader.define_rights(hash)
  end

  # Reloads all files that were loaded with load_rights or load_relations.
  #
  # In development mode, reset is being executed before each request.
  #
  def self.reset
    PolicyManager.reset
  end
end

%w{
  manager/policy_manager
  manager/policy_factory
  manager/relation_loader
  manager/right_loader
  manager/resource_manager
  policy/abstract_policy
  policy/abstract_static_policy
  policy/rule_set
  policy/rule
  includes/resource
  includes/action_controller
  includes/active_record
  includes/role
  includes/user
  includes/helper
  exceptions
  filter
  model_observer
  user_wrapper
  utils
}.each {|f| require "annotation_security/" + f}

# Policy files are situated under RAILS_ROOT/config/security
AnnotationSecurity.load_relations(File.dirname(__FILE__) + '/annotation_security/policy/all_resources_policy')