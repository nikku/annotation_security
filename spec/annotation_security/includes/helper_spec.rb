require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AnnotationSecurity::Helper do
  
  before(:each) do
    SecurityContext.initialize(TestController.new)
    SecurityContext.credential = TestUser.new 'theuser'
    @helper = TestHelper.new
    @res = TestResource.new 'theuser'
  end

  it "should understand options hash" do
    options = { :action => :edit, :controller => :test, :id => @res }
    expect(:test, :edit, [], {:id => @res})
    @helper.action_allowed?(options).should be_true
  end

  it "should understand path strings" do
    path = 'test/theuser/edit'
    with_path_info path
    expect :test, :edit, [], {:id => 'theuser'}
    @helper.action_allowed?(path).should be_true
  end

  it "should understand resource objects" do
    with_path_info 'test/theuser', :get, {:action => :show}
    expect :test, :show, [], {:id => 'theuser'}
    @helper.expects(:url_for).with(@res).returns('test/theuser')
    @helper.action_allowed?(@res).should be_true
  end

  it "should take html options into account" do
    with_path_info 'test/theuser', :delete, {:action => :destroy}
    expect :test, :destroy, [], {:id => 'theuser'}
    @helper.expects(:url_for).with(@res).returns('test/theuser')
    @helper.action_allowed?(@res, { :method => :delete}).should be_true
  end

  it "should call named routes" do
    with_path_info 'test/theuser/edit'
    expect :test, :edit, [@res], {}
    @helper.expects(:edit_test_path).with(@res, {}).returns('test/theuser/edit')
    @helper.action_allowed?(:edit_test_path, @res).should be_true
  end

  it "should support defining all parameters explicitly" do
    expect :test, :edit, [@res], {:option => true}
    params = { :action => :edit, :controller => :test, :option => true }
    @helper.action_allowed?('path/to/something', @res, params).should be_true
  end

  it "should create links if allowed" do
    options = { :action => :edit, :controller => :test, :id => @res }
    expect(:test, :edit, [], {:id => @res})
    @helper.expects(:link_to_if).with(true, "Edit", options, {}).returns("<a>success</a>")
    @helper.link_to_if_allowed("Edit", options){'no access'}.should == "<a>success</a>"
  end

  it "should not create links if forbidden" do
    options = { :action => :edit, :controller => :test, :id => @res }
    expect(:test, :edit, [], {:id => @res}, false)
    @helper.expects(:link_to_if).with(false, "Edit", options, {}).returns("no access")
    @helper.link_to_if_allowed("Edit", options){"no access"}.should == "no access"
  end

  def expect(ctrl, action, obj, param, result=true)
    SecurityContext.expects(:allow_action?).with(ctrl, action, obj, param).returns(result)
  end

  # prepares #recognize_path to resolve the request path
  def with_path_info(path, env = nil, result={})
    env = { :method => env } if env.is_a? Symbol
    env ||= { :method => :get }
    parts = path.split('/')
    result[:controller] ||= parts.first.to_sym
    result[:id] ||= parts.second
    result[:action] ||= parts.third.to_sym
    ActionController::Routing::Routes.expects(:recognize_path).with(path, env).returns(result)
  end

end

