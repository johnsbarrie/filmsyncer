class BackUp

    def initialize (config)
        @config=config
    end

    def start(mountedDrives)
        @mountedDrives=mountedDrives
        backUpNetworkToLocal()
        backUpLocalToExternal()
    end

    def backUpNetworkToLocal()
        @mountedDrives.each do |machine|
            machinename = machine['mountpoint']
            fromPath=@config['volumes_base_path']
            toPath=@config['backup_local_base_path']
            `#{constructRsyncCommand(machinename, fromPath, toPath, true)}`
        end
    end

    def backUpLocalToExternal
        @mountedDrives.each do |machine|
            machinename = machine['mountpoint']
            fromPath=@config['backup_local_base_path']
            toPath=@config['backup_external_base_path']
            `#{constructRsyncCommand(machinename, fromPath, toPath)}`
        end
    end

    def constructRsyncCommand(machinename, fromPath, toPath, delete=false)
        deleteCommand = delete ? '--delete' : ''
        cmd = "rsync -azv #{deleteCommand} #{fromPath}/#{machinename}/ #{toPath}/#{machinename}/"
    end

    def syncToWeb()
        `rsync -azv --delete #{@config['encodedshots_path']}/ #{@config['web_shot_path']}/`
        `rsync -azv --delete #{@config['thumbnails_path']}/ #{@config['web_thumbnail_path']}/`
    end
end