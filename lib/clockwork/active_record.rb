require 'active_record'
require 'active_support/time'

module Clockwork
  module ActiveRecord
    class Tick < ::ActiveRecord::Base
      TIME_INTERVAL = 1.minute
      self.table_name = 'clockwork_ticks'

      class << self
        def process_tick
          raise NoHandlerDefined unless block_given?

          transaction do
            last_processed_tick = lock.last
            current_minute = current_time.beginning_of_minute

            if last_processed_tick.nil?
              create!(processed_at: current_minute)
            elsif current_minute - last_processed_tick.processed_at >= TIME_INTERVAL
              yield(current_minute, last_processed_tick.processed_at)
              last_processed_tick.update!(processed_at: current_minute)
            end
          end
        end

        private

        def current_time
          if Clockwork.manager.config[:tz]
            Time.now.in_time_zone(Clockwork.manager.config[:tz])
          else
            Time.now
          end
        end
      end
    end
  end
end
