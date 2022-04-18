#####MODDED
def swm_manageEvGain(evgain, k, thispoke)
  return [] if evgain == 0
  messages=swm_handleIvEvGain(evgain, k, thispoke)
  swm_handleEvLimit(evgain, k, thispoke)
  return messages
end

def swm_handleIvEvGain(evgain, k, thispoke)
  startIv=thispoke.iv[k]
  thispoke.ev[k]+=evgain # evgain can be lower than 0
  while thispoke.ev[k] > 252
    if thispoke.iv[k] < 31
      thispoke.ev[k]-=252
      thispoke.iv[k]+=1
    else
      thispoke.ev[k]=252
    end
  end
  while thispoke.ev[k] < 0
    if thispoke.iv[k] > 0
      thispoke.ev[k]+=252
      thispoke.iv[k]-=1
    else
      thispoke.ev[k]=0
    end
  end
  ivgain=thispoke.iv[k]-startIv
  return swm_notifyIvChange(k, thispoke, ivgain)
end

def swm_notifyIvChange(k, thispoke, ivgain)
  return [] if ivgain == 0
  case k
    when 0
      stat='Hit Points'
    when 1
      stat='Attack'
    when 2
      stat='Defense'
    when 3
      stat='Speed'
    when 4
      stat='Special Attack'
    when 5
      stat='Special Defense'
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
  return nil if $game_switches[:No_Total_EV_Cap]
  # Redistribute by removing from the lowest ev
  totalev=0
  for i in 0...thispoke.ev.length
    totalev+=thispoke.ev[i]
  end
  evdiff=totalev-510
  if evgain < 0 && evdiff > 0
    # Reduce the EV we were already reducing first
    # Don't reduce the IV further - we do not want to risk a loop
    lowerBy=[thispoke.ev[k], evdiff].min
    thispoke.ev[k]-=lowerBy
    evdiff-=lowerBy
  end
  while evdiff > 0
    ev=swm_getLowestEv(k, thispoke) # Never results in k
    break if ev < 0 # All 0 already (???)
    lowerBy=[thispoke.ev[ev], evdiff].min
    thispoke.ev[ev]-=lowerBy
    evdiff-=lowerBy
  end
end

def swm_getLowestEv(k, thispoke)
  lowestVal=0
  retval=[]
  for ev in 0...thispoke.ev.length
    next if ev == k
    next if thispoke.ev[ev] <= 0
    if retval.length <= 0 || lowestVal > thispoke.ev[ev]
      lowestVal=thispoke.ev[ev]
      retval=[ev]
    elsif lowestVal == thispoke.ev[ev]
      retval.push(ev)
    end
  end
  return -1 if retval.length <= 0
  randId=rand(retval.length)
  return retval[randId]
end
#####/MODDED

class PokeBattle_Battle
  def pbGainEvs(thispoke,i)
    #Gain effort value points, using RS effort values
    totalev=0
    for k in 0..5
      totalev+=thispoke.ev[k]
    end
    # Original species, not current species
    evyield=@battlers[i].evYield
    for k in 0..5
      evgain=evyield[k]
      evgain*=8 if (thispoke.item == PBItems::MACHOBRACE) || (thispoke.itemInitial == PBItems::MACHOBRACE)
      evgain=0 if [PBItems::POWERWEIGHT, PBItems::POWERBRACER,PBItems::POWERBELT,PBItems::POWERANKLET,PBItems::POWERLENS,PBItems::POWERBAND].include?(thispoke.item)
      case k
        when 0 then evgain+=32 if (thispoke.item == PBItems::POWERWEIGHT)
        when 1 then evgain+=32 if (thispoke.item == PBItems::POWERBRACER)
        when 2 then evgain+=32 if (thispoke.item == PBItems::POWERBELT)
        when 3 then evgain+=32 if (thispoke.item == PBItems::POWERANKLET)
        when 4 then evgain+=32 if (thispoke.item == PBItems::POWERLENS)
        when 5 then evgain+=32 if (thispoke.item == PBItems::POWERBAND)
      end
      evgain*=4 if thispoke.pokerusStage>=1 # Infected or cured
      evgain = 0 if $game_switches[:Stop_Ev_Gain] == true
      #####MODDED
      msgs=swm_manageEvGain(evgain, k, thispoke)
      for i in 0...msgs.length
        pbDisplayPaused(msgs[i])
      end
      #####/MODDED
      if false #####MODDED, was if evgain>0
        # Can't exceed overall limit
        evgain-=totalev+evgain-510 if totalev+evgain>510 && !$game_switches[:No_Total_EV_Cap]
        # Can't exceed stat limit
        evgain-=thispoke.ev[k]+evgain-252 if thispoke.ev[k]+evgain>252
        # Add EV gain
        thispoke.ev[k]+=evgain
        if thispoke.ev[k]>252
          print "Single-stat EV limit 252 exceeded.\r\nStat: #{k}  EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
          thispoke.ev[k]=252
        end
        totalev+=evgain
        if totalev>510 && !$game_switches[:No_Total_EV_Cap]
          print "EV limit 510 exceeded.\r\nTotal EVs: #{totalev} EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
        end
      end
    end
    battler = @battlers.find {|battler| battler.pokemon == thispoke}
    battler.pbUpdate if battler
    @scene.sprites["battlebox#{battler.index}"].refresh if battler
  end
end

def pbRaiseHappinessAndLowerEV(pokemon,scene,ev,messages)
  #####MODDED
  if pokemon.happiness<255
    pokemon.changeHappiness("EV berry")
    scene.pbDisplay(messages[2])
  else
    scene.pbDisplay(messages[0])
  end
  msgs=swm_manageEvGain(-20, ev, pokemon)
  for i in 0...msgs.length
    scene.pbDisplay(msgs[i])
  end
  pokemon.calcStats
  scene.pbRefresh
  return true
  #####/MODDED
  #####MODDED, was if pokemon.happiness==255 && pokemon.ev[ev]==0
  #####MODDED, was   scene.pbDisplay(_INTL("It won't have any effect."))
  #####MODDED, was   return false
  #####MODDED, was elsif pokemon.happiness==255
  #####MODDED, was   pokemon.ev[ev]-=20
  #####MODDED, was   pokemon.ev[ev]=0 if pokemon.ev[ev]<0
  #####MODDED, was   pokemon.calcStats
  #####MODDED, was   scene.pbRefresh
  #####MODDED, was   scene.pbDisplay(messages[0])
  #####MODDED, was   return true
  #####MODDED, was elsif pokemon.ev[ev]==0
  #####MODDED, was   pokemon.changeHappiness("EV berry")
  #####MODDED, was   scene.pbRefresh
  #####MODDED, was   scene.pbDisplay(messages[1])
  #####MODDED, was   return true
  #####MODDED, was else
  #####MODDED, was   pokemon.changeHappiness("EV berry")
  #####MODDED, was   pokemon.ev[ev]-=20
  #####MODDED, was   pokemon.ev[ev]=0 if pokemon.ev[ev]<0
  #####MODDED, was   pokemon.calcStats
  #####MODDED, was   scene.pbRefresh
  #####MODDED, was   scene.pbDisplay(messages[2])
  #####MODDED, was   return true
  #####MODDED, was end
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version='19'
if !getversion().start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
