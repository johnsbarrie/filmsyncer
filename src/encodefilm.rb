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

    def createTakeArray(shot)
        shotpath = shotPath(shot)
        validTakes=[]
        Dir.glob("#{shotpath}*") do |file| 
            #TODO regular expression
            potentialFileName = File.basename(file)
            
            if (potentialFileName.match(/^[A-Z]{2}[0-9]+-{1}[0-9]+_[0-9]+[A-Z]{0,2}_Take_[A-Z]-[A-Z]{2}-V[0-90]{1}[A-Z]?$/))
                #puts "potentialFileName #{potentialFileName}"
                validTakes.push(potentialFileName)
            end
        end 
        return validTakes
    end

    def encodeActiveShots
        @activeShots.each do |shot|
            takeindex = 0;
            validTakes = createTakeArray(shot)
            #puts "validTakes #{validTakes}"
            validTakes.each { |takeName| 
            
                shotPath = "#{shotPath(shot)}#{takeName}"
                takeName = File.basename(shotPath)
                
                shot_prefix = "#{shot['shotName']}_Take_"
                takeName = takeName[shot_prefix.length, takeName.length]
                
                shotExists = File.exists? shotPath

                if !shotExists
                    puts "TAKE DOES NOT EXIST #{shotPath}" if takeindex == 0
                    break
                end

                encodedShotPath = ffmpegOutputPath(shot['shotName'], takeName)
                puts encodedShotPath
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
            }
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