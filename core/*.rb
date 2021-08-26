if ENV["ALPINE"] == 'true' then
  require 'core/connect_db_env.rb'
else
  require 'core/load_oned_conf.rb'
  require 'core/connect_db.rb'
end
require 'core/settings.rb'
