class Participant < ApplicationRecord
  belongs_to :tasting_session
  has_many :ratings, dependent: :destroy
  has_secure_token :session_token, length: 44
  normalizes :name, with: ->(name) { name.strip }
  validates :name, presence: true, length: { maximum: 25 }
  scope :active, -> { where(blocked: false) }
end
