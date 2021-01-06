#####MODDED
class Game_Screen
  def RerollWeather
    @previousDate = pbGetTimeNow.to_i - 432005
  end
  
  def ChangeWeatherPlan(aChoiceType, aChoicePower)
    if (pbGetMetadata($game_map.map_id,MetadataOutdoor) )
      if ($game_switches[151])
        Kernel.pbMessage("The Plot forbids this right now.")
      else
        self.RerollWeather #Prevent the fixnum error by resetting the weather week
        setWeather #Let the game update its internal calendar
        
        #Get current zone
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
        
        currentWeather = @weatherVector[96] + regionOffset
        
        #Change the planned weather here
        @weatherVector[currentWeather][0] = aChoiceType
        @weatherVector[currentWeather][0] = 0 if aChoicePower == 0

        @weatherVector[currentWeather][1] = aChoicePower
        
        setWeather #Give visual feedback of the change
        
        Kernel.pbMessage("The weather has been set.")
        Kernel.pbMessage("Go inside to update the events.")
      end
    else
      Kernel.pbMessage("Only works outside.")
    end
  end
end
#####/MODDED

class Scene_Pokegear
  def main
    commands=[]
  # OPTIONS - If you change these, you should also change update_command below.
    @cmdRerollWeather=-1 #####MODDED
    @cmdMap=-1
    @cmdPhone=-1
    @cmdJukebox=-1
    @cmdOnline=-1    
    @cmdPulse=-1
    @cmdNotes=-1
    
    commands[@cmdRerollWeather=commands.length]=_INTL("Control weather") #####MODDED
    commands[@cmdMap=commands.length]=_INTL("Map")
    commands[@cmdPhone=commands.length]=_INTL("Phone") if $PokemonGlobal.phoneNumbers &&
                                                          $PokemonGlobal.phoneNumbers.length>0
    commands[@cmdJukebox=commands.length]=_INTL("Jukebox")
    commands[@cmdOnline=commands.length]=_INTL("Online Play") 
    if $game_switches[586]
      commands[@cmdPulse=commands.length]=_INTL("PULSE Dex")
    end
    if $game_switches[599]
      commands[@cmdNotes=commands.length]=_INTL("Field Notes")
    end
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @button=AnimatedBitmap.new("Graphics/Pictures/pokegearButton")
    @sprites={}
    @sprites["background"] = IconSprite.new(0,0)
    femback=pbResolveBitmap(sprintf("Graphics/Pictures/pokegearbgf"))
    if $Trainer.isFemale? && femback
      @sprites["background"].setBitmap("Graphics/Pictures/pokegearbgf")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/pokegearbg")
    end
    @sprites["command_window"] = Window_CommandPokemon.new(commands,160)
    @sprites["command_window"].index = @menu_index
    @sprites["command_window"].x = Graphics.width
    @sprites["command_window"].y = -3000 #0
    for i in 0...commands.length
      x=118
      y=196 - (commands.length*24) + (i*48)
      @sprites["button#{i}"]=PokegearButton.new(x,y,commands[i],i,@viewport)
      @sprites["button#{i}"].selected=(i==@sprites["command_window"].index)
      @sprites["button#{i}"].update
    end
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      if $scene != self
        break
      end
    end
    Graphics.freeze
    pbDisposeSpriteHash(@sprites)
  end
  
  def update_command
    if Input.trigger?(Input::B)
      pbPlayCancelSE()
      $scene = Scene_Map.new
      return
    end
    if Input.trigger?(Input::C)
      #####MODDED
      if @cmdRerollWeather>=0 && @sprites["command_window"].index==@cmdRerollWeather
        pbPlayDecisionSE()
        
        aChoices = Array.new()
        aChoices[aChoices.length]=_INTL("Select weather")
        aChoices[aChoices.length]=_INTL("Reroll weather week")
        if defined?($game_screen.aSetTime)
          aChoices[aChoices.length]=_INTL("Change time")
        end
        aChoices[aChoices.length]=_INTL("Cancel")
        
        choice = Kernel.pbMessage("What do you wish to do?",aChoices,aChoices.length)
        
        if choice >= 0
          if aChoices[choice] == "Select weather"
            #For future reference: "@weatherTypes=[ # bitmap(s), x per frame, y per frame, opacity per frame" is set at line 113 in PokemonFieldWeather
            choiceWType = Kernel.pbMessage("Select weather type",[_INTL("Clear"),_INTL("Rain"),_INTL("Storm"),_INTL("Snow"),_INTL("Sandstorm"),_INTL("Sunny"),_INTL("Windy"),_INTL("Heavy rain"),_INTL("Blizzard"),_INTL("Cancel")],10)
            
            choiceWPower = -1
            if choiceWType == 0
              choiceWPower = 0
            else
              if (choiceWType > 0) && (choiceWType < 9)
                choiceWPower = Kernel.pbMessage("Select weather strength",[_INTL("Normal"),_INTL("Harsh"),_INTL("Cancel")],3)
                choiceWPower = choiceWPower+1
              end
            end
            
            if (choiceWType >= 0) && (choiceWType < 9) && (choiceWPower >= 0) && (choiceWPower < 3)
              $game_screen.ChangeWeatherPlan(choiceWType, choiceWPower)
              
            end
          end
          if aChoices[choice] == "Reroll weather week"
            $game_screen.RerollWeather
            Kernel.pbMessage("One week will pass after you exit this area.")
            Kernel.pbMessage("Next week's weather: dry spell") if $game_variables[317] == 1
            Kernel.pbMessage("Next week's weather: showers") if $game_variables[317] == 2
            Kernel.pbMessage("Next week's weather: chilly") if $game_variables[317] == 3
            Kernel.pbMessage("Next week's weather: wet") if $game_variables[317] == 4
            Kernel.pbMessage("Next week's weather: blizzard") if $game_variables[317] == 5
            Kernel.pbMessage("Next week's weather: variety") if $game_variables[317] == 6
          end
          if aChoices[choice] == "Change time"
            aNow = Time.new
            
            #Reset time
            aCurTime = pbGetTimeNow
            
            params=ChooseNumberParams.new
            params.setRange(0,23)
            params.setDefaultValue(aCurTime.hour)
            
            aSecs = (Kernel.pbMessageChooseNumber(_INTL("What hour is it?"), params)-aNow.hour)*3600
            
            #Sunday = 0
            aSecs = aSecs+(Kernel.pbMessage("Which weekday?",[_INTL("Sunday"),_INTL("Monday"),_INTL("Tuesday"),_INTL("Wednesday"),_INTL("Thursday"),_INTL("Friday"),_INTL("Saturday")],aCurTime.wday+1)-aNow.wday)*86400
            if aSecs < 0
              aSecs = aSecs+604800 #+1 week worth of seconds
            end
            
            #Finish
            $game_screen.aSetTime(aNow+aSecs)

            aCurTime = pbGetTimeNow
            if aCurTime.wday == 0
              Kernel.pbMessage(_INTL("Day: Sunday, hour: {1}", aCurTime.hour))
            end
            if aCurTime.wday == 1
              Kernel.pbMessage(_INTL("Day: Monday, hour: {1}", aCurTime.hour))
            end
            if aCurTime.wday == 2
              Kernel.pbMessage(_INTL("Day: Tuesday, hour: {1}", aCurTime.hour))
            end
            if aCurTime.wday == 3
              Kernel.pbMessage(_INTL("Day: Wednesday, hour: {1}", aCurTime.hour))
            end
            if aCurTime.wday == 4
              Kernel.pbMessage(_INTL("Day: Thursday, hour: {1}", aCurTime.hour))
            end
            if aCurTime.wday == 5
              Kernel.pbMessage(_INTL("Day: Friday, hour: {1}", aCurTime.hour))
            end
            if aCurTime.wday == 6
              Kernel.pbMessage(_INTL("Day: Saturday, hour: {1}", aCurTime.hour))
            end
            
            #Reset the lottery minigame (there are easier ways to cheat)
            # Last lottery: $PokemonGlobal.eventvars[[@map_id,@event_id]]=time
            # @map_id = 117
            # @event_id = 3
            # time = pbGetTimeNow (and time=time.to_i)
            $PokemonGlobal.eventvars={} if !$PokemonGlobal.eventvars
            $PokemonGlobal.eventvars[[117,3]]=0

            #Update the clock
            pbGetTimeNow
            
            #Reset the weather calendar
            $game_screen.RerollWeather
          end
        end
      end
      #####/MODDED
      if @cmdMap>=0 && @sprites["command_window"].index==@cmdMap
        pbPlayDecisionSE()               
        pbShowMap(-1,false)
      end
      if @cmdPhone>=0 && @sprites["command_window"].index==@cmdPhone
        pbPlayDecisionSE()
        pbFadeOutIn(99999) {
           PokemonPhoneScene.new.start
        }
      end
      if @cmdJukebox>=0 && @sprites["command_window"].index==@cmdJukebox
        pbPlayDecisionSE()
        $scene = Scene_Jukebox.new
      end
      if @cmdOnline>=0 && @sprites["command_window"].index==@cmdOnline
        pbPlayDecisionSE()
        if Kernel.pbConfirmMessage(_INTL("Would you like to save the game?"))
          if pbSave
            Kernel.pbMessage("Saved the game!")
            tryConnect
          else
            Kernel.pbMessage("Save failed.")
          end
        end        
      end          
      if @cmdPulse>=0 && @sprites["command_window"].index==@cmdPulse
        pbPlayDecisionSE()
        $scene = Scene_PulseDex.new
      end
      
      if @cmdNotes>=0 && @sprites["command_window"].index==@cmdNotes
        pbPlayDecisionSE()
        $scene = Scene_FieldNotes.new
      end
      
      return
    end
  end
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
