require './src/helpers/commandrunner'
require 'fileutils'
require 'timeout'
require 'logger'

class NetworkDrives
    include CommandRunner

    def initialize (config)
        @volumes_base_path=config['volumes_base_path']
        @expected_machine=config['networkpaths']
        @validation_folder= config['validation_folder']
        @data_folder=config['data_folder']
        @mountedrives=[]
        @drivestomount=[]
        FileUtils.mkdir_p "./log"
        @log = Logger.new('./log/network.log')
    end

    def mountedDrives
        @mountedrives
    end

    def expectedMachines
        @expected_machine
    end

    def start
        listMountedDrives()
        mountDrives()
    end

    def listMountedDrives
        @expected_machine.each do |machine|
            mountpoint=machine['mountpoint']
            
            path = "#{@data_folder}#{@volumes_base_path}/#{mountpoint}/#{@validation_folder}"
            #if machine && serverIsAvailable(machine) && resourceIsAvailable(machine) && Dir.exist?(path)
            if machine && resourceIsAvailable(machine) && Dir.exist?(path)

                @mountedrives.push(machine)
            elsif
                @drivestomount.push(machine)
            end
        end
    end

    def mountDrives
        @drivestomount.each do |machine|
            mountFolder = "#{@data_folder}#{@volumes_base_path}/#{machine['mountpoint']}"
            FileUtils.mkdir_p mountFolder unless File.directory?(mountFolder)
            
            if resourceIsAvailable(machine)
                mountMachine(machine)
            else
                nofoundmsg = "#{ machine['servername'] } not found on the network"
                puts nofoundmsg
                @log.warn nofoundmsg
            end
        end
    end

    def createNetworkPath (machine)
        "//#{machine['user']}:#{machine['password']}@#{machine['servername']}/#{machine['sharedpath']}"
    end 

    def mountMachine machine
        networkpath = createNetworkPath(machine)
        begin
            cmd = "mount -t smbfs #{networkpath} #{@data_folder}#{@volumes_base_path}/#{machine['mountpoint']}";
            puts cmd
            runExe("#{cmd}", 50)
        rescue SystemExit => e
            msg = "ERROR: Mounting disk command has hung for #{networkpath}"
            puts msg
            @log.error msg
        end
    end

    def serverIsAvailable machine
        networkinfo = `arp -a`
        hasMachineBeenFound = networkinfo.include? machine['servername']
        puts "#{machine['servername']} network detection = #{hasMachineBeenFound}"
        return hasMachineBeenFound
    end 

    def resourceIsAvailable machine
        begin
            cmd = "smbutil view //#{machine['user']}:#{machine['password']}@#{machine['servername']}"
            puts "Checking for shared resource #{machine['sharedpath']} on #{machine['servername']}"
            resourcelist = runExe(cmd, 20)
            return resourcelist.include? machine['sharedpath']
        rescue SystemExit => e
            msg = "ERROR: resource Availabilty script has hung for #{machine['servername']}"
            puts msg
            @log.error msg
            return false
        end
    end

end