if defined?(ActiveRecord::Base)
  require 'test_help' 
else
  require 'action_controller/test_process'
  require 'action_controller/integration'
end

require 'cucumber/rails/test_unit'
require 'cucumber/rails/action_controller'

$__cucumber_toplevel = self

module Cucumber #:nodoc:
  module Rails
    # All scenarios will execute in the context of a new instance of Cucumber::Rails:World if this file 
    # is loaded. This gives Step Definitions access to all the methods from Rails' ActionController::IntegrationTest
    class World < ActionController::IntegrationTest
      if defined?(ActiveRecord::Base)
        self.use_transactional_fixtures = false
      else
        def self.fixture_table_names; []; end # Workaround for projects that don't use ActiveRecord
      end

      def initialize #:nodoc:
        @_result = Test::Unit::TestResult.new
      end
    end

    def self.use_transactional_fixtures

      unless ::Rails.configuration.cache_classes
        warn "WARNING: You have set Rails' config.cache_classes to false (most likely in config/environments/test.rb).  This setting is known to break Cucumber's use_transactional_fixtures method. Set config.cache_classes to true if you want to use transactional fixtures.  For more information see https://rspec.lighthouseapp.com/projects/16211/tickets/165."
      end

      World.use_transactional_fixtures = true
      if defined?(ActiveRecord::Base)
        $__cucumber_toplevel.Before do
          @__cucumber_ar_connection = ActiveRecord::Base.connection
          if @__cucumber_ar_connection.respond_to?(:increment_open_transactions)
            @__cucumber_ar_connection.increment_open_transactions
          else
            ActiveRecord::Base.__send__(:increment_open_transactions)
          end
          @__cucumber_ar_connection.begin_db_transaction
          ActionMailer::Base.deliveries = [] if defined?(ActionMailer::Base)
        end
        
        $__cucumber_toplevel.After do
          @__cucumber_ar_connection.rollback_db_transaction
          if @__cucumber_ar_connection.respond_to?(:decrement_open_transactions)
            @__cucumber_ar_connection.decrement_open_transactions
          else
            ActiveRecord::Base.__send__(:decrement_open_transactions)
          end
        end
      end
    end
  end
end

World do
  Cucumber::Rails::World.new
end
