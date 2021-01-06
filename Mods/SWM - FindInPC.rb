class PokemonStorageScreen
  #####MODDED
  def aNameContains(aFoundName, aNewName)
    iMax = aFoundName.length-aNewName.length
    for i in 0..iMax
      bMatches = true
      for i2 in 0...aNewName.length
        if !(aFoundName[i+i2] == aNewName[i2])
          bMatches = false
          break
        end
      end
      return true if bMatches
    end
    return false
  end
  def aFindPokemon
    iIsNickName = Kernel.pbMessage("What do you want to find?", ["Name", "Species", "Item"], 0) #0 prevents exiting without selecting an option
    #iFindEggs:
    #0 = Name
    #1 = Species
    #2 = Item
    
    if iIsNickName == 0
      iFindEggs = 1
      sSearch = pbEnterPokemonName("Nickname of the mon?",0,15,"")
    elsif iIsNickName == 1
      iFindEggs = Kernel.pbMessage("Include eggs in the search?", ["Yes", "No eggs", "Eggs only"], 0)  #0 prevents exiting without selecting an option
      #iFindEggs:
      #0 = eggs too
      #1 = no eggs
      #2 = eggs only
      
      sSearch = pbEnterPokemonName("Name of the species?",0,15,"")
    else
      iFindEggs = 1
      sSearch = pbEnterPokemonName("Item name?",0,15,"")
    end
    sName = sSearch.downcase
    
    aFoundArr = ["Done"]
    aFoundBoxes = [0]
    aFoundCount = [0]
    for iBox in 0...$PokemonStorage.maxBoxes
      bFound = false
      for i in 0...$PokemonStorage[iBox].length
        poke = $PokemonStorage[iBox, i]
        if poke
          if iFindEggs == 1
            next if poke.isEgg?
          elsif iFindEggs == 2
            next if !poke.isEgg?
          end
          
          if iIsNickName == 0
            sFound = poke.name
          elsif iIsNickName == 1
            sFound = PBSpecies.getName(poke.species)
          else
            if poke.item == 0
              next
            else
              sFound = $ItemData[poke.item][ITEMNAME]
            end
          end
          
          if aNameContains(sFound.downcase, sName)
            if bFound
              aFoundCount[aFoundCount.length-1] = aFoundCount[aFoundCount.length-1]+1
            else
              aFoundArr.push(_INTL("Jump to {1}", $PokemonStorage[iBox].name))
              aFoundBoxes.push(iBox)
              aFoundCount.push(1)
              bFound = true
            end
          end
        end
      end
    end
    
    if aFoundArr.length > 1
      for i in 1...aFoundArr.length
        aFoundArr[i] = _INTL("{1} ({2})", aFoundArr[i], aFoundCount[i])
      end
      
      if aFoundArr.length == 2
        sNumBoxes = _INTL("{1} box", aFoundArr.length-1)
      else
        sNumBoxes = _INTL("{1} boxes", aFoundArr.length-1)
      end
      
      iBox = Kernel.pbMessage(_INTL("'{1}' was found in {2}", sSearch, sNumBoxes), aFoundArr, 1)
      @scene.pbJumpToBox(aFoundBoxes[iBox]) if iBox > 0
    else
      if sSearch == ""
        Kernel.pbMessage(_INTL("Sorry, didn't find anything.", sSearch))
      else
        Kernel.pbMessage(_INTL("Sorry, '{1}' was not found.", sSearch))
      end
    end
  end
  #####/MODDED
  
  def pbBoxCommands
    commands=[
       _INTL("Jump"),
       _INTL("Wallpaper"),
       _INTL("Name"),
       _INTL("Find"), #####MODDED
       _INTL("Cancel"),
    ]
    command=pbShowCommands(
       _INTL("What do you want to do?"),commands)
    case command
      when 0
        destbox=@scene.pbChooseBox(_INTL("Jump to which Box?"))
        if destbox>=0
          @scene.pbJumpToBox(destbox)
        end
      when 1
        commands=[
          _INTL("Monochrome"),
          _INTL("Urban"),
          _INTL("Beach"),
          _INTL("Forest"),
          _INTL("Wasteland"),
          _INTL("Wilderness"),
          _INTL("Rustic"),
          _INTL("Snowy"),
          _INTL("Desert"),
          _INTL("Lake"),
          _INTL("Volcano"),
          _INTL("Crystal Cave"),
          _INTL("Library"),
          _INTL("Chess"),
          _INTL("Moon"),
          _INTL("Sword"),
          _INTL("Ruby"),
          _INTL("Sapphire"),
          _INTL("Emerald"),
          _INTL("Amethyst"),
          _INTL("Checks"),
          _INTL("Reborn"),
          _INTL("Meteor"),
          _INTL("Arceus")
        ]
        wpaper=pbShowCommands(_INTL("Pick the wallpaper."),commands)
        if wpaper>=0
          @scene.pbChangeBackground(wpaper)
        end
      when 2
        @scene.pbBoxName(_INTL("Box name?"),0,12)
      #####MODDED
      when 3
        aFindPokemon
      #####/MODDED
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
