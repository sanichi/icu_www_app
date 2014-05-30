class Game < ActiveRecord::Base
  MAX_ELO = 3000
  RESULTS = %w[1-0 0-1 ½-½ *]

  belongs_to :pgn

  before_validation :normalize_attributes, :sign

  validates :black, :white, presence: true
  validates :black_elo, :white_elo, numericality: { integer_only: true, greater_than: 0, less_than: MAX_ELO }, allow_nil: true
  validates :date, format: { with: /\A\d{4}\.(0[1-9]|1[012]|\?\?)\.(0[1-9]|[12][0-9]|3[01]|\?\?)\z/ }
  validates :eco, format: { with: /\A[A-E]\d\d\z/ }, allow_nil: true
  validates :event, presence: true
  validates :signature, length: { is: 32 }, uniqueness: true
  validates :moves, presence: true
  validates :pgn_id, numericality: { integer_only: true, greater_than: 0 }
  validates :ply, numericality: { integer_only: true, greater_than: 0 }, allow_nil: true
  validates :result, inclusion: { in: RESULTS }, allow_nil: true
  validates :round, format: { with: /\A[0-9]\d{0,2}([-.\/][0-9]\d{0,2})?\z/ }, allow_nil: true

  def add_tag(name, value)
    return if value.blank?
    value.trim!
    remove_html_tags(value)
    if name.match(/\A(Annotator|Black|Date|ECO|Event|FEN|Result|Round|Site|White)\z/i)
      send("#{name.underscore}=", value)
    elsif name.match(/\A(BlackElo|Ply|WhiteElo)\z/i)
      int_val = value.gsub(/[^\d]/, "").to_i
      send("#{name.underscore}=", int_val > 0 ? int_val : nil)
    end
  end

  def add_moves(line)
    remove_html_tags(line)
    if moves.blank?
      self.moves = line
    else
      self.moves += line
    end
  end

  private

  def normalize_attributes
    %w[annotator eco fen round site].each do |atr|
      if send(atr).blank? || send(atr).trim.match(/\A\?+\z/)
        send("#{atr}=", nil)
      end
    end
    self.result = "½-½" if result == "1/2-1/2"
  end

  def sign
    signature = ""
    signature += date.to_s
    signature += result.to_s
    signature += white.to_s.downcase.sub(/,.*/, "").gsub(/[^a-z]/, "")
    signature += black.to_s.downcase.sub(/,.*/, "").gsub(/[^a-z]/, "")
    move_text = moves.to_s.downcase
    move_text.gsub!(/\{[^}]*\}/, "")        # remove comments
    move_text.gsub!(/\([^)]*\)/, "")        # remove variations (TODO - handle nested variations)
    move_text.gsub!(/[1-9]\d*\.\.\./, "")   # black move numbers after a variation
    move_text.gsub!(/\$\d*/, "")            # remove move annotations
    move_text.gsub!(/[^rnkqpa-h0-9\s]/, "") # remove anything not a piece, square, move number or whitespace
    move_text.trim!                         # squash all whitespace
    signature += move_text
    self.signature = Digest::MD5.hexdigest(signature)
  end

  def remove_html_tags(str)
    str.gsub!(/<[^>]*>/, "")
  end
end
