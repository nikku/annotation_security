require 'fileutils'

plugin_assets_root = File.dirname(__FILE__) + "/../assets"
rails_root = "#{RAILS_ROOT}"
config_root = File.join(rails_root, "config")

files = %w{
  config/initializers/annotation_security.rb
  config/security/relations.rb
  config/security/rights.yml
  app/helpers/annotation_security_helper.rb
}

namespace :as do
	desc "Install files for annotation_security plugin in web-app"
	task :install_config => :environment do    
    FileUtils.mkdir_p "#{config_root}/security"
    
    files.each do |f|
      FileUtils.install "#{plugin_assets_root}/#{f}", "#{rails_root}/#{f}"
    end
    
    puts "Done."
	end
end