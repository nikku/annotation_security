#
# = lib/extensions/filter.rb
#
# Adds security filters to the Rails filter mechanism.
# 
# Modifies ActionController::Filter::FilterChain. Might not work with other
# gems modifying this class.
#

# Extends ActiveRecord::Base and patches ActionController::Filters
#
# Performs additions to the rails filter chain. It basically adds two
# filters which may not be removed:
#
#  1) Before Fiter to initialize SecurityContext
#  2) Around Filter around actions
#
# The altered filter chain looks like this:
#
#  * AnnotationSecurity::Filters::InitializeSecurity
#  * ... other before filters
#  * around filters ...
#  * AnnotationSecurity::Filters::ApplySecurity
#  * after filters
#
module ActionController # :nodoc:
  module Filters # :nodoc:
    class FilterChain # :nodoc:
      def self.new(&block)
        returning super do |filter_chain|
          filter_chain.append_filter_to_chain([AnnotationSecurity::Filters::InitializeSecurity], :security, &block)
          filter_chain.append_filter_to_chain([AnnotationSecurity::Filters::ApplySecurity], :action_security, &block)
        end
      end

      private

      def find_filter_append_position(filters, filter_type)
        # appending an after filter puts it at the end of the call chain
        # before and around filters go after security filters and
        # before the first after or action_security filter
        #
        return -1 if filter_type == :after

        if filter_type == :security
          #security filters are first filters in chain
          each_with_index do |f,i|
            return i unless f.security?
          end
        else
          each_with_index do |f,i|
            return i if f.after? or f.action_security?
          end
        end
        return -1
      end

      def find_filter_prepend_position(filters, filter_type)
        if filter_type == :after
          # after filters go before the first after filter in the chain
          each_with_index do |f,i|
            return i if f.after?
          end
          return -1
        elsif filter_type == :security
          return 0
        else
          # prepending a before or around filter puts it at the front of the call chain
          each_with_index do |f,i|
            return i unless f.security?
          end
        end
        return 0 # Since first filter is security initialization filter
      end

      def find_or_create_filter(filter, filter_type, options = {})
        update_filter_in_chain([filter], options)

        if found_filter = find(filter) { |f| f.type == filter_type }
          found_filter
        else
          filter_kind = case
          when filter.respond_to?(:before) && filter_type == :before
            :before
          when filter.respond_to?(:after) && filter_type == :after
            :after
          else
            :filter
          end

          case filter_type
          when :before
            BeforeFilter.new(filter_kind, filter, options)
          when :after
            AfterFilter.new(filter_kind, filter, options)
          when :security
            SecurityFilter.new(filter_kind, filter, options)
          when :action_security
            ActionSecurityFilter.new(filter_kind, filter, options)
          else
            AroundFilter.new(filter_kind, filter, options)
          end
        end
      end
    end

    class Filter # :nodoc:

      # override to return true in appropriate subclass
      def security?
        false
      end

      def action_security?
        false
      end
    end

    # the customized security filter that sets the current user
    # and catches security exceptions
    class SecurityFilter < AroundFilter # :nodoc:
      def security?
        true
      end
    end

    # filter used to activate security for actions
    class ActionSecurityFilter < AroundFilter # :nodoc:
      def action_security?
        true
      end
    end
  end
end