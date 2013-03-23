# How to secure your Rails application with Annotation Security

## Step 0: Install Annotation Security

Annotation Security comes as a gem hosted on rubygems.org. You can install it
via `gem install annotation_security`.
The gem contains a binary called `annotation_security`. It can be used to
install the security layer into a rails app via
`annotation_security --rails RAILS_HOME`. This will make your app ready to be
secured.

### Version Notes

Use the gem version < 2 for Rails 2.3.x applications.
Use the gem version 3.x for Rails 3.x applications.

## Step 1: Defining user and roles

Annotation Security assumes that there is a user class, representing the user,
and some role classes containing additional information if the user has a
certain role in the application.

If you don't have user or role classes in your application,
continue with step 2.

### User

In most cases the user class will be a subclass of `ActiveRecord::Base`,
but this is not necessary.

Include the `module AnnotationSecurity::User` into this class.

    class User < ActiveRecord::Base
      include AnnotationSecurity::User
      ...

### Roles

Include the module `AnnotationSecurity::Role` into these classes. If you are
having a hierachy of role classes, only include the module in the topmost class.

    class Role < ActiveRecord::Base
      belongs_to :user
      include AnnotationSecurity::Role
      ...

    class Student < Role
      # no include here
      ...

A role object should respond to `user` with returning the user object
it belongs to.

__Do not include both modules in one class!__

### Connecting user and roles

As next, you should provide some default methods for accessing the roles
of a user. You can skip this step, but it will be helpfull later on.

There are two types of access methods: `is_ROLE?` and `as_ROLE`.

IS-methods return true or false whether a user has a role or not.
 
    class User < ActiveRecord::Base
      def is_administrator?
        self.admin_flag == 1
      end

      def is_student?
        self.roles.any? { |role| role.is_a? Student }
      end
      ...

AS-methods return a single object or an array of objects representing the role.
If the user does not have the role, the result should be an empty array or nil.
    
    class User < ActiveRecord::Base
      def as_administrator
        # there is no administrator class, just return the user
        is_administrator? ? self : nil
      end
      
      def as_student
        # assuming a user can only be student once
        self.roles.detect { |role| role.is_a? Student }
      end
      
      def as_corrector
        # assuming a user can be a corrector several times
        self.roles.select { |role| role.is_a? Corrector }
      end

## Step 2: Providing the current credential

To evaluate the security policies, for each request the current credential has
to be provided. Therefore, a new filter type was introduced: security filters
are around filters that are always the first in the filter chain. You can also
use these filters to react to security violations.

In this example, the user is simply fetched from the session. However, you
could also pass a symbol or a string (e.g. if you are using API-keys).

Passing `nil` will be interpreted as not being authenticated in any way.

    class ApplicationController < ActionController::Base
    
      security_filter :security_filter

      private

      def security_filter
        SecurityContext.current_credential = session[:user]
        yield
      rescue SecurityViolationError
        if SecurityContext.is? :logged_in
         render :template => "welcome/not_allowed"
        else
         render :template => "welcome/please_login"
        end
      end

Please notice that once set, the credential cannot be changed.

## Step 3: Defining your resources

Another wild assumption we made is that your application contains some resources
you want to protect. In most cases, this will be your ActiveRecord classes.
To turn them into resources, just call `resource(symbol)` in the class
definition.

    class Course < ActiveRecord::Base
      resource :course
      ...

The symbol is used to further identify this class and should be unique.

It is possible (and likely) that the users and roles are resources as well.

If you want to restrict access to other resource classes, see
`AnnotationSecurity::Resource` for more information.

## Step 4: Defining relations and rights

in `config/security` you will find the files `relations.rb` and
`rights.yml`.

### Relations

The relations between the user (or the roles) and the resources are defined
as code blocks, that evaluate to true or false.

The `:as`-flag causes that instead of the user object, a role object
will be passed into the block (using the `as_ROLE`-method from above).
Similar, the `:is`-flag can be used as precondition.

    AnnotationSecurity.define_relations do
      resource :course do
        enrolled :as => :student { |student,course| course.students.include? student }
        corrector :as => :corrector { |corrector,course| corrector.corrects? course }
        lecturer :as => :lecturer { |lecturer,course| lecturer.lectures? course }
      end
      ...

You can also define relations that are valid for all resources.

    all_resources do
      # corrector and lecturer are defined by the resource
      responsible { corrector or lecturer }
      # no block required here
      administrator :is => :administrator
    end

For more details and features on defining relations,
see `AnnotationSecurity::RelationLoader`.

### Rights

The rights of application are specified in a YAML-file, they correspond to the
actions(not necessarily the controller actions) that can be performed on a
resource. For instance, to edit a course object, you will need the edit-right
for the course resource. If you are not sure which rights your application
needs, just skip this now and return after step 5.

Rights should be valid ruby conditional statements.

    course:
      create: if lecturer
      show: if enrolled or responsible
      edit: if responsible

AnnotationSecurity provides two default relations: `logged_in`, that is true
if there is a user at all, and +self+, that can be used to determine if a user
or role resource belongs to the current user.

    user:
      register: unless logged_in
      show: if logged_in
      edit: if self or administrator
    student:
      show_results: if self

To improve readability, you can append 'may', 'is', 'can' or 'has' as prefix and
'for', 'in', 'of' or 'to' as suffix to the relation name.
This is especially recommended if you are defining rights that depend on
other rights of the resource.

    assignment:
      edit: if responsible
      delete: if may_edit

Another example can be found at `AnnotationSecurity::RightLoader`.

## Step 5: Securing your actions

The main goal of AnnotationSecurity was to remove security logic from
controller actions. Now you only have to define the abstract effects of an
action.

An action performs one or more tasks on different resources. You have to provide
this information as a descriptions, using the
[Action Annotation Gem](http://github.com/Nikku/action_annotation).
A description always has the form 'ACTION on RESOURCE'.

    desc 'shows a course'
    def show
      @course = Course.find(params[:id])
    end

To perform a task, the user must have the right for it. Thus, when a course is
fetched from the database during the show-action, the right course/show will be
evaluated for the current user and the course instance.

In our example, the user has to be responsible or enrolled. If both relations
evaluate to false, the right is not given and access will be denied by raising
a SecurityViolationError, which will then be catched in the security filter.

Congratulations, you Rails application is secured now.

## Step 6: Securing your views

However, actions aren't the only place with security code. Links to the actions
are shown in the view and very often, the view itself depends on the
user's rights.

When setting up Annotation Security in your Rails project, a helper will be
included automatically. The most important functions this helper provides are
`allowed?` and `link_to_if_allowed`.

The method `allowed?` expects a right and a resource and returns true iif
the current user has that right.

    <% unless allowed? :edit, @course %>
      <p>You may not edit this course!</p>
    <% end %>

`link_to_if_allowed` expects the same arguments as +link_to+, except it also
expects a block like +link_to_if+ (which will be called internally).

    <%= link_to_if_allowed("New", new_course_path) { "You may not create a new course." } %>
    <%= link_to_if_allowed("Edit", edit_course_path(@course)) { } %>
    <%= link_to_if_allowed("Delete", @course, {:method => :delete}) { } %>

`link_to_if_allowed` tries to automatically detect the accessed resources.
In case this should not work for you, see `AnnotationSecurity::Helper` for more
features.

## Step 7: Live long and prosper

Well, that's it. Here are some additional notes:

* in development mode, the rights and relations are reloaded with every request.
* See `AnnotationSecurity::RelationLoader` and `AnnotationSecurity::RightLoader`
  for more examples and features for defining relations and rights.
* See `AnnotationSecurity::Helper` for more methods for securing your views.
