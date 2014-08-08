module Util
  class Cleanup
    # How old a cart has to be in days before being eligible for cleanup.
    EMPTY = 1
    UNPAID = 30

    # Width of stats display.
    WIDTH = 40

    def stats
      puts "Carts"
      puts "-----"
      format("total", get_total_carts)
      format("items", get_total_items)
      empty, old_empty = get_empty
      format("empty", empty)
      format("empty for over #{EMPTY} #{'day'.pluralize(EMPTY)}", old_empty.count)
      unpaid, old_unpaid = get_unpaid
      format("unpaid", unpaid)
      format("unpaid for over #{UNPAID} #{'day'.pluralize(UNPAID)}", old_unpaid.count)
    end

    def empty(force=false)
      empty, old_empty = get_empty
      destroy(old_empty, force, :empty)
    end

    def unpaid(force=false)
      unpaid, old_unpaid = get_unpaid
      destroy(old_unpaid, force, :unpaid)
    end

    private

    def destroy(gonners, force=false, type)
      if force
        puts "cleanup #{type} carts #{Time.now.to_s(:db)}"
        if gonners.any?
          format("total carts before", get_total_carts)
          format("total items before", get_total_items)
          gonners.each { |c| c.destroy }
          format("carts destroyed", gonners.size)
          format("total carts after", get_total_carts)
          format("total items after", get_total_items)
        else
          puts "no carts eligible to be cleaned up"
        end
      else
        puts "would destroy #{gonners.count} #{'cart'.pluralize(gonners.count)} if force were used"
      end
    end

    def get_total_carts
      Cart.count
    end

    def get_total_items
      Item.where(source: "www2").count
    end

    def get_empty
      all = Cart.unpaid.include_items.select { |c| c.items.empty? }
      del = all.select{ |c| c.updated_at < EMPTY.days.ago }
      [all.count, del]
    end

    def get_unpaid
      all = Cart.unpaid.include_items.select { |c| c.items.any? }
      del = all.select{ |c| c.updated_at < UNPAID.days.ago }
      [all.count, del]
    end

    def format(text, number)
      length = text.length
      dots = length >= WIDTH ? "" : "." * (WIDTH - length)
      puts "#{text} #{dots} #{number}"
    end
  end
end
