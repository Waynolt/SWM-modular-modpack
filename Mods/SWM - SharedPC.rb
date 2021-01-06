#####MODDED
class PokemonStorage
  def SetBox(x,value)
    @boxes[x]=value
    
    if $Trainer
      for i in 0...value.length
        poke = value[i]
        if poke
          if !poke.isEgg?
            $Trainer.seen[poke.species]=true
            $Trainer.owned[poke.species]=true
          end
        end
      end
    end
  end
end
#####/MODDED

module Kernel
  def self.pbTicketClear
    #####MODDED
    aSharedBox = $PokemonStorage[$PokemonStorage.maxBoxes-1]
    for i in 0...aSharedBox.length
      poke = aSharedBox[i]
      if poke
        if !poke.isEgg?
          $Trainer.seen[poke.species]=true
          $Trainer.owned[poke.species]=true
        end
      end
    end
    #####/MODDED
    
    @sprites.clear
    @viewport.dispose
  end
end
  
class PokemonLoad
  #####MODDED
  def LoadSharedBox()
    if safeExists?(RTP.getSaveFileName("SharedPC.rxdata"))
      if $PokemonStorage[$PokemonStorage.maxBoxes-1].name == "TestSharedPC"
        sTest_Name = "SharedPCTest"
      else
        sTest_Name = "TestSharedPC"
      end
      #Try to check if the file can be read
      File.open(RTP.getSaveFileName("SharedPC.rxdata")){|f|
        if f.read(2) == Marshal.dump("")[0,2]
          if $PokemonStorage[$PokemonStorage.maxBoxes-1].name == "TestSharedPC"
            $PokemonStorage[$PokemonStorage.maxBoxes-1].name = "SharedPCTest"
          else
            $PokemonStorage[$PokemonStorage.maxBoxes-1].name = "TestSharedPC"
          end
        else
          Kernel.pbMessage("SharedPC.rxdata may be corrupted; could not load the shared box.")
          Kernel.pbMessage("If at the moment you aren't trying to import pokemon through it, then there's no reason to try and restore it.")
          Kernel.pbMessage("Simply save the game and it will be replaced.")
        end
      }
      #If the file can be read, then load it
      if $PokemonStorage[$PokemonStorage.maxBoxes-1].name == sTest_Name
        File.open(RTP.getSaveFileName("SharedPC.rxdata")){|f|
          $PokemonStorage.SetBox($PokemonStorage.maxBoxes-1, Marshal.load(f))
          $PokemonStorage[$PokemonStorage.maxBoxes-1].name = "Shared Box"
        }
      end
    end
  end
  #####/MODDED
  
  def pbStartLoadScreen(savenum=0,auto=nil,savename="Save Slot 1")
    $PokemonTemp   = PokemonTemp.new
    $game_temp     = Game_Temp.new
    $game_system   = Game_System.new
    $PokemonSystem = PokemonSystem.new if !$PokemonSystem
    cmdContinue    = -1
    cmdNewGame     = -1
    cmdControls    = -1
    cmdChooseSaveFile = -1
    cmdOption      = -1
    cmdLanguage    = -1
    cmdMysteryGift = -1
    cmdQuit        = -1
    cmdDeleteSaveFile = -1
    commands       = []
    savedir = RTP.getSaveFileName("Game.rxdata")
    savefolder = savedir[0..savedir.size-12]
    latestsavefile = savefolder + "latest_save.txt"
    if safeExists?(latestsavefile)
      savefileName = File.open(latestsavefile) {|f| f.readline}
      savenum = savefileName.to_i
      if savenum >= 2
        savename = "Save Slot " + savenum.to_s
      end
    end
    
    if auto != nil
      if savenum==0 || savenum==1
        savefile=RTP.getSaveFileName("Game_autosave.rxdata")
      else
        savefile = RTP.getSaveFileName("Game_"+savenum.to_s+"_autosave.rxdata")
      end
    elsif savenum==0 || savenum==1
      savefile=RTP.getSaveFileName("Game.rxdata")
    else
      savefile = RTP.getSaveFileName("Game_"+savenum.to_s+".rxdata")
    end
    #savefile = RTP.getSaveFileName("Game.rxdata")
    FontInstaller.install if !$MKXP # ~Zoro
    data_system = pbLoadRxData("Data/System")
    mapfile=$RPGVX ? sprintf("Data/Map%03d.rvdata",data_system.start_map_id) :
                     sprintf("Data/Map%03d.rxdata",data_system.start_map_id)
    if data_system.start_map_id==0 || !pbRgssExists?(mapfile)
      Kernel.pbMessage(_INTL("No starting position was set in the map editor.\1"))
      Kernel.pbMessage(_INTL("The game cannot continue."))
      @scene.pbEndScene
      $scene=nil
      return
    end
    if safeExists?(savefile)
      trainer=nil
      #success = false
      framecount=0
      mapid=0
      showContinue=false
      haveBackup=false
      begin
        trainer, framecount, $game_system, $PokemonSystem, mapid=pbTryLoadFile(savefile)
        showContinue=true
      rescue
#        while !success
        if safeExists?(RTP.getSaveFileName(trainer.lastSave))
          begin
            trainer, framecount, $game_system, $PokemonSystem, mapid=pbTryLoadFile(savefile+".bak")
            haveBackup  = true
            showContinue= true
          rescue
          end
        end
        if haveBackup
          Kernel.pbMessage(_INTL("The save file is corrupt.  The previous save file will be loaded."))
        else
          Kernel.pbMessage(_INTL("The save file is corrupt, or is incompatible with this game."))
          if !Kernel.pbConfirmMessageSerious(_INTL("Do you want to delete the save file and start anew?"))
            raise "scss error - Corrupted or incompatible save file."
          end
          begin; File.delete(savefile); rescue; end
          begin; File.delete(savefile+".bak"); rescue; end
          $game_system=Game_System.new
          $PokemonSystem=PokemonSystem.new if !$PokemonSystem
          Kernel.pbMessage(_INTL("The save file was deleted."))
        end
      end
      if showContinue
        if !haveBackup
          begin; File.delete(savefile+".bak"); rescue; end
        end
      end
      commands[cmdContinue=commands.length]=_INTL("Continue") if showContinue
      commands[cmdNewGame=commands.length]=_INTL("New Game")
      commands[cmdChooseSaveFile=commands.length]=_INTL("Other Save Files")
      commands[cmdDeleteSaveFile=commands.length]=_INTL("Delete This Save File")
      commands[cmdMysteryGift=commands.length]=_INTL("Mystery Gift") if (trainer.mysterygiftaccess rescue false)
      commands[cmdOption=commands.length]=_INTL("Options")
      commands[cmdControls=commands.length]=_INTL("Controls")
    else
      commands[cmdNewGame=commands.length]=_INTL("New Game")
      commands[cmdChooseSaveFile=commands.length]=_INTL("Other Save Files")
      commands[cmdOption=commands.length]=_INTL("Options")
      commands[cmdControls=commands.length]=_INTL("Controls")
    end
    if LANGUAGES.length>=2
      commands[cmdLanguage=commands.length]=_INTL("Language")
    end
    #commands[cmdQuit=commands.length]=_INTL("Quit Game")
    @scene.pbStartScene(commands,showContinue,trainer,framecount,mapid)
    @scene.pbSetParty(trainer) if showContinue
    @scene.pbStartScene2
#    @scene.pbDrawCurrentSaveFile(savename,auto)
    loop do
      command=@scene.pbChoose(commands)
      deleting=false
      if cmdDeleteSaveFile>=0 && command==cmdDeleteSaveFile
        if Kernel.pbConfirmMessageSerious(_INTL("Are you sure you want to delete this save file?"))
          if Kernel.pbConfirmMessageSerious(_INTL("All data will be lost.  Confirm once more to proceed."))
            begin; File.delete(savefile); rescue; end
            begin; File.delete(savefile+".bak"); rescue; end
            deleting=true
            @scene.pbClearOverlay2
            @scene.pbEndScene
            return
            pbSetUpSystem(0,nil)
            scene=PokemonLoadScene.new
            screen=PokemonLoad.new(scene)
            screen.pbStartLoadScreen(0,nil)
          end
        end
        retry if deleting==false
      elsif cmdContinue>=0 && command==cmdContinue
        unless safeExists?(savefile)
          pbPlayBuzzerSE()
          next
        end
        @scene.pbEndScene        
        metadata = nil
        File.open(savefile){|f|
          Marshal.load(f) # Trainer already loaded
          $Trainer             = trainer
          Graphics.frame_count = Marshal.load(f)
          $game_system         = Marshal.load(f)
          Marshal.load(f) # PokemonSystem already loaded
          Marshal.load(f) # Current map id no longer needed
          $game_switches       = Marshal.load(f)
          $game_variables      = Marshal.load(f)
          $game_self_switches  = Marshal.load(f)
          $game_screen         = Marshal.load(f)
          $MapFactory          = Marshal.load(f)
          $game_map            = $MapFactory.map
          $game_player         = Marshal.load(f)
          $PokemonGlobal       = Marshal.load(f)
          metadata             = Marshal.load(f)
          $ItemData            = readItemList("Data/items.dat")
          $PokemonBag          = Marshal.load(f)
          $PokemonStorage      = Marshal.load(f)

          xsave = savefile[0..savefile.size-8]
          slot = xsave.split("_")[-1]
          if slot.to_i.to_s == slot
            $game_variables[27] = slot.to_i
          else
            $game_variables[27] = 0
          end
          
          magicNumberMatches=false
          if $data_system.respond_to?("magic_number")
            magicNumberMatches=($game_system.magic_number==$data_system.magic_number)
          else
            magicNumberMatches=($game_system.magic_number==$data_system.version_id)
          end
          if !magicNumberMatches || $PokemonGlobal.safesave
            if pbMapInterpreterRunning?
              pbMapInterpreter.setup(nil,0)
            end
            begin
              $MapFactory.setup($game_map.map_id) # calls setMapChanged
            rescue Errno::ENOENT
              if $DEBUG
                Kernel.pbMessage(_INTL("Map {1} was not found.",$game_map.map_id))
                map = pbWarpToMap()
                if map
                  $MapFactory.setup(map[0])
                  $game_player.moveto(map[1],map[2])
                else
                  $game_map=nil
                  $scene=nil
                  return
                end
              else
                $game_map=nil
                $scene=nil
                Kernel.pbMessage(_INTL("The map was not found. The game cannot continue."))
              end
            end
            $game_player.center($game_player.x, $game_player.y)
          else
            $MapFactory.setMapChanged($game_map.map_id)
          end
        }
        LoadSharedBox() #####MODDED
        if !$game_map.events # Map wasn't set up
          $game_map=nil
          $scene=nil
          Kernel.pbMessage(_INTL("The map is corrupt. The game cannot continue."))
          return
        end
        $PokemonMap=metadata
        $PokemonEncounters=PokemonEncounters.new
        $PokemonEncounters.setup($game_map.map_id)
        pbAutoplayOnSave
        $game_map.update
        auto=(auto==nil)?false:auto
        pbStoredLastPlayed($game_variables[27],auto)
        $scene = Scene_Map.new
        return
      elsif cmdNewGame>=0 && command==cmdNewGame
        @scene.pbEndScene
        if $game_map && $game_map.events
          for event in $game_map.events.values
            event.clear_starting
          end
        end
        $game_temp.common_event_id=0 if $game_temp
        $scene               = Scene_Map.new
        Graphics.frame_count = 0
        $game_system         = Game_System.new
        $game_switches       = Game_Switches.new
        $game_variables      = Game_Variables.new
        $game_self_switches  = Game_SelfSwitches.new
        $game_screen         = Game_Screen.new
        $game_player         = Game_Player.new
        $ItemData            = readItemList("Data/items.dat")
        $PokemonMap          = PokemonMapMetadata.new
        $PokemonGlobal       = PokemonGlobalMetadata.new
        $PokemonStorage      = PokemonStorage.new
        $PokemonEncounters   = PokemonEncounters.new
        $PokemonTemp.begunNewGame=true
        $data_system         = pbLoadRxData("Data/System")
        $MapFactory          = PokemonMapFactory.new($data_system.start_map_id) # calls setMapChanged
        $game_player.moveto($data_system.start_x, $data_system.start_y)
        $game_player.refresh
        $game_map.autoplay
        $game_map.update
        LoadSharedBox() #####MODDED
        
        #find next available slot
        checksave=RTP.getSaveFileName("Game.rxdata")
        if !safeExists?(checksave)
          $game_variables[27]=0
        else
          j=2
          loop do
            checksave=RTP.getSaveFileName("Game_"+j.to_s+".rxdata")
            if !safeExists?(checksave)
              $game_variables[27]=j
              break
            end
            j+=1
          end
        end
        auto=(auto==nil)?false:auto
        pbStoredLastPlayed($game_variables[27],auto)
        return
      elsif cmdMysteryGift>=0 && command==cmdMysteryGift
        pbFadeOutIn(99999){
           trainer=pbDownloadMysteryGift(trainer)
        }
      elsif cmdChooseSaveFile>=0 &&  command==cmdChooseSaveFile
        cancelled=false
        saveslots=[]
        newsavecheck=RTP.getSaveFileName("Game.rxdata")  #load first save file outside the loop, since a save number isn't involved
        newautosavecheck=RTP.getSaveFileName("Game_autosave.rxdata")
        if safeExists?(newsavecheck)
          hasauto=(safeExists?(newautosavecheck))?true:false
          if hasauto==true
              t=File.mtime(newautosavecheck) rescue pbGetTimeNow
              autosavetime=t.strftime("%c")
            else
              autosavetime=""
          end
          t=File.mtime(newsavecheck) rescue pbGetTimeNow
          savetime=t.strftime("%c")
          info = saveinfo(newsavecheck)
          slotname = "Save Slot 1 " + info
          saveslots.push([1,slotname,hasauto,true,savetime,autosavetime])
        elsif safeExists?(newautosavecheck)
          t=File.mtime(newautosavecheck) rescue pbGetTimeNow
          autosavetime=t.strftime("%c")
          savetime=""
          info = saveinfo(newsavecheck)
          slotname = "Save Slot 1" + info
          saveslots.push([1,slotname,true,false,savetime,autosavetime])
        end
        i=2
        loop do
          newsavecheck=RTP.getSaveFileName("Game_"+i.to_s+".rxdata")
          newautosavecheck=RTP.getSaveFileName("Game_"+i.to_s+"_autosave.rxdata")
          if safeExists?(newsavecheck)
            t=File.mtime(newsavecheck) rescue pbGetTimeNow
            savetime=t.strftime("%c")
            hasauto=(safeExists?(newautosavecheck))?true:false
            if hasauto==true
              t=File.mtime(newautosavecheck) rescue pbGetTimeNow
              autosavetime=t.strftime("%c")
            else
              autosavetime=""
            end
            info = saveinfo(newsavecheck)
            slotname = "Save Slot #{i}" + info
            slotname=sprintf("Save Slot %d ",i)
            saveslots.push([i,slotname,hasauto,true,savetime,autosavetime])
            #Kernel.pbMessage(_INTL("{1}",saveslots))
          elsif  safeExists?(newautosavecheck)
            t=File.mtime(newautosavecheck) rescue pbGetTimeNow
            savetime=""
            autosavetime=t.strftime("%c")
            info = saveinfo(newsavecheck)
            slotname = "Save Slot #{i}" + info
            slotname=sprintf("Save Slot %d ",i)
            saveslots.push([i,slotname,true,false,savetime,autosavetime])
          else  #don't break quite yet, in case save file in middle was removed
             newi=(i+1)
             newsavecheck=RTP.getSaveFileName("Game_"+newi.to_s+".rxdata")
             newautosavecheck=RTP.getSaveFileName("Game_"+newi.to_s+"_autosave.rxdata")
             if safeExists?(newsavecheck)
                i=newi
                t=File.mtime(newsavecheck) rescue pbGetTimeNow
                savetime=t.strftime("%c")
                hasauto=(safeExists?(newautosavecheck))?true:false
                if hasauto==true
                  t=File.mtime(newautosavecheck) rescue pbGetTimeNow
                  autosavetime=t.strftime("%c")
                else
                  autosavetime=""
                end
                info = saveinfo(newsavecheck)
                slotname = "Save Slot #{newi}" + info
                slotname=sprintf("Save Slot %d",newi)
                saveslots.push([newi,slotname,hasauto,true,savetime,autosavetime])
             elsif  safeExists?(newautosavecheck)
                i=newi
                t=File.mtime(newautosavecheck) rescue pbGetTimeNow
                autosavetime=t.strftime("%c")
                savetime=""
                info = saveinfo(newsavecheck)
                slotname = "Save Slot #{newi}" + info
                slotname=sprintf("Save Slot %d",newi)
                saveslots.push([newi,slotname,true,false,savetime,autosavetime])
             else  #give one extra slot space check
               newi+=1
               newsavecheck=RTP.getSaveFileName("Game_"+newi.to_s+".rxdata")
               newautosavecheck=RTP.getSaveFileName("Game_"+newi.to_s+"_autosave.rxdata")
               if safeExists?(newsavecheck)
                  i=newi
                  t=File.mtime(newsavecheck) rescue pbGetTimeNow
                  savetime=t.strftime("%c")
                  hasauto=(safeExists?(newautosavecheck))?true:false
                  if hasauto==true
                    t=File.mtime(newautosavecheck) rescue pbGetTimeNow
                    autosavetime=t.strftime("%c")
                  else
                    autosavetime=""
                  end
                  info = saveinfo(newsavecheck)
                  slotname = "Save Slot #{newi}" + info
                  slotname=sprintf("Save Slot %d",newi)
                  saveslots.push([newi,slotname,hasauto,true,savetime,autosavetime])
               elsif  safeExists?(newautosavecheck)
                  i=newi
                  t=File.mtime(newautosavecheck) rescue pbGetTimeNow
                  autosavetime=t.strftime("%c")
                  savetime=""
                  info = saveinfo(newsavecheck)
                  slotname = "Save Slot #{newi}" + info
                  slotname=sprintf("Save Slot %d",newi)
                  saveslots.push([newi,slotname,true,false,savetime,autosavetime])
               else
                 break
               end
             end  
           end
           i+=1
         end  
         if saveslots.length>=1
           for i in 1..21 #move the commands and other graphics
             @scene.pbMoveSprites(i*2)
             Graphics.update
           end  
             @scene.pbDrawSaveCommands(saveslots)
             #@scene.pbDrawSaveText(saveslots)
             Graphics.update
             @selected=0
             loop do
               Input.update
               Graphics.update
               if Input.trigger?(Input::DOWN)
                 #@scene.pbToggleSelecting
                 if @selected==saveslots.length-1
                   @selected=0
                 else
                   @selected+=1
                 end  
                 @scene.pbMoveSaveSel(@selected)
               elsif Input.trigger?(Input::UP)
                 if @selected==0
                   @selected=saveslots.length-1
                 else
                   @selected-=1
                 end
                 @scene.pbMoveSaveSel(@selected)
               elsif Input.trigger?(Input::B)
                 @scene.pbRemoveSaveCommands
                 Graphics.update
                 for i in 1..21 #move the commands and other graphics
                   @scene.pbMoveSprites(i*-2)
                   Graphics.update
                 end
                 @scene.pbToggleSelecting
                 break
                elsif Input.trigger?(Input::C)
                  @scene.pbRemoveSaveCommands
                  if saveslots[@selected][2]==true && saveslots[@selected][3]==true
                     @scene.pbRemoveSaveCommands
                     Graphics.update
                     @scene.pbChooseAutoSubFile(0,@selected)
                     autoindex=0
                     loop do
                       Graphics.update
                       Input.update
                       if Input.trigger?(Input::LEFT)
                          if autoindex==0
                             autoindex=1
                             @scene.pbChooseAutoSubFile(1,@selected)
                          else
                             autoindex=0
                             @scene.pbChooseAutoSubFile(0,@selected)
                          end  
                        elsif Input.trigger?(Input::RIGHT)
                          if autoindex==1
                             autoindex=0
                             @scene.pbChooseAutoSubFile(0,@selected)
                          else
                             autoindex=1
                             @scene.pbChooseAutoSubFile(1,@selected)
                          end
                        elsif Input.trigger?(Input::C)  
                          break                    
                        end
                     end
                     auto=(autoindex==1)?true:nil
                     tempsave=saveslots[@selected][0]
                     @scene.pbEndScene
                     pbSetUpSystem(tempsave,auto)
                     scene=PokemonLoadScene.new
                     screen=PokemonLoad.new(scene)
                     screen.pbStartLoadScreen(tempsave,auto,saveslots[@selected][1])
                     return
                  elsif saveslots[@selected][2]==true
                    tempsave=saveslots[@selected][0]
                    @scene.pbEndScene
                    pbSetUpSystem(tempsave,true)
                    scene=PokemonLoadScene.new
                    screen=PokemonLoad.new(scene)
                    screen.pbStartLoadScreen(tempsave,true,saveslots[@selected][1])
                    return
                  else
                    tempsave=saveslots[@selected][0]
                    
                    savedir = RTP.getSaveFileName("Game.rxdata")
                    savefolder = savedir[0..savedir.size-12]
                    latestsavefile = savefolder + "latest_save.txt"
                    File.open(latestsavefile, 'w') { |file| file.write(tempsave) }
                    
                    @scene.pbEndScene
                    pbSetUpSystem(tempsave,nil)
                    scene=PokemonLoadScene.new
                    screen=PokemonLoad.new(scene)
                    screen.pbStartLoadScreen(tempsave,nil,saveslots[@selected][1])
                    return
                  end  
               end
             end  
             
          else
            Kernel.pbMessage(_INTL("You don't have any other save files"))
          end
      elsif cmdOption>=0 && command==cmdOption
        scene=PokemonOptionScene.new
        screen=PokemonOption.new(scene)
        pbFadeOutIn(99999) { screen.pbStartScreen }
      # control binding		
      elsif cmdControls>=0 && command==cmdControls		
        scene=PokemonControlsScene.new		
        screen=PokemonControls.new(scene)		
        pbFadeOutIn(99999) {		
          screen.pbStartScreen
        }
      elsif cmdLanguage>=0 && command==cmdLanguage
        @scene.pbEndScene
        $PokemonSystem.language=pbChooseLanguage
        pbLoadMessages("Data/"+LANGUAGES[$PokemonSystem.language][1])
        savedata=[]
        if safeExists?(savefile)
          File.open(savefile,"rb"){|f|
             15.times { savedata.push(Marshal.load(f)) }
          }
          savedata[3]=$PokemonSystem
          begin
            File.open(RTP.getSaveFileName("Game.rxdata"),"wb"){|f|
               15.times {|i| Marshal.dump(savedata[i],f) }
            }
          rescue; end
        end
        $scene=pbCallTitle
        return
#      elsif cmdQuit>=0 && command==cmdQuit
#        @scene.pbEndScene
#        $scene=nil
#        return        
      end
    end
    @scene.pbEndScene
    return
  end
end

def pbSaveOld(safesave=false)
  SaveSharedBox() #####MODDED
  
  $Trainer.metaID=$PokemonGlobal.playerID
  if $game_variables[27]>1
    savename="Game_"+$game_variables[27].to_s+".rxdata"
  else
    savename="Game.rxdata"
  end
  begin  
      File.open(RTP.getSaveFileName(savename),"wb"){|f|
       Marshal.dump($Trainer,f)
       Marshal.dump(Graphics.frame_count,f)
       if $data_system.respond_to?("magic_number")
         $game_system.magic_number = $data_system.magic_number
       else
         $game_system.magic_number = $data_system.version_id
       end
       $game_system.save_count+=1
       Marshal.dump($game_system,f)
       Marshal.dump($PokemonSystem,f)
       Marshal.dump($game_map.map_id,f)
       Marshal.dump($game_switches,f)
       Marshal.dump($game_variables,f)
       Marshal.dump($game_self_switches,f)
       Marshal.dump($game_screen,f)
       Marshal.dump($MapFactory,f)
       Marshal.dump($game_player,f)
       $PokemonGlobal.safesave=safesave
       Marshal.dump($PokemonGlobal,f)
       Marshal.dump($PokemonMap,f)
       Marshal.dump($PokemonBag,f)
       Marshal.dump($PokemonStorage,f)
     }
     Graphics.frame_reset
    rescue
    return false
  end
  pbStoredLastPlayed($game_variables[27],nil)
  return true
end

#####MODDED
def SaveSharedBox()
  sFile = RTP.getSaveFileName("SharedPC.rxdata")
  if safeExists?(sFile)
    File.delete(sFile)
  end
  File.open(sFile,"wb"){|f|
    Marshal.dump($PokemonStorage[$PokemonStorage.maxBoxes-1], f)
  }
end
#####/MODDED

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18") || !defined?(pbStoredLastPlayed)
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18.2")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
