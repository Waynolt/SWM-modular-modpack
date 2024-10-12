#####MODDED
$swm_loadedSharedBox = false

def swm_getSharedSaveFile
  folder = RTP.getSaveFolder().gsub(/[\/\\]$/,'')+'/../Pokemon Shared PC'
  Dir.mkdir(folder) unless (File.exists?(folder))
  return "#{folder}/SharedBox.rxdata"
end

def swm_loadSharedBox
  $swm_loadedSharedBox = true
  return nil if !$PokemonStorage
  return nil if !swm_ensureSharedSavedFile
  File.open(swm_getSharedSaveFile){|f|
    $PokemonStorage.swm_setSharedBoxContents(Marshal.load(f))
  }
end

def swm_ensureSharedSavedFile
  sharedSavefile = swm_getSharedSaveFile
  return true if safeExists?(sharedSavefile)
  # The file doesn't exist - create one
  $swm_loadedSharedBox = true # This way swm_saveSharedBox will save it even if it was not loaded
  return swm_saveSharedBox
end

def swm_saveSharedBox
  return false if !$swm_loadedSharedBox
  return false if !defined?($PokemonStorage)
  sharedSavefile = swm_getSharedSaveFile
  sharedSavefileTmp = "#{sharedSavefile}.tmp"
  sharedSavefileBackup = "#{sharedSavefile}.bak"
  boxNum = $PokemonStorage.swm_getSharedBoxId(true)
  if !boxNum
    Kernel.pbMessage(_INTL('ERROR: could not find an empty box in the PC to be used as the Shared Box'))
    return false
  end
  File.open(sharedSavefileTmp, 'wb'){|f|
    Marshal.dump($PokemonStorage[boxNum], f)
  }
  # The save didn't fail - shuffle the files around
  File.delete(sharedSavefileBackup) if safeExists?(sharedSavefileBackup)
  File.rename(sharedSavefile, sharedSavefileBackup) if safeExists?(sharedSavefile)
  File.rename(sharedSavefileTmp, sharedSavefile)
  return true
end
#####/MODDED

class StorageSystemPC
  #####MODDED
  # Try to catch newly created trainers
  if !defined?(swm_sharedPC_oldAccess)
    alias :swm_sharedPC_oldAccess :access
  end
  #####/MODDED

  def access(*args, **kwargs)
    #####MODDED
    # swm_getSharedBoxId(false) returns nil if no shared box has ever been loaded
    # If this is the case, try to load it now
    boxNum = $PokemonStorage.swm_getSharedBoxId(false)
    swm_loadSharedBox if !boxNum
    return swm_sharedPC_oldAccess(*args, **kwargs)
    #####/MODDED
  end
end

class PokemonStorage
  #####MODDED
  attr_accessor   :swm_sharedBoxNum

  def swm_getSharedBoxId(allowUndefined)
    if !defined?(@swm_sharedBoxNum) || !@swm_sharedBoxNum
      return nil if !allowUndefined
      return self.swm_setSharedBoxId
    end
    return @swm_sharedBoxNum
  end

  def swm_setSharedBoxId
    # Is there already a Shared Box?
    for boxNum in (self.maxBoxes-1).downto(0)
      next if !self.swm_isOldSharedBox?(boxNum)
      @swm_sharedBoxNum = boxNum
      return @swm_sharedBoxNum
    end
    # Find the last empty box
    for boxNum in (self.maxBoxes-1).downto(0)
      next if !self.swm_isBoxEmpty?(boxNum)
      @swm_sharedBoxNum = boxNum
      return @swm_sharedBoxNum
    end
    return nil
  end

  def swm_isOldSharedBox?(boxNum)
    return @boxes[boxNum].name == 'Shared Box'
  end

  def swm_isBoxEmpty?(boxNum)
    contents = @boxes[boxNum]
    for i in 0...contents.length
      return false if contents[i]
    end
    return true
  end

  def swm_setSharedBoxContents(value)
    return false if !$Trainer || $Trainer.nil? # Wait, what? We can have a PC but no player???
    # Only load the box if we already have loaded a box before
    # or if we can find an empty box to use
    boxNum = self.swm_getSharedBoxId(true)
    if !boxNum
      Kernel.pbMessage(_INTL('ERROR: could not find an empty box in the PC to be used as the Shared Box'))
      return false
    end
    @boxes[boxNum] = value
    @boxes[boxNum].name = 'Shared Box'
    # Update the pokedex
    if $Trainer.pokedex && !$Trainer.pokedex.nil? && $Trainer.pokedex.dexList && !$Trainer.pokedex.dexList.nil?
      for i in 0...value.length
        poke = value[i]
        next if !poke
        next if poke.isEgg?
        $Trainer.pokedex.dexList[poke.species][:seen?] = true
        $Trainer.pokedex.dexList[poke.species][:owned?] = true
        $Trainer.pokedex.dexList[poke.species][:formsOwned][poke.form] = true
      end
    end
    return true
  end
  #####/MODDED
end

class PokemonLoad
  #####MODDED
  if !defined?(swm_sharedPC_oldPbStartLoadScreen)
    alias :swm_sharedPC_oldPbStartLoadScreen :pbStartLoadScreen
  end

  def pbStartLoadScreen(*args, **kwargs)
    result = swm_sharedPC_oldPbStartLoadScreen(*args, **kwargs)
    swm_loadSharedBox
    return result
  end
  #####/MODDED
end

#####MODDED
if !defined?(swm_sharedPC_oldPbSave)
  alias :swm_sharedPC_oldPbSave :pbSave
end
#####/MODDED

def pbSave(*args, **kwargs)
  #####MODDED
  result = swm_sharedPC_oldPbSave(*args, **kwargs)
  swm_saveSharedBox
  return result
  #####/MODDED
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
