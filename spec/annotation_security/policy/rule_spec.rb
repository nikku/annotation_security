require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AnnotationSecurity::Rule do

  before(:all) do
    AnnotationSecurity.define_relations(:rule_test_res) do
      res_dummy
      sys_dummy(:system) { false }
      pre_dummy :pretest
      noc_dummy :system, :require_credential => false

      res_dummy_test { has_res_dummy }
      sys_dummy_test "if is_sys_dummy"
    end
  end

  it 'should create valid dynamic relations' do
    rule = AnnotationSecurity::Rule.new(:res_proc, RuleTestResPolicy) { |u,r| true }
    rule.to_s.should == '<RuleTestResPolicy#res_proc[--du]>'
    rule = AnnotationSecurity::Rule.new(:res, RuleTestResPolicy, :resource)
    rule.to_s.should == '<RuleTestResPolicy#res[--du]>'
  end

  it 'should create valid static relations' do
    rule = AnnotationSecurity::Rule.new(:sys_proc, RuleTestResPolicy, :system) { true }
    rule.to_s.should == '<RuleTestResPolicy#sys_proc[-s-u]>'
  end

  it 'should create valid pretest relations' do
    rule = AnnotationSecurity::Rule.new(:pre_proc, RuleTestResPolicy, :pretest) { true }
    rule.to_s.should == '<RuleTestResPolicy#pre_proc[-sdu]>'
  end

  it 'should create valid relations without user' do
    rule = AnnotationSecurity::Rule.new(:no_u, RuleTestResPolicy, :require_credential => false)
    rule.to_s.should == '<RuleTestResPolicy#no_u[--d-]>'
    rule = AnnotationSecurity::Rule.new(:no_u, RuleTestResPolicy,
                              :system, :require_credential => false)
    rule.to_s.should == '<RuleTestResPolicy#no_u[-s--]>'
    rule = AnnotationSecurity::Rule.new(:no_u, RuleTestResPolicy,
                              :pretest, :require_credential => false)
    rule.to_s.should == '<RuleTestResPolicy#no_u[-sd-]>'
  end

  it 'should create valid rights' do
    {
      'if res_dummy' => '-du',
      'if sys_dummy' => 's-u',
      'if pre_dummy' => 'sdu',
      'if res_dummy or sys_dummy' => '-du',
      'if res_dummy or pre_dummy' => '-du',
      'if sys_dummy or pre_dummy' => 'sdu',
      'if noc_dummy' => 's--',
      'if noc_dummy or sys_dummy' => 's-u',
      'if noc_dummy or res_dummy' => '-du',
      'if self' => '-du',
      'if other_right: resource_property' => '-du',
      'true' => 's--',
      'false or nil' => 's--'
    }.each_pair do |condition,flags|
      right = AnnotationSecurity::Rule.new(:right, RuleTestResPolicy, :right, condition)
      right.flag_s.should == 'r???'
      right.static? # trigger lazy initialization
      right.flag_s.should == 'r'+flags
    end
  end

  it 'should call referred rules when being executed' do
    policy = RuleTestResPolicy.new(:user,:res)
    
    policy.expects(:res_dummy).returns(true)
    policy.res_dummy_test.should be_true

    policy.expects(:sys_dummy).returns(false)
    policy.sys_dummy_test?.should be_false
  end

end