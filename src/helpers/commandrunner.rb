require 'ostruct'

module CommandRunner
  
  def runExe(cmd, timeoutDelay)
    begin
      Timeout::timeout(timeoutDelay) { 
      return `#{cmd}`
    }
    rescue Timeout::Error
      exit 1
    end
  end

  def encodeShot (shot, takeName)
    sequencePath = jpgSequencePath(shot, takeName)
    output = ffmpegOutputPath(shot['shotName'], takeName)
    soundOutput = soundOutputFolderPath(shot['shotName'], takeName) 
    soundOutputCommand = File.exists?(soundOutput) ? "-i #{soundOutput} -map 0:v -map 1:a" : ""

    cmd=<<-FOO 
        ffmpeg -y -i #{sequencePath} #{soundOutputCommand} -r 24 -c:v libx264 -pix_fmt yuv420p -vf scale=1920:-2 #{output}
    FOO
    puts cmd
    `#{cmd}`
  end

  def extractSound (soundFile, soundOutputFile)    
    cmd=<<-FOO 
      ffmpeg -y -i #{soundFile} -q:a 0 -map a #{soundOutputFile}
    FOO
    puts cmd
    `#{cmd}`
  end

  def encodeThumbnail (shot, takeName)
      image_path = firstImagePath(shot, takeName)
      thumbnails_path = thumbnailPath(shot, takeName)
      cmd="convert #{image_path} -resize 320x320 #{thumbnails_path}"
      `#{cmd}`
  end

  def cropImageToMask (imagepath, takeXMLInfo, output)
    pushinProportions = takeXMLInfo[:maskPushIn].to_f
    horizontalOffSetPercentage = takeXMLInfo[:maskOffsetHorizontal].to_f
    verticalOffSetPercentage = takeXMLInfo[:maskOffsetVertical].to_f

    imagewidth = `identify -format "%w" #{imagepath}`.to_f
    imageheight = `identify -format "%h" #{imagepath}`.to_f
  
    width = imagewidth-((pushinProportions * 2) * imagewidth)
    height = imageheight-((pushinProportions * 2) * imageheight)
  
    proportionalHeight = width/takeXMLInfo[:aspectMask].to_f
  
    horizontalCropPoint = ((pushinProportions) * imagewidth)
    verticalCropPoint = ((pushinProportions) * imageheight)
  
    hOffSet = horizontalCropPoint + (horizontalCropPoint * horizontalOffSetPercentage/100)
    vOffSet = verticalCropPoint + (verticalCropPoint * verticalOffSetPercentage/100) + (( height - proportionalHeight )/2)
  
    `convert #{imagepath} -crop #{width}x#{proportionalHeight}+#{hOffSet}+#{vOffSet} #{output}`
  end
  
  def watermarkCmd(imagepath, outputpath, imageindex)
    imageheight = `identify -format "%h" #{imagepath}`.to_f
    pointsize = 40
    textOffset = imageheight/2 - (pointsize / 2)
    offsetCoordinates = OpenStruct.new('x'=>0, 'y'=>100)
    `convert #{imagepath} -pointsize #{pointsize}  -gravity east -draw 'fill black text 1,#{textOffset-1} "#{imageindex}" fill white text 0,#{textOffset}  "#{imageindex}" ' #{outputpath}`
  end
end