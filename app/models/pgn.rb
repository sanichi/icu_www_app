class Pgn < ActiveRecord::Base
  extend Util::Pagination
  include Journalable
  journalize %w[comment], "/admin/pgns/%d"

  attr_accessor :file, :import

  belongs_to :user
  has_many :games, dependent: :delete_all

  MAX_SIZE = 2.megabytes
  TYPES = %w[text/plain application/x-chess-pgn]
  class PGNError < StandardError; end

  before_validation :normalize_attributes

  validates :duplicates, :game_count, :imports, :lines, numericality: { integer_only: true, greater_than_or_equal_to: 0 }
  validates :content_type, inclusion: { in: TYPES }
  validates :file_name, presence: true
  validates :file_size, numericality: { integer_only: true, greater_than: 0, less_than: MAX_SIZE }
  validates :user_id, numericality: { integer_only: true, greater_than: 0 }

  scope :ordered, -> { order(created_at: :desc) }
  scope :include_player, -> { includes(user: :player) }

  def self.search(params, path)
    matches = ordered.include_player
    matches = matches.where("comment LIKE ?", "%#{params[:comment]}%") if params[:comment].present?
    matches = matches.where("file_name LIKE ?", "%#{params[:file_name]}%") if params[:file_name].present?
    if params[:player_id].to_i > 0
      matches = matches.joins(user: :player)
      matches = matches.where("players.id = ?", params[:player_id].to_i)
    end
    paginate(matches, params, path)
  end

  def parse(file)
    @state = :initial
    file.each_line do |line|
      self.lines += 1
      parse_line(line)
    end
    parse_line("")
  rescue PGNError => e
    self.problem = e.message
  rescue => e
    self.problem = "#{e.message} #{e.backtrace.first}"
  ensure
    file.close!
  end

  def remaining
    @remaining ||= Game.where(pgn_id: id).count
  end

  private

  def normalize_attributes
    %w[comment problem].each do |atr|
      if self.send(atr).blank?
        self.send("#{atr}=", nil)
      end
    end
  end

  def import?
    import == "true"
  end

  def parse_line(line)
    type = case line
           when /\A\s*\[\s*([a-z]+)\s+"([^"]*)"\s*\]\s*\z/i
             :tag
           when /\A\s*\z/
             :blank
           else
             :other
           end
    case @state
    when :initial
      if type == :tag
        @state = :tags
        @game = Game.new(pgn_id: self.id)
        @game.add_tag($1, $2)
      end
    when :tags
      if type == :other
        @state = :moves
        @game.add_moves(line)
      elsif type == :tag
        @game.add_tag($1, $2)
      end
    when :moves
      if type == :blank
        check_game_but_dont_raise_error_for_a_duplicate
        self.game_count += 1
        @game = nil
        @state = :initial
      elsif type == :other
        @game.add_moves(line)
      elsif type == :tag
        raise PGNError.new("line #{lines}: tag encountered where blank line or moves expected")
      end
    end
  end

  def check_game_but_dont_raise_error_for_a_duplicate
    if @game.valid?
      if import?
        @game.save!
        self.imports += 1
      end
    else
      if @game.errors.include?(:signature) && @game.signature.to_s.length == 32
        self.duplicates += 1
      else
        raise PGNError.new("line #{lines}: #{@game.errors.full_messages.first || 'Unknown error'}")
      end
    end
  end
end
