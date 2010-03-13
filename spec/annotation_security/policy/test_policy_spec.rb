require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

AnnotationSecurity.define_relations(:a_test) do
  sys_relation :system
  res_relation :resource
  pre_relation :pretest
end

describe ATestPolicy do

  it 'should be dynamic' do
    ATestPolicy.static?.should be_false
  end

  it 'should have a static partner' do
    ATestPolicy.static_policy_class.should eql(ATestStaticPolicy)
  end

  it 'should know its resource type' do
    ATestPolicy.resource_type.should eql(:a_test)
  end

  it 'should have all rules' do
    ATestPolicy.has_rule?(:sys_relation).should be_true
    ATestPolicy.has_rule?(:res_relation).should be_true
    ATestPolicy.has_rule?(:pre_relation).should be_true
  end

  it 'should be aware of the evaluation time of a rule' do
    ATestPolicy.has_dynamic_rule?(:sys_relation).should be_false
    ATestPolicy.has_dynamic_rule?(:res_relation).should be_true
    ATestPolicy.has_dynamic_rule?(:pre_relation).should be_true
    
    ATestPolicy.has_static_rule?(:sys_relation).should be_true
    ATestPolicy.has_static_rule?(:res_relation).should be_false
    ATestPolicy.has_static_rule?(:pre_relation).should be_true
  end

  it 'should have access to rules defined for all resources' do
    ATestPolicy.has_rule?(:__self__).should be_true
    ATestPolicy.has_rule?(:logged_in).should be_true
  end
#
#  it 'should be possible to add rules'
#
#  it 'should be possible to evaluate a list of rules (static/dynamic/both)'

end

describe ATestStaticPolicy do

  it 'should be static' do
    ATestStaticPolicy.static?.should be_true
  end

  it 'should not have a static partner' do
    lambda {
      ATestStaticPolicy.static_policy_class
    }.should raise_error(NameError)
  end

  it 'should know its resource type' do
    ATestStaticPolicy.resource_type.should eql(:a_test)
  end

  it 'should use the rule set of the dynamic policy' do
    ATestStaticPolicy.rule_set.should eql(ATestPolicy.rule_set)
  end

  it 'should have all static rules' do
    ATestStaticPolicy.has_rule?(:sys_relation).should be_true
    ATestStaticPolicy.has_rule?(:res_relation).should be_false
    ATestStaticPolicy.has_rule?(:pre_relation).should be_true
  end

  it 'should have access to static rules defined for all resources' do
    ATestStaticPolicy.has_rule?(:__self__).should be_false
    ATestStaticPolicy.has_rule?(:logged_in).should be_true
  end
  
end