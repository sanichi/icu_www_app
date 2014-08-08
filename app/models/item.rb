class Item < ActiveRecord::Base
  include Pageable
  include Payable

  serialize :notes, Array

  belongs_to :player
  belongs_to :fee
  belongs_to :cart, touch: true

  after_initialize :compensate_for_unchecked_options
  before_validation :copy_fee, :normalise

  validates :status, exclusion: { in: %w[part_refunded] } # unlike carts, items are not part-refundable (see models/concerns/Payable.rb)
  validates :description, presence: true
  validates :fee, presence: true, unless: Proc.new { |i| i.source == "www1" }
  validates :cost, numericality: { greater_than: Cart::MIN_AMOUNT, less_than: Cart::MAX_AMOUNT }, allow_nil: true
  validates :cost, presence: true, unless: Proc.new { |i| i.fee.blank? || i.fee.user_amount? }
  validates :player_data, absence: true, unless: Proc.new { |i| i.fee.try(:new_player_allowed?) }
  validates :source, inclusion: { in: Global::SOURCES }
  validate :age_constraints, :rating_constraints, :check_user_inputs

  def self.search(params, path)
    matches = includes(:player).references(:players).order(created_at: :desc).includes(:cart)
    matches = matches.where(type: params[:type]) if params[:type].present?
    matches = matches.where(status: params[:status]) if params[:status].present?
    matches = matches.where(payment_method: params[:payment_method]) if params[:payment_method].present?
    matches = matches.where(player_id: params[:player_id].to_i) if params[:player_id].to_i > 0
    matches = matches.where("players.last_name LIKE ?", "%#{params[:last_name]}%") if params[:last_name].present?
    matches = matches.where("players.first_name LIKE ?", "%#{params[:first_name]}%") if params[:first_name].present?
    paginate(matches, params, path)
  end

  def complete(payment_method)
    update_columns(payment_method: payment_method, status: "paid")
    if player_id.blank? && player_data.present?
      begin
        player = new_player.to_player
        player.save!
        update_column(:player_id, player.id)
      rescue => e
        logger.error "coundn't create new player record; data: #{player_data}, error: #{e.message}"
      end
    end
  end

  def full_description
    parts = []
    parts.push description
    parts.push player_name
    parts.push "€#{'%.2f' % cost}"
    parts += additional_information if respond_to?(:additional_information)
    parts += notes
    parts.push I18n.t("shop.payment.status.#{status}", locale: :en) unless paid?
    parts.reject(&:blank?).join(", ")
  end

  def new_player
    return unless player_data.present?
    @new_player ||= NewPlayer.from_json(player_data)
  end

  def player_name
    if player.present?
      player.name(id: true)
    elsif new_player = self.new_player
      new_player.name
    else
      nil
    end
  end

  def note_references(all_notes)
    notes.each_with_object([]) do |note, refs|
      number = all_notes[note]
      refs.push number if number
    end
  end

  private

  def copy_fee
    return unless new_record? && fee.present?
    self.description = fee.description(:full) unless description.present?
    self.start_date  = fee.start_date         unless start_date.present?
    self.end_date    = fee.end_date           unless end_date.present?
    self.cost        = fee.amount             unless cost.present?
  end

  def normalise
    self.player_data = player_data.presence
  end

  def compensate_for_unchecked_options
    return unless new_record? && fee && notes.size < fee.user_inputs.size
    new_notes = []
    fee.user_inputs.each_with_index do |user_input, i|
      new_notes.push("") if user_input.subtype == "option" && notes[i] != user_input.label
      new_notes.push(notes[i]) unless i >= notes.size
    end
    self.notes = new_notes
  end

  def age_constraints
    return unless player && fee.try(:age_ref_date)
    if fee.max_age.present? && player.age_over?(fee.max_age, fee.age_ref_date)
      errors.add(:base, I18n.t("item.error.age.old", member: player.name, date: fee.age_ref_date.to_s, limit: fee.max_age))
    end
    if fee.min_age.present? && player.age_under?(fee.min_age, fee.age_ref_date)
      errors.add(:base, I18n.t("item.error.age.young", member: player.name, date: fee.age_ref_date.to_s, limit: fee.min_age))
    end
  end

  def rating_constraints
    return unless player && fee
    if fee.max_rating.present? && player.too_strong?(fee.max_rating)
      errors.add(:base, I18n.t("item.error.rating.high", member: player.name, limit: fee.max_rating))
    end
    if fee.min_rating.present? && player.too_weak?(fee.min_rating)
      errors.add(:base, I18n.t("item.error.rating.low", member: player.name, limit: fee.min_rating))
    end
  end

  def check_user_inputs
    return unless new_record? && fee
    logger.error "mismatched number of user inputs (#{fee.user_inputs.map(&:id).join('|')}) and notes #{notes.join('|')}" unless fee.user_inputs.size == notes.size
    self.notes = notes[0..(fee.user_inputs.size-1)] if fee.user_inputs.size < notes.size
    fee.user_inputs.each_with_index { |input, i| input.check(self, i) }
    self.notes.compact!
  end
end
