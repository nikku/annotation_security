require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AllResourcesPolicy do

  it 'should provide :__self__ relation' do
    user = TestUser.new
    user2 = TestUser.new
    policy = AllResourcesPolicy.new(user)
    policy.with_resource(user).__self__?.should be_true
    policy.with_resource(user.as_one_role).__self__?.should be_true
    policy.with_resource(user2).__self__?.should be_false
  end

  it 'should provide :logged_in relation' do
    AllResourcesPolicy.new(TestUser.new).logged_in?.should be_true
    AllResourcesPolicy.new(nil).logged_in?.should be_false

    AllResourcesPolicy.has_static_rule?(:logged_in).should be_true
    AllResourcesPolicy.has_dynamic_rule?(:logged_in).should be_false
    rule = AllResourcesPolicy.rule_set.get_static_rule(:logged_in)
    rule.requires_credential?.should be_false
  end

end
