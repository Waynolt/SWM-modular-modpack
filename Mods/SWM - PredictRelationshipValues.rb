#####MODDED
def swm_pbPsychic(seer, gender)
  Kernel.pbMessage(_INTL('{1} is trying to reach out to your friends\' minds', seer))
  Kernel.pbMessage(_INTL('{1} is sneaking in your foes\' thoughts...', seer))
  if gender == 0
    msg = _INTL('{1} wants to let you know what did he find in there', seer)
  elsif gender == 1
    msg = _INTL('{1} wants to let you know what did she find in there', seer)
  else
    msg = _INTL('{1} wants to let you know what did it find in there', seer)
  end
  
  return nil if Kernel.pbMessage(msg, [_INTL('Ok'), _INTL('Nevermind')], 2) != 0
  values = swm_getRelationshipValues
  return Kernel.pbMessage(_INTL('Relationship Values'), values, values.length)
end

def swm_getRelationshipValues
  values = []
  suffix = 'relationship'
  mapping = {
    'relaceshionship': 'Ace'
  }
  max = $cache.RXsystem.variables.length
  for i in 0...max
    var = $cache.RXsystem.variables[i]
    next if !var
    name = swn_getCharName(var, suffix, mapping)
    next if !name
    values.push(_INTL('{1}: {2}', name, $game_variables[i]))
  end
  values = values.sort
  return values
end

def swn_getCharName(var, suffix, mapping)
  varLower = var.downcase.strip
  if varLower.end_with?(suffix)
    # Standard
    return var.slice(0,var.length-suffix.length).strip
  end
  sym = varLower.to_sym
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
     Kernel.pbMessage(_INTL('{1} used {2}!',pokemon.name,getMoveName(move)))
   end
   swm_pbPsychic(pokemon.name, pokemon.gender)
   return true
})
#####/MODDED

class PokemonScreen
  def passwordUseTMX(pkmn)
    # Find TMs
    aMoves = []
    aCmds = []
    for machine in $PokemonBag.pockets[4]
      atk = pbGetTM(machine)
      if HiddenMoveHandlers.hasHandler(atk)
        aMoves.push(atk)
        # aCmds.push(_INTL("{1}: {2}", $cache.items[aItem][ITEMNAME], getMoveName(atk)))
        aCmds.push(_INTL("{1}", getMoveName(atk)))
      end
    end

    # There is no Headbutt TM
    atk = :HEADBUTT
    aMoves.push(atk)
    aCmds.push(_INTL("{1}", getMoveName(atk)))

    if Reborn
      # Adding Dig to the list
      atk = :DIG
      aMoves.push(atk)
      aCmds.push(_INTL("{1}", getMoveName(atk)))

      # Adding Teleport to the list
      atk = :TELEPORT
      aMoves.push(atk)
      aCmds.push(_INTL("{1}", getMoveName(atk)))

      #####MODDED
      # You hardcoded all of this??? :(
      atk = :PSYCHIC
      aMoves.push(atk)
      aCmds.push(_INTL("{1}", getMoveName(atk)))
      ######/MODDED
    end

    # Adding Sweet Scent to the list
    atk = :SWEETSCENT
    aMoves.push(atk)
    aCmds.push(_INTL("{1}", getMoveName(atk)))

    # Sort TMs
    counter = 1
    while counter < aCmds.length
      index = counter
      while index > 0
        indexPrev = index - 1

        firstName  = getMoveName(aMoves[indexPrev])
        secondName = getMoveName(aMoves[index])

        firstName = "AAAA" if firstName == "Fly"
        secondName = "AAAA" if secondName == "Fly"

        if firstName > secondName
          aux               = aCmds[index]
          aCmds[index]      = aCmds[indexPrev]
          aCmds[indexPrev]  = aux

          aux               = aMoves[index]
          aMoves[index]     = aMoves[indexPrev]
          aMoves[indexPrev] = aux
        end
        index -= 1
      end
      counter += 1
    end

    # Add "None"
    aMoves = aMoves + [-1]
    aCmds = aCmds + ["None"]

    iC = Kernel.pbMessage(_INTL("Which TM should be used?"), aCmds, aCmds.length)
    if !(aCmds[iC] == "None")
      atk = aMoves[iC]
      if Kernel.pbCanUseHiddenMove?(pkmn, atk)
        @scene.pbEndScene
        if atk == :FLY
          if $cache.mapdata[$game_map.map_id].MapPosition.is_a?(Hash)
            region = pbUnpackMapHash[0]
          else
            region = $cache.mapdata[$game_map.map_id].MapPosition[0]
          end

          if $game_switches[:Blindstep]
            ret = Blindstep.flyMenu
          else
            scene = PokemonRegionMapScene.new(region, false)
            screen = PokemonRegionMap.new(scene)
            ret = screen.pbStartFlyScreen
          end

          if ret
            $PokemonTemp.flydata = ret
            return [pkmn, atk]
          end
          @scene.pbStartScene(@party, @party.length > 1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
        else
          return [pkmn, atk]
        end
      end
    end

    return []
  end
end

def Kernel.pbUseKeyItem
  begin
    # TODO: Remember move order
    moves = [:CUT, :DEFOG, :DIG, :DIVE, :FLASH, :FLY, :HEADBUTT, :ROCKCLIMB, :ROCKSMASH,
             :SECRETPOWER, :STRENGTH, :SURF, :SWEETSCENT, :TELEPORT, :WATERFALL,
             :WHIRLPOOL]
    moves.push(:PSYCHIC) #####MODDED
    realmoves = []
    realitems = []
    for i in $PokemonBag.registeredItems
      realitems.push(i) if $PokemonBag.pbHasItem?(i)
    end
    if realitems.length == 0 && realmoves.length == 0
      Kernel.pbMessage(_INTL("An item in the Bag can be registered to this key for instant use."))
    elsif realitems.length == 1 && realmoves.length == 0
      Kernel.pbUseKeyItemInField(realitems[0])
    else
      # $game_temp.in_menu = true
      $game_map.update
      sscene = PokemonReadyMenu_Scene.new
      sscreen = PokemonReadyMenu.new(sscene)
      sscreen.pbStartReadyMenu(realmoves, realitems)
      # $game_temp.in_menu = false
    end
  rescue
    pbPrintException($!)
  end
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
