require 'ostruct'
require 'pathname'
require './src/helpers/paths'
require './src/helpers/prepareimages'

class EncodeFilms
    include PrepareImages
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
                shotPath = takePath(shot, takeName)
                shotExists = File.exists? shotPath

                if !shotExists
                    puts "TAKE DOES NOT EXIST #{shotPath}" if takeindex == 0
                    break
                end

                encodedShotPath = ffmpegOutputPath(shot['shotName'], takeName)

                if !File.exists? encodedShotPath
                    if takeHasAtLeastImage(shot, takeName)
                        puts "preparing Images #{shot['shotName']}_#{takeName}"
                        prepareImageSequence(shot, takeName)
                        
                        puts "encoding #{shot['shotName']}_#{takeName}"
                        encodeShot(shot, takeName)
                        puts "thumbnail #{shot['shotName']}_#{takeName}"
                        encodeThumbnail(shot, takeName)
                        cleanupData()
                    end
                end
                takeindex = takeindex + 1;
            end
        end
    end
    
    def deleteInactiveShots
        Dir.glob("#{@config['data_folder']}#{@config['encodedshots_path']}/*") do |file| 
            name = File.basename(file, File.extname(file))
            result = @activeShots.select do |struct|
                name.include? struct['shotName']
            end
            
            if result.empty? 
                File.delete file
                File.delete "#{@config['data_folder']}#{@config['thumbnails_path']}/#{name}.jpg"
            end
        end
    end
end