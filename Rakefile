require 'rubygems'
require 'rubygems/package_task'

require 'rake'
require 'rake/clean'

require 'rdoc/task'

require 'rspec/core/rake_task'

require File.dirname(__FILE__) + '/lib/annotation_security/version'

module RakeFileUtils
  extend Rake::FileUtilsExt
end

spec = Gem::Specification.new do |s|
  s.name = 'annotation_security'
  s.version = AnnotationSecurity::Version
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.md', 'LICENSE', 'CHANGELOG.md', 'HOW-TO.md']
  s.summary = 'A role based security model for rails applications with ' +
              'descriptive definitions and automated evaluation.'
  s.description =
    'AnnotationSecurity provides a role based security model with automated ' +
    'rule evaluation for Ruby on Rails. It allows you to define user-resource-'+
    'relations and rights in separate files, keeping your controllers and ' +
    'views free from any security logic. See the gem\'s homepage for an ' +
    'example.'
  s.author = 'Nico Rehwaldt, Arian Treffer'
  s.email = 'ruby@nixis.de'
  s.homepage = 'http://github.com/Nikku/annotation_security'
  s.add_dependency 'action_annotation', '>= 1.0.1'
  s.add_dependency 'activesupport', '>= 2.3.18'
  s.add_development_dependency 'rspec', '>= 1.3.2'
  s.add_development_dependency 'mocha', '>= 0.9.8'
  s.executables = ['annotation_security']
  s.files = %w(CHANGELOG.md LICENSE README.md HOW-TO.md Rakefile) + Dir.glob("{bin,lib,spec,assets}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end

desc "Create rdoc documentation"
Rake::RDocTask.new do |rdoc|
  files = ['README.md', 'LICENSE', 'CHANGELOG.md', 'HOW-TO.md', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.md" # page to start on
  rdoc.title = "Annotation Security Docs"
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

desc "Run rspec tests"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/**/*_spec.rb'
end

desc "Package library as gem"
Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end