#####MODDED
Events.onStepTaken += proc {
	$game_screen.swm_updateRadar
}

ItemHandlers::UseInField.add(:ITEMFINDER,proc{|item|
	$game_screen.swm_toggleRadar
	$game_screen.swm_updateRadar
})
#####/MODDED

$swm_itemRadarMarkersLayerBitmap = nil # Force the reloading of disposed graphics on soft resetting
class Game_Screen
	#####MODDED
	attr_accessor   :swm_itemRadarIsOn
	
	def swm_checkIsItemRadarOn?
    @swm_itemRadarIsOn = false if !defined?(@swm_itemRadarIsOn)
		if @swm_itemRadarIsOn
			if !defined?($swm_itemRadarMarkersLayer) || $swm_itemRadarMarkersLayer.disposed?
				$swm_itemRadarMarkersLayer = Sprite.new(nil)
				$swm_itemRadarMarkersLayer.bitmap = Bitmap.new(Graphics.width, Graphics.height)
				$swm_itemRadarMarkersLayer.ox = 0
				$swm_itemRadarMarkersLayer.oy = 0
				$swm_itemRadarMarkersLayer.z = 9998
				$swm_itemRadarMarkersLayer.visible = true
			end
		end
		return @swm_itemRadarIsOn
	end
	
	def swm_itemRadarCheckScroll(deltaX, deltaY)
		return nil if !swm_checkIsItemRadarOn?
    $swm_itemRadarMarkersLayer.ox = ($game_player.real_x/Game_Map::XSUBPIXEL)-(($game_player.x-deltaX)*Game_Map::TILEWIDTH)
    $swm_itemRadarMarkersLayer.oy = ($game_player.real_y/Game_Map::YSUBPIXEL)-(($game_player.y-deltaY)*Game_Map::TILEHEIGHT)
	end
	
	def swm_toggleRadar
		@swm_itemRadarIsOn = !@swm_itemRadarIsOn
		if swm_checkIsItemRadarOn?
			Kernel.pbMessage(_INTL('The ITEMFINDER is now ON.'))
		else
			if defined?($swm_itemRadarMarkersLayer)
				if !$swm_itemRadarMarkersLayer.disposed?
					$swm_itemRadarMarkersLayer.dispose
				end
			end
			Kernel.pbMessage(_INTL('The ITEMFINDER is now OFF.'))
		end
	end
	
	def swm_updateRadar
		return nil if !swm_checkIsItemRadarOn?
    if !$swm_itemRadarMarkersLayerBitmap
      $swm_itemRadarMarkersLayerBitmap = AnimatedBitmap.new('patch/Mods/SWM - ItemRadar.png')
    end
    playerX = $game_player.x
    playerY = $game_player.y
    offsetX = ((Graphics.width-Game_Map::TILEWIDTH)/2)
    offsetY = ((Graphics.height-Game_Map::TILEHEIGHT)/2)
    $swm_itemRadarMarkersLayer.bitmap = Bitmap.new(Graphics.width,Graphics.height)
    $swm_itemRadarMarkersLayer.ox = 0
    $swm_itemRadarMarkersLayer.oy = 0
    #Find and print items
    for event in $game_map.events.values
      next if event.name != 'HiddenItem'
      next if (playerX-event.x).abs >= 8
      next if (playerY-event.y).abs >= 6
      next if $game_self_switches[[$game_map.map_id, event.id, 'A']]
      next if $game_self_switches[[$game_map.map_id, event.id, 'B']]
      next if $game_self_switches[[$game_map.map_id, event.id, 'C']]
      next if $game_self_switches[[$game_map.map_id, event.id, 'D']]
      #Print items
      $swm_itemRadarMarkersLayer.bitmap.blt(
        offsetX+(event.x-playerX)*Game_Map::TILEWIDTH,
        offsetY+(event.y-playerY)*Game_Map::TILEHEIGHT,
        $swm_itemRadarMarkersLayerBitmap.bitmap,
        $swm_itemRadarMarkersLayerBitmap.bitmap.rect
      )
    end
	end
	#####/MODDED
end

class Game_Map
	def scroll_down(distance)
		self.display_y += distance
		$game_screen.swm_itemRadarCheckScroll(0, +1) #####MODDED
	end

	def scroll_left(distance)
		self.display_x -= distance
		$game_screen.swm_itemRadarCheckScroll(-1, 0) #####MODDED
	end

	def scroll_right(distance)
		self.display_x += distance
		$game_screen.swm_itemRadarCheckScroll(+1, 0) #####MODDED
	end

	def scroll_up(distance)
		self.display_y -= distance
		$game_screen.swm_itemRadarCheckScroll(0, -1) #####MODDED
	end
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
