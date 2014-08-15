class SalesLedger
  attr_reader :seasons, :stats, :unclassified

  TYPES = %w[subscription entry other total]

  class Counter
    attr_reader :count, :total

    def initialize
      @count = 0
      @total = 0.0
    end

    def add(item)
      @count += 1
      @total += item.cost
    end
  end

  def initialize
    get_seasons
    init_stats
    process_items
  end

  private

  def get_seasons
    season = Season.new
    season = season.next if Date.today.month == 8
    @seasons = []
    10.times do |i|
      @seasons.push season.to_s
      break if season.to_s == "2006-07"
      season = season.last
    end
  end

  def init_stats
    @stats = {}
    TYPES.each do |type|
      @stats[type] = {}
      seasons.each do |season|
        @stats[type][season] = Counter.new
      end
    end
    @unclassified = Counter.new
  end

  def process_items
    Item.active.where.not(cost: nil).each do |item|
      type, season = classify(item)
      if type && season
        if seasons.include?(season)
          stats[type][season].add(item)
          stats["total"][season].add(item)
        end
      else
        unclassified.add(item)
      end
    end
  end
  
  def classify(item)
    type = item.subtype
    type = nil unless TYPES.include?(type) && type != "total"
    season = item.season
    if season
      if season.error.present?
        season = nil
      else
        season = season.to_s
      end
    end
    [type, season]
  end
end
