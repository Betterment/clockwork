class CreateClockworkTicks < ActiveRecord::Migration
  def self.up
    create_table :clockwork_ticks, force: true do |table|
      table.datetime :processed_at, null: false
      table.boolean :unique, null: false, default: true
      table.timestamps null: false
    end

    add_index :clockwork_ticks, :unique, unique: true
  end

  def self.down
    drop_table :clockwork_ticks
  end
end
