require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AnnotationSecurity::RuleSet do

  before(:all) do
    AnnotationSecurity.define_relations(:rule_set_test,:rule_set_test2) do
      sys_relation :system, "true"
      res_relation :resource, "true"
      pre_relation :pretest, "true"
    end
    # This rule set is not to be modified during the tests!
    @rule_set2 = RuleSetTest2Policy.rule_set
  end

  before(:each) do
    # Use a fresh rule set for each test.
    # This will break some functions of RuleSet,
    # in these cases @rule_set2 is used for testing.
    @rule_set = AnnotationSecurity::RuleSet.new(RuleSetTestPolicy)
  end

  it 'should have a self explaining name' do
    @rule_set.to_s.should eql('<RuleSet of RuleSetTestPolicy>')
  end

  it 'should manage static relations' do
    rule = @rule_set.add_rule(:sys_relation, :system) { true }
    rule.should be_instance_of(AnnotationSecurity::Rule)
    @rule_set.get_rule(:sys_relation, true).should eql(rule)
    @rule_set.get_rule(:sys_relation, false).should be_nil
  end

  it 'should manage dynamic relations' do
    rule = @rule_set.add_rule(:res_relation, :resource) { true }
    rule.should be_instance_of(AnnotationSecurity::Rule)
    @rule_set.get_rule(:res_relation, false).should eql(rule)
    @rule_set.get_rule(:res_relation, true).should be_nil
  end

  it 'should manage pretest relations' do
    rule = @rule_set.add_rule(:pre_relation, :pretest) { true }
    rule.should be_instance_of(AnnotationSecurity::Rule)
    @rule_set.get_rule(:pre_relation, true).should eql(rule)
    @rule_set.get_rule(:pre_relation, false).should eql(rule)
  end

  it 'should manage dynamic rights' do
    rule = @rule_set.add_rule(:res_right, :right, "if res_relation")
    rule.should be_instance_of(AnnotationSecurity::Rule)
    @rule_set.get_rule(:res_right,false).should eql(rule)
    @rule_set.get_rule(:res_right,true).should be_nil
  end

  it 'should manage static rights' do
    rule = @rule_set.add_rule(:sys_right, :right, "if sys_relation")
    rule.should be_instance_of(AnnotationSecurity::Rule)
    @rule_set.get_rule(:sys_right,true).should eql(rule)
    @rule_set.get_rule(:sys_right,false).should be_nil
  end

  it 'should manage pretest rights' do
    rule = @rule_set.add_rule(:pre_right, :right, "if pre_relation")
    rule.should be_instance_of(AnnotationSecurity::Rule)
    @rule_set.get_rule(:pre_right,true).should eql(rule)
    @rule_set.get_rule(:pre_right,false).should eql(rule)
  end

  it 'should be able to copy dynamic rules from other rule sets' do
    rule = @rule_set.copy_rule_from(:res_relation, @rule_set2, false)
    rule.should be_instance_of(AnnotationSecurity::Rule)
    @rule_set.get_rule(:res_relation, false).should eql(rule)
    @rule_set2.get_rule(:res_relation, false).should_not eql(rule)
  end

  it 'should not create dynamic copies of static rules from other rule sets' do
    rule = @rule_set.copy_rule_from(:sys_relation, @rule_set2, false)
    rule.should be_nil
  end

  it 'should be able to copy static rules from other rule sets' do
    rule = @rule_set.copy_rule_from(:sys_relation, @rule_set2, true)
    rule.should be_instance_of(AnnotationSecurity::Rule)
    @rule_set.get_rule(:sys_relation, true).should eql(rule)
    @rule_set2.get_rule(:sys_relation, true).should_not eql(rule)
  end

  it 'should not create static copies of dynamic rules from other rule sets' do
    rule = @rule_set.copy_rule_from(:res_relation, @rule_set2, true)
    rule.should be_nil
  end

  it 'should not allow rules with forbidden names' do
    lambda {
      @rule_set.add_rule(:get_rule) {  }
    }.should raise_error(AnnotationSecurity::RuleError)
  end

  it 'should not allow rules to be defined twice' do
    @rule_set.add_rule(:test_rule) {  }
    lambda {
      @rule_set.add_rule(:test_rule) {  }
    }.should raise_error(AnnotationSecurity::RuleError)
  end

  it 'should allow rules to be defined both statically and dynamically' do
    r1 = @rule_set.add_rule(:test_rule, :system) {  }
    r2 = @rule_set.add_rule(:test_rule, :resource) {  }
    @rule_set.get_rule(:test_rule,true).should eql(r1)
    @rule_set.get_rule(:test_rule,false).should eql(r2)
  end

end
