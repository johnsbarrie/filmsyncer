#!/usr/bin/ruby
require('./src/backup')
require('./src/networkdrives')
require('./src/encodefilm')
require 'yaml'
require 'json'

config = YAML::load_file("env.config")

while true
  `reset`
  puts "##########################################"
  puts "SYNC STARTING #{Time.now.strftime("%d/%m/%Y %H:%M")}"
  puts 
  puts "##########################################"

  networkdrives = NetworkDrives.new(config)
  
  puts "BOOTING Network"
  networkdrives.start
  puts "__________________________________________"
  puts "BACKING UP"
  backup = BackUp.new(config)
  backup.start(networkdrives.mountedDrives)
  puts "__________________________________________"
  puts "ENCODING"
  encodefilm = EncodeFilms.new(config)
  encodefilm.start(networkdrives.mountedDrives)
  puts "__________________________________________"
  puts "SENDING TO WEB"
  backup.syncToWeb
  puts "__________________________________________"
  puts "SYNC FINISH #{Time.now.strftime("%d/%m/%Y %H:%M")}"
  sleep(4*60)

end