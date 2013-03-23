# Resource Based security for Rails applications

This plugin provides a thin security layer for rails applications. It performs access
checks based on a behavioural description of controller actions. Security rules
are defined on a resource model which is cleanly separated from your models and controllers.

## Installation steps

The security layer is a gem and may be installed using
`gem install annotation_security`.

After installing the gem, run `annotation_security --rails RAILS_HOME` to
integrate the security layer in your rails app. Along with the
annotation_security plugin this will add

* the `AnnotationSecurity::Helper` in the `app/helpers` folder of your
  rails-app. It provides some useful methods to create links and query the
  security layer from views.
* example configuration files to setup the security layer under `config/security`
* an initializer for the security layer under `config/initializer`

## Where to start

Check out the basic introduction on [how to secure your application](HOW-TO.md).
In order to get a detailed idea about how things work, have a deeper look
inside `AnnotationSecurity::ActionController` (how to secure your application),
`AnnotationSecurity::RightLoader` (how to setup rights) and
`AnnotationSecurity::RelationLoader` (how to setup relations).

Have a look at the view methods provided by the `AnnotationSecurity::Helper` as
well and at the `SecurityContext` which is the main entry-point for security related
functionality in the layer.

## License

Copyright Nico Rehwaldt, Arian Treffer 2009, 2010, 2013

You may use, copy and redistribute this library under the same terms as
[Ruby itself](http://www.ruby-lang.org/en/LICENSE.txt) or under the MIT license.