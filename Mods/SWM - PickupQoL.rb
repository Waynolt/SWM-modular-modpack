class PokemonSystem
  #####MODDED
  attr_accessor :AMB_opt_PickupChance
  
  def AMB_opt_PickupChance
    @AMB_opt_PickupChance = 10 if !@AMB_opt_PickupChance
    return @AMB_opt_PickupChance
  end
  #####/MODDED
end

#####MODDED
#Make sure it exists
$ModAdditionalOptions=[] if !defined?($ModAdditionalOptions)

#Record the new options
$ModAdditionalOptions.push(NumberOption.new(_INTL("Pickup chance"),_INTL("Type %d"),0,100,
							proc { $PokemonSystem.AMB_opt_PickupChance },
							proc {|value|  $PokemonSystem.AMB_opt_PickupChance=value }
						  ))
#####/MODDED

def Kernel.pbPickup(pokemon)
  return if !isConst?(pokemon.ability,PBAbilities,:PICKUP) || pokemon.isEgg?
  return if pokemon.item!=0
  return if rand(100) >= $PokemonSystem.AMB_opt_PickupChance #####MODDED, was return if rand(10)!=0
  pickupList=pbDynamicItemList(
     :ORANBERRY,
     :GREATBALL,
     :SUPERREPEL,
     :POKESNAX,
     :CHOCOLATEIC,
     :BLASTPOWDER,
     :DUSKBALL,
     :ULTRAPOTION,
     :MAXREPEL,
     :FULLRESTORE,
     :REVIVE,
     :ETHER,
     :PPUP,
     :HEARTSCALE,
     :ABILITYCAPSULE,
     :HEARTSCALE,
     :BIGNUGGET,
     :SACREDASH
  )

  pickupListRare=pbDynamicItemList(
     :NUGGET,
     :STRAWBIC,
     :NUGGET,
     :RARECANDY,
     :BLUEMIC,
     :RARECANDY,
     :BLUEMIC,
     :BIGNUGGET,
     :LEFTOVERS,
     :LUCKYEGG,
     :LEFTOVERS
  )
  return if pickupList.length!=18
  return if pickupListRare.length!=11
  randlist=[30,10,10,10,10,10,10,4,4,1,1]
  items=[]
  plevel=[100,pokemon.level].min
  rnd=rand(100)
  itemstart=(plevel-1)/10
  itemstart=0 if itemstart<0
  for i in 0...9
    items.push(pickupList[i+itemstart])
  end
  items.push(pickupListRare[itemstart])
  items.push(pickupListRare[itemstart+1])
  cumnumber=0
  for i in 0...11
    cumnumber+=randlist[i]
    if rnd<cumnumber
      #####MODDED
      if $PokemonBag.pbCanStore?(items[i])
        $PokemonBag.pbStoreItem(items[i])
      else
      #####/MODDED
        pokemon.setItem(items[i])
      #####MODDED
      end
      Kernel.pbMessage(_INTL("{1} picked up: {2}", pokemon.name, PBItems.getName(items[i])))
      #####/MODDED
      break
    end
  end
end

#####MODDED
Events.onEndBattle+=proc {|sender,e|
    if hasConst?(PBItems,:HONEY)
      for pkmn in $Trainer.party
        if isConst?(pkmn.ability,PBAbilities,:HONEYGATHER)
          if !pkmn.isEgg? && isConst?(pkmn.item,PBItems,:HONEY) && $PokemonBag.pbCanStore?(:HONEY)
            $PokemonBag.pbStoreItem(pkmn.item)
            pkmn.setItem(0)
            Kernel.pbMessage(_INTL("{1} gathered some honey", pkmn.name))
          end
        end
      end
    end
}
#####/MODDED

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
