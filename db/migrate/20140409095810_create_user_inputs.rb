class CreateUserInputs < ActiveRecord::Migration
  def change
    create_table :user_inputs do |t|
      t.integer  :fee_id
      t.string   :type, limit: 40
      t.string   :label, limit: 100
      t.boolean  :required, default: true
      t.integer  :max_length, limit: 2
    end
  end
end
