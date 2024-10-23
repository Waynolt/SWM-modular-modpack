#####MODDED
$swm_autoDex_showNotification = false

Events.onEndBattle += proc {|sender,e|
  swm_handlePokedexUpdate # Update the pokedex after any battle
}

def swm_handlePokedexUpdate
  # Get the newly caught mons and update all the others in the same evo line
  addedEntries = []
  newOwned = swm_getNewOwned
  for itm in newOwned
    tmp = swm_updatePokedex(itm)
    addedEntries.push(*tmp) 
  end
  return nil if !$swm_autoDex_showNotification || addedEntries.length <= 0
  if addedEntries.length > 25
    Kernel.pbMessage(_INTL(
      'Pokedex update! {1} new entries added.',
      addedEntries.length
    ))
  else
    Kernel.pbMessage(_INTL(
      'Pokedex update! {1} new {2} added: {3}',
      addedEntries.length,
      addedEntries.length == 1 ? 'entry' : 'entries',
      addedEntries.join(', ')
    ))
  end
end

def swm_updatePokedex(examinedSpecies)
  # Actually perform the dex update
  newEntries = []
  line = swm_getMonsInSameEvoLine(examinedSpecies[:species])
  for itm in line
    species = itm[:species]
    form = itm[:form]
    if form.nil?
      newEntries.push(getMonName(species)) if !$Trainer.pokedex.dexList[species][:owned?]
    else
      if !$Trainer.pokedex.dexList[species][:formsOwned][form]
        mon_name =
          form == 0 \
            ? getMonName(species, form)
            : _INTL(
              '{1} ({2})',
              getMonName(species, form),
              $cache.pkmn[species].forms[form]
            )
        newEntries.push(mon_name)
      end
      $Trainer.pokedex.dexList[species][:formsOwned][form] = true
    end
    $Trainer.pokedex.dexList[species][:seen?] = true
    $Trainer.pokedex.dexList[species][:owned?] = true
  end
  return newEntries.uniq # Remove duplicates
end

def swm_getMonsInSameEvoLine(species)
  # Get all the mons in the same evo line as "species"
  # Species and forms are considered to be in the same line if they have the same baby species
  retval = []
  mapping = swm_getBabyMapping
  babies = swm_autoDex_getPossibleBabies(species)
  for baby in babies
    next if !mapping[baby]
    retval.push(*mapping[baby])
  end
  return retval.uniq # Remove duplicates
end

$swm_oldOwned = nil # Makes sure to reset the global variable on system reset
def swm_getNewOwned
  # Check if there are captured mons in the dex that we hadn't seen yet
  retval = []
  $swm_oldOwned = {} if !defined?($swm_oldOwned) || !$swm_oldOwned
  $cache.pkmn.each_key { |species|
    $swm_oldOwned[species] = {} if !$swm_oldOwned[species]
    if $cache.pkmn[species].forms.keys.length <= 0
      # Shouldn't happen, but we can handle the case where a species has no forms
      form = nil
      if $Trainer.pokedex.dexList[species][:owned?] && !$swm_oldOwned[species][form]
        retval.push({:species => species, :form => form})
        $swm_oldOwned[species][form] = true
      end
    end
    $cache.pkmn[species].forms.each_key { |form|
      # Let it crash if a mon is not available! It needs to be reported and fixed!
      if $Trainer.pokedex.dexList[species][:formsOwned][form] && !$swm_oldOwned[species][form]
        retval.push({:species => species, :form => form})
        $swm_oldOwned[species][form] = true
      end
    }
  }
  return retval.uniq # Remove duplicates
end

def swm_getBabyMapping
  # Map each baby species to all the species and forms that can evolve from it
  return $swm_babyMapping if defined?($swm_babyMapping)
  mapping = {}
  $cache.pkmn.each_key { |species|
    babies = swm_autoDex_getPossibleBabies(species)
    for baby in babies
      mapping[baby] = [] if !mapping[baby]
      mapping[baby].push({:species => species, :form => nil}) if $cache.pkmn[species].forms.keys.length <= 0
      $cache.pkmn[species].forms.each_key { |form|
        mapping[baby].push({:species => species, :form => form})
      }
    end
  }
  $swm_babyMapping = mapping
  return $swm_babyMapping
end

def swm_autoDex_getPossibleBabies(species)
  # Get all the baby species that might evolve into "species"
  babyspecies = pbGetBabySpecies(species)[0]
  babies = [babyspecies, pbGetNonIncenseLowestSpecies(babyspecies, 0)[0]]
  if babyspecies == :MANAPHY
    babyspecies = :PHIONE
    babies.push(*[babyspecies, pbGetNonIncenseLowestSpecies(babyspecies, 0)[0]])
  end
  if babyspecies == :NIDORANfE
    tmp = [(:NIDORANmA), (:NIDORANfE)]
  elsif babyspecies == :NIDORANmA
    tmp = [(:NIDORANmA), (:NIDORANfE)]
  elsif babyspecies == :VOLBEAT
    tmp = [:VOLBEAT, :ILLUMISE]
  elsif babyspecies == :ILLUMISE
    tmp = [:VOLBEAT, :ILLUMISE]
  else
    tmp = []
  end
  for baby in tmp
    babies.push(*[baby, pbGetNonIncenseLowestSpecies(baby, 0)[0]])
  end
  return babies.uniq # Remove duplicates
end
#####/MODDED

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
