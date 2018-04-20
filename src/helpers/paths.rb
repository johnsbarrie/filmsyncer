module Paths
  def jpgSequencePath (shot, takename)
    "#{croppedImageDataPath(shot, takename)}#{shot['shotName']}_#{takename}_X1_%04d_watermarked.jpg"
  end

  def takeX1SingleImageName (shot, takename, imagenum)
    "#{shot['shotName']}_#{takename}_X1_#{imagenum}.jpg"
  end

  def takeX1SingleImagePath (shot, takename, imagenum)
    "#{takePath(shot, takename)}/#{shot['shotName']}_#{takename}_X1/#{ takeX1SingleImageName(shot, takename, imagenum) }"
  end

  def takeX1ImagesPath (shot, takename)
    "#{takePath(shot, takename)}/#{shot['shotName']}_#{takename}_X1/"
  end
  
  def takePath (shot, takename)
    "#{shot['path']}/#{shot['shotName']}/#{shot['shotName']}.dgn/#{shot['shotName']}_Take_#{takename}"
  end

  def takeXMLPath (shot, takeName)
    "#{takePath(shot, takeName)}/take.xml"
  end

  def ffmpegOutputPath (shotName, takeName)
    "#{@config['data_folder']}#{@config['encodedshots_path']}/#{shotName}_#{takeName}.mp4"
  end

  def thumbnailPath (shot, takeName)
    "#{@config['data_folder']}#{@config['thumbnails_path']}/#{shot['shotName']}_#{takeName}.jpg"
  end

  def croppedDataPath ()
    "#{@config['data_folder']}#{@config['cropimages_path']}/"
  end

  def croppedImageDataPath (shot, takeName)
    "#{croppedDataPath()}#{shot['shotName']}_Take_#{takeName}/"
  end

  def firstImagePath (shot, takeName)
    "#{takeX1ImagesPath(shot, takeName)}#{shot['shotName']}_#{takeName}_X1_0001.jpg"
  end

  def takeHasAtLeastImage (shot, takeName)
    File.exist?(firstImagePath(shot, takeName))
  end

  def suffixedPath(path, suffix)
    "#{File.basename(path, ".*")}_#{suffix}.jpg"
  end
  
  def fileIndex(imagepath)
    filename = File.basename(imagepath,'.*')
    filename[filename.length-4, filename.length]
  end
end