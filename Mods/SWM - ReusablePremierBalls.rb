#####MODDED
BallHandlers::ModifyCatchRate.add(:PREMIERBALL,proc{|ball,catchRate,battle,battler|
  if $PokemonBag.pbCanStore?(:PREMIERBALL)
    $PokemonBag.pbStoreItem(:PREMIERBALL)
  end
  qty_current = $PokemonBag.pbQuantity(:PREMIERBALL)
  qty_for_normal_rate = 50
  rate_modifier = qty_current.to_f/qty_for_normal_rate.to_f
  next (catchRate*rate_modifier*0.1).floor if pbIsUltraBeast?(battler)
  next (catchRate*rate_modifier).floor
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
