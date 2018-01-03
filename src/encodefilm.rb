
require 'ostruct'
require 'pathname'
class EncodeFilms
    
    def initialize(config)
        @config=config
        @activeShots=[]
        @encodedShots=[]
    end

    def start(mountedDrives)
        @mountedDrives=mountedDrives
        listActiveShots()
        deleteInactiveShots()
        encodeActiveShots()
    end

    def listActiveShots
        @mountedDrives.each do |machine|
            folder= "#{@config['backup_local_base_path']}/#{machine['mountpoint']}/2_VALIDATION"
            Dir.glob("#{folder}/*") do |file| 
                name = File.basename(file, File.extname(file))
                shot = OpenStruct.new('shotName'=>name, 'path'=>folder)
                @activeShots.push(shot)
            end
        end
    end

    def deleteInactiveShots
        Dir.glob("#{@config['encodedshots_path']}/*") do |file| 
            name = File.basename(file, File.extname(file))
            result = @activeShots.select do |struct|
                struct['shotName'] === name
            end

            if result.empty? 
                File.delete file
                File.delete "#{@config['thumbnails_path']}/#{name}.jpg"
            end
        end
    end

    def encodeActiveShots
        @activeShots.each do |shot|
            encodedShotPath = "#{@config['encodedshots_path']}/#{shot['shotName']}.mp4"
            if !File.exists? encodedShotPath
                puts "encoding #{encodedShotPath}"
                encodeShot (shot)
                encodeThumbnail (shot)
            end
        end
    end

    def encodeShot (shot)
        cmd=<<-FOO 
        ffmpeg -y -i #{shot['path']}/#{shot['shotName']}.dgn/#{shot['shotName']}_Take_01/#{shot['shotName']}_01_X1/#{shot['shotName']}_01_X1_%04d.jpg -c:v libx264 -pix_fmt yuv420p -vf scale=1920:-2 #{@config['encodedshots_path']}/#{shot['shotName']}.mp4
        FOO
        `#{cmd}`
    end

    def encodeThumbnail (shot)
        image_path="#{shot['path']}/#{shot['shotName']}.dgn/#{shot['shotName']}_Take_01/#{shot['shotName']}_01_X1/#{shot['shotName']}_01_X1_0001.jpg"
        thumbnails_path="#{@config['thumbnails_path']}/#{shot['shotName']}.jpg"
        cmd="convert #{image_path} -resize 320x320 #{thumbnails_path}"
        `#{cmd}`
    end

end