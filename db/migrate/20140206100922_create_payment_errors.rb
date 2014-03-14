class CreatePaymentErrors < ActiveRecord::Migration
  def change
    create_table :payment_errors do |t|
      t.integer  :kart_id
      t.string   :message, :details
      t.string   :payment_name, limit: 100
      t.string   :confirmation_email, limit: 50

      t.datetime :created_at
    end
  end
end
