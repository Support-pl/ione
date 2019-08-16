require 'json'

puts 'Extending Hash class by out method'
# Ruby default Hash class
class Hash
    # Returns hash as 'pretty generated' JSON String
    def out
        JSON.pretty_generate(self)
    end
    # Returns hash as 'pretty generated' JSON String with replaced JSON(':' to '=>' and 'null' to 'nil')
    def debug_out
        JSON.pretty_generate(self).gsub("\": ", "\" => ").gsub(" => null", " => nil")
    end
    # Replaces string keys with symbol keys
    # @return [Hash]
    def to_sym!
        self.keys.each do |key| 
            self[key.to_sym] = self.delete key if key.class == String
        end
        self
    end
    # Replaces all keys with string keys
    # @return [Hash]
    def to_s!
        self.keys.each do |key| 
            self[key.to_s] = self.delete key if key.class != String
        end
        self
    end
    # Returns array of values with given keys
    # @param [Array] keys - Array of values
    # @return [Array]
    def get *keys
        keys.collect do | key |
            self[key]
        end
    end

    def without(*keys)
        cpy = self.dup
        keys.each { |key| cpy.delete(key) }
        cpy
    end
end

# Standard Ruby class extensions
class Array
    # Returns Array values converted to Symbol
    def to_sym
        self.map do | el |
            el.to_sym
        end
    end
    # Converts Array values to Symbol
    def to_sym!
        self.map! do | el |
            el.to_sym
        end
    end
    # Returns multiple values of array
    # @param [Array] indexes - Collection of indexes
    def get *indexes
        indexes.collect do | index |
            self[index]
        end
    end
    # Returns Array values without values under given indexes
    def without(*vals)
        cpy = self.dup
        vals.each do | val |
            cpy.delete(val) 
        end
        cpy
    end
end

# Basic class 
class BasicObject
    # Returns objects self
    def itself
     self
    end
end 


puts 'Extending NilClass by add method'
# Ruby default Nil class
class NilClass
    # @!visibility private   
    # Rebind for + method for NilClass 
    def +(obj)
        obj
    end
end

class IPAddr
    def local?
        a, b = self.to_s.split('.')[0..1]
        return (a == '10') || (a == '192' && b == '168') || (a == '172' && (16..31) === b.to_i )
    end
end