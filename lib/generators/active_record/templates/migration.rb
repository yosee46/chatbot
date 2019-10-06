# frozen_string_literal: true

class ChatbotCreateTable
  def change
    create_table :chatbot_scenarios, id: false do |t|
      t.column :id, :'CHAR(16)', null: false
      t.column :question, :text, null: false
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
    end
    execute('alter table chatbot_scenarios add primary key (id)')

    create_table :chatbot_scenario_options, id: false do |t|
      t.column :id, :'CHAR(16)', null: false
      t.column :chatbot_scenario_id, :'CHAR(16)', null: false
      t.column :content, :text, null: false
      t.column :condition_command_alias, :string, default: nil, null: true
      t.column :condition_operation, :integer, default: nil, null: true
      t.column :condition_value, :string, default: nil, null: true
      t.column :variable_command_alias, :string, default: nil, null: true
      t.column :command_config, :text, default: nil, null: true
      t.column :html_content_template, :text, default: nil, null: true
      t.column :saving_state_params, :text, default: nil, null: true
      t.column :conversion_flg, :integer, null: false, default: 0, limit: 1
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
    end
    execute('alter table chatbot_scenario_options add primary key (id)')
    add_foreign_key :chatbot_scenario_options, :chatbot_scenarios, column: :chatbot_scenario_id, primary_key: 'id'

    create_table :chatbot_scenario_feedbacks, id: false do |t|
      t.column :id, :'CHAR(16)', null: false
      t.column :chatbot_scenario_option_id, :'CHAR(16)', null: false
      t.column :feedback_type, :integer, null: false
      t.column :content_template, :text, null: false
      t.column :command_alias, :text
      t.column :order, :integer, null: false, default: 0
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
    end
    execute('alter table chatbot_scenario_feedbacks add primary key (id)')
    add_foreign_key :chatbot_scenario_feedbacks, :chatbot_scenario_options, column: :chatbot_scenario_option_id, primary_key: 'id'


    create_table :chatbot_scenario_path_groups, id: false do |t|
      t.column :id, :'CHAR(16)', null: false
      t.column :group_alias, :'CHAR(80)', null: false
      t.column :note, :text
      t.column :delivery_status, :integer, default: 0, null: false, limit: 1
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
    end

    execute('alter table chatbot_scenario_path_groups add primary key (id)')
    add_index :chatbot_scenario_path_groups, :group_alias, unique: true


    create_table :chatbot_scenario_paths, id: false do |t|
      t.column :id, :'CHAR(16)', null: false
      t.column :chatbot_scenario_path_group_id, :'CHAR(16)', null: false
      t.column :parent_chatbot_scenario_path_id, :'CHAR(16)'
      t.column :parent_chatbot_scenario_option_id, :'CHAR(16)'
      t.column :chatbot_scenario_id, :'CHAR(16)'
      t.column :select_rule, :integer, default: 0, null: false
      t.column :delivery_status, :integer, default: 0, null: false, limit: 1
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
    end

    execute('alter table chatbot_scenario_paths add primary key (id)')
    add_foreign_key :chatbot_scenario_paths, :chatbot_scenario_options, column: :parent_chatbot_scenario_option_id, primary_key: 'id'
    add_foreign_key :chatbot_scenario_paths, :chatbot_scenarios, column: :chatbot_scenario_id, primary_key: 'id'
    add_foreign_key :chatbot_scenario_paths, :chatbot_scenario_path_groups, column: :chatbot_scenario_path_group_id, primary_key: 'id'
    add_foreign_key :chatbot_scenario_paths, :chatbot_scenario_paths, column: :parent_chatbot_scenario_path_id, primary_key: 'id'


    create_table :chatbot_conversations, id: false do |t|
      t.column :id, :'CHAR(16)', null: false
      t.column :user_id, :'CHAR(16)', null: false
      t.column :conversation_session_id, :'CHAR(16)', null: false
      t.column :chatbot_scenario_path_id, :'CHAR(16)', null: false
      t.column :chatbot_scenario_option_id, :'CHAR(16)'
      t.column :before_chatbot_conversation_id, :'CHAR(16)'
      t.column :conversion, :integer, default: 0, null: false
      t.column :review, :integer
      t.column :state_params, :text, default: nil, null: true
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :deleted_at
    end

    execute('alter table chatbot_conversations add primary key (id)')
    add_foreign_key :chatbot_conversations, :chatbot_scenario_paths, column: :chatbot_scenario_path_id, primary_key: 'id'
    add_foreign_key :chatbot_conversations, :chatbot_scenario_options, column: :chatbot_scenario_option_id, primary_key: 'id'
    add_foreign_key :chatbot_conversations, :chatbot_conversations, column: :before_chatbot_conversation_id, primary_key: 'id'

    add_index :chatbot_conversations, %i[user_id conversation_session_id chatbot_scenario_path_id], name: 'user_session_scenario_path'
  end
end
