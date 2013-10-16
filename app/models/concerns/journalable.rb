module Journalable
  extend ActiveSupport::Concern

  included do
    has_many :journal_entries, as: :journalable
  end

  def journal(action, by, ip)
    action = action.to_s.downcase
    if action == "create" || action == "destroy"
      journal_entries.create!(action: action, by: by, ip: ip)
    else
      journalable_columns = self.class.journalable_columns
      previous_changes.each do |column, changes|
        from, to = Util::Diff.new(*changes).difference
        if journalable_columns.include?(column)
          journal_entries.create!(action: action, column: column, from: from, to: to, by: by, ip: ip)
        end
      end
    end
  end

  private

  module ClassMethods
    attr_reader :journalable_columns, :journalable_path

    def journalize(path, opt={})
      @journalable_path = path
      only = Array(opt[:only]).map(&:to_s)
      except = Array(opt[:except]).map(&:to_s).concat(%w[id created_at updated_at])
      @journalable_columns = column_names.each_with_object(Set.new) do |column, columns|
        if only.any?
          if only.include?(column)
            columns << column
          end
        else
          unless except.include?(column)
            columns << column
          end
        end
      end
    end
  end
end
