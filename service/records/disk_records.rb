begin
  $db.create_table :disk_records do
    primary_key :key
    foreign_key :vm, :vm_pool, null: false
    Integer   :id, null: false
    Integer   :crt, null: false
    Integer   :del, null: true
    Integer   :size, null: false
    String    :type, size: 10, null: true
    Integer   :img, null: true
  end
rescue
  puts "Table :disk_records already exists, skipping"
end

# Disk Record Model class
class DiskRecord < Sequel::Model(:disk_records)
  # State hash key generator, e.g. backup disk would be :backup_disk
  def type_sym
    "#{type}_disk".to_sym
  end

  # Disk Created Record class
  class CreateDiskRecord < DiskRecord
    # Since this is Create record sorter is 'create time'
    def sorter
      crt
    end
    alias :ts :sorter

    # Increments :snaps
    def mod st
      st[type_sym] += size
    end
  end

  # Disk Deleted Record class
  class DeleteDiskRecord < DiskRecord
    # Since this is Delete record sorter is 'delete time'
    def sorter
      del
    end
    alias :ts :sorter

    # Decrements :snaps
    def mod st
      st[type_sym] -= size
    end
  end

  # Record values withoud DB key
  def values
    @values.without(:key)
  end

  # Splits itself into Create- and Delete-(if snap has been deleted) DiskRecord
  def sortable
    if self.del then
      [CreateDiskRecord.new(values), DeleteDiskRecord.new(values)]
    else
      CreateDiskRecord.new(values)
    end
  end
end

# # (Disk)Records source class for fullfilling Timeline
# class OpenNebula::DiskRecords < RecordsSource
#   # Overrides key for db queries
#   def key
#     :vm
#   end

#   # inits RecordsSource class with DiskRecord class as base
#   def initialize id
#     super(DiskRecord, id)
#   end

#   # Returns all needed records for given timerange
#   def find stime, etime
#     @records.where(crt: stime..etime).or(del: stime..etime)
#   end

#   # Gets All of the DiskRecords before stime and with deletion time greater than stime or nil and counts(which is initial quantity of disks)
#   def init_state stime
#     # SELECT * FROM `disk_records` WHERE ((`crt` < 0) AND ((`del` >= 0) OR NOT `del`))
#     {
#       snaps: @records.where { crt < stime }.where { (del >= stime) | ~del }.count
#     }
#   end
# end
