class BackUp

    def initialize (config)
        @config=config
    end

    def start(mountedDrives)
        @mountedDrives=mountedDrives
        backUpNetworkToLocal()
        #backUpLocalToExternal()
    end

    def backUpNetworkToLocal()
        @mountedDrives.each do |machine|
            machinename = machine['mountpoint']
            fromPath="#{@config['data_folder']}#{@config['volumes_base_path']}/#{machinename}/#{@config['validation_folder']}"
            toPath="#{@config['data_folder']}#{@config['backup_local_base_path']}/#{machinename}/"
            cmd = constructRsyncCommand(machinename, fromPath, toPath, true)
            puts "Backingup #{machine['servername']}"
            `#{cmd}`
        end
    end

    def backUpLocalToExternal
        @mountedDrives.each do |machine|
            machinename = machine['mountpoint']
            fromPath="#{@config['backup_local_base_path']}/#{machinename}/VALIDATION"
            toPath="#{@config['backup_external_base_path']}/#{machinename}/"
            `#{constructRsyncCommand(machinename, fromPath, toPath)}`
        end
    end

    def constructRsyncCommand(machinename, fromPath, toPath, delete=false)
        deleteCommand = delete ? '--delete' : ''
        "rsync -azv --include '*/' --include '*.jpg' --include '*.xml' --exclude '*' #{deleteCommand} #{fromPath} #{toPath}"
    end

    def syncToWeb()
        `rsync -azv --delete #{@config['data_folder']}#{@config['encodedshots_path']}/ #{@config['web_shot_path']}/`
        `rsync -azv --delete #{@config['data_folder']}#{@config['thumbnails_path']}/ #{@config['web_thumbnail_path']}/`
    end

end