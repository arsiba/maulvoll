class TastingSession < ApplicationRecord
  include TastingConfiguration
  belongs_to :user
  belongs_to :current_round, class_name: "Round", optional: true
  has_many :rounds, -> { order(:number) }, dependent: :destroy
  has_many :participants, dependent: :destroy
  has_secure_token :invite_token, length: 44
  has_secure_token :tv_token, length: 44
  enum :status, { lobby: 0, voting: 1, round_vibe: 2, final_reveal: 3 }, validate: true
  validates :title, presence: true, length: { maximum: 120 }
  validates :date, presence: true
  validate :current_round_belongs_here

  private

  def current_round_belongs_here
    errors.add(:current_round, "gehört zu einer anderen Verkostung") if current_round && current_round.tasting_session_id != id
  end
end
