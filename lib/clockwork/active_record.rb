require 'active_record'

module Clockwork
  module ActiveRecord
    class Tick < ::ActiveRecord::Base
      self.table_name = 'clockwork_ticks'

      def self.process_tick
        transaction do
          last_processed_tick = lock.last
          current_minute = Time.zone.now.beginning_of_minute

          if last_processed_tick.nil?
            create!(processed_at: Time.zone.now.beginning_of_minute)
          elsif current_minute - last_processed_tick.processed_at >= 1.minute
            yield(current_minute, last_processed_tick.processed_at)
            last_processed_tick.update!(processed_at: current_minute)
          end
        end
      end
    end
  end
end
