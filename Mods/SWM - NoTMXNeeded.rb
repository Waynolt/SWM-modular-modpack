class PokemonSystem
  #####MODDED
  attr_accessor :SWM_opt_Headbutt
  
  def SWM_opt_Headbutt
    @SWM_opt_Headbutt = 0 if !@SWM_opt_Headbutt
    return @SWM_opt_Headbutt
  end
  #####/MODDED
end

#####MODDED
#Make sure it exists
$ModAdditionalOptions=[] if !defined?($ModAdditionalOptions)

#Record the new option
$ModAdditionalOptions.push(EnumOption.new(_INTL("SWM - Headbutt is an HM"),[_INTL("No"),_INTL("Yes")],
							proc { $PokemonSystem.SWM_opt_Headbutt },
							proc {|value|  $PokemonSystem.SWM_opt_Headbutt=value }
						  ))
#####/MODDED

class PokemonScreen
  #####MODDED
  def aaaUseTMX(pkmn)
    #Find TMs
    aMoves = []
    aCmds = []
    if $ItemData
      for aItem in 0...$ItemData.length
        if pbGetPocket(aItem) == 4 # TM pocket
          if $PokemonBag.pbQuantity(aItem) > 0
            atk = $ItemData[aItem][ITEMMACHINE] # ITEMMACHINE   = 8
            if HiddenMoveHandlers.hasHandler(atk)
              aMoves.push(atk)
              aCmds.push(_INTL("{1}: {2}", $ItemData[aItem][ITEMNAME], PBMoves.getName(atk)))
            end
          end
        end
      end
    end
    
    #There is no Headbutt TM
    if defined?($PokemonSystem.SWM_opt_Headbutt)
      if $PokemonSystem.SWM_opt_Headbutt == 1
        atk = getID(PBMoves, :HEADBUTT)
        aMoves.push(atk)
        aCmds.push(_INTL("TMna: {1}", PBMoves.getName(atk)))
      end
    end
    
    #Sort TMs
    counter = 1
    while counter < aCmds.length
      index     = counter
      while index > 0
        indexPrev = index - 1
        
        firstName  = PBMoves.getName(aMoves[indexPrev])
        secondName = PBMoves.getName(aMoves[index])  
        
        firstName = "AAAB" if firstName == "Flash"
        firstName = "AAAA" if firstName == "Fly"
        secondName = "AAAB" if secondName == "Flash"
        secondName = "AAAA" if secondName == "Fly"
        
        if firstName > secondName
          aux               = aCmds[index]
          aCmds[index]      = aCmds[indexPrev]
          aCmds[indexPrev]  = aux
          
          aux               = aMoves[index]
          aMoves[index]     = aMoves[indexPrev]
          aMoves[indexPrev] = aux
        end
        index -= 1
      end
      counter += 1
    end
    
    #Add "None"
    aMoves = aMoves+[-1]
    aCmds = aCmds+["None"]
    
    iC = Kernel.pbMessage(_INTL("Which TM should be used?"), aCmds, aCmds.length)
    if !(aCmds[iC] == "None")
      atk = aMoves[iC]
      if Kernel.pbCanUseHiddenMove?(pkmn, atk)
        @scene.pbEndScene
        if isConst?(atk,PBMoves,:FLY)
          scene=PokemonRegionMapScene.new(-1,false)
          screen=PokemonRegionMap.new(scene)
          ret=screen.pbStartFlyScreen
          if ret
            $PokemonTemp.flydata=ret
            return [pkmn,atk]
          end
          @scene.pbStartScene(@party,
             @party.length>1 ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
        else
          return [pkmn,atk]
        end
      end
    end
    
    return []
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
      if defined?(aaaChangeSpecies)
        if $game_map.map_id == 39
          commands[acmdReroll=commands.length]=_INTL("Change Starter") if $Trainer.numbadges <= 0
        end
      end
      acmdTMX=-1
      commands[acmdTMX=commands.length]=_INTL("Use TMX")
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

module Kernel
  def self.pbCheckMove(move)
    move=getID(PBMoves,move)
    return nil if !move || move<=0
    #####MODDED
    if $ItemData
      for aItem in 0...$ItemData.length
        if pbIsTechnicalMachine?(aItem)
          if $ItemData[aItem][8] == move # ITEMMACHINE   = 8
            if $PokemonBag.pbQuantity(aItem) > 0
              aIDs = []
              for i in 0...$Trainer.party.length
                aPoke = $Trainer.party[i]
                if !aPoke.isEgg? && aPoke.hp>0
                  aIDs.push(i)
                end
              end
              
              aID = aIDs[rand(aIDs.length)]
              
              return $Trainer.party[aID]
            end
          end
        end
      end
    end
    
    #There is no Headbutt TM
    if defined?($PokemonSystem.SWM_opt_Headbutt)
      if $PokemonSystem.SWM_opt_Headbutt == 1
        if move == getID(PBMoves, :HEADBUTT)
          aIDs = []
          for i in 0...$Trainer.party.length
            aPoke = $Trainer.party[i]
            if !aPoke.isEgg? && aPoke.hp>0
              aIDs.push(i)
            end
          end
          
          aID = aIDs[rand(aIDs.length)]
          
          return $Trainer.party[aID]
        end
      end
    end
    #####/MODDED
    for i in $Trainer.party
      next if i.isEgg?
      for j in i.moves
        return i if j.id==move
      end
    end
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
