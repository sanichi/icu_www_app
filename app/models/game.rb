class Game < ActiveRecord::Base
  extend Util::Pagination
  include Journalable
  journalize %w[annotator black black_elo date eco event fen moves ply result round site white white_elo], "/games/%d"

  MAX_ELO = 3000
  RESULTS = %w[1-0 0-1 ½-½ ?-?]

  belongs_to :pgn

  before_validation :normalize_attributes, :sign

  validates :black, :white, presence: true
  validates :black_elo, :white_elo, numericality: { integer_only: true, greater_than: 0, less_than: MAX_ELO }, allow_nil: true
  validates :date, format: { with: /\A\d{4}\.(0[1-9]|1[012]|\?\?)\.(0[1-9]|[12][0-9]|3[01]|\?\?)\z/ }
  validates :eco, format: { with: /\A[A-E]\d\d\z/ }, allow_nil: true
  validates :signature, length: { is: 32 }, uniqueness: { message: "duplicate detected" }
  validates :moves, presence: true
  validates :pgn_id, numericality: { integer_only: true, greater_than: 0 }
  validates :ply, numericality: { integer_only: true, greater_than: 0 }, allow_nil: true
  validates :result, inclusion: { in: RESULTS }, allow_nil: true
  validates :round, format: { with: /\A[0-9]\d{0,2}([-.\/][0-9]\d{0,2})?\z/ }, allow_nil: true

  scope :ordered, -> { order(date: :desc) }

  def self.search(params, path)
    matches = ordered
    if params[:date].present?
      if params[:date].match(/\A\s*(\d{4})(?:\D+(0[1-9]|1[012]|[1-9])(?:\D+(0[1-9]|[12][0-9]|3[01]|[1-9]))?)?/)
        year, mon, day = $1, $2, $3
        mon = "0#{mon}" if mon && mon.length == 1
        day = "0#{day}" if day && day.length == 1
        if year && mon && day
          matches = matches.where(date: "#{year}.#{mon}.#{day}")
        elsif year && mon
          matches = matches.where("date LIKE ?", "#{year}.#{mon}%")
        elsif year
          matches = matches.where("date LIKE ?", "#{year}%")
        else
          matches = matches.none
        end
      else
        matches = matches.none
      end
    end
    if params[:eco].present?
      eco = params[:eco].upcase.gsub(/\s/, "")
      case eco
      when /\A[A-E]\d\d\z/
        matches = matches.where(eco: eco)
      when /\A[A-E]\d?\z/
        matches = matches.where("eco LIKE ?", "#{eco}%")
      else
        matches = matches.none
      end
    end
    if params[:name].present?
      name = "%#{normalize_name(params[:name], true)}%"
      matches = matches.where("white LIKE ? OR black LIKE ?", name, name)
    else
      matches = matches.where("white LIKE ?", "%#{normalize_name(params[:white], true)}%") if params[:white].present?
      matches = matches.where("black LIKE ?", "%#{normalize_name(params[:black], true)}%") if params[:black].present?
    end
    matches = matches.where(result: params[:result]) if RESULTS.include?(params[:result])
    matches = matches.where("result LIKE ?", "%#{params[:result]}%") if params[:result].present?
    matches = matches.where(pgn_id: params[:pgn_id].to_i) if params[:pgn_id].to_i > 0
    paginate(matches, params, path)
  end

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

  def white_with_elo
    return white unless white_elo.present?
    "#{white} (#{white_elo})"
  end

  def black_with_elo
    return black unless black_elo.present?
    "#{black} (#{black_elo})"
  end

  def details
    details = []
    details.push event if event.present?
    details.push site if site.present?
    details.push date[0,4]
    details.join(", ")
  end

  def self.normalize_name(name, search=false)
    name.gsub!(/\s*,\s*/, ", ")                   # no space before comma, always one space after
    name.gsub!(/\./, " ")                         # no periods, e.g. after an initial
    name.gsub!(/\s*[`‘’‛'′´`]\s*/, "'")           # apostrophe is a single quote and never surrounded by spaces
    name.gsub!(/\A\s*O\s+([A-Z][a-z])/i, "O'\\1") # for example "O'Boyle", not "O Boyle"
    name.sub!(/, ([A-Z]{2,})/) do
      ", #{$1.split('').join(' ')}"               # split up runs of two or more initials
    end
    if search
      name.gsub!(/\s+/, " ")                      # search strings don't have to be full names so don't trim white space at edges
    else
      name.trim!                                  # trim white space (see initializers/string.rb)
    end
    name
  end

  def expand(opt)
    text = case opt[:text].to_s
    when /\A\s*\z/
      "#{white}—#{black}"
    when "*-*"
      then result
    else
      opt[:text]
    end
    %q{<a href="/games/%d">%s</a>} % [id, text]
  end

  private

  def normalize_attributes
    %w[annotator eco event fen round site].each do |atr|
      if send(atr).blank? || send(atr).trim.match(/\A\?+\z/)
        send("#{atr}=", nil)
      else
        send("#{atr}=", send(atr).trim)
      end
    end
    if result == "1/2-1/2"
      self.result = "½-½"
    elsif result == "*"
      self.result = "?-?"
    end
    if moves.present?
      moves.gsub!(/\r\n/, "\n")
    end
    if date.present?
      parts = date.scan(/\d+/).map{ |n| n.length == 1 ? "0#{n}" : n }
      parts.append('??') while parts.size < 3
      self.date = parts.join(".")
    end
    Game.normalize_name(white) if white.present?
    Game.normalize_name(black) if black.present?
  end

  def sign
    signature = ""
    signature += date.to_s
    signature += result.to_s
    signature += black.to_s.downcase.sub(/,.*/, "").gsub(/[^a-z]/, "")
    signature += black.to_s.downcase.sub(/,.*/, "").gsub(/[^a-z]/, "")
    move_text = moves.to_s.downcase
    move_text.gsub!(/\{[^}]*\}/, "")        # remove comments
    move_text.gsub!(/\([^)]*\)/, "")        # remove variations (TODO - handle nested variations)
    move_text.gsub!(/[1-9]\d*\.\.\./, "")   # remove black move numbers after a variation
    move_text.gsub!(/\$\d*/, "")            # remove move annotations
    move_text.gsub!(/[^rnkqpa-h0-9\s]/, "") # remove anything not a piece, square, move number or whitespace
    move_text.trim!                         # strip whitespace at either end and turn internal whitespace runs into single spaces
    signature += move_text
    self.signature = Digest::MD5.hexdigest(signature)
  end

  def remove_html_tags(str)
    str.gsub!(/<[^>]*>/, "")
  end
end
