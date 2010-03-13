require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AnnotationSecurity::RuleExecutionError do

  before(:all) do
    AnnotationSecurity.define_relations(:rule_ex_error_test) do
      broken_relation { 1/0 }
    end
  end

  it 'should be raised if a relation throws an error' do
    lambda {
      RuleExErrorTestPolicy.new(:user,:res).broken_relation?
    }.should raise_error(AnnotationSecurity::RuleExecutionError)
  end

end