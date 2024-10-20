#####MODDED
Events.onStepTaken += proc {
	$game_screen.swm_updateRadar
}

ItemHandlers::UseInField.add(:ITEMFINDER,proc{|item|
	$game_screen.swm_toggleRadar
	$game_screen.swm_updateRadar
})
#####/MODDED

$swm_performUpdateCheckMoreOften = true # Set to false to improve performance but at the cost of quality

$swm_itemRadarMarkersLayerBitmap = nil # Force the reloading of disposed graphics on soft resetting
class Game_Screen
	#####MODDED
	attr_accessor   :swm_itemRadarIsOn
	
	def swm_checkIsItemRadarOn?
    @swm_itemRadarIsOn = false if !defined?(@swm_itemRadarIsOn)
    $swm_oldX = $game_player.x if !defined?($swm_oldX) || $swm_oldX.nil?
    $swm_oldY = $game_player.y if !defined?($swm_oldY) || $swm_oldX.nil?
		if @swm_itemRadarIsOn
			if !defined?($swm_itemRadarMarkersLayer) || $swm_itemRadarMarkersLayer.disposed?
				$swm_itemRadarMarkersLayer = Sprite.new(nil)
				swm_clearRadarScreen
				$swm_itemRadarMarkersLayer.z = 9998
				$swm_itemRadarMarkersLayer.visible = true
			end
		end
		return @swm_itemRadarIsOn
	end

  def swm_clearRadarScreen
    $swm_itemRadarMarkersLayer.bitmap = Bitmap.new(Graphics.width,Graphics.height)
    $swm_itemRadarMarkersLayer.ox = 0
    $swm_itemRadarMarkersLayer.oy = 0
  end
	
	def swm_itemRadarCheckScroll
		return nil if !swm_checkIsItemRadarOn?
		deltaX = $game_player.x - $swm_oldX
		deltaY = $game_player.y - $swm_oldY
		swm_updateRadar if $swm_performUpdateCheckMoreOften && deltaX == 0 && deltaY == 0
    $swm_oldDeltaX = deltaX if deltaX != 0
    $swm_oldDeltaY = deltaY if deltaY != 0
    $swm_itemRadarMarkersLayer.ox = ($game_map.display_x + (Graphics.width - Game_Map::TILEWIDTH) * 2) / Game_Map::XSUBPIXEL - ($game_player.x - $swm_oldDeltaX) * Game_Map::TILEWIDTH
    $swm_itemRadarMarkersLayer.oy = ($game_map.display_y + (Graphics.height - Game_Map::TILEHEIGHT) * 2) / Game_Map::YSUBPIXEL - ($game_player.y - $swm_oldDeltaY) * Game_Map::TILEHEIGHT
    $swm_oldX = $game_player.x
    $swm_oldY = $game_player.y
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
	
	def swm_updateRadar(skipEventInFrontOfPlayer = false)
		return nil if !swm_checkIsItemRadarOn?
    if !$swm_itemRadarMarkersLayerBitmap
      $swm_itemRadarMarkersLayerBitmap = AnimatedBitmap.new('patch/Mods/SWM - ItemRadar.png')
    end
    $swm_oldDeltaX = 0
    $swm_oldDeltaY = 0
    playerX = $game_player.x
    playerY = $game_player.y
    offsetX = ((Graphics.width-Game_Map::TILEWIDTH)/2)
    offsetY = ((Graphics.height-Game_Map::TILEHEIGHT)/2)
    swm_clearRadarScreen
    #Find and print items
    for event in $game_map.events.values
      next if event.name != 'HiddenItem'
      next if (playerX-event.x).abs >= 8
      next if (playerY-event.y).abs >= 6
      next if $game_self_switches[[$game_map.map_id, event.id, 'A']]
      next if $game_self_switches[[$game_map.map_id, event.id, 'B']]
      next if $game_self_switches[[$game_map.map_id, event.id, 'C']]
      next if $game_self_switches[[$game_map.map_id, event.id, 'D']]
      next if skipEventInFrontOfPlayer && isEventInFrontOfPlayer(event)
      #Print items
      $swm_itemRadarMarkersLayer.bitmap.blt(
        offsetX+(event.x-playerX)*Game_Map::TILEWIDTH,
        offsetY+(event.y-playerY)*Game_Map::TILEHEIGHT,
        $swm_itemRadarMarkersLayerBitmap.bitmap,
        $swm_itemRadarMarkersLayerBitmap.bitmap.rect
      )
    end
	end
	
	def isEventInFrontOfPlayer(event)
	  deltaX = $game_player.x - event.x
	  deltaY = $game_player.y - event.y
	  return false if deltaX.abs + deltaY.abs != 1
	  dir = $game_player.direction
    case dir
      when 2 then return deltaX == 0 && deltaY < 0
      when 4 then return deltaX > 0 && deltaY == 0
      when 6 then return deltaX < 0 && deltaY == 0
      when 8 then return deltaX == 0 && deltaY > 0
    end
	  return false
	end
	#####/MODDED
end

class << Kernel
  #####MODDED
  if !defined?(swm_itemRadar_oldpbItemBall)
    alias :swm_itemRadar_oldpbItemBall :pbItemBall
  end

  def pbItemBall(*args, **kwargs)
    retval = swm_itemRadar_oldpbItemBall(*args, **kwargs)
    $game_screen.swm_updateRadar(true) if $swm_performUpdateCheckMoreOften && $game_screen.swm_checkIsItemRadarOn?
    return retval
  end
  #####/MODDED
end

class PokemonLoad
  #####MODDED
  if !defined?(swm_itemRadar_oldPbStartLoadScreen)
    alias :swm_itemRadar_oldPbStartLoadScreen :pbStartLoadScreen
  end

  def pbStartLoadScreen(*args, **kwargs)
    result = swm_itemRadar_oldPbStartLoadScreen(*args, **kwargs)
    $game_screen.swm_updateRadar if $swm_performUpdateCheckMoreOften
    return result
  end
  #####/MODDED
end

class Game_Map
	def scroll_down(distance)
		self.display_y += distance
		$game_screen.swm_itemRadarCheckScroll #####MODDED
	end

	def scroll_left(distance)
		self.display_x -= distance
		$game_screen.swm_itemRadarCheckScroll #####MODDED
	end

	def scroll_right(distance)
		self.display_x += distance
		$game_screen.swm_itemRadarCheckScroll #####MODDED
	end

	def scroll_up(distance)
		self.display_y -= distance
		$game_screen.swm_itemRadarCheckScroll #####MODDED
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
