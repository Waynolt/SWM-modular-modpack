#####MODDED
def swm_pbRest(mon, gender)
  if !swm_canRest?()
    Kernel.pbMessage(_INTL('You feel uneasy, and are unable to sleep.\n(Unreal Time is turned off!)'))
    return
  end
  timePast=swm_getHowLongToRestFor() # Returns the number of real time seconds that are supposed to have been passed
  return nil if timePast == 0
  $gameTimeLastCheck-=timePast
  $game_screen.getTimeCurrent() # Will update the time
  Kernel.pbMessage(_INTL('Please exit the area to properly update its events.'))
end

def swm_canRest?
  return false if !$game_switches[:Unreal_Time]
  return $idk[:settings].unrealTimeDiverge != 0
end

def swm_getHowLongToRestFor
  choice=Kernel.pbMessage(
    _INTL('Do you wish to rest for a while or until some time?'),
    [
      _INTL('For a while'),
      _INTL('Until some time'),
      _INTL('I changed my mind')
    ],
    3
  )
  return swm_getHowLongToRestForAsPeriod if choice == 0
  return swm_getHowLongToRestForAsPointInTime if choice == 1
  return 0
end

def swm_getHowLongToRestForAsPeriod
  params=ChooseNumberParams.new
  params.setRange(0,9999)
  params.setDefaultValue(0)
  hours=Kernel.pbMessageChooseNumber(_INTL('How many hours would you like to rest?'), params)
  seconds=hours*3600
  return seconds.to_f / $game_screen.getTimeScale().to_f
end

def swm_getHowLongToRestForAsPointInTime
  now=$game_screen.getTimeCurrent()
  # Get the target weekday
  choiceWday=Kernel.pbMessage(
    _INTL('When would you like to wake up?'),
    [
      _INTL('Sunday'),
      _INTL('Monday'),
      _INTL('Tuesday'),
      _INTL('Wednesday'),
      _INTL('Thursday'),
      _INTL('Friday'),
      _INTL('Saturday'),
      _INTL('Never')
    ],
    8
  )
  if choiceWday == 7
    Kernel.pbMessage(_INTL("Oh.\nI... I'll leave you alone now."))
    return 0
  end
  daysPast=choiceWday-now.wday
  while daysPast < 0
    daysPast+=7
  end
  # Get the target hour
  params=ChooseNumberParams.new
  params.setRange(0,23)
  params.setDefaultValue(now.hour)
  choiceHour=Kernel.pbMessageChooseNumber(_INTL('At which hour?'), params)
  hoursPast=choiceHour-now.hour
  # Combine the two
  hours=daysPast*24+hoursPast
  while hours < 0
    # Go to the next week
    hours+=168 # 24*7 = 168
  end
  seconds=hours*3600 # 60*60 = 3600
  return seconds.to_f / $game_screen.getTimeScale().to_f
end

HiddenMoveHandlers::CanUseMove.add(:REST,lambda{|move,pkmn|
   return true # swm_canRest?()
})

HiddenMoveHandlers::UseMove.add(:REST,lambda{|move,pokemon|
   if !pbHiddenMoveAnimation(pokemon)
     Kernel.pbMessage(_INTL('{1} used {2}!',pokemon.name,PBMoves.getName(move)))
   end
   swm_pbRest(pokemon.name, pokemon.gender)
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
