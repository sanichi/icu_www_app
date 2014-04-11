class UserInput < ActiveRecord::Base
  include Journalable
  journalize %w[label type], "/admin/user_inputs/%d"

  belongs_to :fee

  TYPES = %w[UserInput::Option UserInput::Text]

  validates :type, inclusion: { in: TYPES }
  validates :label, presence: true

  def subtype
    Fee.subtype(type.presence || self.class.to_s)
  end

  def self.subtype(type)
    type.to_s.split("::").last.downcase
  end
end
