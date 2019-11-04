# frozen_string_literal: true

class ChatbotConversation < ApplicationRecord
  include CreatedAtTrait
  include UpdatedAtTrait
  include DeletedAtTrait

  save_history save: false

  belongs_to :user
  belongs_to :chatbot_scenario_path
  belongs_to :chatbot_scenario_option
  belongs_to :chatbot_conversation_cache

  enum review: %i[unresolved resolved]

  validates :id, presence: true, length: { is: 16 }, uniqueness: true
  validates :user_id, presence: true, length: { is: 16 }
  validates :conversation_session_id, presence: true, length: { is: 16 }
  validates :chatbot_scenario_path_id, presence: true, length: { is: 16 }
  validates :state_params, json: true

  def review=(value)
    self[:review] = value.to_i
  end

  def state_params
    self[:state_params] && JSON.parse(self[:state_params])
  rescue JSON::ParserError => e
    {}
  end

  def state_params=(value)
    if value.nil?
      self[:state_params] = value
    else
      json = value.gsub(/(\r\n|\r|\n)/, '')
      self[:state_params] = json
    end
  end

  def find_by_id(id)
    find_by(id: id, deleted_at: nil)
  end

  def find_by_id_or_fail(id)
    find_by!(id: id, deleted_at: nil)
  end

  def find_latest_in_session(user_id, conversation_session_id)
    where(user_id: user_id, conversation_session_id: conversation_session_id, chatbot_scenario_option_id: nil, deleted_at: nil).order(:id).last
  end

  def find_latest(user_id)
    where(user_id: user_id, deleted_at: nil).order(:id).last
  end

  def find_all_in_session(user_id, conversation_session_id)
    where(user_id: user_id, conversation_session_id: conversation_session_id, deleted_at: nil)
  end

  def find_all
    all
  end

  def save_storage(args)
    id = generate_time_base_id

    conversation_session_id = args[:conversation_session_id]
    if conversation_session_id.nil?
      conversation_session_id = generate_time_base_id
    end

    chatbot_conversation = ChatbotConversation.new(
      id: id,
      user_id: args[:user_id],
      conversation_session_id: conversation_session_id,
      chatbot_scenario_path_id: args[:chatbot_scenario_path_id],
      chatbot_scenario_option_id: args[:chatbot_scenario_option_id],
      before_chatbot_conversation_id: args[:before_chatbot_conversation_id],
      conversion: args[:conversion],
      state_params: args[:state_params],
      created_at: DateTime.now,
      updated_at: DateTime.now
    ).tap(&:save)
    chatbot_conversation
  end

  def update_storage(args)
    conversation_session_id = args[:conversation_session_id]
    if conversation_session_id.nil?
      conversation_session_id = generate_time_base_id
    end

    chatbot_conversation = find_by(id: args[:id])
    chatbot_conversation.update(
      conversation_session_id: conversation_session_id,
      chatbot_scenario_option_id: args[:chatbot_scenario_option_id],
      conversion: args[:conversion],
      state_params: args[:state_params],
      updated_at: DateTime.now
    )
    chatbot_conversation
  end

  def update_review(args)
    chatbot_conversation = find_by(id: args[:id])
    chatbot_conversation.update(
      review: args[:review],
      updated_at: DateTime.now
    )
    chatbot_conversation
  end
end
