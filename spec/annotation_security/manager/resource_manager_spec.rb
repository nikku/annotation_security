require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AnnotationSecurity::ResourceManager do

  it "should provide resource classes" do
    klass = AnnotationSecurity::ResourceManager.get_resource_class :test_resource
    klass.should == TestResource
  end

  it "should find resource instances" do
    res = AnnotationSecurity::ResourceManager.get_resource :test_resource, 'xy'
    res.should be_instance_of(TestResource)
    res.name.should == 'xy'
  end

end

