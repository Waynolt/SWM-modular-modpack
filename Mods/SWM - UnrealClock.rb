#####MODDED
def aGetDrawnTextWOutline(outline, sText)
  bitmap = Bitmap.new(Graphics.width, 24)
  bitmap.font.name = $VersionStyles[$PokemonSystem.font]
  bitmap.font.size = 24
  bitmap.font.color.set(0, 0, 0)
  bitmap.draw_text(0, 0, bitmap.width, bitmap.height, sText, 0)
  
  
  bitmap2 = Bitmap.new(Graphics.width, 24)
  for i in 0...(outline*2+1)
    bitmap2.blt(0, i, bitmap, bitmap.rect)
  end
  
  bitmap3 = Bitmap.new(Graphics.width, 24)
  bitmap3.blt(0, 0, bitmap2, bitmap2.rect)
  
  for i in 0...(outline*2+1)
    bitmap2.blt(i, 0, bitmap3, bitmap3.rect)
  end
  
  bitmap.font.color.set(255, 255, 255)
  bitmap.draw_text(outline, outline, bitmap.width, bitmap.height, sText, 0)
  bitmap2.blt(0, 0, bitmap, bitmap.rect)
  
  return bitmap2
end
#####/MODDED

class Game_Screen
  #####MODDED
  def aUpdateClock(sGameTime)
    if !defined?($aUnrealClock) || $aUnrealClock.disposed?
      $aUnrealClock = Sprite.new(nil)
      $aUnrealClock.ox = 0
      $aUnrealClock.oy = 0
      $aUnrealClock.x = 0
      $aUnrealClock.y = 0
      $aUnrealClock.z = 9998
    end
    
    $aUnrealClock.visible = true
    if defined?($PokemonSystem.unrealTimeClock)
      $aUnrealClock.visible = $game_temp.menu_calling if $PokemonSystem.unrealTimeClock == 1
      $aUnrealClock.visible = false if $PokemonSystem.unrealTimeClock == 2
    end
    
    if $aUnrealClock.visible
      iInt = sGameTime.hour
      if iInt < 10
        sTime = _INTL(" 0{1}", iInt)
      else
        sTime = _INTL(" {1}", iInt)
      end
      
      iInt = sGameTime.min
      if iInt < 15
        sTime = _INTL("{1}:00", sTime)
      elsif iInt < 30
        sTime = _INTL("{1}:15", sTime)
      elsif iInt < 45
        sTime = _INTL("{1}:30", sTime)
      else
        sTime = _INTL("{1}:45", sTime)
      end
      
      iInt = sGameTime.wday
      case iInt
        when 0
          sTime = sTime+" Sunday"
          
        when 1
          sTime = sTime+" Monday"
          
        when 2
          sTime = sTime+" Tuesday"
          
        when 3
          sTime = sTime+" Wednesday"
          
        when 4
          sTime = sTime+" Thursday"
          
        when 5
          sTime = sTime+" Friday"
          
        else
          sTime = sTime+" Saturday"
      end
      
      $aOldsTime = "" if !defined?($aOldsTime)
      if $aOldsTime != sTime
        bitmap = aGetDrawnTextWOutline(2, sTime)
        
        $aUnrealClock.bitmap = bitmap
        
        $aOldsTime = sTime
      end
    end
  end
  
  def aGetTime
    sTimeNow = Time.new

    if defined?(aSetTime) && !defined?(@aGameTimeCurrent) #UnrealTime is installed
      @aGameTimeCurrent = sTimeNow
    end
    if !defined?($aGameTimeLast)
      $aGameTimeLast = sTimeNow
    end
    if !defined?($aUnrealClock) || $aUnrealClock.disposed?
      if defined?(aSetTime) #UnrealTime is installed
        aUpdateClock(@aGameTimeCurrent)
      else
        aUpdateClock(sTimeNow)
      end
    end
    
    aDiff = sTimeNow-$aGameTimeLast
    
    if aDiff < 0
      $aGameTimeLast = sTimeNow
    end
    if aDiff > 5 #Once every 5 seconds (so graphics update and online requests can be kept approximately unaltered)
      if aDiff < 120 #Make sure we are not simply loading up
        if defined?(aSetTime) #UnrealTime is installed
          if defined?($PokemonSystem.unrealTimeTimeScale)
            @aGameTimeCurrent = @aGameTimeCurrent+aDiff*$PokemonSystem.unrealTimeTimeScale
          else
            @aGameTimeCurrent = @aGameTimeCurrent+aDiff*30 #Default timescale = 1:30
          end

          aUpdateClock(@aGameTimeCurrent)
        else
          aUpdateClock(sTimeNow)
        end
      end
      $aGameTimeLast = sTimeNow
    end
    
    if defined?(aSetTime) #UnrealTime is installed
      return @aGameTimeCurrent
    else
      return sTimeNow
    end
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

class Scene_Map
  def call_menu
    $game_player.straighten
    $game_map.update
    sscene=PokemonMenu_Scene.new
    sscreen=PokemonMenu.new(sscene) 
    $game_screen.aGetTime #####MODDED
    sscreen.pbStartPokemonMenu
    $game_temp.menu_calling = false 
    $game_screen.aGetTime #####MODDED
  end
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
