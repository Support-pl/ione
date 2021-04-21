########################################################
#       Server control and info-getting methods        #
########################################################

puts 'Extending Handler class by server-info getters'
class IONe
  # Returns current running IONe Cloud Server version
  # @return [String]
  def version
    VERSION
  end

  # Returns IONe Cloud Server uptime(formated)
  # @return [String]
  def uptime
    fmt_time(Time.now.to_i - STARTUP_TIME)
  end

  # Returns whole IONe settings table if user is Admin
  # @return [Hash]
  def get_all_settings
    return @db[:settings].as_hash(:name, :body) if onblock(:u, -1, @client).admin?
  end
end
