require 'json'

puts 'Extending Hash class'
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

  # Replaces string keys with Symbol keys
  # @return [Hash]
  def to_sym!
    self.keys.each do |key|
      self[key.to_sym] = self.delete key if key.class == String
    end
    self
  end

  # Replaces all keys with String keys
  # @return [Hash]
  def to_s!
    self.keys.each do |key|
      self[key.to_s] = self.delete key if key.class != String
      if self[key.to_s].class == Hash then
        self[key.to_s].to_s!
      end
    end
    self
  end

  # Converts all keys to Integer
  # @return [Hash]
  def keys_to_i!
    self.keys.each do |key|
      self[key.to_i] = self.delete key if key.class != Integer
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
      if value.class == String || value.class == Integer then
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
    result.nil? ? "" : result
  end

  # Generate Hash from ONe template string
  def self.from_one_template tmpl
    lines = tmpl.split("\n")
    res, i = {}, 0
    while i < lines.length do
      raise StandardError.new("Template Syntax Error: Bracket isn't paired") if lines[i].nil?

      puts i, lines[i]
      line = lines[i]
      key, value = line.split("=").map { | el | el.strip }
      if value != '[' then
        res[key] = value[1...(value.length - 1)]
      else
        res[key] = {}
        i += 1
        until lines[i].strip == ']' do
          raise StandardError.new("Template Syntax Error: Bracket isn't paired") if lines[i].nil?

          puts i, lines[i]
          line = lines[i]
          sub_key, value = line.split("=").map { | el | el.strip }
          value.delete_suffix! ','
          puts value, value.length
          res[key][sub_key] = value[1...(value.length - 1)]
          i += 1
        end
      end
      i += 1
    end
    res
  end

  # Generic #merge method better version
  def deep_merge(second)
    merger = proc { | _, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end

  # @!endgroup
end

puts 'Extending Array class'

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
  def +(other)
    other
  end
end

# Public Gem class IPAddr
class IPAddr
  # Returns true if given IP address is private(10.x.x.x||192.168.x.x||172.(16-31).x.x)
  def local?
    a, b = self.to_s.split('.')[0..1]
    return (a == '10') || (a == '192' && b == '168') || (a == '172' && (16..31) === b.to_i)
  end
  alias private? :local?
end

class String
  # Copy of OpenNebula VCenterDriver::FileHelper
  def sanitize
    text = self.clone
    # Bad as defined by wikipedia:
    # https://en.wikipedia.org/wiki/Filename in
    # Reserved_characters_and_words
    # Also have to escape the backslash
    bad_chars = ['/', '\\', '?', '%', '*', ':',
                 '|', '"', '<', '>', '.', ' ']
    bad_chars.each do |bad_char|
      text.gsub!(bad_char, '_')
    end
    text
  end
end
