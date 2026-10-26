class Round < ApplicationRecord
  belongs_to :tasting_session
  has_many :ratings, dependent: :destroy
  validates :number, numericality: { only_integer: true, in: 1..100 }, uniqueness: { scope: :tasting_session_id }
  validates :secret_identity, presence: true, length: { maximum: 120 }
  validates :context_info, length: { maximum: 160 }
  validate :valid_tags

  private

  def valid_tags
    errors.add(:tags, "maximal 8 kurze Tags erlaubt") unless tags.is_a?(Array) && tags.size <= 8 && tags.all? { |tag| tag.is_a?(String) && tag.length.between?(1, 30) }
  end
end
