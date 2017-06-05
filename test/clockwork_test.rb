require File.expand_path('../../lib/clockwork', __FILE__)
require 'minitest/autorun'
require 'mocha/setup'
require 'timecop'
require 'pry'

describe Clockwork do
  before do
    @log_output = StringIO.new
    Clockwork.configure do |config|
      config[:sleep_timeout] = 0
      config[:logger] = Logger.new(@log_output)
      config[:time_zone] = 'Eastern Time (US & Canada)'
    end

    ActiveRecord::Base.establish_connection(
      :adapter => 'sqlite3',
      :database => ':memory:'
    )

    ActiveRecord::Schema.define do
      self.verbose = false

      create_table :clockwork_ticks, :force => true do |t|
        t.datetime :processed_at, null: false
      end
    end

    Timecop.freeze(Time.zone.parse("2015-05-01 10:00:30"))
  end

  after do
    Timecop.return
    Clockwork.clear!
  end

  describe 'when there are no recorded runs' do
    it 'should raise an error' do
      run = false
      Clockwork.handler do |job|
        run = job == 'myjob'
      end
      Clockwork.every(1.minute, 'myjob')
      Clockwork.manager.expects(:loop).yields.then.returns

      assert_raises(RuntimeError, 'Could not determine the last processed tick') { Clockwork.run }
      refute run
    end
  end

  describe 'when it has been less than a minute since the last recorded run' do
    before do
      Clockwork::ActiveRecord::Tick.create!(processed_at: Time.zone.parse('2015-05-01 10:00:00'))
    end

    it 'should not execute any handlers' do
      run = false
      Clockwork.handler do |job|
        run = job == 'myjob'
      end
      Clockwork.every(1.minute, 'myjob')
      Clockwork.manager.expects(:loop).yields.then.returns
      Clockwork.run

      refute run
    end
  end

  describe 'when it has been more than a minute since the last recorded run' do
    before do
      Clockwork::ActiveRecord::Tick.create!(processed_at: Time.zone.parse('2015-05-01 09:58:00'))
    end

    it 'should execute events and warn about the missing tick' do
      run = false
      Clockwork.handler do |job|
        run = job == 'myjob'
      end
      Clockwork.every(1.minute, 'myjob')
      Clockwork.manager.expects(:loop).yields.then.returns
      Clockwork.run

      assert run
      assert @log_output.string.include?('More than 1 minute has elapsed between recorded ticks')
    end
  end

  describe 'when there are multiple processes running' do
    before do
      Clockwork::ActiveRecord::Tick.create!(processed_at: Time.zone.parse('2015-05-01 09:59:00'))
    end

    it 'should only execute the handler once' do
      run_count = 0
      Clockwork.handler do |job|
        run_count += 1 if job == 'myjob'
      end
      Clockwork.every(1.minute, 'myjob')
      Clockwork.manager.expects(:loop).times(3).yields.then.returns
      3.times { Clockwork.run }

      assert_equal 1, run_count
    end
  end

  describe 'when it has been one minute since the last recorded run' do
    before do
      Clockwork::ActiveRecord::Tick.create!(processed_at: Time.zone.parse('2015-05-01 09:59:00'))
    end

    it 'should run events with configured logger' do
      run = false
      Clockwork.handler do |job|
        run = job == 'myjob'
      end
      Clockwork.every(1.minute, 'myjob')
      Clockwork.manager.expects(:loop).yields.then.returns
      Clockwork.run

      assert run
      assert @log_output.string.include?('Triggering')
    end

    it 'should log event correctly' do
      run = false
      Clockwork.handler do |job|
        run = job == 'an event'
      end
      Clockwork.every(1.minute, 'an event')
      Clockwork.manager.expects(:loop).yields.then.returns
      Clockwork.run
      assert run
      assert @log_output.string.include?("Triggering 'an event'")
    end

    it 'should pass event without modification to handler' do
      event_object = Object.new
      run = false
      Clockwork.handler do |job|
        run = job == event_object
      end
      Clockwork.every(1.minute, event_object)
      Clockwork.manager.expects(:loop).yields.then.returns
      Clockwork.run
      assert run
    end

    it 'should not run anything after reset' do
      Clockwork.every(1.minute, 'myjob') {  }
      Clockwork.clear!
      Clockwork.configure do |config|
        config[:sleep_timeout] = 0
        config[:logger] = Logger.new(@log_output)
      end
      Clockwork.manager.expects(:loop).yields.then.returns
      Clockwork.run
      assert @log_output.string.include?('0 events')
    end

    it 'should pass all arguments to every' do
      Clockwork.every(1.second, 'myjob', if: lambda { |_| false }) {  }
      Clockwork.manager.expects(:loop).yields.then.returns
      Clockwork.run
      assert @log_output.string.include?('1 events')
      assert !@log_output.string.include?('Triggering')
    end

    it 'should update the processed_at timestamp' do
      run = false
      Clockwork.handler do |job|
        run = job == 'myjob'
      end
      Clockwork.every(1.minute, 'myjob')
      Clockwork.manager.expects(:loop).yields.then.returns
      Clockwork.run

      assert run
      assert_equal Time.zone.parse("2015-05-01 10:00:00").utc, Clockwork::ActiveRecord::Tick.last.processed_at
    end

    it 'support module re-open style' do
      $called = false
      module ::Clockwork
        every(1.second, 'myjob') { $called = true }
      end
      Clockwork.manager.expects(:loop).yields.then.returns
      Clockwork.run
      assert $called
    end
  end
end
