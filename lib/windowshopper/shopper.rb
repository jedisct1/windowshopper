
require 'windowshopper/store.rb'

module WindowShopper
  class Shopper
    attr_reader :id
    attr_reader :store
    attr_reader :path
    attr_reader :location_id_current
    attr_reader :goal_id_previous

    def initialize(store, id = nil)
      reset
      @id = id
      @store = store
    end

    def reset
      @path = [ ]
      @location_id_current = "(null location)"
      @goal_id_previous = "(null goal)"
    end

    def begin_next_trip_segment(goal_id)
      @goal_id_previous = goal_id
      @location_id_previous = @path.last
      @path = [@location_id_previous]
    end

    def move_to(location_id)
      @path << location_id
      @location_id_current = location_id
    end

    def buy(goal_id)
      store.record_trip_segment_switch(self, goal_id)
      begin_next_trip_segment(goal_id)
    end

    def predict
      store.predict(self)
    end
  end
end
