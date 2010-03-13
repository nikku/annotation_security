require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SecurityContext do

  before(:each) do
    @user1 = TestUser.new 'theuser'
    @user2 = TestUser.new 'otheruser'
  end

  it "should check 'logged_in' for 'show'" do
    request(@user1, :show, { :id => 'theuser' }).should succeed
    request(@user2, :show, { :id => 'theuser' }).should succeed
    request(nil, :show, { :id => 'theuser' }).should fail
  end

  it "should check 'owner' for 'edit'" do
    request(@user1, :edit, { :id => 'theuser' }).should succeed
    request(@user2, :edit, { :id => 'theuser' }).should fail
  end

  it "should check 'logged_in' and 'owner' for 'show_edit'" do
    request(@user1, :show_edit, { :id => 'theuser' }).should succeed
    request(@user2, :show_edit, { :id => 'theuser' }).should fail
  end

  it "should check 'owner' for 'delete' based on :id" do
    request(@user1, :delete, { :id => 'theuser' }).should succeed
    request(@user2, :delete, { :id => 'theuser' }).should fail
  end

  it "should not call action if check based on :id fails" do
    TestController.expects(:enter_delete).never
    request(@user2, :delete, { :id => 'theuser' }).should fail
  end

  it "should check 'owner' for 'list' based on @list" do
    request(@user1, :list, { :id1 => 'theuser', :id2 => 'theuser' }).should succeed
    request(@user1, :list, { :id1 => 'theuser', :id2 => 'otheruser' }).should fail
    request(@user1, :list, { :id1 => 'otheruser', :id2 => 'theuser' }).should fail
  end

  it "should not be disturbed by calls to #render" do
    TestController.expects(:exit_render).twice
    request(@user1, :edit_with_render,
            { :id1 => 'theuser', :id2 => 'theuser' }).should succeed
    request(@user1, :edit_with_render,
            { :id1 => 'theuser', :id2 => 'otheruser' }).should fail
  end

  it "should check rules before #render" do
    TestController.expects(:exit_render).never
    request(@user1, :edit_with_render,
            { :id1 => 'otheruser', :id2 => 'theuser' }).should fail
  end

  # simulates an action invokation in rails
  def request(user, action, params)
    controller = TestController.new
    controller.test_init(action, params)
    SecurityContext.initialize(controller)
    SecurityContext.credential = user
    rules = controller.class.descriptions_of(action)
    SecurityContext.current.send_with_security(rules, controller, action)
    'no_error'
  rescue SecurityViolationError => sve
    sve
  end

  def succeed
    eql 'no_error'
  end

  def fail
    be_instance_of SecurityViolationError
  end

end

