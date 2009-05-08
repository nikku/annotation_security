# Needed to find resource objects when only their id is known
#
class AnnotationSecurity::ResourceManager # :nodoc:

  @classes = {}

  def self.add_resource_class(res_type,klass)
    @classes.delete_if { |k,v| v == klass }
    @classes[res_type] = klass
  end

  def self.get_resource_class(res_type)
    @classes[res_type]
  end

  unless RAILS_ENV == 'production'
    def self.get_resource_class(res_type)
      c = @classes[res_type]
      unless c
        res_type.to_s.camelize.constantize # load the class
        c = @classes[res_type]
      end
      c
    end
  end

  # Call get_resource of the class that is registered for +res_type+
  def self.get_resource(res_type,object)
    c = get_resource_class(res_type)
    c ? c.get_resource(object) : object
  end
end
