require './src/commandrunner'
require 'fileutils'
require 'timeout'
require 'logger'

class NetworkDrives
    include CommandRunner
    def initialize (config)
        @volumes_base_path=config['volumes_base_path']
        @expected_machine=config['networkpaths']
        @inprogress_folder_name='1_INPROGRESS'
        @mountedrives=[]
        @drivestomount=[]
        FileUtils.mkdir_p "./log"
        @log = Logger.new('./log/network.log')

    end

    def mountedDrives
        @mountedrives
    end

    def start
        listMountedDrives()
        mountDrives()
    end

    def listMountedDrives
        @expected_machine.each do |machine|
            mountpoint=machine['mountpoint']
            path = "#{@volumes_base_path}/#{mountpoint}/#{@inprogress_folder_name}"
            if serverIsAvailable(machine) && resourceIsAvaible(machine) && Dir.exist?(path)
                @mountedrives.push(machine)
            elsif
                @drivestomount.push(machine)
            end
        end
        
    end

    def mountDrives
        @drivestomount.each do |machine|
            networkpath = createNetworkPath(machine)
            FileUtils.mkdir_p "#{@volumes_base_path}/#{machine['mountpoint']}"
            if serverIsAvailable(machine) && resourceIsAvaible(machine)
                mountMachine(machine)
            else
                @log.warn "#{ machine['servername'] } not found on the network"
            end
        end
    end

    def createNetworkPath (machine)
        "//#{machine['user']}:#{machine['password']}@#{machine['servername']}/#{machine['sharedpath']}"
    end 

    def mountMachine machine
        begin
            runExe("mount -t smbfs #{networkpath} #{@volumes_base_path}/#{machine['mountpoint']}", 50) 
        rescue SystemExit => e
            @log.error "ERROR: Mounting disk command has hung for #{networkpath}"
        end
    end

    def serverIsAvailable machine
        networkinfo = `arp -a`
        networkinfo.include? machine['servername']
    end 

    def resourceIsAvaible machine
        begin
            resourcelist = runExe("smbutil view //#{machine['user']}:#{machine['password']}@#{machine['servername']}", 20)
            return resourcelist.include? machine['sharedpath']
        rescue SystemExit => e
            @log.error "ERROR: resource Availabilty script has hung for #{machine['servername']}"
            return false
        end
    end

end