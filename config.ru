WITH_RACKUP = true

$: << '.'
require 'ione_server'

run Sinatra::Application
