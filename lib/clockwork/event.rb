module Clockwork
  class Event
    attr_accessor :job

    def initialize(manager, period, job, block, options={})
      validate_if_option(options[:if])
      validate_period_and_at(period, options[:at])
      @manager = manager
      @period = period
      @job = job
      @at = At.parse(options[:at])
      @block = block
      @if = options[:if]
      @thread = options.fetch(:thread, @manager.config[:thread])
      @timezone = options.fetch(:tz, @manager.config[:tz])
    end

    def convert_timezone(t)
      @timezone ? t.in_time_zone(@timezone) : t
    end

    def run_now?(t)
      t = convert_timezone(t)

      (@at.nil? or @at.ready?(t)) and (@if.nil? or @if.call(t))
    end

    def thread?
      @thread
    end

    def run(t)
      @manager.log "Triggering '#{self}'"
      if thread?
        if @manager.thread_available?
          t = Thread.new do
            execute
          end
          t['creator'] = @manager
        else
          @manager.log_error "Threads exhausted; skipping #{self}"
        end
      else
        execute
      end
    end

    def to_s
      job.to_s
    end

    private

    def execute
      @block.call(@job)
    rescue => e
      @manager.log_error e
      @manager.handle_error e, job
    end

    def validate_if_option(if_option)
      if if_option && !if_option.respond_to?(:call)
        raise ArgumentError.new(':if expects a callable object, but #{if_option} does not respond to call')
      end
    end

    def validate_period_and_at(period, at)
      if period == 1.day
        raise ArgumentError.new('must supply at for daily events') if at.nil?
      elsif period == 1.minute
        raise ArgumentError.new('must not supply at for minute events') if at.present?
      else
        raise ArgumentError.new('period must either be 1.day or 1.minute')
      end
    end
  end
end
