class Language < ActiveRecord::Base
  # Associtations
  has_and_belongs_to_many :offers

  # Validations
  validates :name, uniqueness: true, presence: true
  validates :code, uniqueness: true, presence: true, length: { is: 3 } # ISO 639-2
end