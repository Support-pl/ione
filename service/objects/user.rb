# Extensions for OpenNebula::User class
class OpenNebula::User
  # Sets user quota by his existing VMs and/or appends new vm specs to it
  # @param [Hash] spec
  # @option spec [Boolean]      'append'  Set it true if you wish to append specs
  # @option spec [Integer | String] 'cpu'   CPU quota limit to append
  # @option spec [Integer | String] 'ram'   RAM quota limit to append
  # @note Method sets quota to 'used' values by default
  # @return nil
  def update_quota_by_vm(spec = {})
    quota = self.to_hash!['USER']['VM_QUOTA']['VM']
    if quota.nil? then
      quota = Hash.new
    end
    self.set_quota(
      "VM=[
        CPU=\"#{(spec['cpu'].to_i + quota['CPU_USED'].to_i)}\",
        MEMORY=\"#{(spec['ram'].to_i + quota['MEMORY_USED'].to_i)}\",
        SYSTEM_DISK_SIZE=\"#{spec['drive'].to_i + quota['SYSTEM_DISK_SIZE_USED'].to_i}\",
        VMS=\"#{spec['append'].nil? ? quota['VMS_USED'].to_s : (quota['VMS_USED'].to_i + 1).to_s}\" ]"
    )
  end

  # Returns users actual balance
  def balance
    info! || self['TEMPLATE/BALANCE']
  end

  # Sets users balance
  # @param [Integer] num
  def balance= num
    update("BALANCE = #{num}", true)
  end

  # Returns true if user balance is less than user alert point
  def alert
    alert_at = (info! || self['TEMPLATE/ALERT']) || IONe::Settings['ALERT']
    return balance.to_f <= alert_at.to_f, alert_at.to_f
  end

  # Sets users alert point
  def alert= at
    update("ALERT = #{at}", true)
  end

  # Returns users VMs objects array
  # @return [Array<OpenNebula::VirtualMachine>]
  def vms db
    db[:vm_pool].where(uid: @pe_id).exclude(:state => 6).select(:oid).to_a.map { |row| onblock(:vm, row[:oid]) { |vm| vm.info! || vm } }
  rescue
    nil
  end

  # Returns users VNets objects array
  # @return [Array<OpenNebula::VirtualNetwork>]
  def vns db
    db[:network_pool].where(uid: @pe_id).select(:oid).to_a.map { |row| onblock(:vn, row[:oid]) { |vn| vn.info! || vn } }
  end

  # Returns users VNets being billed
  def billable_vns
    AR.where(owner: @pe_id, etime: nil).all
  end

  # Calculates VNs Showback
  # @param [Integer] stime_req - Point from which calculation starts(timestamp)
  # @param [Integer] etime_req - Point at which calculation stops(timestamp)
  # @return [Hash]
  def calculate_networking_showback stime_req, etime_req
    raise ShowbackError, ["Wrong Time-period given", stime_req, etime_req] if stime_req >= etime_req

    info!

    vnp = AR.where(owner: @pe_id).where { (etime == nil) | (etime >= etime_req) }.all

    vnp.inject({ 'TOTAL' => 0 }) do | showback, rec |
      first = rec.stime

      stime, etime = stime_req, etime_req

      stime = rec.stime if rec.stime > stime
      etime = rec.etime if !rec.etime.nil? && rec.etime < etime

      stime   = Time.at(stime).to_datetime
      current = Time.at(first).to_datetime
      etime   = Time.at(etime).to_datetime

      while current < stime do
        current = current >> 1
      end

      periods = 0
      while current <= etime do
        periods += 1
        current = current >> 1
      end

      ip, r = onblock(:vn, rec.vnid).ar_record(rec.arid, periods)

      if showback[ip].nil? then
        showback[ip] = r
      else
        showback[ip] += r
      end

      showback['TOTAL'] += r
      showback
    end
  end

  # Checks if user exists
  def exists?
    info! == nil
  end

  # Returns User sunstone language
  def lang
    info! || self['//LANG']
  end

  # Sets User sunstone language
  # @param [String] l - lang code, like en_US/ru_RU/etc
  def lang= lang
    sunstone = to_hash!['USER']['TEMPLATE']['SUNSTONE']
    sunstone['LANG'] = lang

    update({ "SUNSTONE" => sunstone }.to_one_template, true)
  end

  # Checks if user is admin
  # @note Admin means user is a part of oneadmin group
  # @return [Boolean]
  def admin?
    info!
    (groups << gid).include? 0
  rescue
    false
  end
  alias :is_admin? :admin?
  alias :is_admin  :admin?

  # User doesn't exist Exception object
  class UserNotExistsError < StandardError
    def initialize msg = "User not exists or error occurred while getting user."
      super
    end
  end

  # Error while processing(calculating) showback Exception
  class ShowbackError < StandardError
    attr_reader :params

    def initialize params = []
      @params = params[1...params.length]
      super "#{params[0]}\nParams:#{@params.inspect}"
    end
  end
end
