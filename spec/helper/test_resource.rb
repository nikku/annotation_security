class TestResource

  include AnnotationSecurity::Resource

  self.resource_type = :test_resource

  def self.find(arg)
    obj = new arg

    # normally, this is done by a model observer
    SecurityContext.observe obj

    obj
  end

  def self.get_resource(arg)
    return nil if arg.nil?
    return arg if arg.is_a? self
    new arg
  end

  def initialize(name = "")
    @name = name
  end

  def name
    @name
  end

  def ==(other)
    return false unless other.is_a? self.class
    name == other.name
  end

  def to_s
    "<TestResource:#{name}>"
  end

end