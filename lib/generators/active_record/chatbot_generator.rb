module Generators
  module ActiveRecord
    class ChatbotGenerator

      def copy_chatbot_migration
        migration_template "migration.rb", "#{migration_path}/devise_create_#{table_name}.rb", migration_version: migration_version
      end

      def generate_model
        invoke "active_record:model", [name], migration: false
      end

    end
  end
end