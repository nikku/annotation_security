#
# = lib/extensions/filter.rb
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
#  * AnnotationSecurity::InitializeSecurityFilter
#  * ... other before filters
#  * around filters ...
#  * AnnotationSecurity::ApplySecurityfilter
#  * after filters
#
module ActionController # :nodoc:
  module Filters # :nodoc:
    class FilterChain # :nodoc:
      def self.new(&block)
        returning super do |filter_chain|
          filter_chain.append_filter_to_chain([AnnotationSecurity::InitializeSecurityFilter], :before, &block)
          filter_chain.append_filter_to_chain([AnnotationSecurity::ApplySecurityFilter], :security, &block)
        end
      end

      private

      def find_filter_append_position(filters, filter_type)
        # appending an after filter puts it at the end of the call chain
        # before and around filters go before the first after filter or before
        # security_filter in the chain
        unless filter_type == :after
          each_with_index do |f,i|
            return i if f.after? or f.apply_security?
          end
        end
        return -1
      end

      def find_filter_prepend_position(filters, filter_type)
        # prepending a before or around filter puts it at the front of the call chain
        # after filters go before the first after filter in the chain
        if filter_type == :after
          each_with_index do |f,i|
            return i if f.after?
          end
          return -1
        end
        return 1 # Since first filter is security initialization filter
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
          else
            AroundFilter.new(filter_kind, filter, options)
          end
        end
      end
    end

    class Filter # :nodoc:

      # override to return true in appropriate subclass
      def apply_security?
        false
      end
    end

    class SecurityFilter < AroundFilter # :nodoc:
      def apply_security?
        true
      end
    end
  end
end