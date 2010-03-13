class TestController < ActionController::Base

  describe :show, 'shows a test_resource'
  describe :edit, 'edit some test_resources'
  describe :show_edit, 'shows a test_resource', 'edits a test_resource'
  describe :edit_with_render, 'edits the test_resource in @resource'
  describe :delete, 'delete test_resource by :id'
  describe :list, 'list all test_resources in @list'


  def test_init(action, params)
    @action = action
    @params = params
  end

  def action_name
    @action
  end

  def params
    @params
  end

  def show
    @resource = TestResource.find params[:id]
  end

  def edit
    @resource = TestResource.find params[:id]
  end

  def show_edit
    @resource = TestResource.find params[:id]
  end

  def edit_with_render
    @resource = TestResource.find params[:id1]
    render 'view'
    @resource = TestResource.find params[:id2]
  end

  def delete
    self.class.enter_delete
    @resource = TestResource.find params[:id]
  end

  def list
    r1 = TestResource.find params[:id1]
    r2 = TestResource.find params[:id2]
    @list = [r1, r2]
  end

  def render(*args)
    super(*args)
    self.class.exit_render
  end

  # callbacks used for mocking
  
  def self.enter_delete
  end

  def self.exit_render
  end

end