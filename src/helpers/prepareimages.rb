require 'rexml/document'
require 'ostruct'
require 'fileutils'
require './src/helpers/paths'
require './src/helpers/commandrunner'
module PrepareImages
  include Paths
  include REXML
  include CommandRunner


  def readXML(shot, takeName)
    file = File.new(takeXMLPath(shot, takeName))
    doc = Document.new(file)
    
    imageArray = []

    doc.elements.each("scen:scene/scen:edl/scen:vframe") { |element| 
      imageArray.push(
        OpenStruct.new(
          'imagePath'=>takeX1SingleImagePath(shot, takeName, "%04d" % element.attributes['file'].to_i), 
          'linkName'=>takeX1SingleImageName(shot, takeName, "%04d" % element.attributes['vframe'].to_i)
        )    
      )
    }

    #doc.elements.each("scen:scene/scen:audioFile") { |audioFile| 
     # puts audioFile.attributes['soundFile']
    #}
    soundFilePath=''
    doc.elements.each("scen:scene/scen:audioTrack") { |audioTrack|
      audioTrack.elements.each("scen:segment") {|segment|
        soundFilePath = "#{packAnimPath(shot, takeName)}#{segment.attributes['soundFile']}"
        break;
       }
    }

    attribs = doc.root.attributes
    takeXMLObj = OpenStruct.new(
                  'maskOffsetHorizontal'=>attribs['maskOffsetHorizontal'], 
                  'maskOffsetVertical'=>attribs['maskOffsetVertical'],
                  'aspectMask'=>attribs['aspectMask'],
                  'maskPushIn'=>attribs['maskPushIn'], 
                  'fps'=>attribs['fps'],
                  'imageArray'=>imageArray
                )
                
    takeXMLObj[:fps] = "24" if takeXMLObj[:fps].nil? || takeXMLObj[:fps].empty? 
    takeXMLObj[:aspectMask] = 1.85 if takeXMLObj[:aspectMask].nil? || takeXMLObj[:aspectMask].empty? 
    
    takeXMLObj[:maskOffsetVertical] = 0 if takeXMLObj[:maskOffsetVertical].nil? || takeXMLObj[:maskOffsetVertical].empty? 
    takeXMLObj[:maskOffsetHorizontal] = 0 if takeXMLObj[:maskOffsetHorizontal].nil? || takeXMLObj[:maskOffsetHorizontal].empty? 
    takeXMLObj[:symLinkInfo] = imageArray
    takeXMLObj[:soundFilePath] = soundFilePath
    return takeXMLObj
  end

  def createSymlinks(sylinkInfo, takeConformedLinkPath)
    Dir.mkdir(takeConformedLinkPath) unless File.exists?(takeConformedLinkPath)
    sylinkInfo.each do |linkinfo|
      linkpath = "#{takeConformedLinkPath}/#{linkinfo[:linkName]}"
      filepath = linkinfo[:imagePath]
      File.symlink(filepath, linkpath)
    end
  end

  def prepareImageSequence(shot, takeName)
    takeXMLInfo = readXML(shot, takeName)
    createSymlinks(takeXMLInfo[:symLinkInfo], takeConformedLinkFolderPath(shot, takeName))
    folderPath = croppedImageDataPath(shot, takeName)
    FileUtils.mkdir_p(folderPath) unless Dir.exist?(folderPath)
    FileUtils.mkdir_p(soundFolderPath) unless Dir.exist?(soundFolderPath)
    
    extractSound(takeXMLInfo[:soundFilePath], soundOutputFolderPath(shot['shotName'], takeName))

    Dir.glob("#{takeConformedLinkFolderPath(shot, takeName)}*.jpg") do |imagepath|
      puts imagepath
      croppedImage = "#{folderPath}/#{suffixedPath(imagepath, 'cropped')}"
      watermarkedImage = "#{folderPath}/#{suffixedPath(imagepath, 'watermarked')}"
      fileIndex(imagepath)
      cropImageToMask(imagepath, takeXMLInfo, "#{folderPath}/#{suffixedPath(imagepath, 'cropped')}")
      watermarkCmd(croppedImage, watermarkedImage, fileIndex(imagepath))
    end
  end

  def cleanupCroppedImageData
    FileUtils.rm_rf(croppedDataPath()) 
  end

end