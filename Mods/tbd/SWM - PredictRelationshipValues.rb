#####MODDED
def swm_pbPsychic(seer, gender)
  Kernel.pbMessage(_INTL('{1} is trying to reach out to your friends\' minds', seer))
  Kernel.pbMessage(_INTL('{1} is sneaking in your foes\' thoughts...', seer))
  if gender == 0
    msg=_INTL('{1} wants to let you know what did he find in there', seer)
  elsif gender == 1
    msg=_INTL('{1} wants to let you know what did she find in there', seer)
  else
    msg=_INTL('{1} wants to let you know what did it find in there', seer)
  end
  
  return nil if Kernel.pbMessage(msg, [_INTL('Ok'), _INTL('Nevermind')], 2) != 0
  values=swm_getRelationshipValues
  return Kernel.pbMessage(_INTL('Relationship Values'), values, values.length)
end

def swm_getRelationshipValues
  values=[]
  suffix='relationship'
  mapping={
    'relaceshionship': 'Ace'
  }
  max=$cache.RXsystem.variables.length
  for i in 0...max
    var=$cache.RXsystem.variables[i]
    next if !var
    name=swn_getCharName(var, suffix, mapping)
    next if !name
    values.push(_INTL('{1}: {2}', name, $game_variables[i]))
  end
  values=values.sort
  return values
end

def swn_getCharName(var, suffix, mapping)
  varLower=var.downcase.strip
  if varLower.end_with?(suffix)
    # Standard
    return var.slice(0,var.length-suffix.length).strip
  end
  sym=varLower.to_sym
  if mapping[sym]
    # Extra values
    return mapping[sym]
  end
  # if varLower.include?('ace')
  #   # Search results
  #   return _INTL('|{1}|', varLower)
  # end
  return nil
end

HiddenMoveHandlers::CanUseMove.add(:PSYCHIC,lambda{|move,pkmn|
   return true
})

HiddenMoveHandlers::UseMove.add(:PSYCHIC,lambda{|move,pokemon|
   if !pbHiddenMoveAnimation(pokemon)
     Kernel.pbMessage(_INTL('{1} used {2}!',pokemon.name,PBMoves.getName(move)))
   end
   swm_pbPsychic(pokemon.name, pokemon.gender)
   return true
})
#####/MODDED

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
