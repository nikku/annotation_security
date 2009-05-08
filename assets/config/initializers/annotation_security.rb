#
# = config/initializers/annotation_security.rb
#
# Sets up files under <code>config/security</code> which hold
# the security configuration.
#
# Add your own files here if they should also be loaded.
#

AnnotationSecurity.load_relations('relations')
AnnotationSecurity.load_rights('rights')