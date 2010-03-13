AnnotationSecurity.define_relations(:test_resource) do

  owner do |user, res|
    user.name == res.name
  end

end