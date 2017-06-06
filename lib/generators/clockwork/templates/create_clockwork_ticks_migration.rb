class CreateClockworkTicks < ActiveRecord::Migration
  class ClockworkTick < ActiveRecord::Base; end

  def self.up
    create_table :clockwork_ticks, force: true do |table|
      table.datetime :processed_at, null: false
      table.timestamps null: false
    end

    ClockworkTick.create!(processed_at: Time.zone.now.beginning_of_minute)
  end

  def self.down
    drop_table :clockwork_ticks
  end
end
