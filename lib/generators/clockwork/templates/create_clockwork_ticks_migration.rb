class CreateClockworkTicks < ActiveRecord::Migration
  def self.up
    create_table :clockwork_ticks, force: true do |table|
      table.datetime :processed_at, null: false
      table.timestamps null: false
    end

    execute <<-SQL
      INSERT INTO clockwork_ticks (processed_at, created_at, updated_at)
      VALUES ('#{Time.zone.now.beginning_of_minute.to_s(:db)}', '#{Time.zone.now.to_s(:db)}', '#{Time.zone.now.to_s(:db)}')
    SQL
  end

  def self.down
    drop_table :clockwork_ticks
  end
end
