require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AnnotationSecurity::PolicyManager do

  it "should provide policy factories" do
    AnnotationSecurity::PolicyManager.policy_factory(:policy_manager)
    (defined? PolicyManagerPolicy).should_not be_nil
  end

  it "should return the policy class for a resource" do
    AnnotationSecurity::PolicyManager.policy_class(:policy_manager_2).
      should == PolicyManager2Policy
  end
  
end
