require 'json'

if defined?(INIT_IONE) && INIT_IONE then
  begin
    $db.create_table :settings do
      String  :name, size: 128, primary_key: true
      String  :body, text: true, null: false
      String  :description, text: true, null: true
      Integer :access_level, null: false, default: 1
      String  :type, null: false
    end
  rescue
    puts "Table :settings already exists, skipping"
  end

  required = [
    ['ALERT', 0.0, "Balance, when user will be alerted", 0, "float"],
    ['CAPACITY_COST', "{\"CPU_COST\":\"0.0\",\"MEMORY_COST\":\"0.0\"}", "VM Capacity resources costs per sec", 1, "object"],
    ['DISK_TYPES', "HDD,SSD,NVMe", "Comma-separated list of existing disk types", 1, "list"],
    ['DISK_COSTS', "{\"HDD\":0.0,\"SSD\":0.0}", "Costs of different disk types GB/sec", 1, "object"],
    ['IAAS_GROUP_ID', 100, "IaaS(VDC) Users group ID", 1, "int"],
    ['NODES_DEFAULT', "{\"VCENTER\":\"host_id\"}", "Default nodes for different hypervisors", 1, "object"],
    ['VDC_NODES_DEFAULT', "{\"VCENTER\":\"host_id\"}", "Default nodes for different hypervisors for VDC", 1, "object"],
    ['PUBLIC_IP_COST', 0.0, "Public IP Address cost per sec", 0, "float"],
    ['PUBLIC_NETWORK_DEFAULTS', "{\"IAAS\":\"0\", \"PAAS\": \"0\"}", "Default Public Network Pool IDs for IaaS and PaaS", 1, "object"],
    ['CURRENCY_MAIN', "€", "Currency", 0, "str"],
    ['TRAFFIC_COST', 0.0, "Cost of 1 kByte VM traffic", 0, "float"],
    ['TRAFFIC_BILL_FREQ', 86400, "Frequency of debits for Traffic usage in seconds", 1, "int"],
    ['SNAPSHOT_COST', 0.0, "Cost of 1 Snapshot per sec", 0, "float"],
    ['SNAPSHOTS_ALLOWED_DEFAULT', "TRUE", "If set to FALSE VM should have SNAPSHOTS_ALLOWED=TRUE to allow snapshots creation", 1, "bool"],
    ['BACKUP_IMAGE_CONF', "{}", "DataStore IDs to Images(backup drives) mapping", 0, "object"],
    ['BACKUP_IMAGE_COSTS', "{}", "Backup Drives Images prices GB/sec", 1, "object"],
    ['USERS_GROUP', 1, "Main group for PaaS Users", 1, "int"],
    ['TRIAL_SUSPEND_DELAY', 86400, "Delay value for trial VMs in seconds", 1, "int"],
    ['USERS_VMS_SSH_PORT', 22, "Default SSH port at OpenNebula Virtual Machines", 1, "int"],
    ['BASE_VNC_PORT', 5900, "Base VNC-port number", 1, "int"],
    ['USERS_DEFAULT_LANG', "en_US", "Default locale for new users", 1, "str"],
    ['VCENTER_CPU_LIMIT_FREQ_PER_CORE', "{\"default\":2000}", "Frequency per Core limit for different Nodes(don't remove default)", 1, "object"],
    ['VCENTER_DRIVES_IOPS', "{\"HDD\":350,\"SSD\":1000}", "IOPs limits for Drive types", 1, "object"],
    ['VNETS_TEMPLATES', "{}", "VNs Types to VNs Templates mapping(types must be upper case)", 1, "object"],
    ['PRE_PAID_REDUCE_FACTOR', "{\"0\": 1}", "Reduce factor for Pre-Paid VMs depending on billing period", 1, "object"],
    ['ALLOW_USING_SYSTEM_DATASTORES', "FALSE", "Allow using(deploying) on default datastores(id <= 2)", 1, "bool"]
  ]
  required.each do | record |
    begin
      $db[:settings].insert(name: record[0], body: record[1], description: record[2], access_level: record[3], type: record[4])
    rescue Sequel::UniqueConstraintViolation
      $db[:settings].where(name: record[0]).update(description: record[2], access_level: record[3], type: record[4])
    end
  end

  # In case there any custom settings created before splitting num into int and float
  $db[:settings].where(type: 'num').update(type: 'float')
end

class IONe
  # IONe Settings table accessor class
  class Settings < Sequel::Model(:settings)
    # Get Settings value with explicit type casting
    def self.[] name
      rec = first(name: name)
      return nil if rec.nil?

      case rec[:type]
      when "int"
        rec[:body].to_i
      when "float"
        rec[:body].to_f
      when "bool"
        rec[:body] == "TRUE"
      when "list"
        rec[:body].split(',')
      when "str"
        rec[:body]
      else
        JSON.parse rec[:body]
      end
    end

    def self.[]= name, value
      rec = first(name: name)
      return nil if rec.nil?

      to_write =
        case rec[:type]
        when "int"
          value.to_i
        when "float"
          value.to_f
        when "bool"
          value ? 'TRUE' : 'FALSE'
        when "list"
          raise TypeError.new "Record has type 'list', so :value should be Array" if value.class != Array

          value.join(',')
        when "str"
          value.to_s
        else
          JSON.generate value
        end

      where(name: name).update(body: to_write)
      return to_write
    end
  end
end

SETTINGS_TABLE = $db[:settings]
