class TestUser

  include AnnotationSecurity::User

  def initialize(name='user_name')
    @name = name
    @one_role = TestRole.new(:one,self)
    @many_roles = [
        TestRole.new(:a,self), TestRole.new(:b,self), TestRole.new(:c,self)]
  end

  def user_name
    @name
  end

  def name
    user_name
  end

  def as_one_role
    @one_role
  end

  def as_many_roles
    @many_roles
  end

  def to_s
    "<TestUser:#{name}>"
  end

end