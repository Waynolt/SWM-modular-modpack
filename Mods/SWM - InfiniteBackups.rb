def pbSave(safesave=false)
  if $PokemonSystem.backup == 0
    counter = 0
    trainer    = nil
    mapid      = nil
    framecount = nil
    system     = nil
    if $game_variables[27]>1
      actual_savename="Game_"+$game_variables[27].to_s+".rxdata"
    else
      actual_savename="Game.rxdata"
    end
    if safeExists?(RTP.getSaveFileName(actual_savename))
      File.open(RTP.getSaveFileName(actual_savename),  'rb') {|save|
        trainer    = Marshal.load(save) # Trainer 
        framecount = Marshal.load(save) # Graphics
        system     = Marshal.load(save) # Game System
        Marshal.load(save)              # Pokemon System
        mapid      = Marshal.load(save) # Map ID 
      }
      number = 1
      if trainer.saveNumber
        number += trainer.saveNumber
      end
      if !$PokemonSystem.backupNames
        $PokemonSystem.backupNames = []
        number = 1
      end
=begin #####MODDED
      if number > $PokemonSystem.maxBackup 
        for i in 0...(number - $PokemonSystem.maxBackup )
          if $PokemonSystem.backupNames[i]
            if safeExists?(RTP.getSaveFileName($PokemonSystem.backupNames[i]))
              File.delete(RTP.getSaveFileName($PokemonSystem.backupNames[i]))
            end
          end
        end
      end
=end #####MODDED
      totalsec = framecount / 40 #Graphics.frame_rate  #Because Turbo exists
      hour = totalsec / 60 / 60
      min = totalsec / 60 % 60
      map = pbGetMapNameFromId(mapid)
      trainame = trainer.name
      trainame.gsub!(/[^0-9A-Za-z]/, '')
      savename = "Game - #{number} - #{trainame} - #{hour}h #{min}m - #{trainer.numbadges} badges.rxdata"
      if $game_variables[27]>1
        savename = "Game_#{$game_variables[27]} - #{number} - #{trainame} - #{hour}h #{min}m - #{trainer.numbadges} badges.rxdata"
      end      
      $Trainer.lastSave   = savename
      $Trainer.saveNumber = number
      $PokemonSystem.backupNames.push(savename)
       File.open(RTP.getSaveFileName(actual_savename),  'rb') {|oldsave|
        File.open(RTP.getSaveFileName("#{savename}"), 'wb') {|backup|
          while line = oldsave.read(4096)
            backup.write line
          end
        }
      }
    end
  end
  return pbSaveOld(safesave)
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
