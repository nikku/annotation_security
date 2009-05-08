require 'yaml'

#
# = lib/annotation_security/manager/policy_manager.rb
#
# Manages the policies for all resource classes.
#
class AnnotationSecurity::PolicyManager # :nodoc:

  # Get the policy factory for a resource class
  def self.policy_factory(resource_type) # :nodoc:
    policy_factories[resource_type.to_sym]
  end

  # Creates a policy object for a user and a resource type
  #
  # ==== Example
  #
  #  picture = Picture.find_by_id(params[:picture])
  #  policy = PolicyManager.get_policy(:picture,@current_user)
  #  policy.allowed? :show, picture # => true or false
  #
  def self.create_policy(resource_type,*args)
    policy_factory(resource_type).create_policy(*args)
  end

  def self.policy_class(resource_class) # :nodoc:
    policy_factory(resource_class).policy_class
  end

  def self.config_files # :nodoc:
    @files ||= []
  end

  # Adds a file that contains security configurations
  # * +f+ file name
  # * +ext+ 'yml' or 'rb'
  def self.add_file(f,ext) # :nodoc:
    unless config_files.include? [f,ext]
      config_files.push [f,ext]
      load_file(f,ext)
    end
  end

  def self.reset
    policy_factories.each_value(&:reset)
    config_files.each { |f,ext| load_file(f,ext) }
  end

  private

  def self.load_file(f,ext)
    fname = get_file_name(f,ext)
    case ext
    when 'yml'
      AnnotationSecurity::RightLoader.define_rights(YAML.load_file(fname))
    when 'rb'
      load fname
    end
  end

  SEARCH_PATH = ['', RAILS_ROOT, RAILS_ROOT + '/config/security/',
                 RAILS_ROOT + '/config/', RAILS_ROOT + '/security/']

  def self.get_file_name(f,ext)
    SEARCH_PATH.each do |fname1|
      [f, f+'.'+ext].each do |fname2|
        return (fname1 + fname2) if File.exist?(fname1 + fname2)
      end
    end
    raise "File not found: '#{f+'.'+ext}'"
  end

  def self.policy_factories
    # Create a new factory if it is needed
    @factories ||= Hash.new { |h,k| h[k] = AnnotationSecurity::PolicyFactory.new(k) }
  end
end