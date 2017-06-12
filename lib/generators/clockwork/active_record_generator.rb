require 'rails/generators'
require 'rails/generators/migration'
require 'active_record'

module Clockwork
  class ActiveRecordGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_paths << File.join(File.dirname(__FILE__), 'templates')
    desc 'Add migration for clockwork_ticks table'

    def copy_migrations
      migration_template "create_clockwork_ticks_migration.rb", "db/migrate/create_clockwork_ticks.rb"
    end

    def self.next_migration_number(dirname)
      ::ActiveRecord::Migration.next_migration_number(current_migration_number(dirname) + 1)
    end
  end
end
