#####MODDED
def swm_getAllEggMoves(pokemon)
  moves = []
  babies = swm_getPossibleBabies(pokemon.species)
  for baby in babies
    tmp = swm_getEggMoves(baby, pokemon.form)
    moves.push(*tmp)
  end
  moves |= [] # remove duplicates
  retval = []
  for move in moves
    # next if level>pokemon.level # No need to check for level... we're talking egg moves here, remember?
    next if pokemon.knowsMove?(move)
    retval.push(move)
  end
  return retval
end

def swm_getPossibleBabies(species)
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
  return babies|[] # Remove duplicates
end

def swm_getEggMoves(babyspecies, form)
  moves = []
	formcheck = $cache.pkmn[babyspecies, form].EggMoves
  if formcheck.nil?
    movelist = $cache.pkmn_egg[babyspecies]
    if movelist
      moves.push(*movelist)
    end
  else
    moves.push(*formcheck)
  end
  # Volt Tackle
  moves.push(:VOLTTACKLE) if [:PICHU, :PIKACHU, :RAICHU].include?(babyspecies)
  return moves|[] # remove duplicates
end

if !defined?(swm_learnEggMoves_oldPbGetRelearnableMoves)
  alias :swm_learnEggMoves_oldPbGetRelearnableMoves :pbGetRelearnableMoves
end
#####/MODDED

def pbGetRelearnableMoves(pokemon, *args, **kwargs)
  moves = swm_learnEggMoves_oldPbGetRelearnableMoves(pokemon, *args, **kwargs)
  emoves = swm_getAllEggMoves(pokemon)
  moves.push(*emoves)
  moves |= [] # remove duplicates
  # moves.sort { |atkA, atkB| getMoveName(atkA) <=> getMoveName(atkB) }
  return moves
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
