#####MODDED
def swm_add_one_premier_ball
  if $PokemonBag.pbCanStore?(:PREMIERBALL)
    $PokemonBag.pbStoreItem(:PREMIERBALL)
  end
end

BallHandlers::ModifyCatchRate.add(:PREMIERBALL,proc{|ball,catchRate,battle,battler|
  swm_add_one_premier_ball
  qty_current = $PokemonBag.pbQuantity(:PREMIERBALL)
  qty_for_normal_rate = 50
  rate_modifier = qty_current.to_f/qty_for_normal_rate.to_f
  next (catchRate*rate_modifier*0.1).floor if pbIsUltraBeast?(battler)
  next (catchRate*rate_modifier).floor
})
#####/MODDED

module PokeBattle_BattleCommon
  #####MODDED
  if !defined?(swm_reusablePremierBalls_oldpbThrowPokeBall)
    alias :swm_reusablePremierBalls_oldpbThrowPokeBall :pbThrowPokeBall
  end

  def swm_check_for_ball_deflection(battler, ball, snag)
    if ball != :PREMIERBALL
      return false
    end
    if battler.isFainted?
      return true
    end
    if !snag
      if @opponent
        return true
      end
      if $game_switches[:No_Catching] || battler.issossmon || (battler.isbossmon && (!battler.capturable || battler.shieldCount > 0))
        return true
      end
    end
    return false
  end

  def swm_handle_ball_deflection(battler, ball, snag)
    if swm_check_for_ball_deflection(battler, ball, snag)
      swm_add_one_premier_ball
    end
  end
  #####/MODDED

  def pbThrowPokeBall(idxPokemon, ball, *args, **kwargs)
    #####MODDED, was itemname = getItemName(ball)
    battler = nil
    if pbIsOpposing?(idxPokemon)
      battler = self.battlers[idxPokemon]
    else
      battler = self.battlers[idxPokemon].pbOppositeOpposing
    end
    if battler.isFainted?
      battler = battler.pbPartner
    elsif !battler.pbPartner.isFainted?
      idxPokemon = self.scene.pbChooseBallTarget(idxPokemon)
      return if idxPokemon == -1
      battler = self.battlers[idxPokemon]
    end
    #####MODDED, was oldform = battler.form
    #####MODDED, was battler.form = battler.pokemon.getForm(battler.pokemon)
    #####MODDED, was pbDisplayBrief(_INTL("{1} threw a {2}!", self.pbPlayer.name, itemname))
    #####MODDED, was if battler.isFainted?
    #####MODDED, was   pbDisplay(_INTL("But there was no target..."))
    #####MODDED, was   pbBallFetch(ball)
    #####MODDED, was   return
    #####MODDED, was end
    snag = pbIsSnagBall?(ball) && battler.isShadow?
    # "yoink" password only allows one snag per battle
    snag = true if $game_switches[:SnagMachine_Password] && @snaggedpokemon == [] &&
      !$cache.pkmn[battler.species, battler.pokemon.getForm(battler.pokemon)].checkFlag?(:ExcludeDex) && battler.ev.all? { |ev| ev <= 252 } #####MODDED
      #####MODDED, was !$cache.pkmn[battler.species, battler.form].checkFlag?(:ExcludeDex) && battler.ev.all? { |ev| ev <= 252 }
    snag = false if isOnline?
    #####MODDED
    result = swm_reusablePremierBalls_oldpbThrowPokeBall(idxPokemon, ball, *args, **kwargs)
    swm_handle_ball_deflection(battler, ball, snag)
    return result
    #####/MODDED
  end

  def pbBallFetch(pokeball)
    #####MODDED
    if pokeball == :PREMIERBALL
      return
    end
    #####/MODDED
    for i in 0...4
      if self.battlers[i].ability == :BALLFETCH && self.battlers[i].item.nil?
        self.battlers[i].effects[:BallFetch] = pokeball
      end
    end
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
