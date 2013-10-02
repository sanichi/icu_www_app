class CreateTranslations < ActiveRecord::Migration
  def change
    create_table :translations do |t|
      t.string   :locale, limit: 2
      t.string   :key, :value, :english, :old_english, :user
      t.boolean  :active

      t.timestamps
    end
  end
end
