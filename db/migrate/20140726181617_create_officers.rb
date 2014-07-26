class CreateOfficers < ActiveRecord::Migration
  def up
    create_table :officers do |t|
      t.string  :role, limit: 20
      t.string  :emails
      t.integer :player_id
      t.integer :rank, limit: 1
      t.boolean :executive, default: true

      t.timestamps
    end

    Officer.create!(role: "president", rank: 1, executive: false)
    Officer.create!(role: "chairperson", rank: 2, player_id: 5983)
    Officer.create!(role: "secretary", rank: 3, player_id: 5193)
    Officer.create!(role: "treasurer", rank: 4, player_id: 174)

    Officer.create!(role: "development", rank: 13, player_id: 7214)
    Officer.create!(role: "fide_ecu", rank: 13, player_id: 3000)
    Officer.create!(role: "juniors", rank: 13, player_id: 6141)
    Officer.create!(role: "membership", rank: 13, player_id: 174)
    Officer.create!(role: "publicrelations", rank: 13)
    Officer.create!(role: "ratings", rank: 13, player_id: 1350)
    Officer.create!(role: "tournaments", rank: 13, player_id: 507)
    Officer.create!(role: "vicechairperson", rank: 13, player_id: 507)
    Officer.create!(role: "women", rank: 13, player_id: 3364)

    Officer.create!(role: "connaught", rank: 17, player_id: 12275)
    Officer.create!(role: "leinster", rank: 17)
    Officer.create!(role: "munster", rank: 17, player_id: 13486)
    Officer.create!(role: "ulster", rank: 17)

    Officer.create!(role: "webmaster", rank: 20, executive: false, player_id: 1350)
    Officer.create!(role: "arbitration", rank: 20, executive: false, player_id: 1535)
    Officer.create!(role: "selections", rank: 20, executive: false, player_id: 6844)
  end

  def down
    drop_table :officers
  end
end
