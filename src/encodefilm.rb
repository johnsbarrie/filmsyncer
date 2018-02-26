require 'ostruct'
require 'pathname'

class EncodeFilms
    
    def initialize(config)
        @config=config
        @activeShots=[]
        @encodedShots=[]
    end

    def start(expectedMachines)
        @expectedMachines=expectedMachines
        listActiveShots()
        deleteInactiveShots()
        encodeActiveShots()
    end

    def listActiveShots
        @expectedMachines.each do |machine|
            folder = "#{@config['data_folder']}#{@config['backup_local_base_path']}/#{machine['mountpoint']}/#{@config['validation_folder']}"
            Dir.glob("#{folder}/*") do |file| 
                name = File.basename(file, File.extname(file))
                shot = OpenStruct.new('shotName'=>name, 'path'=>folder)
                @activeShots.push(shot)
            end
        end
    end

    def encodeActiveShots
        @activeShots.each do |shot|
            
            takeindex = 0;
            while true
                takeName="A-BG-V#{takeindex}"
                shotPath = takePath(shot['path'], shot['shotName'], takeName)
                shotExists = File.exists? shotPath

                if !shotExists
                    puts "TAKE DOES NOT EXIST #{shotPath}" if takeindex == 0
                    break
                end
                encodedShotPath = ffmpegOutputPath(shot['shotName'], takeName)

                if !File.exists? encodedShotPath
                    puts "encoding #{encodedShotPath}"
                    encodeShot(shot, takeName)
                    encodeThumbnail(shot, takeName)
                end
                takeindex = takeindex + 1;
            end
        end
    end
    
    def encodeShot (shot, takeName)
        sequencePath = jpgSequencePath(shot['path'], shot['shotName'], takeName)
        output= ffmpegOutputPath(shot['shotName'], takeName)
        cmd=<<-FOO 
            ffmpeg -y -i #{sequencePath} -r 24 -c:v libx264 -pix_fmt yuv420p -vf scale=1920:-2 #{output}
        FOO
        puts cmd
        `#{cmd}`
    end

    def takePath (path, name, takename)
        "#{path}/#{name}/#{name}.dgn/#{name}_Take_#{takename}"
    end

    def jpgSequencePath (path, name, takename)
        imagepath("#{takePath(path, name, takename)}/#{name}_#{takename}_X1/#{name}_#{takename}_X1_", "%04d.jpg")
    end

    def imagepath (path, imagename)
        "#{path}#{imagename}"
    end

    def ffmpegOutputPath (shotName, takeName)
        "#{@config['data_folder']}#{@config['encodedshots_path']}/#{shotName}_#{takeName}.mp4"
    end
    
    def encodeThumbnail (shot, takeName)
        image_path="#{shot['path']}/#{shot['shotName']}/#{shot['shotName']}.dgn/#{shot['shotName']}_Take_#{takeName}/#{shot['shotName']}_#{takeName}_X1/#{shot['shotName']}_#{takeName}_X1_0001.jpg"
        thumbnails_path="#{@config['data_folder']}#{@config['thumbnails_path']}/#{shot['shotName']}_#{takeName}.jpg"
        cmd="convert #{image_path} -resize 320x320 #{thumbnails_path}"
        `#{cmd}`
    end

    def deleteInactiveShots
        Dir.glob("#{@config['data_folder']}#{@config['encodedshots_path']}/*") do |file| 
            name = File.basename(file, File.extname(file))

            result = @activeShots.select do |struct|
                file.include? name
            end
    
            if result.empty? 
                File.delete file
                File.delete "#{@config['data_folder']}#{@config['thumbnails_path']}/#{name}.jpg"
            end
        end
    end

end