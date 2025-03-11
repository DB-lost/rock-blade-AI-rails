# frozen_string_literal: true

class ToolUsage < ApplicationRecord
  belongs_to :message

  validates :function_name, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending success failed] }

  before_validation :set_default_status, on: :create

  private

  def set_default_status
    self.status ||= "pending"
  end
end
