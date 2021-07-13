# Mentioning OpenNebula as module to prettify docs side bar
module OpenNebula; end
Dir["#{ROOT}/service/objects/*.rb"].each { |file| require file }
