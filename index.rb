#! /usr/bin/ruby
require('./src/backup')
require('./src/networkdrives')
require('./src/encodefilm')
require 'yaml'
require 'json'

config = YAML::load_file("env.config")

networkdrives = NetworkDrives.new(config)
networkdrives.start

backup = BackUp.new(config)
backup.start(networkdrives.mountedDrives)

encodefilm = EncodeFilms.new(config)
encodefilm.start(networkdrives.mountedDrives)
=begin
=end
#backup.syncToWeb