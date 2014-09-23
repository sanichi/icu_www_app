class Game < ActiveRecord::Base
  include Journalable
  include Normalizable
  include Pageable

  journalize %w[annotator black black_elo date eco event fen moves ply result round site white white_elo], "/games/%d"

  MAX_ELO = 3000
  RESULTS = %w[1-0 0-1 ½-½ ?-?]
  ZIP_FILE = Rails.root + "public" + "system" + "icu.pgn.zip"
  PGN_FILE = Rails.root + "tmp" + "icu.pgn"
  LOG_FILE = Rails.root + "log" + "last_pgn_db.log"
  MAX_DOWNLOAD_SIZE = Rails.env.test?? 2 : 1000

  belongs_to :pgn

  before_validation :normalize_attributes, :sign

  validates :black, :white, presence: true
  validates :black_elo, :white_elo, numericality: { integer_only: true, greater_than: 0, less_than: MAX_ELO }, allow_nil: true
  validates :date, format: { with: /\A\d{4}\.(0[1-9]|1[012]|\?\?)\.(0[1-9]|[12][0-9]|3[01]|\?\?)\z/ }
  validates :eco, format: { with: /\A[A-E]\d\d\z/ }, allow_nil: true
  validates :moves, presence: true
  validates :pgn_id, numericality: { integer_only: true, greater_than: 0 }
  validates :ply, numericality: { integer_only: true, greater_than: 0 }, allow_nil: true
  validates :result, inclusion: { in: RESULTS }, allow_nil: true
  validates :round, format: { with: /\A[0-9]\d{0,2}([-.\/][0-9]\d{0,2})?\z/ }, allow_nil: true
  validates :signature, length: { is: 32 }
  validate :unique_signature

  scope :ordered, -> { order(date: :desc) }

  def self.search(params, path)
    paginate(matches(params), params, path)
  end

  def self.matches(params)
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
    matches = matches.where("event LIKE ?", "%#{params[:event]}%") if params[:event].present?
    matches = matches.where(pgn_id: params[:pgn_id].to_i) if params[:pgn_id].to_i > 0
    matches
  end

  def add_tag(name, value)
    return if value.blank?
    value.trim!
    value.markoff!
    if name.match(/\A(Annotator|Black|Date|ECO|Event|FEN|Result|Round|Site|White)\z/i)
      send("#{name.underscore}=", value)
    elsif name.match(/\A(BlackElo|Ply|WhiteElo)\z/i)
      int_val = value.gsub(/[^\d]/, "").to_i
      send("#{name.underscore}=", int_val > 0 ? int_val : nil)
    end
  end

  def add_moves(line)
    line.markoff!
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

  def to_pgn
    lines = []

    lines << %Q/[Event "#{event || '?'}"]/
    lines << %Q/[Site "#{site || "?"}"]/
    lines << %Q/[Date "#{date}"]/
    lines << %Q/[Round "#{round || '?'}"]/
    lines << %Q/[White "#{white}"]/
    lines << %Q/[Black "#{black}"]/
    lines << %Q/[Result "#{result == '½-½' ? '1/2-1/2' : (result == '?-?' ? '*' : result)}"]/
    lines << %Q/[WhiteElo "#{white_elo}"]/ if white_elo.present?
    lines << %Q/[BlackElo "#{black_elo}"]/ if black_elo.present?
    lines << %Q/[ECO "#{eco}"]/ if eco.present?
    lines << %Q/[Annotator "#{annotator}"]/ if annotator.present?
    lines << %Q/[FEN "#{fen}"]/ if fen.present?
    lines << ""
    lines << moves

    text = lines.join("\n")
    text += text.match(/\n\z/) ? "\n" : "\n\n"

    text
  end

  def self.save_last_pgn_db(last_mod, count)
    File.open(LOG_FILE, "w") do |f|
      f.write "#{last_mod}|#{count}"
    end
  end

  def self.get_last_pgn_db
    last_mod_count = File.open(LOG_FILE, "r") { |f| f.each_line.first }
    if last_mod_count.to_s.match(/\A([^|]+)\|([1-9]\d+)\z/)
      last_mod = $1
      count = $2
    else
      Failure.log("GetLastPGNDB", message: "unexpected log file contents", last_mod_count: last_mod_count || "(nil)")
    end
    [last_mod, count]
  rescue Errno::ENOENT
    [nil, nil]
  end

  def self.db_link
    path, text, details = nil, nil
    if File.exists?(ZIP_FILE)
      path = "/#{ZIP_FILE.relative_path_from(Rails.root + 'public')}"
      text = I18n.t("game.pgn.download.db")
      last_mod, count = get_last_pgn_db
      if last_mod && count
        details = I18n.t("game.pgn.download.details", last_mod: last_mod, count: count)
      end
    end
    [path, text, details]
  end

  private

  def normalize_attributes
    normalize_newlines(:moves)
    %w[annotator eco event fen round site].each do |atr|
      if send(atr).blank? || send(atr).trim.match(/\A\?+\z/)
        send("#{atr}=", nil)
      else
        send("#{atr}=", send(atr).trim)
      end
    end
    if result == "1/2-1/2" || result == "½-½"
      self.result = "½-½"
    elsif result != "1-0" && result != "0-1"
      self.result = "?-?"
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
    signature += white.to_s.downcase.sub(/,.*/, "").gsub(/[^a-z]/, "")
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

  def unique_signature
    duplicates = Game.where(signature: signature)
    duplicates = duplicates.where.not(id: id) unless new_record?
    duplicate = duplicates.first
    if duplicate
      errors.add(:base, "Duplicate game found (ID: #{duplicate.id})") # to higlight the error for the user
      errors.add(:signature, "duplicate") # so the PGN parser (see models/pgn.rb) can be sure the problem is a duplicate error
    end
  end
end
