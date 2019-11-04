# frozen_string_literal: true

module UpdatedAtTrait
  extend ActiveSupport::Concern

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
