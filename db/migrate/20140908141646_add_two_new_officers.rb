class AddTwoNewOfficers < ActiveRecord::Migration
  def up
    Officer.create!(role: "fide", rank: 13, executive: true, active: false)
    Officer.create!(role: "ecu", rank: 13, executive: true, active: false)
  end

  def down
    Officer.where(role: %w[fide ecu]).each { |o| o.destroy }
  end
end
