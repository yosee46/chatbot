require 'rails/generators/active_record'

module ActiveRecord
  module Generators
    class ChatbotRailsGenerator < ActiveRecord::Generators::Base
      argument :attributes, type: :array, default: [], banner: "field:type field:type"
      class_option :primary_key_type, type: :string, desc: "The type for primary key"
      source_root File.expand_path("../templates", __FILE__)

      def copy_chatbot_rails_migration
        migration_template "migration.rb", "#{migration_path}/chatbot_rails_create_#{table_name}_table.rb", migration_version: migration_version
      end

      def generate_model
        invoke "active_record:model", [name], migration: false
      end

      def migration_path
        if Rails.version >= '5.0.3'
          db_migrate_path
        else
          @migration_path ||= File.join("db", "migrate")
        end
      end

      def migration_version
        if rails5_and_up?
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end

      def rails5_and_up?
        Rails::VERSION::MAJOR >= 5
      end
    end
  end
end