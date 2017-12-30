require 'fileutils'

class NetworkDrives

    def initialize (config)
        @volumes_base_path=config['volumes_base_path']
        @expected_machine=config['networkpaths']
        @inprogress_folder_name='1_INPROGRESS'
        @mountedrives=[]
        @drivestomount=[]
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
                `mount -t smbfs #{networkpath} #{@volumes_base_path}/#{machine['mountpoint']}`
            else
               puts "#{ machine['servername'] } not found on the network"
            end 
        end
    end

    def createNetworkPath (machine)
        "//#{machine['user']}:#{machine['password']}@#{machine['servername']}/#{machine['sharedpath']}"
    end 

    def serverIsAvailable machine
        networkinfo = `arp -a`
        networkinfo.include? machine['servername']
    end 

    def resourceIsAvaible machine
        resourcelist = `smbutil view //#{machine['user']}:#{machine['password']}@#{machine['servername']}`
        resourcelist.include? machine['sharedpath']
    end

end