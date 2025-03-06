class User < ApplicationRecord
  attr_accessor :verification_code
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :assistants, dependent: :destroy
  belongs_to :last_used_assistant, class_name: "Assistant", optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :phone, with: ->(p) { p&.gsub(/\D/, "") }
  normalizes :username, with: ->(u) { u.strip }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, uniqueness: true, allow_nil: true
  validates :gender, inclusion: { in: %w[male female other], allow_nil: true }
  validates :username, presence: true,
                    uniqueness: true,
                    length: { minimum: 3 },
                    format: { with: /\A[a-zA-Z0-9_]+\z/,
                             message: "only allows letters, numbers and underscore" }
end
