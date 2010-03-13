require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AnnotationSecurity::AbstractPolicy do
  # For more tests see test_policy_spec.rb

  it 'should create a subclass for a resource type' do
    klass = AnnotationSecurity::AbstractPolicy.new_subclass(:abs_policy_test)
    (defined? AbsPolicyTestPolicy).should_not be_nil
    klass.should eql(AbsPolicyTestPolicy)
    klass.static?.should be_false

    (defined? AbsPolicyTestStaticPolicy).should_not be_nil
    klass.static_policy_class.should eql(AbsPolicyTestStaticPolicy)
    klass.static_policy_class.static?.should be_true
  end

end