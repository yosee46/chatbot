# frozen_string_literal: true

module DeletedAtTrait
  extend ActiveSupport::Concern

  def deleted_at
    return nil if self[:deleted_at].nil?
    !self[:deleted_at] ? DateTime.new(self[:deleted_at]) : self[:deleted_at].in_time_zone(Constants::TIMEZONE)
  end

  def deleted_at=(value)
    return self[:deleted_at] = nil if value.blank?
    deleted_at = value.class == DateTime ? value : value.in_time_zone(Constants::TIMEZONE)
    self[:deleted_at] = deleted_at.in_time_zone('UTC')
  end
end
