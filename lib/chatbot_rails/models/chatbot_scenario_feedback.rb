# frozen_string_literal: true

class ChatbotScenarioFeedback < ApplicationRecord
  include CreatedAtTrait
  include UpdatedAtTrait
  include DeletedAtTrait

  belongs_to :chatbot_scenario_option

  enum feedback_type: %i[html]

  validates :id, presence: true, length: { is: 16 }, uniqueness: true
  validates :chatbot_scenario_option_id, length: { is: 16 }
  validates :content_template, length: { maximum: 500 }
  validates :command_alias, length: { maximum: 200 }

  def find_by_id(id)
    find_by(id: id, deleted_at: nil)
  end

  def find_by_id_or_fail(id)
    find_by!(id: id, deleted_at: nil)
  end

  def find_by_chatbot_scenario_option_id(chatbot_scenario_option_id)
    where(chatbot_scenario_option_id: chatbot_scenario_option_id, deleted_at: nil)
  end

  def find_all
    where(deleted_at: nil)
  end

  def save_storage(args)
    id = generate_time_base_id
    chatbot_scenario_feedback = ChatbotScenarioFeedback.new(
      id: id,
      chatbot_scenario_option_id: args[:chatbot_scenario_option_id],
      feedback_type: args[:feedback_type],
      content_template: args[:content_template],
      command_alias: args[:command_alias],
      order: args[:order],
      created_at: DateTime.now,
      updated_at: DateTime.now
    ).tap(&:save)
    chatbot_scenario_feedback
  end

  def update_storage(args)
    chatbot_scenario_feedback = find_by(id: args[:id])
    chatbot_scenario_feedback.update(
      chatbot_scenario_option_id: args[:chatbot_scenario_option_id],
      feedback_type: args[:feedback_type],
      content_template: args[:content_template],
      command_alias: args[:command_alias],
      order: args[:order],
      updated_at: DateTime.now
    )
    chatbot_scenario_feedback
  end

  def delete_storage(args)
    chatbot_scenario_feedback = find_by(id: args[:id])
    chatbot_scenario_feedback.update(
      deleted_at: DateTime.now
    )
    chatbot_scenario_feedback
  end
end
