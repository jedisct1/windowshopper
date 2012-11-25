
require 'windowshopper/node'

module WindowShopper
  class Goal < Node
    def self.type
      :goal
    end
  end

  class Location < Node
    def self.type
      :location
    end
  end

  class Store
    attr_reader :id

    def initialize(id = nil)
      @id = id
      @locations = Location.new("(locations)")
      location = @locations.get(Location, "(null location)")
      location.weight = 0
      @locations.add_edge(location)
      @goals = Goal.new("(goals)")
      goal = @goals.get(Goal, "(null goal)")
      goal.weight = 0
      @goals.add_edge(goal)
    end

    def record_trip_segment_switch(shopper, goal_id)
      goal_previous_node = @goals.get(Goal, shopper.goal_id_previous)
      goal_previous_node.add_edge(goal_previous_node.get(Goal, goal_id))
      new_node = @goals.get(Goal, goal_id)
      @goals.add_edge(new_node)
      previous_edge = new_node.get(Goal, shopper.goal_id_previous)
      previous_edge.weight = 0 if previous_edge.id == "(null goal)"
      new_node.add_edge(previous_edge)

      shopper.path.each do |location_id|
        location_node = @locations.get(Location, location_id)
        @locations.add_edge(location_node)
        goal_node = location_node.get(Goal, goal_id)
        location_node.add_edge(goal_node)

        shopper.path.each do |location_id_next|
          next if location_id == location_id_next
          location_node.add_edge(location_node.get(Location, location_id_next))
        end
      end
    end

    def dump_network
      @locations.dump_network
      @goals.dump_network
    end

    def predict_first_time_slice(shopper)
      l0_id = shopper.location_id_current
      g0_id = shopper.goal_id_previous
      goals = @goals.get(Goal, g0_id).all_for_class(Goal)

# p(l1|g1,l0) ~= p(l1)p(g1|l1)p(l0|l1)

      l1_ps = { }
      goals.each do |g1|
        l1s = @locations.get(Location, shopper.location_id_current).
        all_for_class(Location)
        l1s.each do |l1|
          next if l1.id == l0_id
          p_l0_l1 = @locations.get(Location, l1.id).get(Location, l0_id).p
          p_g1_l1 = @locations.get(Location, l1.id).get(Goal, g1.id).p
          p_l1 = @locations.get(Location, l1.id).p
          p_l1_g1l0 = p_l1 * p_g1_l1 * p_l0_l1
          l1_ps[l1.id] = (l1_ps[l1.id] || 0.0) + p_l1_g1l0
        end
      end

      l1_p_max = l1_ps.values.max
      l1_argmax = l1_ps.select { |id, p| p >= l1_p_max }.keys

# p(g1|g0,l0,l1) ~= p(g1)p(g0|g1)p(l0|g1)p(l1|g1)
# p(g1|g0,l0,l1) ~= p(l1|g1,l0)p(g1|g0) ~= p(l1)p(g1|l1)p(l0|l1)p(g1|g0)

      g1_ps = { }
      goals = @goals.get(Goal, g0_id).all_for_class(Goal)
      goals.each do |g1|
        next if g1.id == g0_id || g1.weight == 0
        l1s = @locations.get(Location, shopper.location_id_current).
        all_for_class(Location)
        l1s.each do |l1|
          p_g1_g0 = g1.p
          p_l0_l1 = @locations.get(Location, l1.id).get(Location, l0_id).p
          p_g1_l1 = @locations.get(Location, l1.id).get(Goal, g1.id).p
          p_l1 = @locations.get(Location, l1.id).p
          p_g1_g0l0l1 = p_l1 * p_g1_l1 * p_l0_l1 * p_g1_g0
          g1_ps[g1.id] = (g1_ps[g1.id] || 0.0) + p_g1_g0l0l1
        end
      end

      g1_p_max = g1_ps.values.max
      g1_argmax = g1_ps.select { |id, p| p >= g1_p_max }.keys

      { locations: l1_argmax, goals: g1_argmax }
    end

    def predict_next_time_slices(shopper)
      l0_id = shopper.location_id_current
      g0_id = shopper.goal_id_previous

# p(ln|g1,l0,...,l(n-1)) ~= p(ln)p(g1|ln)p(l0|ln)...p(l(n-1)|ln)

      ln_ps = { }
      locations = @locations.get(Location, l0_id).all_for_class(Location)
      locations.each do |ln|
        next if ln.id == l0_id
        g1_ids = shopper.path.collect do |location_id|
          @locations.get(Location, location_id).all_for_class(Goal).
          map { |g| g.id }
        end.flatten.uniq
        g1_ids.each do |g1_id|
          pi = 1.0
          shopper.path.each do |location_id|
            p_lx_ln = @locations.get(Location, ln.id).
            get(Location, location_id).p
            pi *= p_lx_ln
          end
          p_g1_ln = @locations.get(Location, ln.id).get(Goal, g1_id).p
          p_ln = ln.p
          p_ln_g1lxx = p_ln * p_g1_ln * pi
          ln_ps[ln.id] = (ln_ps[ln.id] || 0.0) + p_ln_g1lxx
        end
      end

      ln_p_max = ln_ps.values.max
      ln_argmax = ln_ps.select { |id, p| p >= ln_p_max }.keys

# p(g1|g0,l0,...,l(n-1)) ~= p(g1)p(g0|g1)p(l0|g1)...p(l(n-1)|g1)
# with p(lx|g1) ~= p(lx)p(g1|lx)/p(g1)

      g1_ps = { }
      goals = @goals.get(Goal, g0_id).all_for_class(Goal)
      goals.each do |g1|
        next if g1.id == g0_id || g1.weight == 0
        pi = 1.0
        shopper.path.each do |location_id|
          p_g1 = @goals.get(Goal, g1.id).p
          next if p_g1 <= 0.0
          p_g1_lx = @locations.get(Location, location_id).get(Goal, g1.id).p
          p_lx = @locations.get(Location, location_id).p
          p_lx_g1 = p_lx * p_g1_lx / p_g1
          pi *= p_lx_g1
        end
        p_g0_g1 = @goals.get(Goal, g0_id).get(Goal, g1.id).p
        p_g1 = @goals.get(Goal, g1.id).p
        p_g1_g0lxx = p_g1 * p_g0_g1 * pi
        g1_ps[g1.id] = (g1_ps[g1.id] || 0.0) + p_g1_g0lxx
      end

      g1_p_max = g1_ps.values.max
      g1_argmax = g1_ps.select { |id, p| p >= g1_p_max }.keys

      { locations: ln_argmax, goals: g1_argmax }
    end

    def predict(shopper)
      shopper.path.length <= 1 ?
        predict_first_time_slice(shopper) : predict_next_time_slices(shopper)
    end

    def new_shopper(id = nil)
      Shopper.new(self, id)
    end
  end

  def self.store(id = nil)
    Store.new(id)
  end

  def self.shopper(store, id = nil)
    Shopper.new(store, id)
  end
end
