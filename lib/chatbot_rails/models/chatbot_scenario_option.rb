# frozen_string_literal: true

class ChatbotScenarioOption < ApplicationRecord
  include CreatedAtTrait
  include UpdatedAtTrait
  include DeletedAtTrait

  belongs_to :chatbot_scenario
  has_many :chatbot_scenario_feedbacks

  enum condition_operation: %i[eq gt gte lt lte neq]

  validates :id, presence: true, length: { is: 16 }, uniqueness: true
  validates :chatbot_scenario_id, presence: true, length: { is: 16 }
  validates :content, length: { maximum: 500 }
  validates :command_config, json: true
  validates :saving_state_params, json: true

  def validate_state_params(state_params)
    return false if state_params.nil? || self[:saving_state_params].nil?

    # TODO: 脆弱性対応
    keys = state_params.keys
    keys.all? { |param| saving_state_params.keys.include? param }
  end

  def saving_state_params
    self[:saving_state_params] && JSON.parse(self[:saving_state_params])
  rescue JSON::ParserError => e
    {}
  end

  def saving_state_params=(value)
    if value.nil?
      self[:saving_state_params] = value
    else
      json = value.gsub(/(\r\n|\r|\n)/, '')
      self[:saving_state_params] = json
    end
  end

  def command_config
    self[:command_config] && JSON.parse(self[:command_config])
  rescue JSON::ParserError => e
    {}
  end

  def command_config=(value)
    if value.nil?
      self[:command_config] = value
    else
      json = value.gsub(/(\r\n|\r|\n)/, '')
      self[:command_config] = json
    end
  end

  def find_by_id(id)
    find_by(id: id, deleted_at: nil)
  end

  def find_by_id_or_fail(id)
    find_by!(id: id, deleted_at: nil)
  end

  def find_by_chatbot_scenario_id(chatbot_scenario_id)
    where(chatbot_scenario_id: chatbot_scenario_id, deleted_at: nil)
  end

  def find_all
    where(deleted_at: nil)
  end

  def save_storage(args)
    id = generate_time_base_id
    chatbot_scenario_option = ChatbotScenarioOption.new(
      id: id,
      chatbot_scenario_id: args[:chatbot_scenario_id],
      content: args[:content],
      condition_command_alias: args[:condition_command_alias].blank? ? nil : args[:condition_command_alias],
      condition_operation: args[:condition_operation].blank? ? nil : args[:condition_operation],
      condition_value: args[:condition_value].blank? ? nil : args[:condition_value],
      variable_command_alias: args[:variable_command_alias].blank? ? nil : args[:variable_command_alias],
      command_config: args[:command_config].blank? ? nil : args[:command_config],
      html_content_template: args[:html_content_template].blank? ? nil : args[:html_content_template],
      saving_state_params: args[:saving_state_params].blank? ? nil : args[:saving_state_params],
      created_at: DateTime.now,
      updated_at: DateTime.now
    ).tap(&:save)
    chatbot_scenario_option
  end

  def update_storage(args)
    chatbot_scenario_option = find_by(id: args[:id])
    chatbot_scenario_option.update(
      content: args[:content],
      condition_command_alias: args[:condition_command_alias].blank? ? nil : args[:condition_command_alias],
      condition_operation: args[:condition_operation].blank? ? nil : args[:condition_operation],
      condition_value: args[:condition_value].blank? ? nil : args[:condition_value],
      variable_command_alias: args[:variable_command_alias].blank? ? nil : args[:variable_command_alias],
      command_config: args[:command_config].blank? ? nil : args[:command_config],
      html_content_template: args[:html_content_template].blank? ? nil : args[:html_content_template],
      saving_state_params: args[:saving_state_params].blank? ? nil : args[:saving_state_params],
      updated_at: DateTime.now
    )
    chatbot_scenario_option
  end

  def delete_storage(args)
    chatbot_scenario_option = find_by(id: args[:id])
    chatbot_scenario_option.update(
      deleted_at: DateTime.now
    )
    chatbot_scenario_option
  end
end
