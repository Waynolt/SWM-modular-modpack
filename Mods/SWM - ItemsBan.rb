class PokeBattle_Battle
	def pbItemMenu(i)
		#####MODDED
		item = @scene.pbItemMenu(i)
		
		if pbIsPokeBall?(item[0])
			return item
		else
			Kernel.pbMessage("Items are banned")
			return [0, -1]
		end
		#####/MODDED
		#####MODDED, was return @scene.pbItemMenu(i)
	end
	
	def pbEnemyShouldUseItem?(index)
		return false #####MODDED
		item=pbEnemyItemToUse(index)
		if item>0 && @battlers[index].effects[PBEffects::Embargo]==0
			pbRegisterItem(index,item,nil)
			return true
		end
		return false
	end
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
