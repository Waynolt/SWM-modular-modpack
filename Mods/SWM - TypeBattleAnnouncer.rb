class PokeBattle_Battle
  def pbSwitchInName(index,newpoke) #Illusion
    partynumber = pbParty(index)
    party = pbPartySingleOwner(index)
    #####MODDED, was newname=nil
    if (partynumber[newpoke].ability == PBAbilities::ILLUSION)
      party2=party.find_all {|item| item && !item.egg? && item.hp>0 }
      if party2[-1] != partynumber[newpoke] #last mon isn't the same illusion mon
        illusionpoke = party2[-1]
      end
    end
    #####MODDED, was if pbIsOpposing?(index)
    #####MODDED, was   newname = illusionpoke != nil ? illusionpoke.name : PBSpecies.getName(partynumber[newpoke].species)
    #####MODDED, was else
    #####MODDED, was   newname = illusionpoke != nil ? illusionpoke.name : partynumber[newpoke].name
    #####MODDED, was end
    #####MODDED, was return newname
    #####MODDED
    poke = illusionpoke || partynumber[newpoke]
    return poke.name if !pbIsOpposing?(index)
    if poke.type1 == poke.type2
      return _INTL('{1} ({2})', PBSpecies.getName(poke.species), PBTypes.getName(poke.type1))
    end
    return _INTL('{1} ({2}/{3})', PBSpecies.getName(poke.species), PBTypes.getName(poke.type1), PBTypes.getName(poke.type2))
    #####/MODDED
  end
  
  def pbSwitch(favorDraws=false)
    if !favorDraws
      return if @decision>0
      pbJudge()
      return if @decision>0
    else
      return if @decision==5
      pbJudge()
      return if @decision>0
    end
    firstbattlerhp=@battlers[0].hp
    switched=[]
    for index in 0...4
      next if !@doublebattle && pbIsDoubleBattler?(index)
      next if @battlers[index] && !@battlers[index].isFainted?
      next if !pbCanChooseNonActive?(index)
      if !pbOwnedByPlayer?(index)
        if (!pbIsOpposing?(index) || (@opponent && pbIsOpposing?(index)))
          newenemy=pbSwitchInBetween(index,false,false)
          newname = pbSwitchInName(index,newenemy) #Illusion

          opponent=pbGetOwner(index)
          if !@doublebattle && firstbattlerhp>0 && @shiftStyle && @opponent && @internalbattle && pbCanChooseNonActive?(0) && pbIsOpposing?(index) && @battlers[0].effects[PBEffects::Outrage]==0
            #####MODDED, was pbDisplayPaused(_INTL("{1} is about to send in {2}.",opponent.fullname,newname)) 
            #####MODDED, was if pbDisplayConfirm(_INTL("Will {1} change Pokémon?",self.pbPlayer.name))
            if pbDisplayConfirm(_INTL('{1} is about to send in {2}. Will {3} change Pokémon?', opponent.fullname, newname, self.pbPlayer.name)) #####MODDED
              newpoke=pbSwitchPlayer(0,true,true)
              if newpoke>=0
                pbDisplayBrief(_INTL("{1}, that's enough!  Come back!",@battlers[0].name))
                pbRecallAndReplace(0,newpoke)
                switched.push(0)
              end
            end
          end
          pbRecallAndReplace(index,newenemy)
          switched.push(index)
        end
      elsif @opponent
        newpoke=pbSwitchInBetween(index,true,false)
        pbRecallAndReplace(index,newpoke)
        switched.push(index)
      else
        switch=false
        if !pbDisplayConfirm(_INTL("Use next Pokémon?"))
          switch=(pbRun(index,true)<=0)
        else
          switch=true
        end
        if switch
          newpoke=pbSwitchInBetween(index,true,false)
          pbRecallAndReplace(index,newpoke)
          switched.push(index)
        end
      end
      if newpoke != nil
        for j in 0..index
         if (@battlers[j].ability == PBAbilities::TRACE)
          @battlers[j].pbAbilitiesOnSwitchIn(true)
         end
        end
      end
    end
    if switched.length>0
      priority=pbPriority
      for i in priority
        i.pbAbilitiesOnSwitchIn(true) if switched.include?(i.index)
      end
      for i in priority
        seedCheck
      end
    end
  end
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version='19'
if !getversion().start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
