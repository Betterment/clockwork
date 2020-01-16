require File.expand_path('../../lib/clockwork', __FILE__)
require "minitest/autorun"

describe Clockwork::Event do
  describe '#thread?' do
    before do
      @manager = Class.new
    end

    describe 'manager config thread option set to true' do
      before do
        @manager.stubs(:config).returns({ :thread => true })
      end

      it 'is true' do
        event = Clockwork::Event.new(@manager, 1.minute, nil, nil)
        assert_equal true, event.thread?
      end

      it 'is false when event thread option set' do
        event = Clockwork::Event.new(@manager, 1.minute, nil, nil, :thread => false)
        assert_equal false, event.thread?
      end
    end

    describe 'manager config thread option not set' do
      before do
        @manager.stubs(:config).returns({})
      end

      it 'is true if event thread option is true' do
        event = Clockwork::Event.new(@manager, 1.minute, nil, nil, :thread => true)
        assert_equal true, event.thread?
      end
    end
  end

  describe '#run_now?' do
    before do
      @manager = Class.new
      @manager.stubs(:config).returns({})
    end

    describe 'when event is run every minute' do
      before do
        @event = Clockwork::Event.new(@manager, 1.minute, nil, nil)
      end

      it 'returns true' do
        assert_equal true, @event.run_now?(Time.now)
      end
    end

    describe 'when the event is run every day' do
      before do
        @event = Clockwork::Event.new(@manager, 1.day, nil, nil, at: '16:00')
      end
      it 'runs at specified time' do
        assert_equal true, @event.run_now?(Time.parse('16:00'))
        assert_equal false, @event.run_now?(Time.parse('15:59'))
        assert_equal false, @event.run_now?(Time.parse('16:01'))
      end
    end

    describe 'during daylight savings' do
      before do
        Time.zone = 'Eastern Time (US & Canada)'
        @manager.stubs(:config).returns(tz: 'Eastern Time (US & Canada)')
        @manager.stubs(:log).returns(nil)
        @event = Clockwork::Event.new(@manager, 1.day, nil, ->(_) { }, at: '16:00')
      end

      it 'runs at specified time' do
        Timecop.freeze(Time.parse('2019-03-09')) do
          @event.run(Time.zone.parse('16:00'))
        end

        Timecop.freeze(Time.parse('2019-03-10')) do
          assert_equal true, @event.run_now?(Time.zone.parse('16:00'))
        end
      end
    end
  end
end
