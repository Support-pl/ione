require 'json'
require 'digest/md5'

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
    # @!visibility private
    # Crypts all private keys data, such as passwords. Configurable
    def privatize
        result = {}
        self.each do |key, value|
            if value.class == Hash then
                result[key] = value.privatize
                next
            elsif key.private? then
                result[key] = Digest::MD5.hexdigest(Digest::MD5.hexdigest(Digest::MD5.hexdigest(value.to_s)))
            else
                result[key] = value
            end
        end
        result
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

class Array
    def to_sym
        self.map do | el |
            el.to_sym
        end
    end
    def to_sym!
        self.map! do | el |
            el.to_sym
        end
    end
    def get *indexes
        indexes.collect do | index |
            self[index]
        end
    end
    def without(*vals)
        cpy = self.dup
        vals.each do | val |
            cpy.delete(val) 
        end
        cpy
    end
end

# Ruby default String class
class String
    # @!visibility private
    # Checks is key configured as private
    def private?
        result = false
        for key in CONF['PrivateKeys'] do
            result = result || self.include?(key)
        end
        result
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
        a, b, c, d = self.to_s.split('.')
        return (a == '10') || (a == '192' && b == '168') || (a == '172' && (16..31) === b.to_i )
    end
end