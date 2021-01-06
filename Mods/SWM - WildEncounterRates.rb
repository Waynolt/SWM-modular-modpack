class PokemonEncounters
  def pbEncounteredPokemon(enctype,tries=1)
    if enctype<0 || enctype>EncounterTypes::EnctypeChances.length
      raise ArgumentError.new(_INTL("Encounter type out of range"))
    end
    return nil if @enctypes[enctype]==nil
chances=EncounterTypes::EnctypeChances[enctype]
# UPDATE 11/18/2013
# I assumed multiple abilities would change the encounter rate.
# (Apparently it's only Magnet Pull)
# But if more exist in the future, this will make it easy to add them
# First Pokemon has Magnet Pull
if !$Trainer.party[0].egg?
abl = $Trainer.party[0].ability
if isConst?(abl,PBAbilities,:MAGNETPULL)
chances = shiftChances(chances, enctype, :STEEL, 1.5)
end
end
# end of update
    #####MODDED
    aArr = []
    if !$Trainer.party[0].egg? #Should also check for $Trainer.party[0].hp > 0 by logic, but then it wouldn't be in line with the other overworld party leader checks
      if isConst?($Trainer.party[0].ability, PBAbilities, :RUNAWAY) || isConst?($Trainer.party[0].item, PBItems, :SMOKEBALL)
        for i in 0...chances.length
          aEnc = @enctypes[enctype][i]
          
          if !(aEnc == nil)
            if !$Trainer.owned[aEnc[0]]
              aArr.push(i)
            end
          end
        end
      end
    end

    if aArr.length > 0
      chosenpkmn = aArr[rand(aArr.length)]
      encounter = @enctypes[enctype][chosenpkmn]
    else
    #####/MODDED
    chancetotal=0
    chances.each {|a| chancetotal+=a}
    rnd=0
    tries.times do
      r=rand(chancetotal)
      rnd=r if rnd<r
    end
    chosenpkmn=0
    chance=0
    for i in 0...chances.length
      chance+=chances[i]
      if rnd<chance
        chosenpkmn=i
        break
      end
    end
    encounter=@enctypes[enctype][chosenpkmn]
    end #####MODDED
return nil if !encounter
# UPDATE 11/19/2013
# pressure, hustle and vital spirit will now have a 150% chance of
# finding higher leveled pokemon in encounters
if !$Trainer.party[0].egg?
abl = $Trainer.party[0].ability
if (isConst?(abl, PBAbilities, :PRESSURE) ||
isConst?(abl, PBAbilities, :HUSTLE) ||
isConst?(abl, PBAbilities, :VITALSPIRIT)) &&
rand(2) == 0
# increase the lower bound to half way in-between lower and upper
encounter[1] += (encounter[2] - encounter[1]) / 2
end
end
# end of update
    level=encounter[1]+rand(1+encounter[2]-encounter[1])
    return [encounter[0],level]
  end
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
