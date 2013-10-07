class Club < ActiveRecord::Base
  WEB_FORMAT = ['https?:\/\/', '[^.\/\s:]+(\.[^.\/\s:]+){1,}[^\s]+']

  before_validation :normalize_attributes

  validates :name, presence: true, uniqueness: true
  validates :active, inclusion: { in: [true, false] }
  validates :province, inclusion: { in: Ireland.provinces }
  validates :county, inclusion: { in: Ireland.counties }
  validates :city, presence: true
  validates :contact, presence: true, if: Proc.new { |c| c.active }
  validates :web, format: { with: /\A#{WEB_FORMAT[0]}#{WEB_FORMAT[1]}\z/ }, allow_nil: true
  validates :email, format: { with: /\A[^\s]+@[^\s]+\z/ }, allow_nil: true
  validates :phone, format: { with: /\d{3}/ }, allow_nil: true
  validates :latitude,  numericality: { greater_than:  51.2, less_than: 55.6 }, allow_nil: true
  validates :longitude, numericality: { greater_than: -10.6, less_than: -5.3 }, allow_nil: true

  validate :province_has_county, :has_contact_method

  private

  def province_has_county
    unless Ireland.has?(province, county)
      errors.add(:county, "%s does not belong to %s" % [I18n.t("ireland.co.#{county}"), I18n.t("ireland.prov.#{province}")])
    end
  end

  def has_contact_method
    if active
      unless phone.present? || email.present? || web.present?
        errors[:base] << "there should be at least one contact method (phone, email or web)"
      end
    end
  end

  def normalize_attributes
    [:meetings, :district, :address, :contact, :phone, :email, :web, :latitude, :longitude].each do |atr|
      self.send("#{atr}=", nil) if self.send(atr).blank?
    end
    if web.present? && web.match(/\A#{WEB_FORMAT[1]}/)
      self.web = "http://#{web}"
    end
  end
end