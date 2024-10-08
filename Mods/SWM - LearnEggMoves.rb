#####MODDED
def swm_getAllEggMoves(pokemon)
  moves=[]
  babies=swm_getPossibleBabies(pokemon.species)
  for baby in babies
    tmp=swm_getEggMoves(baby, pokemon.form)
    moves.push(*tmp)
  end
  moves|=[] # remove duplicates
  retval=[]
  for move in moves
    # next if level>pokemon.level # No need to check for level... we're talking egg moves here, remember?
    next if pokemon.knowsMove?(move)
    retval.push(move)
  end
  return retval
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

def swm_getEggMoves(babyspecies, form)
  moves=[]
  egg=PokeBattle_Pokemon.new(babyspecies,EGGINITIALLEVEL,$Trainer)
  egg.form = form
  name = egg.getFormName
	formcheck = PokemonForms.dig(egg.species,name,:EggMoves)
  if formcheck!=nil
    for move in formcheck
      atk = getID(PBMoves,move)
      moves.push(atk)
    end
  else 
    movelist = $cache.pkmn_egg[babyspecies]
    if movelist
      for i in movelist
        atk = getID(PBMoves,i)
        moves.push(atk)
      end
    end
  end
  # Volt Tackle
  moves.push(PBMoves::VOLTTACKLE) if [PBSpecies::PICHU, PBSpecies::PIKACHU, PBSpecies::RAICHU].include?(babyspecies)
  return moves|[] # remove duplicates
end

if !defined?(swm_learnEggMoves_oldPbGetRelearnableMoves)
  alias :swm_learnEggMoves_oldPbGetRelearnableMoves :pbGetRelearnableMoves
end
#####/MODDED

def pbGetRelearnableMoves(pokemon, *args, **kwargs)
  moves=swm_learnEggMoves_oldPbGetRelearnableMoves(pokemon, *args, **kwargs)
  emoves=swm_getAllEggMoves(pokemon)
  moves.push(*emoves)
  moves|=[] # remove duplicates
  # moves.sort { |atkA, atkB| PBMoves.getName(atkA) <=> PBMoves.getName(atkB) }
  return moves
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version='19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
