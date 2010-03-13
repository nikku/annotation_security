class TestRole

  include AnnotationSecurity::Role

  def initialize(name,user)
    @name = name
    @user = user
  end

  def role_name
    @name
  end

  def name
    role_name
  end

  def user
    @user
  end

end