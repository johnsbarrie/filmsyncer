class EncodeFilms

    def initialize(config)
        @config=config
    end

    def start
        #deleteShots()
        #listShots()
        #encodeFilms('CH3-14_02')
    end

    def listShots
        puts 'listShots'
    end

    def deleteShots
        Dir.glob("#{folder}/*") do |file| 
            
        end

        puts 'deleteShots'
    end

    def encodeFilms (shotname)
        cmd=<<-FOO 
        ffmpeg -i ./data/backuplocal/machine1/2_VALIDATION/#{shotname}.dgn/#{shotname}_Take_01/#{shotname}_01_X1/#{shotname}_01_X1_%04d.jpg -c:v libx264 -pix_fmt yuv420p -vf scale=1920:-2 #{@config['encodedshots_path']}/#{shotname}.mp4
        FOO
        `#{cmd}`
    end

end