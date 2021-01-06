#####MODDED
def aaaGetBabyMoves(pokemon, babyspecies)
  emoves = []
  
  egg=PokeBattle_Pokemon.new(babyspecies,EGGINITIALLEVEL,nil)
  egg.form = pokemon.form unless egg.species == 479 # New form inheriting
  
  formcheck = MultipleForms.call("getEggMoves",egg)
  if formcheck!=nil
    for move in formcheck
	  atk = getID(PBMoves,move)
      emoves.push(atk) if !pokemon.knowsMove?(atk)
    end
  else  
	pbRgssOpen("Data/eggEmerald.dat","rb"){|f|
		 f.pos=(babyspecies-1)*8
		 offset=f.fgetdw
		 length=f.fgetdw
		 if length>0
		   f.pos=offset
		   i=0; loop do break unless i<length
			 atk = f.fgetw
			 emoves.push(atk) if !pokemon.knowsMove?(atk)
			 
			 i+=1
		   end
		 end
	}
  end
  # Volt Tackle
  if isConst?(pokemon.species,PBSpecies,:PICHU) || isConst?(pokemon.species,PBSpecies,:PIKACHU) || isConst?(pokemon.species,PBSpecies,:RAICHU)
    move = getConst(PBMoves,:VOLTTACKLE)
    emoves.push(move) if !pokemon.knowsMove?(move)
  end
  
  return emoves
end
#####/MODDED

def pbGetRelearnableMoves(pokemon)
  return [] if !pokemon || pokemon.isEgg? || (pokemon.isShadow? rescue false)
  moves=[]
  pbEachNaturalMove(pokemon){|move,level|
     if level<=pokemon.level && !pokemon.knowsMove?(move)
       moves.push(move) if !moves.include?(move)
     end
  }
  tmoves=[]
  if pokemon.firstmoves
    for i in pokemon.firstmoves
      tmoves.push(i) if !pokemon.knowsMove?(i) && !moves.include?(i)
    end
  end
  #####MODDED
  #Get baby species
  babyspecies = pbGetBabySpecies(pokemon.species)
  if isConst?(babyspecies,PBSpecies,:MANAPHY) && hasConst?(PBSpecies,:PHIONE)
    babyspecies=getConst(PBSpecies,:PHIONE)
  end
  emoves = aaaGetBabyMoves(pokemon, babyspecies)
  
  #Get non incense baby species
  babyspeciesOld = babyspecies
  babyspecies = pbGetNonIncenseLowestSpecies(babyspecies)
  if babyspecies != babyspeciesOld
    emoves = emoves+aaaGetBabyMoves(pokemon, babyspecies)
  end
  
  moves=tmoves+moves+emoves
  #####/MODDED
  #####MODDED, was moves=tmoves+moves
  return moves|[] # remove duplicates
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
