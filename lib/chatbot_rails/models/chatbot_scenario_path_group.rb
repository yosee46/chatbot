# frozen_string_literal: true

class ChatbotScenarioPathGroup < ApplicationRecord
  include CreatedAtTrait
  include UpdatedAtTrait
  include DeletedAtTrait
  include DeliveryStatusTrait

  enum delivery_status: %i[inactive active]

  validates :id, presence: true, length: { is: 16 }, uniqueness: true
  validates :group_alias, presence: true, length: { maximum: 80 }, uniqueness: true

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

  def find_by_group_alias(group_alias)
    find_by(group_alias: group_alias, deleted_at: nil)
  end

  def find_all
    all
  end

  def save_storage(args)
    id = generate_time_base_id
    chatbot_scenario_path_group = ChatbotScenarioPathGroup.new(
      id: id,
      group_alias: args[:group_alias],
      note: args[:note],
      delivery_status: args[:delivery_status],
      created_at: DateTime.now,
      updated_at: DateTime.now
    ).tap(&:save)
    chatbot_scenario_path_group
  end

  def update_storage(args)
    chatbot_scenario_path_group = find_by(id: args[:id])
    chatbot_scenario_path_group.update(
      note: args[:note],
      delivery_status: args[:delivery_status],
      updated_at: DateTime.now
    )
    chatbot_scenario_path_group
  end
end
