#
# = lib/annotation_security/includes/helper.rb
#

# = AnnotationSecurity::Helper
# 
# This module adds some useful helper methods to your templates.
#
module AnnotationSecurity::Helper

  # Returns true if the operation defined by +policy_args+ is allowed.
  #
  # The following calls to #allowed? are possible:
  #
  #   allowed? :show, :resource, @resource
  #   # => true if the current user has the right to show @resource,
  #   #    which belongs to the :resource resource-class
  #
  # In case of model objects or other classes which implement a #resource_type
  # method the the second argument may be ommited
  #
  #   allowed? :show, @resource
  #   # equivalent to the above call if @resource.resource_type == :resource
  #
  # A policy description used as a controller annotation may also be used 
  # to check a right
  #
  #   allowed? "show resource", @resource
  #   # => true if the current user has the right "show resource" for @resource
  #
  # A policy may also be applied without an object representing the context:
  #
  #   allowed? :show, :resource
  #   # => true if the current may show resources.
  #
  # This will only check system and pretest rules. The result +true+ does not
  # mean that the user may show all resources. However, a +false+ indicates
  # that the user is not allowed to show any resources.
  #
  # If the resource class is omitted as well, only rules defined for all
  # resources can be tested. See RelationLoader#all_resources for details.
  #
  #  allowed? :administrate
  #  # => true if the user is allowed to administrate all resources.
  #
  # See SecurityContext#allowed?.
  #
  def allowed?(*args)
    SecurityContext.allowed?(*args)
  end

  alias a? allowed?

  # Equivalent to allowed?; is? is provided for better readability.
  #
  #  allowed? :logged_in
  # vs
  #  is? :logged_in
  #
  def is?(*args)
    SecurityContext.is?(*args)
  end

  # Checks whether the user is allowed to access the action.
  #
  # Expects arguments like #link_to_if_allowed, just without name and block.
  #
  # Returns true if the action is allowed.
  #
  def action_allowed?(options, objects=nil, params=nil, html_options=nil)

    options, objects, params, html_options =
              parse_allow_action_args(options, objects, params, html_options)

    controller = params.delete :controller
    action = params.delete :action
    SecurityContext.allow_action?(controller, action, objects, params)
  end

  # Returns a link tag with the specified name to the specified resource if
  # the user is allowed to access it. See #link_to_unless and
  # SecurityContext#action_allowed? for more documentation.
  #
  # There are two ways of using #link_to_if_allowed
  #
  # === As #link_to with alternative
  # (or as #link_to_unless without explicit condition)
  #  link_to_if_allowed(name, options={}, html_options=nil) { 'alternative' }
  # +options+ either is a hash, like
  #  { :controller => :comments, :action => edit, :id => @comment }
  # a string, like
  #  "comments/1/edit"
  # or
  #  edit_comment_path(@comment)
  # or a single resource object.
  #
  # Notice that when providing a string, controller, action and parameters will
  # be parsed. After that, the resource types of the parameters are *guessed*,
  # the resources are retrieved and the rules of the action are evaluated.
  #
  # The block will be evaluated if the action is not allowed,
  # like in #link_to_unless.
  #
  # === As #link_to with alternative and explicit objects
  #  link_to_if_allowed(name, options={}, objects=[], params={}, html_options=nil) { 'alternative' }
  # In this case, controller and action will be derived from +options+ unless
  # they are specified in +params+.
  # All items in +objects+ and all remaining items in +params+ will be used
  # for evaluating the rules of the action.
  #
  # If you want to specify +html_options+, provide at least an empty hash
  # for +params+.
  #
  # Unlike to #link_to, you can also provide a symbol as +options+ value.
  # In this case, the target url will be determined by sending symbol as
  # message, providing +objects+ and +params+ as arguments, e.g.
  #  link_to_if_allowed("Show comment", :comment_path, [@article, @comment], {:details => true})
  # will call
  #  comment_path(@article, @comment, {:details => true})
  #
  # === Examples
  #  <%= link_to_if_allowed("Show", @course) { } %>
  #  <%= link_to_if_allowed("New", new_course_path) { "You may not create a new course." } %>
  #
  # These two are equivalent, however, the second approach is more efficient:
  #  <%= link_to_if_allowed("Edit", edit_course_path(@course)) { } %>
  #  <%= link_to_if_allowed("Edit", :edit_course_path, @course) { } %>
  #
  # The HTML-options are taken into account when choosing the action.
  #  <%= link_to_if_allowed("Delete", @course, {:method => :delete}) { } %>
  #
  # You can also define all values explicitly
  #  <%= link_to_if_allowed("Edit comment", "articles/1/comments/5/edit", [@comment], {:article => @comment.article, :action => :edit, :controller => :comments}) { } %>
  # 
  # === Parameters
  # - +name+ Text of the link
  # - +options+
  # - +objects+
  # - +params+
  # - +html_options+
  #
  def link_to_if_allowed(name, options, objects=nil, params=nil, html_options=nil, &block)

    options, objects, params, html_options =
              parse_allow_action_args(options, objects, params, html_options)

    controller = params.delete :controller
    action = params.delete :action
    allowed = SecurityContext.allow_action?(controller, action, objects, params)

    link_to_if(allowed, name, options, html_options, &block)
  end

  alias link_if_a link_to_if_allowed

  private

  def parse_allow_action_args(*args)
    if args.second && !(args.second.is_a? Hash)
      # objects and params are specified
      options, objects, params, html_options = args
      objects = [objects] unless objects.is_a? Array
      params ||= {}
      html_options ||= {}
      if options.is_a? Symbol
        # options is a symbol, send the message to get the link path
        path_args = objects + [params]
        options = send(options, *path_args)
      end
    else
      # retrieve objects and params from options
      options = args.first
      html_options = args.second || {}
      objects = [] # everything will be in the params
      if options.is_a? Hash
        params = options.dup
      else
        params = parse_action_params(options, html_options)
      end
    end

    unless params[:controller] && params[:action]
      # if controller and action are not given, parse from options
      params = parse_controller_action(options, params, html_options)
    end
    
    [options, objects, params, html_options]
  end

  # uses options and html_options to retrieve controller and action,
  # adds these values to params hash
  def parse_controller_action(options, params, html_options)
    path_info = get_path_info(options, html_options)
    params[:controller] ||= path_info[:controller]
    params[:action] ||= path_info[:action]
    params
  end

  # uses options and html_options to retrieve controller, action
  # and params
  def parse_action_params(options, html_options)
    get_path_info(options, html_options)
  end

  def get_path_info(options, html_options)
    if options.is_a? String
      path = options
    else
      path = url_for(options)
    end
    env = { :method => (html_options[:method] || :get ) }
    ActionController::Routing::Routes.recognize_path(path, env)
  end

end
