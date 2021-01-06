class Game_Screen
  #####MODDED
  attr_accessor   :aGameTimeCurrent
  
  def aGetTime
    sTimeNow = Time.new

    if !defined?(@aGameTimeCurrent)
      @aGameTimeCurrent = sTimeNow
    end
    if !defined?($aGameTimeLast)
      $aGameTimeLast = sTimeNow
    end
    if defined?(aUpdateClock) && (!defined?($aUnrealClock) || $aUnrealClock.disposed?) #UnrealClock is installed
      aUpdateClock(@aGameTimeCurrent)
    end
    
    aDiff = sTimeNow-$aGameTimeLast
    
    if aDiff < 0
      $aGameTimeLast = sTimeNow
    end
    if aDiff > 5 #Once every 5 seconds (so graphics update and online requests can be kept approximately unaltered)
      if aDiff < 120 #Make sure we are not simply loading up
        if defined?($PokemonSystem.unrealTimeTimeScale)
          @aGameTimeCurrent = @aGameTimeCurrent+aDiff*$PokemonSystem.unrealTimeTimeScale
        else
          @aGameTimeCurrent = @aGameTimeCurrent+aDiff*30 #Default timescale = 1:30
        end
        
        aUpdateClock(@aGameTimeCurrent) if defined?(aUpdateClock) #UnrealClock is installed
      end
      $aGameTimeLast = sTimeNow
    end
    
    return @aGameTimeCurrent
  end
  
  def aSetTime(newtime)
    $aGameTimeLast = Time.new
    @aGameTimeCurrent = newtime
  end
  #####/MODDED
  
  def setWeather
    if !@vectorStarted
      initialize_vector
    end    
    outdoor  = pbGetMetadata($game_map.map_id,MetadataOutdoor)  
    if !outdoor
      $game_screen.weather(0,0,20)
    else      
      position = pbGetMetadata($game_map.map_id,MetadataMapPosition)
      posX = position[1]
      posY = position[2]
      if      posX < 6 and posY > 14
        region = 0 # Apophyll
      elsif ( posX < 10 and posY > 6 ) and !$game_switches[479]
        region = 1 # Reborn 
      elsif ( posX < 10 and posY > 6 ) and $game_switches[479]
        region = 2 # Reborn, Evolved
      elsif   posX < 8 and posY < 7
        region = 3 # Tourmaline
      elsif   posX > 7 and posY < 7
        region = 4 # Carnelia
      else
        region = 5 # Others
      end
      regionOffset = 17 * region
      #unix time: 1 hr = 3600; 8hr = 28800; 5 days = 432000
      currentDate  = aGetTime.to_i #####MODDED, was currentDate  = Time.now.to_i
      @weatherVector[16] = currentDate if @weatherVector[16] == nil #####MODDED, was @weatherVector[16] = Time.now.to_i if @weatherVector[16] == nil
      prevTime = @weatherVector[16]
      timeDifference1 = currentDate - prevTime
      timeDifference2 = 0
      timeDifference2 = currentDate - @previousDate.to_i if @previousDate
      if (!@previousDate || timeDifference2 > 432000 ||
        @weatherVector[96] == -1) 
        createArchetype(regionOffset)
        regionArchetype(region, regionOffset)
        @previousDate = currentDate
        @weatherVector[96] = 0
        @weatherVector[16] = currentDate #####MODDED, was @weatherVector[16] = Time.now.to_i
        $game_variables[318] = 0
      elsif timeDifference1 > 28800
        blockCount = (timeDifference1 / 28800).to_i
        @weatherVector[96] = @weatherVector[96] + blockCount
        @weatherVector[16] = currentDate #####MODDED, was @weatherVector[16] = Time.now.to_i
        $game_variables[318] = blockCount
      end
      currentWeather = @weatherVector[96] + regionOffset
      if $game_switches[151] == true
        $game_screen.weather($game_variables[106],3,20)
      else
        current2 = aGetTime #####MODDED, was current2 = Time.new
        if @weatherVector[currentWeather][0] != 5 || (current2.hour > 6 &&
         current2.hour < 19)
          $game_variables[91] = @weatherVector[currentWeather][0]
          $game_screen.weather(@weatherVector[currentWeather][0],@weatherVector[currentWeather][1],20)
        else
          $game_variables[91] = 0
          $game_screen.weather(0,0,20)
        end
      end
    end
  end
end

def pbGetTimeNow
  #####MODDED
  return $game_screen.aGetTime
  #####/MODDED
end

#####MODDED
def Time.now
  return $game_screen.aGetTime
end
#####/MODDED

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
