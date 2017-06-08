require 'active_record'

module Clockwork
  module ActiveRecord
    class Tick < ::ActiveRecord::Base
      self.table_name = 'clockwork_ticks'

      def self.with_last_processed_tick
        transaction do
          last_processed_tick = lock.last
          if last_processed_tick.nil?
            create!(processed_at: Time.zone.now.beginning_of_minute)
          else
            yield(last_processed_tick.processed_at)
          end
        end
      end

      def self.processed(time)
        last.update!(processed_at: time)
      end
    end
  end
end
