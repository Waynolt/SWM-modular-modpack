#####MODDED
Events.onStepTaken+=proc {
	$game_map.swm_checkStarterRoom
}
#####/MODDED

class Game_Map
  #####MODDED
  def swm_checkStarterRoom
    # The last step taken without mons in the party is taken in the starters room
    return nil if $Trainer.numbadges > 0
    swm_tryLoadStarterRoomData()
    return nil if defined?($swm_starterRoomFound) && $swm_starterRoomFound
    if $Trainer.party.length > 0
      $swm_starterRoomFound=true
      swm_trySaveStarterRoomData()
      return nil
    end
    $swm_starterRoomId=@map_id
  end

  def swm_playerInStarterRoom?
    return false if !defined?($swm_starterRoomId) || !$swm_starterRoomId
    return false if $Trainer.numbadges > 0
    return @map_id == $swm_starterRoomId
  end
  #####/MODDED
end

#####MODDED
def swm_getStarterRoomDataFilename
  return RTP.getSaveFileName('SWM_starterRoom.txt')
end

def swm_tryLoadStarterRoomData
  return nil if defined?($swm_starterFileChecked) && $swm_starterFileChecked
  $swm_starterFileChecked=true
  filename=swm_getStarterRoomDataFilename()
  return nil if !safeExists?(filename)
  File.open(filename).each do |line|
    line_stripped=line.strip()
    if line_stripped && (line_stripped != '')
      $swm_starterRoomId=line_stripped.to_i
      $swm_starterRoomFound=true
    end
  end
end

def swm_trySaveStarterRoomData
  return nil if !defined?($swm_starterRoomFound)
  return nil if !defined?($swm_starterRoomId)
  return nil if !$swm_starterRoomFound
  return nil if !$swm_starterRoomId
  filename=swm_getStarterRoomDataFilename()
  return nil if safeExists?(filename) # No need to redo this
  File.open(filename, 'wb') { |f|
    f << "#{$swm_starterRoomId}\n"
  }
end
#####/MODDED

class PokemonScreen
  #####MODDED
  def swm_handleStarterChange
    $game_map.swm_checkStarterRoom()
    return nil if !$game_map.swm_playerInStarterRoom?
    Kernel.pbMessage(_INTL('While in the starter room it is possible to choose any starter species, any time.'))
    choice=Kernel.pbMessage(
      _INTL('Would you like to do so now?'),
      [
        _INTL('Yes'),
        _INTL('No')
      ],
      1
    )
    swm_changeSpecies if choice == 0
  end

  def swm_changeSpecies
    pkmn=@party[0]
    newSpecies, newForm=swm_getNewSpecies(pkmn.species)
    return nil if !newSpecies
    oldSpecies=pkmn.species
    swm_updateOwned(oldSpecies, newSpecies)
    swm_updateMon(pkmn, oldSpecies, newSpecies, newForm)
    # Is the new mon legal?
    if swm_isIllegalMonSpecies?(pkmn.species)
      Kernel.pbMessage(_INTL('Warning: this is an illegal mon'))
      Kernel.pbMessage(_INTL('You won\'t be able to play online with it in the party'))
    end
  end

  def swm_getFormNames(speciesId)
    formnames=pbGetMessage(MessageTypes::FormNames, speciesId)
    if !formnames || formnames==''
      formnames=['']
    else
      formnames=strsplit(formnames,/,/)
    end
    hasAlolan=false
    idAlternate=-1
    result=[]
    for i in 0...formnames.length
      name=formnames[i].strip
      next if name == ''
      nameDowncase=name.downcase
      hasAlolan=true if nameDowncase=='alolan'
      idAlternate=i if nameDowncase=='alternate'
      result.push([name, i])
    end
    if !hasAlolan && idAlternate >= 0
      # In the base game Alolans are named Alternate
      result[idAlternate][0]='Alolan'
    end 
    return result
  end

  def swm_canBeAlolan?(pokedexID)
    # Alolan mons' species ids
    alolans=[19, 20, 26, 27, 28, 37, 38, 50, 51, 52, 53, 74, 75, 76, 88, 89, 103, 105]
    return alolans.include?(pokedexID)
  end

  def swm_isAvailableYet?(pokedexID)
    # # Unavailable mons' species ids
    # unavailable=[]
    # return !unavailable.include?(pokedexID)

    # Simply check if its sprite exists
    species="#{pokedexID}".rjust(3, '0')
    filename="Graphics/Battlers/#{species}"
    return !!pbResolveBitmap(filename)
  end

  def swm_isAlternateFormsPackInstalled?
    # Can also handle Aevian Misdreavus, with the only downside of renaming Alolan to Alternate
    return true
    # # Is this the alternate forms pack mod? Ask drapion!
    # formnames=swm_getFormNames(getID(PBSpecies, :DRAPION))
    # return formnames.length > 1
  end

  def swm_getNewSpecies(oldSpecies)
    choice=Kernel.pbMessage(
      _INTL('Do you prefer to reroll its species or to select a new one?'),
      [
        _INTL('Randomize'),
        _INTL('Choose pokemon'),
        _INTL('Cancel')
      ],
      3
    )
    return swm_randomSpecies if choice==0
    return swm_chooseSpecies(oldSpecies) if choice==1
    return nil, 0
  end

  def swm_chooseSpecies(oldSpecies)
    choice=Kernel.pbMessage(
      _INTL('How?'),
      [
        _INTL('By ID'),
        _INTL('By Name'),
        _INTL('Cancel')
      ],
      3
    )
    return nil, 0 if ![0, 1].include?(choice)
    if choice == 0
      params=ChooseNumberParams.new
      params.setRange(1,PBSpecies.maxValue)
      params.setDefaultValue(oldSpecies)
      newSpecies=Kernel.pbMessageChooseNumber(_INTL('Select a new pokedex ID'), params)
    else
      nameIn=pbEnterPokemonName(_INTL('Name of the new species?'), 0, 15, '')
      nameInDown=nameIn.downcase
      found=[]
      for i in 1..PBSpecies.maxValue
        name=PBSpecies.getName(i)
        tmp=name.downcase
        next if !tmp.include?(nameInDown)
        found.push([i, name])
      end
      if found.length < 1
        Kernel.pbMessage(_INTL('Sorry, {1} was not found.', nameIn))
        return nil, 0
      elsif found.length > 1
        names=[]
        for i in 0...found.length
          names.push(found[i][1])
        end
        i=Kernel.pbMessage(
          _INTL('Found {1} species', found.length),
          names,
          0 # 0 here prevents exiting without making a choice
        )
        newSpecies=found[i][0]
      else
        newSpecies=found[0][0]
      end
    end
    # Is the species legal?
    if !swm_isAvailableYet?(newSpecies)
      Kernel.pbMessage(_INTL('Sorry, this mon would break the game'))
      return nil, 0
    end
    # We have a species - now get the form
    if swm_isAlternateFormsPackInstalled?
      formnames=swm_getFormNames(newSpecies)
      if formnames.length > 1
        names=[]
        for i in 0...formnames.length
          names.push(formnames[i][0])
        end
        i=Kernel.pbMessage(_INTL('Which form would you like?'), names, 1)
        form=formnames[i][1]
        return newSpecies, form
      end
    elsif swm_canBeAlolan?(newSpecies)
      form=Kernel.pbMessage(
        _INTL('Normal or Alolan version?'),
        [_INTL('Normal'),_INTL('Alolan')],
        1
      )
      return newSpecies, form
    end
    return newSpecies, 0
  end

  def swm_isIllegalMonSpecies?(species)
    # There no longer is a reason for actually performing this check
    return false
    # mon=PBPokemon.new(species)
    # return unavailableMonList(mon)
  end

  def swm_getPossibleBabies(species)
    babyspecies=pbGetBabySpecies(species)
    babies=[babyspecies, pbGetNonIncenseLowestSpecies(babyspecies)]
    if isConst?(babyspecies, PBSpecies,:MANAPHY) && hasConst?(PBSpecies, :PHIONE)
      babyspecies=getConst(PBSpecies, :PHIONE)
      babies.push(*[babyspecies, pbGetNonIncenseLowestSpecies(babyspecies)])
    end
    babyspecies=[]
    if (babyspecies == PBSpecies::NIDORANfE) && hasConst?(PBSpecies,:NIDORANmA)
      babyspecies=[(PBSpecies::NIDORANmA), (PBSpecies::NIDORANfE)]
    elsif (babyspecies == PBSpecies::NIDORANmA) && hasConst?(PBSpecies,:NIDORANfE)
      babyspecies=[(PBSpecies::NIDORANmA), (PBSpecies::NIDORANfE)]
    elsif (babyspecies == PBSpecies::VOLBEAT) && hasConst?(PBSpecies,:ILLUMISE)
      babyspecies=[PBSpecies::VOLBEAT, PBSpecies::ILLUMISE]
    elsif (babyspecies == PBSpecies::ILLUMISE) && hasConst?(PBSpecies,:VOLBEAT)
      babyspecies=[PBSpecies::VOLBEAT, PBSpecies::ILLUMISE]
    end
    for baby in babyspecies
      babies.push(*[baby, pbGetNonIncenseLowestSpecies(baby)])
    end
    return babies|[] # Remove duplicates
  end

  def swm_getAllBabySpecies(accountForMultipleForms, alternateFormsPackInstalled)
    allBabies=[]
    for species in 1..PBSpecies.maxValue
      next if !swm_isAvailableYet?(species)
      next if PBSpecies.getName(species) == ''
      next if swm_isIllegalMonSpecies?(species)
      babies=swm_getPossibleBabies(species)
      allBabies.push(*babies)
    end
    allBabies=allBabies|[] # Remove duplicates
    return allBabies if !accountForMultipleForms
    # Add the species multiple times if it has unchangeable alternative forms
    # This way each form has a fair chance of getting chosen
    puppies=[]
    for species in 0...allBabies.length
      # Add the species multiple times if it has unchangeable alternative forms
      # This way each form has a fair chance of getting chosen
      if alternateFormsPackInstalled
        formnames=swm_getFormNames(species)
        tmp=Array.new(formnames.length, species)
        puppies.push(*tmp)
      else
        puppies.push(species)
        puppies.push(species) if swm_canBeAlolan?(species)
      end
    end
    return puppies
  end

  def swm_randomSpecies
    alternateFormsPackInstalled=swm_isAlternateFormsPackInstalled?
    puppies=swm_getAllBabySpecies(
      false, # Use false to increase species variety, at the cost of actual variety
      alternateFormsPackInstalled
    )
    return nil, 0 if puppies.length <= 0
    rnd=rand(puppies.length)
    newSpecies=puppies[rnd]
    if alternateFormsPackInstalled
      formnames=swm_getFormNames(newSpecies)
      if formnames.length > 0
        rnd=rand(formnames.length)
        return newSpecies, formnames[rnd][1]
      end
    elsif swm_canBeAlolan?(newSpecies)
      return newSpecies, rand(2)
    end
    return newSpecies, 0
  end

  def swm_updateOwned(oldSpecies, newSpecies)
    $Trainer.seen[oldSpecies]=false
    $Trainer.owned[oldSpecies]=false
    $Trainer.seen[newSpecies]=true
    $Trainer.owned[newSpecies]=true
  end

  def swm_updateMon(pkmn, oldSpecies, newSpecies, newForm)
    pkmn.species=newSpecies # Species
    pkmn.form=newForm # Normal/Alolan/Alternate form
    pkmn.makeUnmega if pkmn.isMega? # Mega
    pkmn.name=PBSpecies.getName(newSpecies) if pkmn.name == PBSpecies.getName(oldSpecies) # Name
    swm_updateMoves(pkmn) # Moves
    pkmn.calcStats # Stats
  end

  def swm_updateMoves(pkmn)
    # Delete the old moves
    for i in 0..4
      pkmn.pbDeleteMoveAtIndex(0)
    end
    # Get the moves
    moves=[]
    initialmoves=pkmn.getMoveList
    for k in initialmoves
      if k[0] <= pkmn.level
        moves.push(k[1])
      end
    end
    finalmoves=[]
    finalmoves_id=[]
    listend=moves.length-4
    listend=0 if listend<0
    j=0
    for i in listend..listend+3
      moveid=(i>=moves.length) ? 0 : moves[i]
      for iID in finalmoves_id
        if moveid == iID
          moveid=0
          break
        end
      end
      finalmoves[j]=PBMove.new(moveid)
      finalmoves_id[j]=moveid
      j+=1
    end
    # Set the new moves
    for i in 0..3
      pkmn.moves[i]=finalmoves[i]
    end
    pkmn.pbRecordFirstMoves
  end

  if !defined?(swm_chooseStarter_oldPbPokemonScreen)
    alias :swm_chooseStarter_oldPbPokemonScreen :pbPokemonScreen
  end
  #####/MODDED
  
  def pbPokemonScreen(*args, **kwargs)
    swm_handleStarterChange
    return swm_chooseStarter_oldPbPokemonScreen(*args, **kwargs)
  end
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version='19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end