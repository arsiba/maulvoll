class TastingTemplate < ApplicationRecord
  include TastingConfiguration
  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
end
