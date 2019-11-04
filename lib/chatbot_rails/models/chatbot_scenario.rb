# frozen_string_literal: true

class ChatbotScenario < ApplicationRecord
  include CreatedAtTrait
  include UpdatedAtTrait
  include DeletedAtTrait

  has_many :chatbot_scenario_options

  validates :id, presence: true, length: { is: 16 }, uniqueness: true

  def find_by_id(id)
    find_by(id: id, deleted_at: nil)
  end

  def find_by_id_or_fail(id)
    find_by!(id: id, deleted_at: nil)
  end

  def find_all
    where(deleted_at: nil)
  end

  def save_storage(args)
    id = generate_time_base_id
    chatbot_scenario = ChatbotScenario.new(
      id: id,
      question: args[:question],
      created_at: DateTime.now,
      updated_at: DateTime.now
    ).tap(&:save)
    chatbot_scenario
  end

  def update_storage(args)
    chatbot_scenario = find_by(id: args[:id])
    chatbot_scenario.update(
      question: args[:question],
      updated_at: DateTime.now
    )
    chatbot_scenario
  end

  def delete_storage(args)
    chatbot_scenario = find_by(id: args[:id])
    chatbot_scenario.update(
      deleted_at: DateTime.now
    )
    chatbot_scenario
  end

  def updated_at
    return nil if self[:updated_at].nil?
    !self[:updated_at] ? DateTime.new(self[:updated_at]) : self[:updated_at].in_time_zone(Constants::TIMEZONE)
  end

  def updated_at=(value)
    return self[:updated_at] = nil if value.blank?
    updated_at = value.class == DateTime ? value : value.in_time_zone(Constants::TIMEZONE)
    self[:updated_at] = updated_at.in_time_zone('UTC')
  end
end
