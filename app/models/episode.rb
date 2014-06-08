class Episode < ActiveRecord::Base
  belongs_to :article
  belongs_to :series

  default_scope { order(:number) }

  before_validation :accomodate_new_number
  after_destroy :squash_old_numbers

  validates :article_id, numericality: { integer_only: true, greater_than: 0 }, uniqueness: { scope: :series_id }
  validates :series_id, numericality: { integer_only: true, greater_than: 0 }, uniqueness: { scope: :article_id }
  validates :number, numericality: { integer_only: true, greater_than: 0 }, uniqueness: { scope: :series_id }

  private

  def accomodate_new_number
    return unless new_record?
    max = series.max_number

    if number.blank? || number <= 0 || number > max
      self.number = max + 1
    elsif number <= max
      series.episodes.each do |episode|
        if episode.number >= number
          episode.update_column(:number, episode.number + 1)
        end
      end
    end
  end

  def squash_old_numbers
    series.episodes.each do |episode|
      if episode.number > number
        episode.update_column(:number, episode.number - 1)
      end
    end
  end
end
