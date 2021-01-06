class PokeBattle_Battle
  #####MODDED
  def aaaSWMEvOverflow
    #just needs to exist, for compatibility with ExpShareFullTeam
  end
  #####/MODDED
  
  if !defined?(pbPokemonFollow) #Redux compatibility
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
          if defined?(aaaSWMExpShareFullTeam)
            bExpShareFullTeam = ($PokemonBag.pbQuantity(:EXPSHARE) > 0)
            if bExpShareFullTeam
              for j in 0...@party1.length
                bExpShareFullTeam = false if @party1[j] && (isConst?(@party1[j].item,PBItems,:EXPSHARE) || isConst?(@party1[j].itemInitial,PBItems,:EXPSHARE))
              end
            end
          else
            bExpShareFullTeam = false
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
                      if thispoke.iv[k] < 31
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
end

def pbRaiseHappinessAndLowerEV(pokemon,scene,ev,messages)
  #####MODDED
  case ev
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
  case pokemon.gender
    when 0
      sGen = "he"
      sGenC = "He"
    when 1
      sGen = "she"
      sGenC = "She"
    else
      sGen = "it"
      sGenC = "It"
  end
  #####/MODDED
  if pokemon.happiness==255 && pokemon.ev[ev]==0
    #####MODDED
    if pokemon.iv[ev] > 0
      scene.pbDisplay(_INTL("{1}'s base {2} can't fall!", pokemon.name, sStat))
      if Kernel.pbMessage(_INTL("Should {1} become weaker instead?", sGen),[_INTL("No"),_INTL("Ok")],1) == 1
        pokemon.ev[ev]=20
        pokemon.iv[ev]-=1
        pokemon.calcStats
        scene.pbRefresh
        scene.pbDisplay(_INTL("{1} permanently lost some {2}.\n{3} adores you!", pokemon.name, sStat, sGenC))
        return true
      else
        scene.pbDisplay(_INTL("Then it wouldn't have any effect."))
        return false
      end
    else
    #####/MODDED
    scene.pbDisplay(_INTL("It won't have any effect."))
    return false
    end #####MODDED
  elsif pokemon.happiness==255
    pokemon.ev[ev]-=10
    pokemon.ev[ev]=0 if pokemon.ev[ev]<0
    pokemon.calcStats
    scene.pbRefresh
    scene.pbDisplay(messages[0])
    return true
  elsif pokemon.ev[ev]==0
    #####MODDED
    if pokemon.iv[ev] > 0
      scene.pbDisplay(_INTL("{1}'s base {2} can't fall!", pokemon.name, sStat))
      if Kernel.pbMessage(_INTL("Should {1} become weaker instead?", sGen),[_INTL("No"),_INTL("Ok")],1) == 1
        pokemon.ev[ev]=20
        pokemon.iv[ev]-=1
        pokemon.calcStats
        scene.pbDisplay(_INTL("{1} permanently lost some {2}.\n{3} turned friendly!", pokemon.name, sStat, sGenC))
      else
        scene.pbDisplay(_INTL("{1} turned friendly.", pokemon.name))
      end
    else
      scene.pbDisplay(messages[1])
    end
    #####/MODDED
    pokemon.changeHappiness("EV berry")
    scene.pbRefresh
    #####MODDED, was scene.pbDisplay(messages[1])
    return true
  else
    pokemon.changeHappiness("EV berry")
    pokemon.ev[ev]-=10
    pokemon.ev[ev]=0 if pokemon.ev[ev]<0
    pokemon.calcStats
    scene.pbRefresh
    scene.pbDisplay(messages[2])
    return true
  end
end

  ###############################################################################################################################################
  ###############################################################################################################################################
  ###############################################################################################################################################

  #Redux compatibility
if defined?(pbPokemonFollow)
  class PokeBattle_Battle
    def pbGainExpOne(index,defeated,partic,expshare,haveexpall,showmessages=true)
      thispoke=@party1[index]
      # Original species, not current species
      level=defeated.level
      baseexp=defeated.pokemon.baseExp
      evyield=defeated.pokemon.evYield
      # Gain effort value points, using RS effort values
      totalev=0
      for k in 0...6
        totalev+=thispoke.ev[k]
      end
      for k in 0...6
        evgain=evyield[k]
        evgain*=2 if isConst?(thispoke.item,PBItems,:MACHOBRACE) ||
                     isConst?(thispoke.itemInitial,PBItems,:MACHOBRACE)
        case k
        when PBStats::HP
          evgain+=4 if isConst?(thispoke.item,PBItems,:POWERWEIGHT) ||
                       isConst?(thispoke.itemInitial,PBItems,:POWERWEIGHT)
        when PBStats::ATTACK
          evgain+=4 if isConst?(thispoke.item,PBItems,:POWERBRACER) ||
                       isConst?(thispoke.itemInitial,PBItems,:POWERBRACER)
        when PBStats::DEFENSE
          evgain+=4 if isConst?(thispoke.item,PBItems,:POWERBELT) ||
                       isConst?(thispoke.itemInitial,PBItems,:POWERBELT)
        when PBStats::SPATK
          evgain+=4 if isConst?(thispoke.item,PBItems,:POWERLENS) ||
                       isConst?(thispoke.itemInitial,PBItems,:POWERLENS)
        when PBStats::SPDEF
          evgain+=4 if isConst?(thispoke.item,PBItems,:POWERBAND) ||
                       isConst?(thispoke.itemInitial,PBItems,:POWERBAND)
        when PBStats::SPEED
          evgain+=4 if isConst?(thispoke.item,PBItems,:POWERANKLET) ||
                       isConst?(thispoke.itemInitial,PBItems,:POWERANKLET)
        end
        evgain*=2 if thispoke.pokerusStage>=1 # Infected or cured
        if evgain>0
          #####MODDED
          if thispoke.iv[k] < 31
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
          # Can't exceed overall limit
          evgain-=totalev+evgain-510 if totalev+evgain>510
          # Can't exceed stat limit
          evgain-=thispoke.ev[k]+evgain-252 if thispoke.ev[k]+evgain>252
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
      # Gain experience
      ispartic=0
      ispartic=1 if defeated.participants.include?(index)
      haveexpshare=(isConst?(thispoke.item,PBItems,:EXPSHARE) ||
                    isConst?(thispoke.itemInitial,PBItems,:EXPSHARE)) ? 1 : 0
      exp=0
      if expshare>0
        if partic==0 # No participants, all Exp goes to Exp Share holders
          exp=(level*baseexp).floor
          exp=(exp/(NOSPLITEXP ? 1 : expshare)).floor*haveexpshare
        else
          if NOSPLITEXP
            exp=(level*baseexp).floor*ispartic
            exp=(level*baseexp/2).floor*haveexpshare if ispartic==0
          else
            exp=(level*baseexp/2).floor
            exp=(exp/partic).floor*ispartic + (exp/expshare).floor*haveexpshare
          end
        end
      elsif ispartic==1
        if haveexpall
          exp=(level*baseexp).floor
        else
          exp=(level*baseexp/(NOSPLITEXP ? 1 : partic)).floor
        end
      elsif haveexpall
        exp=(level*baseexp/2).floor
      end
      return if exp<=0
      exp=(exp*3/2).floor if @opponent
      if USENEWEXPFORMULA   # Use new (Gen 5) Exp. formula
        exp=(exp/5).floor
        leveladjust=(2*level+10.0)/(level+thispoke.level+10.0)
        leveladjust=leveladjust**5
        leveladjust=Math.sqrt(leveladjust)
        exp=(exp*leveladjust).floor
        exp+=1 if ispartic>0 || haveexpshare>0 || haveexpall
      else                  # Use old (Gen 1-4) Exp. formula
        exp=(exp/7).floor
      end
      isOutsider=((thispoke.trainerID != self.pbPlayer.id && thispoke.trainerID != 0) ||
                 (thispoke.language!=0 && thispoke.language!=self.pbPlayer.language))
      if isOutsider
        if thispoke.language!=0 && thispoke.language!=self.pbPlayer.language
          exp=(exp*1.7).floor
        else
          exp=(exp*3/2).floor
        end
      end
      exp=(exp*3/2).floor if isConst?(thispoke.item,PBItems,:LUCKYEGG) ||
                             isConst?(thispoke.itemInitial,PBItems,:LUCKYEGG)
      growthrate=thispoke.growthrate
  #### COMMANDER - XX1 - START
                $game_switches[1218] = false
                almostLimit = false
   
                levelLimits = [20, 25, 32, 35, 40, 42, 45, 50, 55, 60, 62, 65, 70, 72, 75, 80, 85, 88, 90, 95, 100]
                leadersDefeated = pbPlayer.numbadges
                if $game_variables[107]>=27
                  leadersDefeated += 2
                elsif $game_variables[77]>=16
                  leadersDefeated += 1
                end
                $game_variables[965] = leadersDefeated
                $game_variables[966] = levelLimits[leadersDefeated]
                                     
                if thispoke.level>=levelLimits[leadersDefeated]
                  exp = 0
                  $game_switches[1218] = true
                elsif thispoke.level == levelLimits[leadersDefeated] - 1
                  almostLimit = true
                end
  #### COMMANDER - XX1 - END
  #### COMMANDER - XX2 - START    
                if almostLimit
                  totalExpNeeded = PBExperience.pbGetStartExperience(levelLimits[leadersDefeated],growthrate)
                  currExpNeeded = totalExpNeeded - thispoke.exp
                  if exp > currExpNeeded
                    exp = currExpNeeded
                  end
                end
  #### COMMANDER - XX2 - END
      newexp=PBExperience.pbAddExperience(thispoke.exp,exp,growthrate)
      exp=newexp-thispoke.exp
      if exp>0
  #### KUROTSUNE - 020 - START
        if isOutsider || isConst?(thispoke.item,PBItems,:LUCKYEGG)
  #### KUROTSUNE - 020 - END
          pbDisplayPaused(_INTL("{1} gained a boosted {2} Exp. Points!",thispoke.name,exp))
        elsif !(ispartic==0 && haveexpall)
          pbDisplayPaused(_INTL("{1} gained {2} Exp. Points!",thispoke.name,exp))
        end
        newlevel=PBExperience.pbGetLevelFromExperience(newexp,growthrate)
        tempexp=0
        curlevel=thispoke.level
        if newlevel<curlevel
          debuginfo="#{thispoke.name}: #{thispoke.level}/#{newlevel} | #{thispoke.exp}/#{newexp} | gain: #{exp}"
          raise RuntimeError.new(_INTL("The new level ({1}) is less than the Pokémon's\r\ncurrent level ({2}), which shouldn't happen.\r\n[Debug: {3}]",
                                 newlevel,curlevel,debuginfo))
          return
        end
        if thispoke.respond_to?("isShadow?") && thispoke.isShadow?
          thispoke.exp+=exp
        else
          tempexp1=thispoke.exp
          tempexp2=0
          # Find battler
          battler=pbFindPlayerBattler(index)
          loop do
            # EXP Bar animation
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
                pbLearnMove(index,k[1])
              end
            end
          end
        end
      end
    end
  end
end

  ###############################################################################################################################################
  ###############################################################################################################################################
  ###############################################################################################################################################


#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
