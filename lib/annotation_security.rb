#
# = lib/annotation_security.rb
#
# This modul provides the AnnotationSecurity security layer. 
#

# = AnnotationSecurity
module AnnotationSecurity; end

# Load annotation security files
dir = File.dirname(__FILE__)
require dir + '/annotation_security/manager/policy_manager'
require dir + '/annotation_security/manager/policy_factory'
require dir + '/annotation_security/manager/relation_loader'
require dir + '/annotation_security/manager/right_loader'
require dir + '/annotation_security/manager/resource_manager'
require dir + '/annotation_security/policy/abstract_policy'
require dir + '/annotation_security/policy/abstract_static_policy'
require dir + '/annotation_security/policy/rule_set'
require dir + '/annotation_security/policy/rule'
require dir + '/annotation_security/includes/resource'
require dir + '/annotation_security/includes/action_controller'
require dir + '/annotation_security/includes/active_record'
require dir + '/annotation_security/includes/role'
require dir + '/annotation_security/includes/user'
require dir + '/annotation_security/includes/helper'
require dir + '/annotation_security/exceptions'
require dir + '/annotation_security/filters'
require dir + '/annotation_security/model_observer'
require dir + '/annotation_security/user_wrapper'
require dir + '/annotation_security/utils'

require dir + '/security_context'

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

  # Initializes AnnotationSecurity for a Rails application and loads
  # Rails specific parts of the library.
  #
  # This method is called by `init.rb`,
  # which is run by Rails on startup.
  #
  # * +config+ [Rails::Configuration] the rails configuration.
  def self.init_rails(config)
    puts "Initializing AnnotationSecurity security layer"

    %w{annotation_security/rails extensions/object extensions/action_controller
       extensions/active_record extensions/filter }.each { |f| require f }
    
    AnnotationSecurity::Rails.init!(config)
  end
end