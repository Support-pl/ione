require 'json'

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
  required = [
    ['ALERT', "0.0", "Balance, when user will be alerted", 0, "float"],
    ['CAPACITY_COST', "{\"CPU_COST\":\"0.0\",\"MEMORY_COST\":\"0.0\"}", "VM Capacity resources costs per sec", 1, "object"],
    ['DISK_TYPES', "HDD,SSD,NVMe", "Comma-separated list of existing disk types", 1, "list"],
    ['DISK_COSTS', "{\"disk_type\":\"price\"}", "Costs of different disk types GB/sec", 1, "object"],
    ['IAAS_GROUP_ID', 'iaas_group_id', "IaaS(VDC) Users group ID", 1, "int"],
    ['NODES_DEFAULT', "{\"hypervisor_name\":\"host_id\"}", "Default nodes for different hypervisors", 1, "object"],
    ['PUBLIC_IP_COST', "0.0", "Public IP Address cost per sec", 0, "float"],
    ['PUBLIC_NETWORK_DEFAULTS', "{\"NETWORK_ID\":\"network_id\"}", "Default Public Network Pool ID", 1, "object"],
    ['PRIVATE_NETWORK_DEFAULTS', "{\"NETWORK_ID\":\"network_id\"}", "Default Private Network Pool ID", 1, "object"],
    ['CURRENCY_MAIN', "€", "Currency", 0, "str"],
    ['TRAFFIC_COST', "0.0", "Cost of 1 kByte VM traffic", 0, "float"],
    ['TRAFFIC_BILL_FREQ', "86400", "Frequency of debits for Traffic usage in seconds", 1, "int"],
    ['SNAPSHOT_COST', "0.0", "Cost of 1 Snapshot per sec", 0, "float"],
    ['SNAPSHOTS_ALLOWED_DEFAULT', "TRUE", "If set to FALSE VM should have SNAPSHOTS_ALLOWED=TRUE to allow snapshots creation", 1, "bool"],
    ['BACKUP_IMAGE_CONF', "{}", "DataStore IDs to Images(backup drives) mapping", 0, "object"],
    ['BACKUP_IMAGE_COSTS', "{}", "Backup Drives Images prices GB/sec", 1, "object"]
  ]
  required.each do | record |
    begin
      $db[:settings].insert(name: record[0], body: record[1], description: record[2], access_level: record[3], type: record[4])
    rescue Sequel::UniqueConstraintViolation
      nil # Key already exists
    end
  end
end if defined?(INIT_IONE) && INIT_IONE

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
  end
end

SETTINGS_TABLE = $db[:settings]