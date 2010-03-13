# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

spec = Gem::Specification.new do |s|
  s.name = 'annotation_security'
  s.version = '1.0.1'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'MIT-LICENSE', 'CHANGELOG', 'HOW-TO']
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
  s.homepage = 'http://tech.lefedt.de/2010/3/annotation-based-security-for-rails'
  s.add_dependency 'action_annotation', '>= 1.0.1'
  s.add_dependency 'activesupport', '>= 2.3.5'
  s.add_development_dependency 'rspec', '>= 1.2.0'
  s.add_development_dependency 'mocha', '>= 0.9.8'
  s.executables = ['annotation_security']
  s.files = %w(CHANGELOG MIT-LICENSE README HOW-TO Rakefile) + Dir.glob("{bin,lib,spec,assets}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files = ['README', 'MIT-LICENSE', 'CHANGELOG', 'HOW-TO', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "Annotation Security Docs"
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end