class PokeBattle_Battle
  #####MODDED
  def aaaSWMExpShareFullTeam
    #just needs to exist, for compatibility with EvOverflow
  end
  #####/MODDED
  
  def pbGainEXP
    return if !@internalbattle
    #####MODDED
    sTeamExpTot = 0
    #sTeamExpMsg = ""
    #####/MODDED
    successbegin=true
    for i in 0...4 # Not ordered by priority
      if !@doublebattle && pbIsDoubleBattler?(i)
        @battlers[i].participants=[]
        next
      end
      if pbIsOpposing?(i) && @battlers[i].participants.length>0 && @battlers[i].isFainted?
        battlerSpecies=@battlers[i].pokemon.species
        # Original species, not current species
        baseexp=@battlers[i].baseExp
        level=@battlers[i].level
        # First count the number of participants
        partic=0
        expshare=0
        for j in @battlers[i].participants
          next if !@party1[j] || !pbIsOwner?(0,j)
          partic+=1 if @party1[j].hp>0 && !@party1[j].isEgg?
        end
        #####MODDED
        if defined?($PokemonSystem.expShareFormula)
          bUseOfficialFormula = ($PokemonSystem.expShareFormula!=0)
        else
          bUseOfficialFormula = false #If true battlers get 100% of the exp and the others get 50%
        end
        bExpShareFullTeam = ($PokemonBag.pbQuantity(:EXPSHARE) > 0)
        if bExpShareFullTeam
          for j in 0...@party1.length
            bExpShareFullTeam = false if @party1[j] && (isConst?(@party1[j].item,PBItems,:EXPSHARE) || isConst?(@party1[j].itemInitial,PBItems,:EXPSHARE))
          end
        end
        #####/MODDED
        for j in 0...@party1.length
          next if !@party1[j] || !pbIsOwner?(0,j)
          #####MODDED
          if bExpShareFullTeam
            expshare+=1 if @party1[j].hp>0 && !@party1[j].isEgg?
          else
          #####/MODDED
          expshare+=1 if @party1[j].hp>0 && !@party1[j].isEgg? && 
             (isConst?(@party1[j].item,PBItems,:EXPSHARE) ||
              isConst?(@party1[j].itemInitial,PBItems,:EXPSHARE))
          end #####MODDED
          
        end
        # Now calculate EXP for the participants
        if partic>0 || expshare>0
          if !@opponent && successbegin && pbAllFainted?(@party2)
            @scene.pbWildBattleSuccess
            successbegin=false
          end
          for j in 0...@party1.length
            thispoke=@party1[j]
            next if !@party1[j] || !pbIsOwner?(0,j)
            ispartic=0
            #####MODDED
            if bExpShareFullTeam
              haveexpshare=1
            else
            #####/MODDED
            haveexpshare=(isConst?(thispoke.item,PBItems,:EXPSHARE) ||
                          isConst?(thispoke.itemInitial,PBItems,:EXPSHARE)) ? 1 : 0
            end #####MODDED
            
            for k in @battlers[i].participants
              ispartic=1 if k==j
            end
            if thispoke.hp>0 && !thispoke.isEgg?
              exp=0
              if expshare>0
                #####MODDED
                if bExpShareFullTeam
                  exp=(level*baseexp).floor
                  if bUseOfficialFormula
                    exp=(exp/2).floor if ispartic == 0
                  else
                    exp=(exp/expshare).floor
                  end
                else
                #####/MODDED
                if partic==0
                  exp=(level*baseexp).floor
                  exp=(exp/expshare).floor*haveexpshare
                else
                  exp=(level*baseexp/2).floor
                  exp=(exp/partic).floor*ispartic + (exp/expshare).floor*haveexpshare
                end
                end #####MODDED
              elsif ispartic==1
                exp=(level*baseexp/partic).floor
              end
              exp=(exp*3/2).floor if @opponent
              if USENEWEXPFORMULA   # Use new (Gen 5) Exp. formula
                exp=(exp/5).floor
                leveladjust=(2*level+10.0)/(level+thispoke.level+10.0)
                leveladjust=leveladjust**5
                leveladjust=Math.sqrt(leveladjust)
                exp=(exp*leveladjust).floor
                exp+=1 if ispartic>0 || haveexpshare>0
              else                  # Use old (Gen 1-4) Exp. formula
                exp=(exp/7).floor
              end
  #            print("#{thispoke.trainerID}")
              isOutsider=((thispoke.trainerID != self.pbPlayer.id && 
                 thispoke.trainerID != 0) ||
                 (thispoke.language!=0 && thispoke.language!=self.pbPlayer.language))
   #           print("#{isOutsider}")
              if isOutsider
                if thispoke.language!=0 && thispoke.language!=self.pbPlayer.language
                  exp=(exp*17/10).floor
                else
                  exp=(exp*3/2).floor
                end
              end
              exp=(exp*3/2).floor if isConst?(thispoke.item,PBItems,:LUCKYEGG) ||
                                     isConst?(thispoke.itemInitial,PBItems,:LUCKYEGG)
									 
              growthrate=thispoke.growthrate
              newexp=PBExperience.pbAddExperience(thispoke.exp,exp,growthrate)
              exp=newexp-thispoke.exp
              if exp > 0
#### KUROTSUNE - 020 - START
                if isOutsider || isConst?(thispoke.item,PBItems,:LUCKYEGG)
#### KUROTSUNE - 020 - END
                  #####MODDED
                  if bExpShareFullTeam
                    sTeamExpTot = sTeamExpTot+exp
                    #sTeamExpMsg = _INTL("{1}\n", sTeamExpMsg) if !(sTeamExpMsg == "")
                    #sTeamExpMsg = _INTL("{1}{2} gained a boosted {3} Exp. Points!", sTeamExpMsg, thispoke.name, exp)
                  else
                  #####/MODDED
                  pbDisplayPaused(_INTL("{1} gained a boosted {2} Exp. Points!",thispoke.name,exp))
                  end #####MODDED
                else
                  #####MODDED
                  if bExpShareFullTeam
                    sTeamExpTot = sTeamExpTot+exp
                    #sTeamExpMsg = _INTL("{1}\n", sTeamExpMsg) if !(sTeamExpMsg == "")
                    #sTeamExpMsg = _INTL("{1}{2} gained {3} Exp. Points!", sTeamExpMsg, thispoke.name, exp)
                  else
                  #####/MODDED
                  pbDisplayPaused(_INTL("{1} gained {2} Exp. Points!",thispoke.name,exp))
                  end #####MODDED
                end
                #Gain effort value points, using RS effort values
                totalev=0
                for k in 0..5
                  totalev+=thispoke.ev[k]
                end
                # Original species, not current species
                evyield=@battlers[i].evYield
                for k in 0..5
                  evgain=evyield[k]
                  evgain*=2 if isConst?(thispoke.item,PBItems,:MACHOBRACE) ||
                               isConst?(thispoke.itemInitial,PBItems,:MACHOBRACE)
                  case k
                    when 0
                      if isConst?(thispoke.item,PBItems,:POWERWEIGHT)
                        evgain+=8
                      end
                    when 1
                      if isConst?(thispoke.item,PBItems,:POWERBRACER)
                        evgain+=8
                      end
                    when 2
                      if isConst?(thispoke.item,PBItems,:POWERBELT) 
                        evgain+=8
                      end
                    when 3
                      if isConst?(thispoke.item,PBItems,:POWERANKLET) 
                        evgain+=8
                      end
                    when 4
                      if isConst?(thispoke.item,PBItems,:POWERLENS) 
                        evgain+=8
                      end
                    when 5
                      if isConst?(thispoke.item,PBItems,:POWERBAND) 
                        evgain+=8
                      end
                  end
                  evgain*=2 if thispoke.pokerusStage>=1 # Infected or cured
                  #####MODDED
                  if ispartic == 0
                    if defined?($PokemonSystem.expShareEV)
                      evgain = 0 if $PokemonSystem.expShareEV == 1
                    else
                      evgain = 0 if bExpShareFullTeam
                    end
                  end
                  #####/MODDED
                  if evgain>0
                    # Can't exceed overall limit
                    if totalev+evgain>510
                      evgain-=totalev+evgain-510
                    end
                    # Can't exceed stat limit
                    #####MODDED
                    if defined?(aaaSWMEvOverflow) && (thispoke.iv[k] < 31)
                      case k
                        when 0
                          sStat = "HP"
                        when 1
                          sStat = "Attack"
                        when 2
                          sStat = "Defense"
                        when 3
                          sStat = "Speed"
                        when 4
                          sStat = "Special Attack"
                        when 5
                          sStat = "Special Defense"
                      end
                      case thispoke.gender
                        when 0
                          sGen = "he"
                          sGenP = "his"
                        when 1
                          sGen = "she"
                          sGenP = "her"
                        else
                          sGen = "it"
                          sGenP = "its"
                      end
                      if thispoke.ev[k]+evgain>252
                        pbDisplayPaused(_INTL("{1} is now skilled enough to become stronger!", thispoke.name))
                        if Kernel.pbMessage(_INTL("Should {1} permanently improve {2} {3}?", sGen, sGenP, sStat),[_INTL("No"),_INTL("Ok")],1) == 1
                          evgain = -thispoke.ev[k]
                          thispoke.iv[k] += 1
                          pbDisplayPaused(_INTL("{1}'s {2} has increased!", thispoke.name, sStat))
                        else
                          pbDisplayPaused(_INTL("{1}'s {2} didn't change.", thispoke.name, sStat))
                        end
                      end
                    end
                    #####/MODDED
                    if thispoke.ev[k]+evgain>252
                      evgain-=thispoke.ev[k]+evgain-252
                    end
                    # Add EV gain
                    thispoke.ev[k]+=evgain
                    if thispoke.ev[k]>252
                      print "Single-stat EV limit 252 exceeded.\r\nStat: #{k}  EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
                      print "The SWM modpack is installed" #####MODDED
                      thispoke.ev[k]=252
                    end
                    totalev+=evgain
                    if totalev>510
                      print "EV limit 510 exceeded.\r\nTotal EVs: #{totalev} EV gain: #{evgain}  EVs: #{thispoke.ev.inspect}"
                      print "The SWM modpack is installed" #####MODDED
                    end
                  end
                end
                newlevel=PBExperience.pbGetLevelFromExperience(newexp,growthrate)
                tempexp=0
                curlevel=thispoke.level
                thisPokeSpecies=thispoke.species
                if newlevel<curlevel
                  debuginfo="#{thispoke.name}: #{thispoke.level}/#{newlevel} | #{thispoke.exp}/#{newexp} | gain: #{exp}"
                  raise RuntimeError.new(
                     _INTL("The new level ({1}) is less than the Pokémon's\r\ncurrent level ({2}), which shouldn't happen.\r\n[Debug: {3}]",
                     newlevel,curlevel,debuginfo))
                  return
                end
                if thispoke.respond_to?("isShadow?") && thispoke.isShadow?
                  thispoke.exp+=exp
                else
                  tempexp1=thispoke.exp
                  tempexp2=0
                  # Find battler
                  battler=pbFindPlayerBattler(j)
                  loop do
                    #EXP Bar animation
                    startexp=PBExperience.pbGetStartExperience(curlevel,growthrate)
                    endexp=PBExperience.pbGetStartExperience(curlevel+1,growthrate)
                    tempexp2=(endexp<newexp) ? endexp : newexp
                    thispoke.exp=tempexp2
                    @scene.pbEXPBar(thispoke,battler,startexp,endexp,tempexp1,tempexp2)
                    tempexp1=tempexp2
                    curlevel+=1
                    if curlevel>newlevel
                      thispoke.calcStats 
                      battler.pbUpdate(false) if battler
                      @scene.pbRefresh
                      break
                    end
                    oldtotalhp=thispoke.totalhp
                    oldattack=thispoke.attack
                    olddefense=thispoke.defense
                    oldspeed=thispoke.speed
                    oldspatk=thispoke.spatk
                    oldspdef=thispoke.spdef
                    if battler
                      if battler.pokemon && @internalbattle
                        battler.pokemon.changeHappiness("level up")
                      end
                    end
                    thispoke.calcStats
                    battler.pbUpdate(false) if battler
                    @scene.pbRefresh
                    pbDisplayPaused(_INTL("{1} grew to Level {2}!",thispoke.name,curlevel))
                    @scene.pbLevelUp(thispoke,battler,oldtotalhp,oldattack,
                       olddefense,oldspeed,oldspatk,oldspdef)
                    # Finding all moves learned at this level
                    movelist=thispoke.getMoveList
                    for k in movelist
                      if k[0]==thispoke.level   # Learned a new move
                        pbLearnMove(j,k[1])
                      end
                    end
                  end
                end
              end
            end
          end
        end
        # Now clear the participants array
        @battlers[i].participants=[]
      end
    end
    
    #####MODDED
    if bExpShareFullTeam
      #pbDisplayPaused(sTeamExpMsg) if !(sTeamExpMsg == "")
      pbDisplayPaused(_INTL("Your team gained {1} Exp. Points!", sTeamExpTot)) if sTeamExpTot > 0
    end
    #####/MODDED
  end
end

#Incompatible with Redux, and redundant anyway
if defined?(pbPokemonFollow)
  Kernel.pbMessage("WARNING: the Redux mod has been detected.")
  Kernel.pbMessage("The ExpShare mod from SWM is incompatible and redundant in Redux.")
  Kernel.pbMessage("Please remove the SWM ExpShare mod.")
  exit
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
