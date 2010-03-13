# AnnoationSecurity requires rails.
# Here are some stubs to simulate a rails environment for testing.
#

RAILS_ROOT = ''
RAILS_ENV = {}

class ConfigStub
  def config
    self
  end
end

module ActiveRecord
  class Observer
    def self.observe(*args)
    end
  end
end

module ActionController
  class Base
    def render(*args)
    end
    def redirect_to(*args)
    end
  end
  module Routing
    class Routes
    end
  end
  module Filters
    class Filter
    end
    class AroundFilter < Filter
    end
  end
end