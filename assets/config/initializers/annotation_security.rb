#
# = config/initializers/annotation_security.rb
#
# Sets up files under <tt>config/security</tt> which hold
# the security configuration.

#
# Add your own files here if they should also be loaded.
#
AnnotationSecurity.load_relations('relations')
AnnotationSecurity.load_rights('rights')
# AnnotationSecurity.load_rights('rights', 'rb) # loads rights from a ruby file