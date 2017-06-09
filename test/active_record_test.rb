require File.expand_path('../../lib/clockwork', __FILE__)
require 'active_support/time'
require 'minitest/autorun'
require 'timecop'

describe Clockwork::ActiveRecord::Tick do
  before do
    Time.zone = 'Eastern Time (US & Canada)'
    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database => ':memory:'
    )

    ActiveRecord::Schema.define do
      self.verbose = false

      create_table :clockwork_ticks, force: true do |t|
        t.datetime :processed_at, null: false
      end
    end

    Timecop.freeze(Time.zone.parse("2015-05-01 10:00:30"))
  end

  after do
    Timecop.return
  end

  describe 'when there is no existing tick' do
    it 'creates the tick and assumes the current minute has already been processed' do
      run = false
      Clockwork::ActiveRecord::Tick.process_tick do
        run = true
      end

      refute run

      tick = Clockwork::ActiveRecord::Tick.last
      refute tick.nil?
      assert_equal Time.zone.parse("2015-05-01 10:00:00").utc, tick.processed_at
    end
  end

  describe 'when the existing tick was processed less than a minute ago' do
    before do
      Clockwork::ActiveRecord::Tick.create!(processed_at: Time.zone.parse('2015-05-01 10:00:00'))
    end

    it 'does not yield or update the existing tick' do
      run = false
      Clockwork::ActiveRecord::Tick.process_tick do
        run = true
      end

      refute run
      assert_equal Time.zone.parse("2015-05-01 10:00:00").utc, Clockwork::ActiveRecord::Tick.last.processed_at
    end
  end

  describe 'when the existing tick was processed more than a minute ago' do
    before do
      Clockwork::ActiveRecord::Tick.create!(processed_at: Time.zone.parse('2015-05-01 09:00:00'))
    end

    it 'yields and updates the existing tick' do
      run = false
      Clockwork::ActiveRecord::Tick.process_tick do
        run = true
      end

      assert run
      assert_equal Time.zone.parse("2015-05-01 10:00:00").utc, Clockwork::ActiveRecord::Tick.last.processed_at
    end
  end
end
