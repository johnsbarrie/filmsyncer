require 'rexml/document'
require 'ostruct'
require 'fileutils'
require './src/helpers/paths'
require './src/helpers/commandrunner'
module PrepareImages
  include Paths
  include REXML
  include CommandRunner

  def prepareImageSequence(shot, takeName)
    createTakeSequence(shot, takeName)
  end

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
    return takeXMLObj
  end

  def createSymlinks(sylinkInfo, takePath)
    directory_name = "#{takePath}/CONFORMED"
    Dir.mkdir(directory_name) unless File.exists?(directory_name)
    sylinkInfo.each do |linkinfo|
      linkpath = "#{directory_name}/#{linkinfo[:linkName]}"
      filepath = linkinfo[:imagePath]
      File.symlink(filepath, linkpath)
    end
  end

  def createTakeSequence(shot, takeName)
    takeXMLInfo = readXML(shot, takeName)
    createSymlinks(takeXMLInfo[:symLinkInfo], takePath(shot, takeName))
    folderPath = croppedImageDataPath(shot, takeName)
    FileUtils.mkdir_p(folderPath) unless Dir.exist?(folderPath)
    Dir.glob("#{takeX1ImagesPath(shot, takeName)}*.jpg") do |imagepath|
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