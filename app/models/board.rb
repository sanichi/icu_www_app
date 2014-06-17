class Board
  attr_reader :rows, :to_move

  # Each of these styles needs some custom CSS in assets/stylesheets/application.css.
  VALID_STYLE = /\A([a-z]+)([1-9]\d)(png|gif|jpe?g)\z/
  STYLES = %w[hce30png]

  def initialize(fen=nil)
    fen = fen.present? ? fen.to_s.trim : "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w"
    raise "invalid board position" unless fen.match(/\A([rnbqkRNBQK1-8]+\/(?:[rnbqkRNBQK1-8pP]+\/){6}[rnbqkRNBQK1-8]+) ([bw])/)
    @rows = []
    rows, @to_move = $1, $2
    rows.split(/\//).each do |row|
      raise "invalid board row (#{row})" unless row.each_char.map{|c| c.match(/\A\d\z/) ? c.to_i : 1}.reduce(&:+) == 8
      @rows.push row
    end
  end

  def to_html(style, opt={})
    style = STYLES.first if style.blank?
    raise "invalid board style" unless style.match(VALID_STYLE)
    size = $2.to_i
    float = case opt[:align]
    when "right"
      "float-right left-margin"
    when "center"
      "float-center"
    else
      "float-left right-margin"
    end
    html = []
    html.push [0, "<table class=\"board #{float} #{style}\">"]
    html.push [1, "<tbody>"]
    @white_square = true
    rows.each_with_index do |pieces, row|
      html.push [2, "<tr>"]
      pieces.split(//).each do |piece|
        if piece.to_i > 0
          piece.to_i.times { html.push [3, cell(piece, size)] }
        else
          html.push [3, cell(piece, size)]
        end
      end
      html.push [2, "</tr>"]
      @white_square = !@white_square
    end
    comment = []
    comment.push to_move == "w" ? "⇧" : "⬇︎"
    comment.push opt[:comment] if opt[:comment].present?
    html.push [2, "<tr>"]
    html.push [3, %Q{<th colspan="8" class="comment small" width="#{8 * size}">#{comment.join(' ')}</th>}]
    html.push [2, "</tr>"]
    html.push [1, "</tbody>"]
    html.push [0, "</table>"]
    "%s\n" % html.map{ |row| "  " * row.first + row.last }.join("\n")
  end

  def expand(opt)
    style = opt.delete(:style)
    to_html(style, opt)
  end

  private

  def cell(piece, size)
    # Calculate the offsets for the relevant portion of the sprite image.
    x = -size                                  # horizontal offset
    x += size unless @white_square             # black or white square
    x += size * 2 unless piece == piece.upcase # black of white piece
    y = size * case piece.downcase             # vertical offset
    when "k" then 7
    when "q" then 6
    when "r" then 5
    when "b" then 4
    when "n" then 3
    when "p" then 2
    else 1
    end
    @white_square = !@white_square # toggle square colour for the next piece
    %Q{<td style="background-position: #{x}px #{y}px"></td>} # the table cell HTML
  end
end
