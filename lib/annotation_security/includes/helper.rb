#
# = lib/annotation_security/includes/helper.rb
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
  # A policy description used as a controller annotation may also be to check
  # a right
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
  def allowed?(*args)
    SecurityContext.allowed?(*args)
  end

  # Equivalent to allowed?; is? is provided for better readability.
  #
  #  allowed? :logged_in
  #  is? :logged_in # <= equivalent but better to read
  #
  def is?(*args)
    SecurityContext.is?(*args)
  end

  # Checks whether the user is allowed to access the action.
  #
  # In case context is needed to evaluate the rule this
  # can be provided by passing the context (i.e. some model objects) as
  # an additional parameter
  #
  # ==== Parameters
  # * +options+ See #url_for for details
  # * <tt>*objects</tt> (Optional) Resource objects that will be used in the action
  #
  # ==== Examples
  #
  #  action_allowed?({:controller => :courses, :action => edit, :id => course.id})
  #  action_allowed?(edit_course_path(course))
  # 
  # Checks the 'edit' action of the course controller. Evaluates all static
  # rules and all dynamic rules that are bound to the parameter :id.
  #
  # If you want to have the unbound rules checked as well, you should use one
  # of these examples:
  #  action_allowed?({:controller => :courses, :action => edit,
  #                   :id => course.id, :resource => course})
  #  action_allowed?(edit_course_path(course), course)
  #  action_allowed?(:edit_course_path, course)
  #  
  # Checks the 'edit' action of the course controller. Evaluates all static
  # rules, all dynamic rules that are bound to the parameter :id and all
  # unbound dynamic rules that can be applied to a course resource.
  #
  def action_allowed?(*args)
    options, objects = parse_args(*args)
    params = parse_path_info(options)
    SecurityContext.allow_action?(
        params[:controller], params[:action],
        objects, params)
  end

  # Return a link tag with the specified name to the specified resource if
  # the user is allowed to access it. See #link_to_if and #action_allowed?
  # for documentation of the method signature.
  # 
  # In case context is needed to evaluate the allowed or not allowed rule this
  # can be provided by passing the context (such as a model object) as
  # the third parameter to this method.
  #
  #   <%= link_to_if_allowed "Show", {:action => "Hello"}, @obj %>
  #
  # Otherwise the context is obtained from the :resource key of the second
  # parameter (if it is a Hash)
  #
  #   <%= link_to_if_allowed "Show", :action => "hello", :resource => @obj %>
  #
  # Or the second parameter itself is used as a resource if it responds to
  # #resource_type:
  #
  #   <%= link_to_if_allowed "Show", @obj %>
  #
  # ==== Parameters
  # - +name+
  # - +options+
  # - +objects+
  # - +html_options+
  #
  def link_to_if_allowed(name, *args, &block)

    html_options = (args.size > 1 && args.last.is_a?(Hash)) ? args.pop : {}

    options, objects = parse_args(*args)
    params = parse_path_info(options, html_options)

    allowed = SecurityContext.
      allow_action?(params[:controller], params[:action], objects, params)

    link_to_if(allowed, name, options, html_options, &block)
  end

  alias link_if_a link_to_if_allowed

  private

  # Parse controller and action part from url_options.
  #
  # Returns {:controller => "controller_part", :action => "action_part"}
  #
  def parse_path_info(url_options, html_options = {})

    opts = nil

    # Try to get url options directly form options hash
    #
    if url_options.is_a? Hash
      unless url_options[:action].nil?
        opts = url_options.dup
        opts[:controller] ||= @controller.controller_name
      end
    end

    unless opts
      env = parse_environment(html_options)
      opts = parse_path_info_from_url_options(url_options, env)

      # Exchange opts action and id if action is a number
      # (if no action is given it is supposed that action = "show")
      if opts[:action] =~ /^\d+$/
        action = opts[:id]
        opts[:id] = opts[:action]
        opts[:action] = action
      end
    end

    opts[:action] ||= case html_options[:method]
        when :delete    then "destroy"
        when :put       then "update"
        when :post      then "create"
        else "show"
        end

    opts
  end

  def parse_environment(html_options)
    returning Hash.new do |h|
      h[:method] = html_options[:method] || :get
    end
  end

  # Returns path info for given url string
  #
  def parse_path_info_from_url_options(url_options, env = {})
    url = url_for(url_options)
    url.gsub!(/\?.*$/, "")
    ActionController::Routing::Routes.recognize_path(url, env)
  end

  # Parse context objects from request data
  #
  def parse_args(options, *objects)
    if objects.blank?
      if options.is_a? Hash and options.key? :resource
        objects = [options.delete(:resource)]
      elsif options.__is_resource?
        objects = [options]
      end
    end
    options = __send__(options,*objects) if options.is_a? Symbol
    [options,objects]
  end
end
