
# Make sure this file is only loaded once.
if Object.const_defined? 'AnnotationSecuritySpecHelper'
  # If this happens, some requires or settings are wrong
  raise 'Reloading AnnotationSecurity Spec Helper'
end
puts 'Initializing AnnotationSecurity Spec'
AnnotationSecuritySpecHelper = true


dir = File.dirname(__FILE__)

require 'spec'
require 'mocha'
require 'rails_stub'
require 'action_annotation'
require dir + '/../lib/annotation_security'

module AnnotationSecurity
  # some modifications on the initializer
  def self.init_rails(dir)
    %w{extensions/object extensions/action_controller extensions/active_record
       extensions/filter }.each { |f| require dir + f }
    AnnotationSecurity.load_relations(dir +
      'annotation_security/policy/all_resources_policy')
  end
end


require dir + '/helper/test_user'
require dir + '/helper/test_role'
require dir + '/helper/test_resource'
require dir + '/helper/test_controller'
require dir + '/helper/test_helper'

AnnotationSecurity.load_relations(dir + '/helper/test_relations')
AnnotationSecurity.load_rights(dir + '/helper/test_rights')

AnnotationSecurity.init_rails(dir + '/../lib/')

Spec::Runner.configure do |config|
  config.mock_with :mocha
end