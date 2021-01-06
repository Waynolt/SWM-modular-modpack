#####MODDED
def AAA_GetFormNames(iSpecies)
  formnames=pbGetMessage(MessageTypes::FormNames, iSpecies)
  if !formnames || formnames==""
    formnames=[""]
  else
    formnames=strsplit(formnames,/,/)
  end
  
  result=[]
  for i in 0...formnames.length
    for sChar in formnames[i]
      if !(sChar == " ")
        result[result.length] = []
        result[result.length-1][0] = formnames[i]
        result[result.length-1][1] = i
        break
      end
    end
  end
  
  return result
end
#####/MODDED

class PokemonScreen
  #####MODDED
  def aCanBeAlolan(aPokedexID)
    #Alolan mons' species ids:
    aArray = [19, 20, 26, 27, 28, 37, 38, 50, 51, 52, 53, 74, 75, 76, 88, 89, 103, 105]
    for i in 0..(aArray.length-1)
      if aArray[i] == aPokedexID
        return true
      end
    end
    return false
  end
  def aIsAvailableYet(aPokedexID)
    #Unavailable mons' species ids:
    aArray = [144, 145, 146, 150, 151, 243, 244, 245, 249, 250, 251, 377, 378, 379, 380, 381, 382, 383, 384, 385, 386, 480, 481, 482, 483, 484, 485, 486, 487, 488, 490, 491, 492, 493, 494, 638, 639, 640, 641, 642, 643, 644, 645, 646, 647, 648, 649, 716, 717, 718, 719, 720, 721, 785, 786, 787, 788, 789, 790, 791, 792, 793, 794, 795, 796, 797, 798, 799, 800, 801, 802, 805, 806, 807]
    for i in 0..(aArray.length-1)
      if aArray[i] == aPokedexID
        return false
      end
    end
    return true
  end
  def aNameContains(aFoundName, aNewName)
    iMax = aFoundName.length-aNewName.length
    for i in 0..iMax
      bMatches = true
      for i2 in 0...aNewName.length
        if !(aFoundName[i+i2] == aNewName[i2])
          bMatches = false
          break
        end
      end
      return true if bMatches
    end
    return false
  end
  def aaaChangeSpecies(pkmn)
    #Is this the alternate forms pack mod? Ask drapion!
    formnames = AAA_GetFormNames(getID(PBSpecies, :DRAPION))
    bIsAlternatePack = (formnames.length > 1)
    
    #Start
    aChoice = Kernel.pbMessage(_INTL("Reroll or select a new one?"),[_INTL("Randomize"),_INTL("Choose pokemon"),_INTL("Cancel")],3)
    
    aNewSpecies = 0
    iForm = 0
    
    if aChoice == 0
      aTempArray = Array.new()
      
      for i in 1..PBSpecies.maxValue
        if PBSpecies.getName(i) != ""
          if pbGetPreviousForm(i) == i
            if aIsAvailableYet(i)
              aTempMon = pkmn.clone
              aTempMon.species = i
              
              if !unavailableMonList(aTempMon)
                if bIsAlternatePack
                  formnames = AAA_GetFormNames(i)
                  for form in formnames
                    aTempArray[aTempArray.length] = i
                  end
                else
                  aTempArray[aTempArray.length] = i
                  
                  if aCanBeAlolan(i)
                    #Double chance to get it if it can be alolan - this way alolans are treated as if they were a different species altogether
                    aTempArray[aTempArray.length] = i
                  end
                end
              end
            end
          end
        end
      end
      
      if aTempArray.length > 0
        aNewSpecies = aTempArray[rand(aTempArray.length)]
        
        if bIsAlternatePack
          formnames = AAA_GetFormNames(aNewSpecies)
          iForm = formnames[rand(formnames.length)][1] if formnames.length > 0
        else
          if aCanBeAlolan(aNewSpecies)
            iForm = rand(2)
          end
        end
      end
    end
    if aChoice == 1
      aChoice2 = Kernel.pbMessage(_INTL("How?"),[_INTL("By ID"),_INTL("By name"),_INTL("Cancel")],3)
      
      if aChoice2 == 0
        params=ChooseNumberParams.new
        params.setRange(1,PBSpecies.maxValue)
        params.setDefaultValue(pkmn.species)
        
        aNewSpecies = Kernel.pbMessageChooseNumber(_INTL("Select a new pokedex ID"), params)
      end
      
      if aChoice2 == 1
        aNewName = pbEnterPokemonName("Name of the new species?",0,15,"").downcase
        
        aFoundNames = []
        aFoundSpecies = []
        for i in 1..PBSpecies.maxValue
          aFoundName = PBSpecies.getName(i)
          
          if aNameContains(aFoundName.downcase, aNewName)
            aFoundSpecies.push(i)
            aFoundNames.push(aFoundName)
          end
        end
        
        if aFoundSpecies.length > 0
          if aFoundSpecies.length > 1
            i = Kernel.pbMessage(_INTL("Found {1} species", aFoundNames.length), aFoundNames, 0) #0 here prevents exiting without making a choice
            aNewSpecies = aFoundSpecies[i]
          else
            aNewSpecies = aFoundSpecies[0]
          end
        else
          Kernel.pbMessage(_INTL("Sorry, {1} was not found.", aNewName))
        end
      end
      
      if aNewSpecies > 0
        if bIsAlternatePack
          formnames = AAA_GetFormNames(aNewSpecies)
          if formnames.length > 1
            formnames_strings = []
            for name in formnames
              formnames_strings[formnames_strings.length] = name[0]
            end
            iForm = formnames[Kernel.pbMessage(_INTL("Which form would you like?"), formnames_strings, 1)][1]
          end
        else
          if aCanBeAlolan(aNewSpecies)
            iForm = Kernel.pbMessage(_INTL("Normal or alolan version?"),[_INTL("Normal"),_INTL("Alolan")],1)
          end
        end
      end
    end
    
    if aNewSpecies > 0
      aTempMon = pkmn.clone
      aTempMon.species = aNewSpecies
      if unavailableMonList(aTempMon) == false
        if aIsAvailableYet(aNewSpecies) == false
          aNewSpecies = 0
          Kernel.pbMessage(_INTL("Sorry, this mon would break the game"))
        end
      end
    end
    
    if aNewSpecies > 0
      $Trainer.seen[pkmn.species]=false
      $Trainer.owned[pkmn.species]=false
      
      #Species
      aOldSpecies = pkmn.species
      pkmn.species = aNewSpecies
      
      pkmn.form = iForm #Normal/Alolan/Alternate form
      
      if pkmn.isMega?
        pkmn.makeUnmega
      end 
      
      #Name
      if pkmn.name == PBSpecies.getName(aOldSpecies)
        pkmn.name = PBSpecies.getName(pkmn.species)
      end
      
      #Moves
      for i in 0..4
        pkmn.pbDeleteMoveAtIndex(0)
      end
      moves=[]
      initialmoves = pkmn.getMoveList
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
            moveid = 0
            break
          end
        end
        finalmoves[j]=PBMove.new(moveid)
        finalmoves_id[j]=moveid
        j+=1
      end 
      for i in 0..3
        pkmn.moves[i]=finalmoves[i]
      end
      pkmn.pbRecordFirstMoves
      
      #Legal?
      if unavailableMonList(pkmn)
        Kernel.pbMessage(_INTL("Warning: this is an illegal mon"))
        Kernel.pbMessage(_INTL("You won't be able to play online with it in the party"))
      end
      
      #Stats
      pkmn.calcStats
      
      #Pokedex
      $Trainer.seen[pkmn.species]=true
      $Trainer.owned[pkmn.species]=true
      
      if defined?($PokemonStorage.SetBox)
        for i in 0...$PokemonStorage[$PokemonStorage.maxBoxes-1].length
          poke = $PokemonStorage[$PokemonStorage.maxBoxes-1, i]
          if poke
            if !poke.isEgg?
              $Trainer.seen[poke.species]=true
              $Trainer.owned[poke.species]=true
            end
          end
        end
      end
    end
  end
  #####/MODDED
  
  def pbPokemonScreen
    @scene.pbStartScene(@party,
       @party.length>1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."),nil)
    loop do
      @scene.pbSetHelpText(
         @party.length>1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
      pkmnid=@scene.pbChoosePokemon
      if pkmnid<0
        break
      end
      pkmn=@party[pkmnid]
      commands=[]
      cmdSummary=-1
      cmdSwitch=-1
      cmdItem=-1
      cmdDebug=-1
      cmdMail=-1
      # Build the commands
      commands[cmdSummary=commands.length]=_INTL("Summary")
      if ($DEBUG || (defined?($PokemonSystem.showDebugMenu) && $PokemonSystem.showDebugMenu > 1)) #####MODDED, was if $DEBUG
        # Commands for debug mode only
        commands[cmdDebug=commands.length]=_INTL("Debug")
      end
        
      #####MODDED
      acmdReroll=-1
      if ($game_map.map_id == 39)
        commands[acmdReroll=commands.length]=_INTL("Change Starter") if $Trainer.numbadges <= 0
      end
      acmdTMX=-1
      if defined?(aaaUseTMX)
        commands[acmdTMX=commands.length]=_INTL("Use TMX")
      end
      #####/MODDED
        
      cmdMoves=[-1,-1,-1,-1]
      for i in 0...pkmn.moves.length
        move=pkmn.moves[i]
        # Check for hidden moves and add any that were found
        if !pkmn.isEgg? && (
           isConst?(move.id,PBMoves,:MILKDRINK) ||
           isConst?(move.id,PBMoves,:SOFTBOILED) ||
           HiddenMoveHandlers.hasHandler(move.id)
           )
          commands[cmdMoves[i]=commands.length]=PBMoves.getName(move.id)
        end
      end
      commands[cmdSwitch=commands.length]=_INTL("Switch") if @party.length>1
      if !pkmn.isEgg?
        if pkmn.mail
          commands[cmdMail=commands.length]=_INTL("Mail")
        else
          commands[cmdItem=commands.length]=_INTL("Item")
        end
      end
      commands[commands.length]=_INTL("Cancel")
      command=@scene.pbShowCommands(_INTL("Do what with {1}?",pkmn.name),commands)
      havecommand=false
      for i in 0...4
        if cmdMoves[i]>=0 && command==cmdMoves[i]
          havecommand=true
          if isConst?(pkmn.moves[i].id,PBMoves,:SOFTBOILED) ||
             isConst?(pkmn.moves[i].id,PBMoves,:MILKDRINK)
            if pkmn.hp<=pkmn.totalhp/5
              pbDisplay(_INTL("Not enough HP..."))
              break
            end
            @scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
            oldpkmnid=pkmnid
            loop do
              @scene.pbPreSelect(oldpkmnid)
              pkmnid=@scene.pbChoosePokemon(true)
              break if pkmnid<0
              newpkmn=@party[pkmnid]
              if newpkmn.isEgg? || newpkmn.hp==0 || newpkmn.hp==newpkmn.totalhp || pkmnid==oldpkmnid
                pbDisplay(_INTL("This item can't be used on that Pokémon."))
              else
                pkmn.hp-=pkmn.totalhp/5
                hpgain=pbItemRestoreHP(newpkmn,pkmn.totalhp/5)
                @scene.pbDisplay(_INTL("{1}'s HP was restored by {2} points.",newpkmn.name,hpgain))
                pbRefresh
              end
            end
            break
          elsif Kernel.pbCanUseHiddenMove?(pkmn,pkmn.moves[i].id)
            @scene.pbEndScene
            if isConst?(pkmn.moves[i].id,PBMoves,:FLY)
              scene=PokemonRegionMapScene.new(-1,false)
              screen=PokemonRegionMap.new(scene)
              ret=screen.pbStartFlyScreen
              if ret
                $PokemonTemp.flydata=ret
                return [pkmn,pkmn.moves[i].id]
              end
              @scene.pbStartScene(@party,
                 @party.length>1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
              break
            end
            return [pkmn,pkmn.moves[i].id]
          else
            break
          end
        end
      end
      #####MODDED
      if acmdTMX>=0 && command==acmdTMX
        aRetArr = aaaUseTMX(pkmn)
        if aRetArr.length > 0
          havecommand=true
          return aRetArr
        end
      end
      if acmdReroll>=0 && command==acmdReroll
        havecommand=true
        aaaChangeSpecies(pkmn)
      end
      #####/MODDED
      next if havecommand
      if cmdSummary>=0 && command==cmdSummary
        @scene.pbSummary(pkmnid)
      elsif cmdSwitch>=0 && command==cmdSwitch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        oldpkmnid=pkmnid
        pkmnid=@scene.pbChoosePokemon(true)
        if pkmnid>=0 && pkmnid!=oldpkmnid
          pbSwitch(oldpkmnid,pkmnid)
        end
      elsif cmdDebug>=0 && command==cmdDebug
        pbPokemonDebug(pkmn,pkmnid)
      elsif cmdMail>=0 && command==cmdMail
        command=@scene.pbShowCommands(_INTL("Do what with the mail?"),[_INTL("Read"),_INTL("Take"),_INTL("Cancel")])
        case command
          when 0 # Read
            pbFadeOutIn(99999){
               pbDisplayMail(pkmn.mail,pkmn)
            }
          when 1 # Take
            pbTakeMail(pkmn)
            pbRefreshSingle(pkmnid)
        end
      elsif cmdItem>=0 && command==cmdItem
        command=@scene.pbShowCommands(_INTL("Do what with an item?"),[_INTL("Use"),_INTL("Give"),_INTL("Take"),_INTL("Cancel")])
        case command
          when 0 # Use
          item=@scene.pbChooseItem($PokemonBag)
          if item>0
            pbUseItemOnPokemon(item,pkmn,self)
            pbRefreshSingle(pkmnid)
          end            
          when 1 # Give
            item=@scene.pbChooseItem($PokemonBag)
            if item>0
              pbGiveMail(item,pkmn,pkmnid)
              pbRefreshSingle(pkmnid)
            end
          when 2 # Take
            pbTakeMail(pkmn)
            pbRefreshSingle(pkmnid)
        end
      end
    end
    @scene.pbEndScene
    return nil
  end
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
