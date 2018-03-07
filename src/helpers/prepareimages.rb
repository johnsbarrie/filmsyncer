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
    attribs = doc.root.attributes
    takeXMLObj = OpenStruct.new('maskOffsetHorizontal'=>attribs['maskOffsetHorizontal'], 
                'maskOffsetVertical'=>attribs['maskOffsetVertical'],
                ' aspectMask'=>attribs['aspectMask'],
                'maskPushIn'=>attribs['maskPushIn'], 'fps'=>attribs['fps'])
                
    takeXMLObj[:fps] = "24" if takeXMLObj[:fps].nil? || takeXMLObj[:fps].empty? 
    takeXMLObj[:aspectMask] = 1.85 if takeXMLObj[:aspectMask].nil? || takeXMLObj[:aspectMask].empty? 
    
    takeXMLObj[:maskOffsetVertical] = 0 if takeXMLObj[:maskOffsetVertical].nil? || takeXMLObj[:maskOffsetVertical].empty? 
    takeXMLObj[:maskOffsetHorizontal] = 0 if takeXMLObj[:maskOffsetHorizontal].nil? || takeXMLObj[:maskOffsetHorizontal].empty? 
    
    return takeXMLObj
  end

  def createTakeSequence(shot, takeName)
    takeXMLInfo = readXML(shot, takeName)

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