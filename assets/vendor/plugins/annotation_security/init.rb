#
# = init.rb
#
# This file will be copied to a rails apps `vendors/plugins/annotation_security`
# directory if the annotation_security gem is installed into a rails app
# via `annosec --rails`. It will be invoked by the rails app during startup an
# loads the security layer.
#

require "annotation_security"

# Initialize security layer for rails root
puts "Initializing AnnotationSecurity security layer"
AnnotationSecurity::init_rails(binding)