require 'json'

puts 'Extending Hash class by out method'
# Ruby default Hash class
class Hash

    # @!group Debug Tools

    # Returns hash as 'pretty generated' JSON String
    def out
        JSON.pretty_generate(self)
    end
    # Returns hash as 'pretty generated' JSON String with replaced JSON(':' to '=>' and 'null' to 'nil')
    def debug_out
        JSON.pretty_generate(self).gsub("\": ", "\" => ").gsub(" => null", " => nil")
    end

    # @!endgroup

    # @!group Dev Tools

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

    # Returns Hash copy without given keys
    def without(*keys)
        cpy = self.dup
        keys.each { |key| cpy.delete(key) }
        cpy
    end
    # Transforms Hash to OpenNebula Template. Only two layers allowed
    # @example VM hash to template
    # {'CPU' => 2, 'DISK' => {'SIZE' => '64'}} ->
    # CPU = "2"
    # DISK = [
    #   SIZE = "64" ]
    def to_one_template
        result = ""
        self.each do | key, value |
            key = key.to_s.upcase
            if value.class == String || value.class == Fixnum then
                result += "#{key}=\"#{value.to_s.gsub("\"", "\\\"")}\"\n"
            elsif value.class == Hash then
                result += "#{key}=[\n"
                size = value.size - 1
                value.each_with_index do | el, i |
                    result += "  #{el[0]}=\"#{el[1].to_s.gsub("\"", "\\\"")}\"#{i == size ? '' : ",\n"}"
                end
                result += " ]\n"
            elsif value.class == Array then
                value.each do | el |
                    result += { key => el }.to_one_template + "\n"
                end
            end
        end
        result.chomp!
    end
    # @!endgroup
end

# Standard Ruby class extensions
class Array
    # @!group Dev Tools
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

    # @!endgroup
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
# Public Gem class IPAddr
class IPAddr
    # Returns true if given IP address is private(10.x.x.x||192.168.x.x||172.(16-31).x.x)
    def local?
        a, b = self.to_s.split('.')[0..1]
        return (a == '10') || (a == '192' && b == '168') || (a == '172' && (16..31) === b.to_i )
    end
    alias private? :local?
end