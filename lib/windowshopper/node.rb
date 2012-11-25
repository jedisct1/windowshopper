
module WindowShopper
  class Node
    attr_accessor :count
    attr_accessor :p
    attr_accessor :weight
    attr_reader   :children
    attr_reader   :children_total
    attr_reader   :id

    def initialize(id)
      @count = 0
      @p = 0.0
      @weight = 1
      @children = { }
      @children_total = { }
      @id = id
    end

    def type
      self.class::type
    end

    def get(klass, id)
      @children[klass.type] ||= { }
      @children[klass.type][id] || klass.new(id)
    end

    def add_edge(child)
      type = child.class::type
      @children_total[type] ||= 0
      @children_total[type] += child.weight
      @children[type][child.id] ||= child
      @children[type][child.id].count += child.weight
      @children[type].each_value do |child|
        child.p = child.count.to_f / @children_total[type].to_f
      end
    end

    def all_for_class(klass)
      @children[klass::type].values
    end

    def dump_network(level = 0)
      puts ("  " * level) + "- [#{@id}] <#{type}> (count=#{@count}, p=#{@p})"
      @children.each_value do |children_for_type|
        children_for_type.each_value do |child|
          child.dump_network(level + 1)
        end
      end
    end
  end
end
