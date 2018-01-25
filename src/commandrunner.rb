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
  
end