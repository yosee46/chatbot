# frozen_string_literal: true

class ChatbotScenarioPath < ApplicationRecord
  include CreatedAtTrait
  include UpdatedAtTrait
  include DeletedAtTrait

  belongs_to :chatbot_scenario
  belongs_to :chatbot_scenario_option, foreign_key: :parent_chatbot_scenario_option_id
  belongs_to :chatbot_scenario_path_group, foreign_key: :parent_chatbot_scenario_path_id

  enum select_rule: %i[random segment]
  enum delivery_status: %i[inactive active]

  validates :id, presence: true, length: { is: 16 }, uniqueness: true
  validates :chatbot_scenario_path_group_id, presence: true, length: { is: 16 }
  validates :chatbot_scenario_id, presence: true, length: { is: 16 }

  def delivery_status=(value)
    self[:delivery_status] = value == 'active' ? 1 : value.to_i
  end

  def get_delivery_status_active
    return false if self[:delivery_status] != 'active'
    true
  end

  def find_by_id(id)
    find_by(id: id, deleted_at: nil)
  end

  def find_by_id_or_fail(id)
    find_by!(id: id, deleted_at: nil)
  end

  def find_by_parent_chatbot_scenario_path_id_and_option_id(parent_chatbot_scenario_path_id, parent_chatbot_scenario_option_id)
    where(parent_chatbot_scenario_path_id: parent_chatbot_scenario_path_id, parent_chatbot_scenario_option_id: parent_chatbot_scenario_option_id, deleted_at: nil)
  end

  def find_root_path_by_path_group_id(path_group_id)
    where(chatbot_scenario_path_group_id: path_group_id, parent_chatbot_scenario_option_id: nil, deleted_at: nil)
  end

  def find_by_parent_chatbot_scenario_path_id(parent_chatbot_scenario_path_id)
    where(parent_chatbot_scenario_path_id: parent_chatbot_scenario_path_id, deleted_at: nil)
  end

  def find_all
    all
  end

  def save_storage(args)
    id = generate_time_base_id
    chatbot_scenario_path = ChatbotScenarioPath.new(
      id: id,
      chatbot_scenario_path_group_id: args[:chatbot_scenario_path_group_id],
      parent_chatbot_scenario_path_id: args[:parent_chatbot_scenario_path_id],
      parent_chatbot_scenario_option_id: args[:parent_chatbot_scenario_option_id],
      chatbot_scenario_id: args[:chatbot_scenario_id],
      delivery_status: args[:delivery_status],
      created_at: DateTime.now,
      updated_at: DateTime.now
    ).tap(&:save)
    chatbot_scenario_path
  end

  def update_storage(args)
    chatbot_scenario_path = find_by(id: args[:id])
    chatbot_scenario_path.update(
      delivery_status: args[:delivery_status],
      updated_at: DateTime.now
    )
    chatbot_scenario_path
  end

  def delete_storage(args)
    chatbot_scenario_path = find_by(id: args[:id])
    chatbot_scenario_path.update(
      deleted_at: DateTime.now
    )
    chatbot_scenario_path
  end
end
