#####MODDED
Events.onStepTaken+=proc {
	$game_screen.aUpdateRadar
}

ItemHandlers::UseInField.add(:ITEMFINDER,proc{|item|
	$game_screen.aToggleRadar
	$game_screen.aUpdateRadar
	
	return
})
#####/MODDED

class Game_Screen
	#####MODDED
	attr_accessor   :aItemsFoundVisible
	
	def aCheckItemsFoundDefined
		if !defined?(@aItemsFoundVisible)
			@aItemsFoundVisible = false
		end
		
		if @aItemsFoundVisible
			if !defined?($aItemsFound) || $aItemsFound.disposed?
				$aItemsFound = Sprite.new(nil)
				$aItemsFound.bitmap = Bitmap.new(Graphics.width,Graphics.height)
				$aItemsFound.ox = 0
				$aItemsFound.oy = 0
				$aItemsFound.z = 9998
				$aItemsFound.visible = true
			end
		end
		
		return @aItemsFoundVisible
	end
	
	def aCheckScroll(adX, adY)
		if aCheckItemsFoundDefined
			$aItemsFound.ox = ($game_player.real_x/Game_Map::XSUBPIXEL)-(($game_player.x-adX)*Game_Map::TILEWIDTH)
			$aItemsFound.oy = ($game_player.real_y/Game_Map::YSUBPIXEL)-(($game_player.y-adY)*Game_Map::TILEHEIGHT)
		end
	end
	
	def aToggleRadar
		@aItemsFoundVisible = !@aItemsFoundVisible
		
		if aCheckItemsFoundDefined
			Kernel.pbMessage("The ITEMFINDER is now ON.")
		else
			if defined?($aItemsFound)
				if !$aItemsFound.disposed?
					$aItemsFound.dispose
				end
			end
			Kernel.pbMessage("The ITEMFINDER is now OFF.")
		end
	end
	
	def aUpdateRadar
		if aCheckItemsFoundDefined
			aItemsFoundBitmap=AnimatedBitmap.new(_INTL("Data/Mods/SWM - ItemRadar"))
			
			playerX=$game_player.x
			playerY=$game_player.y
			
			aOffsetX = ((Graphics.width-Game_Map::TILEWIDTH)/2)
			aOffsetY = ((Graphics.height-Game_Map::TILEHEIGHT)/2)
			
			$aItemsFound.bitmap = Bitmap.new(Graphics.width,Graphics.height)
			$aItemsFound.ox = 0
			$aItemsFound.oy = 0
			
			#Find and print items
			for event in $game_map.events.values
				next if event.name!="HiddenItem"
				next if (playerX-event.x).abs>=8
				next if (playerY-event.y).abs>=6
				next if $game_self_switches[[$game_map.map_id,event.id,"A"]]
				next if $game_self_switches[[$game_map.map_id,event.id,"B"]]
				next if $game_self_switches[[$game_map.map_id,event.id,"C"]]
				next if $game_self_switches[[$game_map.map_id,event.id,"D"]]
				
				#Print items
				$aItemsFound.bitmap.blt(aOffsetX+(event.x-playerX)*Game_Map::TILEWIDTH, aOffsetY+(event.y-playerY)*Game_Map::TILEHEIGHT, aItemsFoundBitmap.bitmap, aItemsFoundBitmap.bitmap.rect)
			end
		end
	end
	#####/MODDED
end

class Game_Map
	def scroll_down(distance)
		self.display_y+=distance

		$game_screen.aCheckScroll(0, +1) #####MODDED
	end

	def scroll_left(distance)
		self.display_x-=distance

		$game_screen.aCheckScroll(-1, 0) #####MODDED
	end

	def scroll_right(distance)
		self.display_x+=distance

		$game_screen.aCheckScroll(+1, 0) #####MODDED
	end

	def scroll_up(distance)
		self.display_y-=distance

		$game_screen.aCheckScroll(0, -1) #####MODDED
	end
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
