#####MODDED
def pbPsychic(sSeer, iGender)
  Kernel.pbMessage(_INTL("{1} is trying to reach out to your friends' minds", sSeer))
  Kernel.pbMessage(_INTL("{1} is sneaking in your foes' thoughts...", sSeer))
  
  if iGender == 0
    sTxt = _INTL("{1} wants to let you know what did he find in there", sSeer)
  elsif iGender == 1
    sTxt = _INTL("{1} wants to let you know what did she find in there", sSeer)
  else
    sTxt = _INTL("{1} wants to let you know what did it find in there", sSeer)
  end
  
  if Kernel.pbMessage(sTxt, ["Ok", "Nevermind"], 2) == 0
    aChoices = []
    
    #Find them
    iMax = $data_system.variables.length
    for i in 0...iMax
      sName = $data_system.variables[i]
      
      if sName
        if sName[sName.length-12..sName.length-1] == "Relationship"
          aChoices.push(_INTL("{1}: {2}", sName[0..sName.length-14], $game_variables[i]))
        end
      end
    end
    
    #Sort them
    counter = 1
    while counter < aChoices.length
      index     = counter
      while index > 0
        indexPrev = index - 1
        
        firstName  = aChoices[indexPrev]
        secondName = aChoices[index]
        
        if firstName > secondName
          aux                 = aChoices[index] 
          aChoices[index]     = aChoices[indexPrev]
          aChoices[indexPrev] = aux
        end
        index -= 1
      end
      counter += 1
    end
    
    Kernel.pbMessage("Relationship Values", aChoices, aChoices.length)
  end
end

HiddenMoveHandlers::CanUseMove.add(:PSYCHIC,proc{|move,pkmn|
   return true
})

HiddenMoveHandlers::UseMove.add(:PSYCHIC,proc{|move,pokemon|
   if !pbHiddenMoveAnimation(pokemon)
     Kernel.pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
   end
   pbPsychic(pokemon.name, pokemon.gender)
   return true
})
#####/MODDED

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
