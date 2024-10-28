#####MODDED
SWM_EV_LIMIT_PER_STAT = 252
SWM_EV_LIMIT_GLOBAL   = 510

def swm_manageEvGain(evgain, k, thispoke)
  return [] if evgain == 0
  messages = swm_handleIvEvGain(evgain, k, thispoke)
  swm_handleEvLimit(evgain, k, thispoke)
  return messages
end

def swm_handleIvEvGain(evgain, k, thispoke)
  if swm_getMonHasPowerItem(thispoke)
    # Excess EVs will be recovered later, in swm_handleEvLimit
    allowedGain = evgain
  else
    # This will prevent swm_handleEvLimit from lowering EVs if evgain is positive 
    maxGain = swm_getEvsForReachingTheGlobalLimit(thispoke)
    allowedGain = [maxGain, evgain].min
  end
  startIv = thispoke.iv[k]
  thispoke.ev[k] += allowedGain # evgain can be lower than 0
  while thispoke.ev[k] > SWM_EV_LIMIT_PER_STAT
    if thispoke.iv[k] < 31
      thispoke.ev[k] -= SWM_EV_LIMIT_PER_STAT
      thispoke.iv[k] += 1
    else
      thispoke.ev[k] = SWM_EV_LIMIT_PER_STAT
    end
  end
  while thispoke.ev[k] < 0
    if thispoke.iv[k] > 0
      thispoke.ev[k] += SWM_EV_LIMIT_PER_STAT
      thispoke.iv[k] -= 1
    else
      thispoke.ev[k] = 0
    end
  end
  ivgain = thispoke.iv[k]-startIv
  return swm_notifyIvChange(k, thispoke, ivgain)
end

def swm_getMonHasPowerItem(thispoke)
  return true if (thispoke.item == :MACHOBRACE) || (thispoke.itemInitial == :MACHOBRACE)
  return true if [:POWERWEIGHT, :POWERBRACER,:POWERBELT,:POWERANKLET,:POWERLENS,:POWERBAND].include?(thispoke.item)
  return true if [:CANONPOWERWEIGHT, :CANONPOWERBRACER,:CANONPOWERBELT,:CANONPOWERANKLET,:CANONPOWERLENS,:CANONPOWERBAND].include?(thispoke.item)
  return false
end

def swm_notifyIvChange(k, thispoke, ivgain)
  return [] if ivgain == 0
  case k
    when PBStats::HP
      stat = 'Hit Points'
    when PBStats::ATTACK
      stat = 'Attack'
    when PBStats::DEFENSE
      stat = 'Defense'
    when PBStats::SPEED
      stat = 'Speed'
    when PBStats::SPATK
      stat = 'Special Attack'
    when PBStats::SPDEF
      stat = 'Special Defense'
  end
  # case thispoke.gender
  #   when 0
  #     pronoun = 'he'
  #     possessive = 'his'
  #   when 1
  #     pronoun = 'she'
  #     possessive = 'her'
  #   else
  #     pronoun = 'it'
  #     possessive = 'its'
  # end
  if ivgain > 0
    return [
      _INTL('{1} is now skilled enough to grow stronger!', thispoke.name),
      _INTL('{1}\'s {2} has increased!', thispoke.name, stat)
    ]
  else
    return [
      _INTL('{1} has become weaker!', thispoke.name),
      _INTL('{1}\'s {2} has decreased!', thispoke.name, stat)
    ]
  end
end

def swm_handleEvLimit(evgain, k, thispoke)
  # Redistribute by removing from the lowest ev
  evdiff = -(swm_getEvsForReachingTheGlobalLimit(thispoke))
  if evgain < 0 && evdiff > 0
    # Reduce the EV we were already reducing first
    # Don't reduce the IV further - we do not want to risk a loop
    lowerBy = [thispoke.ev[k], evdiff].min
    thispoke.ev[k] -= lowerBy
    evdiff -= lowerBy
  end
  while evdiff > 0
    ev = swm_getLowestEv(k, thispoke) # Never results in k
    break if ev < 0 # All 0 already (???)
    lowerBy = [thispoke.ev[ev], evdiff].min
    thispoke.ev[ev] -= lowerBy
    evdiff -= lowerBy
  end
end

def swm_getEvsForReachingTheGlobalLimit(thispoke)
  # Redistribute by removing from the lowest ev
  if $game_switches[:No_Total_EV_Cap]
    maxRemainingEvGlobal = SWM_EV_LIMIT_PER_STAT * 3 * thispoke.ev.length
  else
    maxRemainingEvGlobal = SWM_EV_LIMIT_GLOBAL
  end
  for i in 0...thispoke.ev.length
    maxRemainingEvGlobal -= thispoke.ev[i]
  end
  return maxRemainingEvGlobal
end

def swm_getLowestEv(k, thispoke)
  lowestVal = 0
  retval = []
  for ev in 0...thispoke.ev.length
    next if ev == k
    next if thispoke.ev[ev] <= 0
    if retval.length <= 0 || lowestVal > thispoke.ev[ev]
      lowestVal = thispoke.ev[ev]
      retval = [ev]
    elsif lowestVal == thispoke.ev[ev]
      retval.push(ev)
    end
  end
  return -1 if retval.length <= 0
  randId = rand(retval.length)
  return retval[randId]
end
#####/MODDED

class PokeBattle_Battle
  def pbGainEvs(thispoke, i)
    # Gain effort value points, using RS effort values
    totalev = 0
    for k in 0..5
      totalev += thispoke.ev[k]
    end
    # Original species, not current species
    evyield = @battlers[i].evYield
    for k in 0..5
      evgain = evyield[k]
      evgain *= 8 if thispoke.item == :MACHOBRACE || thispoke.itemInitial == :MACHOBRACE
      evgain = 0 if [:POWERWEIGHT, :POWERBRACER, :POWERBELT, :POWERANKLET, :POWERLENS, :POWERBAND].include?(thispoke.item)
      case k
        when 0 then evgain += 32 if thispoke.item == :POWERWEIGHT
        when 1 then evgain += 32 if thispoke.item == :POWERBRACER
        when 2 then evgain += 32 if thispoke.item == :POWERBELT
        when 3 then evgain += 32 if thispoke.item == :POWERLENS
        when 4 then evgain += 32 if thispoke.item == :POWERBAND
        when 5 then evgain += 32 if thispoke.item == :POWERANKLET
      end
      case k
        when 0 then evgain += 8 if thispoke.item == :CANONPOWERWEIGHT
        when 1 then evgain += 8 if thispoke.item == :CANONPOWERBRACER
        when 2 then evgain += 8 if thispoke.item == :CANONPOWERBELT
        when 3 then evgain += 8 if thispoke.item == :CANONPOWERLENS
        when 4 then evgain += 8 if thispoke.item == :CANONPOWERBAND
        when 5 then evgain += 8 if thispoke.item == :CANONPOWERANKLET
      end
      evgain *= 4 if thispoke.pokerusStage >= 1 # Infected or cured
      evgain = 0 if $game_switches[:Stop_Ev_Gain]
      #####MODDED
      if !$game_switches[:Stop_Ev_Gain]
        msgs = swm_manageEvGain(evgain, k, thispoke)
        for i in 0...msgs.length
          pbDisplayPaused(msgs[i])
        end
      end
      #####/MODDED
      if false #####MODDED, was if evgain>0
        # Can't exceed overall limit
        evgain -= totalev + evgain - 510 if totalev + evgain > 510 && !$game_switches[:No_Total_EV_Cap]
        # Can't exceed stat limit
        evgain -= thispoke.ev[k] + evgain - 252 if thispoke.ev[k] + evgain > 252
        evgain = 0 if evgain < 0
        # Add EV gain
        thispoke.ev[k] += evgain
        if thispoke.ev[k] > 252
          print "Single-stat EV limit 252 exceeded.\r\nStat: #{k}  EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
          thispoke.ev[k] = 252
        end
        totalev += evgain
        if totalev > 510 && !$game_switches[:No_Total_EV_Cap] && !$game_switches[:SnagMachine_Password]
          print "EV limit 510 exceeded.\r\nTotal EVs: #{totalev} EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
        end
      end
    end
  end
end

def useEVBerry(pokemon, scene, amount, stat)
  originalev = pokemon.ev[stat]
  consumed = 0
  while consumed < amount
    #####MODDED, was break if pokemon.happiness == 255 && pokemon.ev[stat] == 0
    pokemon.changeHappiness("EV berry")
    #####MODDED, was pokemon.ev[stat] -= 20
    #####MODDED, was pokemon.ev[stat] = 0 if pokemon.ev[stat] < 0
    #####MODDED
    msgs = swm_manageEvGain(-20, stat, pokemon)
    for i in 0...msgs.length
      scene.pbDisplay(msgs[i])
    end
    #####/MODDED
    consumed += 1
  end

  if consumed == 0
    scene.pbDisplay(_INTL("It won't have any effect."))
    return false, 0
  end

  pokemon.calcStats
  scene.pbRefresh

  if pokemon.happiness == 255 && originalev > pokemon.ev[stat]
    scene.pbDisplay(_INTL("{1} adores you!\nThe base {2} fell!", pokemon.name, STATSTRINGS[stat]))
  elsif pokemon.happiness == 255
    #####MODDED, was scene.pbDisplay(_INTL("{1} adores you!\nThe base {2} can't fall!", pokemon.name, STATSTRINGS[stat]))
    scene.pbDisplay(_INTL("{1} adores you!\nThe base {2} couldn't fall without underflowing!", pokemon.name, STATSTRINGS[stat])) ######MODDED
  elsif originalev > pokemon.ev[stat]
    scene.pbDisplay(_INTL("{1} turned friendly.\nThe base {2} fell!", pokemon.name, STATSTRINGS[stat]))
  else
    #####MODDED, was scene.pbDisplay(_INTL("{1} turned friendly.\nThe base {2} can't fall!", pokemon.name, STATSTRINGS[stat]))
    scene.pbDisplay(_INTL("{1} turned friendly.\nThe base {2} couldn't fall without underflowing!", pokemon.name, STATSTRINGS[stat])) ######MODDED
  end

  return true, consumed
end

def pbRaiseEffortValues(pokemon, ev, evgain = 32, evlimit = true)
  #####MODDED
  # This function is used for vitamins and wings
  # ev_points_before = pokemon.iv[ev] * SWM_EV_LIMIT_PER_STAT + pokemon.ev[ev]
  msgs = swm_manageEvGain(evgain, ev, pokemon)
  for i in 0...msgs.length
    Kernel.pbMessage(msgs[i])
  end
  # ev_points_after = pokemon.iv[ev] * SWM_EV_LIMIT_PER_STAT + pokemon.ev[ev]
  # return ev_points_after - ev_points_before
  return 1 # This return value is only used to check if the EVS were increased before consuming the vitaming/wing and increasing happiness; there's no real reason to actually calculate it
  #####/MODDED
  #####MODDED, was totalev = pokemon.ev.sum
  #####MODDED, was evgain = 510 - totalev if totalev + evgain > 510 && !$game_switches[:No_Total_EV_Cap]
  #####MODDED, was evgain = 252 - pokemon.ev[ev] if pokemon.ev[ev] + evgain > 252
  #####MODDED, was if evgain > 0
  #####MODDED, was   pokemon.ev[ev] += evgain
  #####MODDED, was   pokemon.calcStats
  #####MODDED, was end
  #####MODDED, was return evgain
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
