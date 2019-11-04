# frozen_string_literal: true

module CreatedAtTrait
  extend ActiveSupport::Concern

  def created_at
    return nil if self[:created_at].nil?
    !self[:created_at] ? DateTime.new(self[:created_at]) : self[:created_at].in_time_zone(Constants::TIMEZONE)
  end

  def created_at=(value)
    return self[:created_at] = nil if value.blank?
    created_at = value.class == DateTime ? value : value.in_time_zone(Constants::TIMEZONE)
    self[:created_at] = created_at.in_time_zone('UTC')
  end
end
