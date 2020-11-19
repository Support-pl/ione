# @!visibility private
class CacheStack
  
  include Enumerable
    # Initializer of CacheStack object
    def initialize(num = 5)
      @size = num
      @queue = Array.new
    end
    # Stack iterator
    def each(&blk)
      @queue.each(&blk)
    end
    # Stack pop method
    def pop
      @queue.pop
    end
    # Stack push method
    def push(value)
      @queue.shift if @queue.size >= @size
      @queue.push(value)
    end
    # Stack as array
    def to_a
      @queue.to_a
    end
    # Alias for push
    def <<(value)
      push(value)
    end
    # Reads last object
    def last
        return @queue.last
    end
    # Gets object if include
    def get_if_include(data)
        return (self << @queue.delete(data)).last
    end
    # Returns string array of Stack
    def to_s
        return @queue
    end
    
end 