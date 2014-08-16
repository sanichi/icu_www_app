class SalesLedger
  attr_reader :seasons, :items, :bad_items, :subs, :bad_subs, :other_subs

  ITEM_TYPES = %w[subscription entry other total]
  SUB_TYPES = ["Standard", "Over 65", "Under 18", "Under 12", "New U18", "Overseas", "Unemployed", "Other", "Total"]

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

    def inc
      @count += 1
    end
  end

  def initialize
    get_seasons
    init_counters
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

  def init_counters
    @items = {}
    ITEM_TYPES.each do |type|
      @items[type] = {}
      seasons.each do |season|
        @items[type][season] = Counter.new
      end
    end
    @bad_items = Counter.new

    @subs = {}
    SUB_TYPES.each do |type|
      @subs[type] = {}
      seasons.each do |season|
        @subs[type][season] = Counter.new
      end
    end
    @bad_subs = Counter.new
    @other_subs = Counter.new
  end

  def process_items
    Item.active.where.not(cost: nil).each do |item|
      type, season, sub_type = classify(item)
      if type && season
        if seasons.include?(season)
          items[type][season].add(item)
          items["total"][season].add(item)
          if sub_type
            subs[sub_type][season].inc
            subs["Total"][season].inc
            other_subs.inc if sub_type == "Other"
          end
        end
      else
        bad_items.add(item)
        bad_subs.inc if sub_type
      end
    end
  end

  def classify(item)
    type = item.subtype
    type = nil unless ITEM_TYPES.include?(type) && type != "total"
    season = item.season
    if season
      if season.error.present?
        season = nil
      else
        season = season.to_s
      end
    end
    if type == "subscription"
      sub_type = item.subscription_type
      unless SUB_TYPES.include?(sub_type) && type != "Total"
        sub_type = "Other"
      end
    else
      sub_type = nil
    end
    [type, season, sub_type]
  end
end
