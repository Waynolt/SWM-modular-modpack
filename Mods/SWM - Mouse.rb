########################################################
####################   Settings   ######################
########################################################

SWM_USE_DEFAULT_CURSOR = false  #Controls whether the custom cursor is used
SWM_NO_MAP_HIGHLIGHT   = false  #Controls whether the selected tile is highlighted



########################################################
####################  Base edits  ######################
########################################################

module Mouse
  #####MODDED
  @ShowCursor = Win32API.new('user32', 'ShowCursor', 'p', 'i')
  
  def self.aHideCursor()
    $aShowCursorCount = @ShowCursor.call(0) if !defined?($aShowCursorCount) || ($aShowCursorCount >= 0)
  end
  def self.aShowCursor()
    $aShowCursorCount = @ShowCursor.call(1) if !defined?($aShowCursorCount) || ($aShowCursorCount < 0)
  end
  #####/MODDED
end

class Game_Player
  def character_name
    if !@defaultCharacterName
      @defaultCharacterName=""
    end
    if @defaultCharacterName!=""
      return @defaultCharacterName
    end
    if !moving? && !@move_route_forcing && $PokemonGlobal
      meta=pbGetMetadata(0,MetadataPlayerA+$PokemonGlobal.playerID)
      if $PokemonGlobal.playerID>=0 && meta && 
         !$PokemonGlobal.bicycle && !$PokemonGlobal.diving && !$PokemonGlobal.surfing
        if meta[4] && meta[4]!="" && Input.dir4(false)!=0 && passable?(@x,@y,Input.dir4(false)) && pbCanRun? #####MODDED, was if meta[4] && meta[4]!="" && Input.dir4!=0 && passable?(@x,@y,Input.dir4) && pbCanRun?
          # Display running character sprite
          @character_name=pbGetPlayerCharset(meta,4)
        else
          # Display normal character sprite 
          @character_name=pbGetPlayerCharset(meta,1)
        end
      end
    end
    return @character_name
  end
end

module Input
  #Set mouse click = keyboard input, then handle the few exceptions where this isn't ok
  def self.press?(button)
    return true if (button == Input::B) && Input.repeatex?(Input::RightMouseKey) #####MODDED
    return self.count(button)>0
  end
  
  def self.trigger?(button)
    #####MODDED
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    if aMousePos == nil
      if defined?($aMouseTileCursor)
        $aMouseTileCursor.visible = false if !$aMouseTileCursor.disposed?
      end
    else
      if button == Input::B
        if $aExitScreenMouseClick
          $aExitScreenMouseClick = false
          return true
        end
        return true if Input.triggerex?(Input::RightMouseKey)
      elsif button == Input::C
        if $game_player && $scene && $scene.is_a?(Scene_Map) && !pbIsFaded?
          if Input.aPlayerShouldntMove()
            aCheckTicketScene(aMousePos) #Since it's done as a map event, we're going to catch it this way
            
            #Even Scene_map should think that left mouse click == c key if we're not exploring
            $aMouseTileCursor.visible = false if defined?($aMouseTileCursor) && !$aMouseTileCursor.disposed?
            return true if Input.triggerex?(Input::LeftMouseKey) && !$aInterceptMouseClick
          else
            Input.aGetClickedCell(aMousePos)
          end
        else 
          #Anything except Scene_map should think that left mouse click == c key
          $aMouseTileCursor.visible = false if defined?($aMouseTileCursor) && !$aMouseTileCursor.disposed?
          return true if Input.triggerex?(Input::LeftMouseKey) && !$aInterceptMouseClick
        end
        
        $aInterceptMouseClick = false
      elsif button == Input::RIGHT
        if $aFieldNotesClickRight
          $aFieldNotesClickRight = false
          return true
        end
      elsif button == Input::LEFT
        if $aFieldNotesClickLeft
          $aFieldNotesClickLeft = false
          return true
        end
      elsif button == Input::X
        if $aBagSortClick
          $aBagSortClick = false
          return true
        end
      end
    end
    #####/MODDED
    return self.buttonToKey(button).any? {|item| self.triggerex?(item) }
  end
  
  #####MODDED
  #Now to the actual moving
  #Some of these function don't need to be in Input, but leaving them there makes it less probable to accidentally overwrite an utility
  def self.aProcEvent()
    if !$PokemonTemp.miniupdate
      $game_player.check_event_trigger_here([0])
      $game_player.check_event_trigger_there([0,2]) # *Modified to prevent unnecessary triggers
      
      if !pbMapInterpreterRunning?
        $PokemonTemp.hiddenMoveEventCalling=true
      end
    end
  end
  
  def self.aPlayerChangeDir()
    case $game_player.direction
      when 2 #down
        $game_player.turn_left
      when 4 #left
        $game_player.turn_up
      when 6 #right
        $game_player.turn_down
      when 8 #up
        $game_player.turn_right
    end
  end
  
  def self.aGetClickedCell(aMousePos)
    return if $game_map.map_id != $game_player.map.map_id
    
    icX = (Graphics.width-Game_Map::TILEWIDTH)/2
    icY = (Graphics.height-Game_Map::TILEHEIGHT)/2
    
    #Offset player moving
    iOx = ($game_player.real_x/Game_Map::XSUBPIXEL)-($game_player.x*Game_Map::TILEWIDTH)
    iOy = ($game_player.real_y/Game_Map::YSUBPIXEL)-($game_player.y*Game_Map::TILEHEIGHT)
    if iOx != 0
      if iOx < 0
        iOx = iOx+Game_Map::TILEWIDTH
        iCorrX = -1
      else
        iOx = iOx-Game_Map::TILEWIDTH
        iCorrX = 1
      end
    else
      iCorrX = 0
    end
    if iOy != 0
      if iOy < 0
        iOy = iOy+Game_Map::TILEHEIGHT
        iCorrY = -1
      else
        iOy = iOy-Game_Map::TILEHEIGHT
        iCorrY = 1
      end
    else
      iCorrY = 0
    end
    
    icX = icX-iOx #Actual left edge of player's tile's corner
    icY = icY-iOy #Actual top edge of player's tile's corner
    
    idX = ((aMousePos[0]-icX)/Game_Map::TILEWIDTH).floor
    idY = ((aMousePos[1]-icY)/Game_Map::TILEHEIGHT).floor
    
    Input.aUpdateMouseTileCursor(icX, icY, idX, idY)
    
    if Input.repeatex?(Input::LeftMouseKey)
      iX = $game_player.x+idX+iCorrX
      iY = $game_player.y+idY+iCorrY
      
      if (iX == $game_player.x) && (iY == $game_player.y) && ($game_map.map_id == $game_player.map.map_id)
        iPh = -2
        if defined?($aTargetCell)
          bTurn = $aTargetCell[4]
        else
          bTurn = false
        end
      else
        iPh = 1
        bTurn = false
      end
      
      iOldPX = -1
      iOldPY = -1
      iOldTry = 0
      if defined?($aTargetCell)
        if $aTargetCell[5] > 6
          iOldTry = $aTargetCell[5]
          iOldPX = $aTargetCell[6]
          iOldPY = $aTargetCell[7]
        end
      end
      
      $aTargetCell = [iX, iY, iPh, $game_map.map_id, bTurn, iOldTry, iOldPX, iOldPY]
      #0: x
      #1: y
      #2: iPh: 1: moving, 0: done; < 0: turning
      #3: map
      #4: bTurn: turn around after first click on self
      #5: > 10: try best dir, > 5: best dir tried, > 0: both tried
      #6: old player x
      #7: old player y
    end
  end
  
  def self.aAbsDist(i1, i2)
    if i1 > i2
      return (i1-i2)
    else
      return (i2-i1)
    end
  end
  
  def self.aPlayerShouldntMove()
    return ($game_system.map_interpreter.running? or $game_temp.player_transferring or
        $game_player.move_route_forcing or $game_temp.message_window_showing or
        $PokemonTemp.miniupdate or $game_temp.transition_processing or $game_temp.menu_calling)
  end
  
  def self.aGetNextMove(button, bActuallyMove)
    iRetVal = button
    
    if defined?($aTargetCell)
      #Stop if we shouldn't be moving
      if $aTargetCell[2] != 0
        if Input.aPlayerShouldntMove()
          $aTargetCell[2] = 0
        end
      end
      
      #Move after clicking on the map
      if $aTargetCell[2] > 0
        
        if $game_player.map.map_id == $aTargetCell[3]
          bActuallyMove = false if $game_player.moving?
          
          if ($game_player.x != $aTargetCell[6]) || ($game_player.y != $aTargetCell[7])
            $aTargetCell[5] = 15
            $aTargetCell[6] = $game_player.x
            $aTargetCell[7] = $game_player.y
          end
          
          if ($aTargetCell[1] == $game_player.y) && ($aTargetCell[0] == $game_player.x) && ($aTargetCell[5] >= 2)
            #Destination reached
            $aTargetCell[2] = 0
          else
            iDistX = Input.aAbsDist($aTargetCell[0], $game_player.x)
            iDistY = Input.aAbsDist($aTargetCell[1], $game_player.y)
            if $aTargetCell[0] > $game_player.x
              iButX = Input::RIGHT
            else
              iButX = Input::LEFT
            end
            if $aTargetCell[1] > $game_player.y
              iButY = Input::DOWN
            else
              iButY = Input::UP
            end
            
            if iDistX > iDistY
              if $aTargetCell[5] > 10
                iRetVal = iButX
              elsif $aTargetCell[5] > 5
                if iDistY > 0
                  iRetVal = iButY
                else
                  $aTargetCell[5] = 6
                end
              elsif $aTargetCell[5] > 0
                iRetVal = iButX #Turns the player the correct way before calling aProcEvent
              else
                #Dead end
                if bActuallyMove
                  $aTargetCell[2] = 0
                  Input.aProcEvent()
                end
              end
            else
              if $aTargetCell[5] > 10
                iRetVal = iButY
              elsif $aTargetCell[5] > 5
                if iDistX > 0
                  iRetVal = iButX
                else
                  $aTargetCell[5] = 6
                end
              elsif $aTargetCell[5] > 0
                iRetVal = iButY #Turns the player the correct way before calling aProcEvent
              else
                #Dead end
                if bActuallyMove
                  $aTargetCell[2] = 0
                  Input.aProcEvent()
                end
              end
            end
            
            $aTargetCell[5] = $aTargetCell[5]-1 if bActuallyMove
          end
        else
          #Map changed, stop!
          $aTargetCell[2] = 0
        end
        
      elsif $aTargetCell[2] < 0
        if $aTargetCell[2] < -1
          $aTargetCell[2] = $aTargetCell[2]+1
        else
          Input.aPlayerChangeDir() if $aTargetCell[4]
          Input.aProcEvent()
          $aTargetCell[4] = true
          $aTargetCell[2] = 0
        end
      end
    end
    
    return iRetVal
  end
  
  def self.aManageMouseCursor
    return if SWM_USE_DEFAULT_CURSOR || $MKXP
    
    if !defined?($aMouseCursor) || $aMouseCursor.disposed?
			$aMouseCursor = Sprite.new(nil)
			$aMouseCursor.ox = 0
			$aMouseCursor.oy = 0
			$aMouseCursor.z = 99999999
      aCursorBitmap = AnimatedBitmap.new(_INTL("Data/Mods/SWM - Mouse cursor"))
      $aMouseCursor.bitmap = aCursorBitmap.bitmap
    end
    
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    if aMousePos == nil
      Mouse.aShowCursor()
      $aMouseCursor.visible = false
    else
      Mouse.aHideCursor()
      $aMouseCursor.visible = true
      
      $aMouseCursor.x = aMousePos[0]
      $aMouseCursor.y = aMousePos[1]
    end
  end
  
  def self.aUpdateMouseTileCursor(icX, icY, idX, idY)
    return if SWM_NO_MAP_HIGHLIGHT
    
    if !defined?($aMouseTileCursor) || $aMouseTileCursor.disposed?
      $aMouseTileCursor = Sprite.new(nil)
			$aMouseTileCursor.ox = 0
			$aMouseTileCursor.oy = 0
			$aMouseTileCursor.z = 9998
      aCursorBitmap = AnimatedBitmap.new(_INTL("Data/Mods/SWM - Mouse tile"))
      $aMouseTileCursor.bitmap = aCursorBitmap.bitmap
		end
    
    $aMouseTileCursor.visible = true
    $aMouseTileCursor.x = icX+idX*Game_Map::TILEWIDTH
    $aMouseTileCursor.y = icY+idY*Game_Map::TILEHEIGHT
  end
  #####/MODDED
  
  def self.dir4(bActuallyMove = true) #####MODDED, was def self.dir4
    button=0
    repeatcount=0
    if self.press?(Input::DOWN) && self.press?(Input::UP)
      return 0
    end
    if self.press?(Input::LEFT) && self.press?(Input::RIGHT)
      return 0
    end
    for b in [Input::DOWN,Input::LEFT,Input::RIGHT,Input::UP]
      rc=self.count(b)
      if rc>0
        if repeatcount==0 || rc<repeatcount
          button=b
          repeatcount=rc
        end
      end
    end
    button = aGetNextMove(button, bActuallyMove) #####MODDED
    return button
  end
  
  def self.update
    update_KGC_ScreenCapture
    if trigger?(Input::F8)
      pbScreenCapture
    end
    if trigger?(Input::F7)
      pbDebugF7
    end
    if trigger?(Input::ALT)
      pbTurbo()
    end
    #####MODDED
    Input.aManageMouseCursor()
    $aDexSearchDone = false #The pokedex search is kind of a special case
    #####/MODDED
  end
end

########################################################
####################   Hovering   ######################
########################################################

#####################      1      ######################
#Messages/pause menu

class Window_DrawableCommand < SpriteWindow_SelectableEx
  #####MODDED
  def aMouseHover(bApply = true)
    aDexSearchInd = 0 #The pokedex search is kind of a special case
    return aDexSearchInd if $aDexSearchDone
    
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return aDexSearchInd if (aMousePos == nil) || !defined?(@commands)
    
    iBorderX = borderX/2
    if (aMousePos[0] > (@x+iBorderX)) && (aMousePos[0] < (@x+@width-iBorderX)) && (@commands.length > 0)
      iL0 = top_row-1
      iL1 = iL0+page_row_max+3
      
      iIndex = iL0+((aMousePos[1]-@y+(borderY/2))/rowHeight).floor
      
      aDexSearchInd = iIndex
      
      iL0 = 0 if iL0 < 0
      iL1 = @commands.length-1 if iL1 >= @commands.length
      if bApply
        if @index != iIndex && !((iIndex < iL0) || (iIndex > iL1))
          @index = iIndex
          update_cursor_rect
        end
      end
    end
    
    return aDexSearchInd
  end
  #####/MODDED
  
  def update
    oldindex=self.index
    super
    aMouseHover() #####MODDED
    refresh if self.index!=oldindex
  end
end

#####################      2      ######################
#Pokegear

class Scene_Pokegear
  #####MODDED
  def aMouseHover(aObjects)
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    iX0 = @sprites["button#{0}"].x
    iX1 = iX0+@sprites["button#{0}"].bitmap.rect.width
    
    if (aMousePos[0] > iX0) && (aMousePos[0] < iX1)
      iL = aObjects.commands.length-1
      for i in 0..iL
        if @sprites["button#{iL-i}"].y < aMousePos[1]
          aObjects.index = iL-i
          break
        end
      end
    end
  end
  #####/MODDED
  
  def update
    aMouseHover(@sprites["command_window"]) #####MODDED
    for i in 0...@sprites["command_window"].commands.length
      sprite=@sprites["button#{i}"]
      sprite.selected=(i==@sprites["command_window"].index) ? true : false
    end
    pbUpdateSpriteHash(@sprites)
    #update command window and the info if it's active
    if @sprites["command_window"].active
      update_command
      return
    end
  end
end

#####################      3      ######################
#Start menu
#Skip options and controls, they're much better to navigate with the keyboard

class PokemonLoadScene
  #####MODDED
  def aMouseHover(aObjects)
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    iX0 = @sprites["panel#{0}"].x
    iX1 = iX0+@sprites["panel#{0}"].bitmap.rect.width
    
    if (aMousePos[0] > iX0) && (aMousePos[0] < iX1)
      iL = aObjects.commands.length-1
      for i in 0..iL
        if @sprites["panel#{iL-i}"].y < aMousePos[1]
          aObjects.index = iL-i
          break
        end
      end
    end
  end
  #####/MODDED
  
  def pbUpdate
    oldi=@sprites["cmdwindow"].index rescue 0
    pbUpdateSpriteHash(@sprites)
    aMouseHover(@sprites["cmdwindow"]) #####MODDED
    newi=@sprites["cmdwindow"].index rescue 0
    if oldi!=newi
      @sprites["panel#{oldi}"].selected=false
      @sprites["panel#{oldi}"].pbRefresh
      @sprites["panel#{newi}"].selected=true
      @sprites["panel#{newi}"].pbRefresh
      while @sprites["panel#{newi}"].y>Graphics.height-16*2-23*2-1*2
        for i in 0...@commands.length
          @sprites["panel#{i}"].y-=23*2+1*2
        end
        for i in 0...6
          break if !@sprites["party#{i}"]
          @sprites["party#{i}"].y-=23*2+1*2
        end
        @sprites["player"].y-=23*2+1*2 if @sprites["player"]
      end
      while @sprites["panel#{newi}"].y<16*2
        for i in 0...@commands.length
          @sprites["panel#{i}"].y+=23*2+1*2
        end
        for i in 0...6
          break if !@sprites["party#{i}"]
          @sprites["party#{i}"].y+=23*2+1*2
        end
        @sprites["player"].y+=23*2+1*2 if @sprites["player"]
      end
    end
  end
end

#####################      4      ######################
#Character's look selection
#It is done as a map event, thus we'll catch it by trapping mouse clicks in that map
#During its selection it is stored in $game_variables[358], values 1->6
#Map: Map_id=51
#Coordinates:
#1:  x=5 y=14
#2:  x=7 y=14
#3:  x=9 y=14
#4: x=11 y=14
#5: x=13 y=14
#6: x=15 y=14

def aCheckTicketScene(aPos)
  if $game_map.map_id == 51
    idY = ((aPos[1]-((Graphics.height-Game_Map::TILEHEIGHT)/2))/Game_Map::TILEHEIGHT).to_i
    iY = $game_player.y+idY
    
    if iY == 14
      idX = ((aPos[0]-((Graphics.width-Game_Map::TILEWIDTH)/2))/Game_Map::TILEWIDTH).to_i
      iX = $game_player.x+idX
      
      case iX
        when 5
          iLook = 1
          sTxt = "introPlayer1"
        when 7
          iLook = 2
          sTxt = "introPlayer2"
        when 9
          iLook = 3
          sTxt = "introPlayer3"
        when 11
          iLook = 4
          sTxt = "introPlayer4"
        when 13
          iLook = 5
          sTxt = "introPlayer5"
        when 15
          iLook = 6
          sTxt = "introPlayer6"
        else
          iLook = 0
          sTxt = ""
      end
      
      if iLook > 0
        if $game_variables[358] != iLook
          $game_variables[358] = iLook
          $game_screen.pictures[3].show(sTxt, 0, 0, 0, 100, 100, 255, 0)
        end
      end
    end
  end
end

#####################      5      ######################
#Battle actions and moves

class PokeBattle_Scene
  #####MODDED
  def aMouseHover(aObjects)
    $aTargetCell[2] = 0 if defined?($aTargetCell) #Let battles cancel the mouse movement
    
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    if defined?(aObjects.setIndex)
      #Coordinates copied from class FightMenuButtons
      iX0 = 4
      iY0 = Graphics.height-90 #FightMenuButtons::UPPERGAP is re-added right after, thus there's no point in removing it here
      iX1 = iX0+384
      iY1 = iY0+94
      iXh = iX0+192
      iYh = iY0+47
      bIsFightMenu = true
    else
      #Coordinates copied from class CommandMenuButtons
      iX0 = Graphics.width-260
      iY0 = Graphics.height-96
      iX1 = iX0+256
      iY1 = iY0+94
      iXh = iX0+128
      iYh = iY0+47
      bIsFightMenu = false
    end
    
    if (aMousePos[0] > iX0) && (aMousePos[0] < iX1) && (aMousePos[1] > iY0) && (aMousePos[1] < iY1)
      if aMousePos[0] < iXh
        iIndex = 0
      else
        iIndex = 1
      end
      if aMousePos[1] > iYh
        iIndex = iIndex+2
      end
      if bIsFightMenu
        aObjects.setIndex(iIndex)
      else
        aObjects.index = iIndex
      end
    else
      if bIsFightMenu
        if Input.triggerex?(Input::LeftMouseKey)
          if (aMousePos[0] > 148) && (aMousePos[0] < 242) && (aMousePos[1] > 251) && (aMousePos[1] < 288)
            bPlaySound = false
            iPlayerIndex = 0
            
            if aObjects.megaButton == 1
              @battle.pbRegisterMegaEvolution(iPlayerIndex)
              aObjects.megaButton = 2
              $aInterceptMouseClick = true
              bPlaySound = true
            elsif aObjects.megaButton == 2
              aObjects.megaButton = 1
              $aInterceptMouseClick = true
              bPlaySound = true
              
              #Unregister mega evolution
              side=(@battle.pbIsOpposing?(iPlayerIndex)) ? 1 : 0
              owner=@battle.pbGetOwnerIndex(iPlayerIndex)
              side=(pbIsOpposing?(index)) ? 1 : 0
              @battle.megaEvolution[side][owner] = -1
            end
            if aObjects.ultraButton == 1
              @battle.pbRegisterUltraBurst(iPlayerIndex)
              aObjects.ultraButton = 2
              $aInterceptMouseClick = true
              bPlaySound = true
            elsif aObjects.ultraButton == 2
              aObjects.ultraButton = 1
              $aInterceptMouseClick = true
              bPlaySound = true
              
              #Unregister ultra burst
              side=(@battle.pbIsOpposing?(iPlayerIndex)) ? 1 : 0
              owner=@battle.pbGetOwnerIndex(iPlayerIndex)
              @battle.ultraBurst[side][owner] = -1
            end
            if aObjects.zButton == 1
              @battle.pbRegisterZMove(iPlayerIndex)
              aObjects.zButton = 2
              $aInterceptMouseClick = true
              bPlaySound = true
            elsif aObjects.zButton == 2
              aObjects.zButton = 1
              $aInterceptMouseClick = true
              bPlaySound = true
              
              #Unregister Z move
              side=(@battle.pbIsOpposing?(iPlayerIndex)) ? 1 : 0
              owner=@battle.pbGetOwnerIndex(iPlayerIndex)
              @battle.zMove[side][owner] = -1
            end
            
            pbPlayDecisionSE() if bPlaySound
          end
        end
      end
    end
  end
  
  def aMouseHoverTarget(index)
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return index if aMousePos == nil
    
    iRetVal = index
    
    iPart = Graphics.width/4
    
    if aMousePos[0] > 0
      iX = 0
      for i in 0...4
        if aMousePos[0] > iX
          iSel = i
        end
        iX = iX+iPart
      end
    
      if @battle.doublebattle
        case iSel
          when 0
            iSel2 = 0
          when 1
            iSel2 = 2
          when 2
            iSel2 = 3
          when 3
            iSel2 = 1
        end
      else
        if iSel > 1
          iSel2 = 1
        else
          iSel2 = 0
        end
      end
      
      iRetVal = iSel2 if !@battle.battlers[iSel2].isFainted?
    end
    
    return iRetVal
  end
  #####/MODDED
  
  def pbFrameUpdate(cw)
    cw.update if cw
    aMouseHover(cw) if cw #####MODDED
    for i in 0...4
      if @sprites["battlebox#{i}"]
        @sprites["battlebox#{i}"].update
      end
      if @sprites["pokemon#{i}"]
        @sprites["pokemon#{i}"].update
      end
    end
  end
  
  def pbChooseTarget(index)
    pbShowWindow(FIGHTBOX)
    curwindow=pbFirstTarget(index)
    if curwindow==-1
      raise RuntimeError.new(_INTL("No targets somehow..."))
    end
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      curwindow = aMouseHoverTarget(curwindow) #####MODDED
      pbUpdateSelected(curwindow)
      if Input.trigger?(Input::C)
        pbUpdateSelected(-1)
        return curwindow
      end
      if Input.trigger?(Input::B)
        pbUpdateSelected(-1)
        return -1
      end
      if curwindow>=0
        if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::DOWN)
          loop do
            newcurwindow=3 if curwindow==0
            newcurwindow=1 if curwindow==3
            newcurwindow=2 if curwindow==1
            newcurwindow=0 if curwindow==2
            curwindow=newcurwindow
            next if curwindow==index
            break if !@battle.battlers[curwindow].isFainted?
          end
        elsif Input.trigger?(Input::LEFT) || Input.trigger?(Input::UP)
          loop do 
            newcurwindow=2 if curwindow==0
            newcurwindow=1 if curwindow==2
            newcurwindow=3 if curwindow==1
            newcurwindow=0 if curwindow==3
            curwindow=newcurwindow
            next if curwindow==index
            break if !@battle.battlers[curwindow].isFainted?
          end
        end
      end
    end
  end

  def pbChooseTargetAcupressure(index)
    pbShowWindow(FIGHTBOX)
    curwindow=pbAcupressureTarget(index)
    if curwindow==-1
      raise RuntimeError.new(_INTL("No targets somehow..."))
    end
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      curwindow = aMouseHoverTarget(curwindow) #####MODDED
      pbUpdateSelected(curwindow)
      if Input.trigger?(Input::C)
        pbUpdateSelected(-1)
        return curwindow
      end
      if Input.trigger?(Input::B)
        pbUpdateSelected(-1)
        return -1
      end
      if curwindow>=0
        if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::DOWN)
          loop do
            newcurwindow=2 if curwindow==0
            newcurwindow=1 if curwindow==3
            newcurwindow=3 if curwindow==1
            newcurwindow=0 if curwindow==2
            curwindow=newcurwindow
            break if !@battle.battlers[curwindow].isFainted?
          end
        elsif Input.trigger?(Input::LEFT) || Input.trigger?(Input::UP)
          loop do 
            newcurwindow=2 if curwindow==0
            newcurwindow=0 if curwindow==2
            newcurwindow=3 if curwindow==1
            newcurwindow=1 if curwindow==3
            curwindow=newcurwindow
            break if !@battle.battlers[curwindow].isFainted?
          end
        end
      end
    end
  end
end

#####################      6      ######################
#Bag (in and out of battle)

class PokemonBag_Scene
  #####MODDED
  def aMouseOverItemList(aMousePos, aIW)
    iBorder = aIW.borderX/2
    iX0 = aIW.x+iBorder
    iX1 = aIW.x+aIW.width-iBorder
    if (aMousePos[0] > iX0) && (aMousePos[0] < iX1)
      iLimit = aIW.y+aIW.borderY
      iScroll = 0
      if aMousePos[1] < iLimit
        iScroll = -1
      else
        iL = aIW.page_item_max
        iH = (aIW.height-aIW.borderY)/(iL+1)
        
        iIndex = aIW.top_item-1
        bFound = false
        for i in 0...iL
          iIndex = iIndex+1
          iLimit = iLimit+iH
          if aMousePos[1] < iLimit
            bFound = true
            break
          end
        end
        if bFound
          iIndex = @bag.pockets[aIW.pocket].length if iIndex > @bag.pockets[aIW.pocket].length
          aIW.index = iIndex
        else
          iScroll = 1
        end
      end
      if iScroll != 0
        if iScroll < 0
          aIW.index = aIW.top_item-1 if aIW.top_item > 0
        else
          #If we have iScroll > 0 then we defined iIndex and iLimit for sure; also, bFound is false
          if aMousePos[1] < (iLimit+iH)
            iIndex = iIndex+1
            iIndex = @bag.pockets[aIW.pocket].length if iIndex > @bag.pockets[aIW.pocket].length
            aIW.index = iIndex
          end
        end
      end
    end
  end
  
  def aMouseOverPocket(aMousePos, aIW)
    $aBagSortClick = false
    
    if Input.triggerex?(Input::LeftMouseKey)
      #Got the coordinates directly from the background image
      if (aMousePos[1] > 145) && (aMousePos[1] < 180)
        if (aMousePos[0] > 25) && (aMousePos[0] < 150)
          #Sort
          $aBagSortClick = true
          $aInterceptMouseClick = true
        end
      elsif (aMousePos[1] > 230) && (aMousePos[1] < 250)
        iX0 = 5
        iX1 = 180
        if (aMousePos[0] > iX0) && (aMousePos[0] < iX1)
          #Pocket
          iL = PokemonBag.numPockets
          iW = (iX1-iX0)/iL
          iP = iL-((iX1-aMousePos[0])/iW).floor
          
          #Check; shouldn't actually be needed, but better safe than sorry
          iP = 1 if iP < 1
          iP = iL if iP > iL
          
          #Finish
          $aInterceptMouseClick = true
          if iP != aIW.pocket
            aIW.pocket = iP
            @bag.lastpocket = aIW.pocket
            pbRefresh
          end
        end
      end
    end
  end
  
  def aMouseOverSlider(aMousePos, aIW)
    if Input.repeatex?(Input::LeftMouseKey)
      if (aMousePos[0] > 470) && (aMousePos[0] < 505)
        if (aMousePos[1] > 55) && (aMousePos[1] < 220)
          iMax = aIW.itemCount-1
          iY = aMousePos[1]-@sprites["slider"].bitmap.height/2
          iIndex = (iY-60)*iMax/116
          iIndex = 0 if iIndex < 0
          iIndex = iMax if iIndex > iMax
          
          if iIndex != aIW.index
            aIW.index = iIndex
            @sprites["slider"].y = iY
          end
          
          $aInterceptMouseClick = true
        elsif (aMousePos[1] > 20) && (aMousePos[1] <= 55)
          iMax = aIW.itemCount-1
          if iMax > 0
            iIndex = aIW.index-aIW.page_item_max
            iIndex = 0 if iIndex < 0
            iIndex = iMax if iIndex > iMax
            
            iY = 60+116.0 * iIndex/iMax
            
            if iIndex != aIW.index
              aIW.index = iIndex
              @sprites["slider"].y = iY
            end
            
            $aInterceptMouseClick = true
          end
        elsif (aMousePos[1] >= 220) && (aMousePos[1] < 260)
          iMax = aIW.itemCount-1
          if iMax > 0
            iIndex = aIW.index+aIW.page_item_max
            iIndex = 0 if iIndex < 0
            iIndex = iMax if iIndex > iMax
            
            iY = 60+116.0 * iIndex/iMax
            
            if iIndex != aIW.index
              aIW.index = iIndex
              @sprites["slider"].y = iY
            end
            
            $aInterceptMouseClick = true
          end
        end
      end
    end
  end
  
  def aMouseHover()
    return if (@sprites["helpwindow"].visible) || (@sprites["msgwindow"].visible) #An item is selected
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    aIW = @sprites["itemwindow"]
    aMouseOverItemList(aMousePos, aIW)
    aMouseOverPocket(aMousePos, aIW)
    aMouseOverSlider(aMousePos, aIW)
  end
  #####/MODDED
  
  def update
    aMouseHover() #####MODDED
    pbUpdateSpriteHash(@sprites)
  end
end

#####################      7      ######################
#Party (in and out of battle)

class PokemonScreen_Scene
  #####MODDED
  def aMouseSelMon(aMousePos)
    if Input.triggerex?(Input::LeftMouseKey)
      if aMousePos[0] > 400
        if (aMousePos[1] > 330) && (aMousePos[1] < 375)
          $aExitScreenMouseClick = true
          $aInterceptMouseClick = true
        end
      end
    else
      bFound = false
      for i in 0...@party.length
        aSprite = @sprites["pokemon#{i}"]
        if (aMousePos[0] > aSprite.x) && (aMousePos[0] < (aSprite.x+aSprite.bitmap.width))
          if (aMousePos[1] > aSprite.y) && (aMousePos[1] < (aSprite.y+aSprite.bitmap.height))
            iSel = i
            bFound = true
            break
          end
        end
      end
      
      #We don't have a width or height; instead, we just check the topleft corner without breaking the loop
      if bFound && (iSel != @activecmd) && (@party[i] != nil)
        @sprites["pokemon#{@activecmd}"].selected = false
        @activecmd=iSel
        @sprites["pokemon#{iSel}"].selected = true
      end
    end
  end
  
  def aMouseHover()
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    sTxt = @sprites["helpwindow"].text
    sTxt = sTxt[0..3]
    
    aMouseSelMon(aMousePos) if (sTxt == "Choo") || (sTxt == "Move") || (sTxt == "Give") || (sTxt == "Use ") || (sTxt == "Teac") || (sTxt == "Fuse") #"Choose a pokemon" or "Move to where?" etc
  end
  #####/MODDED
  
  def update
    aMouseHover() #####MODDED
    pbUpdateSpriteHash(@sprites)
  end
end

#####################      8      ######################
#Map

class PokemonRegionMapScene
  #####MODDED
  def aMouseHover()
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    aMap = @sprites["map"]
    if (aMousePos[0] > aMap.x) && (aMousePos[0] < (aMap.x+aMap.bitmap.width))
      if (aMousePos[1] > aMap.y) && (aMousePos[1] < (aMap.y+aMap.bitmap.height))
        xOffset = aMousePos[0]-aMap.x
        yOffset = aMousePos[1]-aMap.y
        iNewX = xOffset/SQUAREWIDTH
        iNewY = yOffset/SQUAREHEIGHT
        
        aCursor = @sprites["cursor"]
        if iNewX != @mapX
          @mapX = iNewX
          aCursor.x = -SQUAREWIDTH/2+(@mapX*SQUAREWIDTH)+(Graphics.width-aMap.bitmap.width)/2
        end
        if iNewY != @mapY
          @mapY = iNewY
          aCursor.y = -SQUAREHEIGHT/2+(@mapY*SQUAREHEIGHT)+(Graphics.height-aMap.bitmap.height)/2
        end
      end
    end
  end
  #####/MODDED
  
  def pbUpdate
    aMouseHover() #####MODDED
    pbUpdateSpriteHash(@sprites)
  end
end

#####################      9      ######################
#Nyu's PC: party selection

class PokemonStorageScene
  #####MODDED
  def aMouseHoverParty(rSel)
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return rSel if aMousePos == nil
    
    iSel = rSel
    
    aTab = @sprites["boxparty"]
    iMX = aMousePos[0]-aTab.x
    if (iMX > 16) && (iMX < aTab.bitmap.width)
      iMY = aMousePos[1]-aTab.y
      if (iMY > 0) && (iMY < aTab.bitmap.height)
        #Copied over from the actual code
        if iMY > 208 #144+64
          iSel = 6
        else
          xDiv=92
          yvalues=[0,16,64,80,128,144]
          if iMX > xDiv
            for i in 0...3
              i2 = i*2+1
              if iMY > yvalues[i2]
                iSel = i2
              end
            end
          else
            for i in 0...3
              i2 = i*2
              if iMY > yvalues[i2]
                iSel = i2
              end
            end
          end
        end
      end
    end
    
    return iSel
  end
  #####/MODDED
  
  def pbSelectPartyInternal(party,depositing)
    selection=@selection
    pbPartySetArrow(@sprites["arrow"],selection)
    pbUpdateOverlay(selection,party)
    pbSetMosaic(selection)
    lastsel=1
    loop do
      Graphics.update
      Input.update
      key=-1
      key=Input::DOWN if Input.repeat?(Input::DOWN)
      key=Input::RIGHT if Input.repeat?(Input::RIGHT)
      key=Input::LEFT if Input.repeat?(Input::LEFT)
      key=Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        pbPlayCursorSE()
        newselection=pbPartyChangeSelection(key,selection)
      #####MODDED
      else
        newselection=aMouseHoverParty(selection)
      end
      if newselection != selection
      #####/MODDED
        if newselection==-1
          return -1 if !depositing
        elsif newselection==-2
          selection=lastsel
        else
          selection=newselection
        end
        pbPartySetArrow(@sprites["arrow"],selection)
        lastsel=selection if selection>0
        pbUpdateOverlay(selection,party)
        pbSetMosaic(selection)
      end
      pbUpdateSpriteHash(@sprites)
      if Input.trigger?(Input::C)
        if selection>=0 && selection<6
          @selection=selection
          return selection
        elsif selection==6 # Close Box 
          @selection=selection
          return (depositing) ? -3 : -1
        end
      end
      if Input.trigger?(Input::B)
        @selection=selection
        return -1
      end
    end
  end
end

#####################      10      ######################
#Nyu's PC: box
#box: pbSelectBoxInternal(party)

class PokemonStorageScene
  #####MODDED
  def aMouseHoverBox(rSel)
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return rSel if aMousePos == nil
    iSel = rSel
    
    #Coordinates taken directly from the bitmap
    if (aMousePos[1] > 20) && (aMousePos[1] < 60)
      #Upper bar
      if (aMousePos[0] > 185) && (aMousePos[0] < 220)
        if Input.triggerex?(Input::LeftMouseKey)
          $aInterceptMouseClick = true
          iSel = -4 # Move to previous box
        end
      elsif (aMousePos[0] > 230) && (aMousePos[0] < 460)
        iSel = -1 # Box name
      elsif (aMousePos[0] > 470) && (aMousePos[0] < 505)
        if Input.triggerex?(Input::LeftMouseKey)
          $aInterceptMouseClick = true
          iSel = -5 # Move to next box
        end
      end
    elsif (aMousePos[1] > 64) && (aMousePos[1] < 304)
      if aMousePos[0] > 202
        if aMousePos[0] < 490
          #Box
          #Squares' edges: 48
          
          iX = ((aMousePos[0]-202)/48).floor
          iY = ((aMousePos[1]-64)/48).floor
          
          iSel = iX+iY*6
        end
      end
    elsif (aMousePos[1] > 325) && (aMousePos[1] < 365)
      #Lower bar
      if (aMousePos[0] > 185) && (aMousePos[0] < 355)
        iSel = -2 # Party
      elsif (aMousePos[0] > 385) && (aMousePos[0] < 505)
        iSel = -3 # Close Box
      end
    end
    
    return iSel
  end
  #####/MODDED
  
  def pbSelectBoxInternal(party)
    selection=@selection
    pbSetArrow(@sprites["arrow"],selection)
    pbUpdateOverlay(selection)
    pbSetMosaic(selection)
    loop do
      Graphics.update
      Input.update
      key=-1
      key=Input::DOWN if Input.repeat?(Input::DOWN)
      key=Input::RIGHT if Input.repeat?(Input::RIGHT)
      key=Input::LEFT if Input.repeat?(Input::LEFT)
      key=Input::UP if Input.repeat?(Input::UP)
      iOldSel=selection #####MODDED
      if key>=0
        pbPlayCursorSE()
        selection=pbChangeSelection(key,selection)
      #####MODDED
      else
        selection=aMouseHoverBox(selection)
      end
      if selection != iOldSel
      #####/MODDED
        pbSetArrow(@sprites["arrow"],selection)
        nextbox=-1
        if selection==-4
          nextbox=(@storage.currentBox==0) ? @storage.maxBoxes-1 : @storage.currentBox-1
          pbSwitchBoxToLeft(nextbox)
          @storage.currentBox=nextbox
          selection=-1
        elsif selection==-5
          nextbox=(@storage.currentBox==@storage.maxBoxes-1) ? 0 : @storage.currentBox+1
          pbSwitchBoxToRight(nextbox)
          @storage.currentBox=nextbox
          selection=-1
        end
        selection=-1 if selection==-4 || selection==-5
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      end
      pbUpdateSpriteHash(@sprites)
      if Input.trigger?(Input::C)
        if selection>=0
          @selection=selection
          return [@storage.currentBox,selection]
        elsif selection==-1 # Box name 
          @selection=selection
          return [-4,-1]
        elsif selection==-2 # Party Pokémon 
          @selection=selection
          return [-2,-1]
        elsif selection==-3 # Close Box 
          @selection=selection
          return [-3,-1]
        end
      end
      if Input.trigger?(Input::B)
        @selection=selection
        return nil
      end
    end
  end
end

#####################      11      ######################
#PC: items

class ItemStorageScene
  #####MODDED
  def aMouseOverItemList(aMousePos, aIW)
    iBorder = aIW.borderX/2
    iX0 = aIW.x+iBorder
    iX1 = aIW.x+aIW.width-iBorder
    if (aMousePos[0] > iX0) && (aMousePos[0] < iX1)
      iLimit = aIW.y+aIW.borderY
      iScroll = 0
      if aMousePos[1] < iLimit
        iScroll = -1
      else
        iL = aIW.page_item_max
        iH = (aIW.height-aIW.borderY)/(iL+1)
        
        iIndex = aIW.top_item-1
        bFound = false
        for i in 0...iL
          iIndex = iIndex+1
          iLimit = iLimit+iH
          if aMousePos[1] < iLimit
            bFound = true
            break
          end
        end
        if bFound
          iIndex = @bag.items.length if iIndex > @bag.items.length
          aIW.index = iIndex
        else
          iScroll = 1
        end
      end
      if iScroll != 0
        if iScroll < 0
          aIW.index = aIW.top_item-1 if aIW.top_item > 0
        else
          #If we have iScroll > 0 then we defined iIndex and iLimit for sure; also, bFound is false
          if aMousePos[1] < (iLimit+iH)
            iIndex = iIndex+1
            iIndex = @bag.items.length if iIndex > @bag.items.length
            aIW.index = iIndex
          end
        end
      end
    end
  end
  
  def aMouseHover()
    return if (@sprites["helpwindow"].visible) || (@sprites["msgwindow"].visible) #An item is selected
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    aIW = @sprites["itemwindow"]
    aMouseOverItemList(aMousePos, aIW)
  end
  #####/MODDED
  
  def update
    aMouseHover() #####MODDED
    pbUpdateSpriteHash(@sprites)
  end
end

#####################      12      ######################
#Vendors: buy menu

class PokemonMartScene
  #####MODDED
  def aMouseOverItemList(aMousePos, aIW)
    iBorder = aIW.borderX/2
    iX0 = aIW.x+iBorder
    iX1 = aIW.x+aIW.width-iBorder
    if (aMousePos[0] > iX0) && (aMousePos[0] < iX1)
      iMax = aIW.itemCount-1
      
      iLimit = aIW.y+aIW.borderY
      iScroll = 0
      if aMousePos[1] < iLimit
        iScroll = -1
      else
        iL = aIW.page_item_max
        iH = (aIW.height-aIW.borderY)/(iL+1)
        
        iIndex = aIW.top_item-1
        bFound = false
        for i in 0...iL
          iIndex = iIndex+1
          iLimit = iLimit+iH
          if aMousePos[1] < iLimit
            bFound = true
            break
          end
        end
        if bFound
          iIndex = iMax if iIndex > iMax
          aIW.index = iIndex
        else
          iScroll = 1
        end
      end
      if iScroll != 0
        if iScroll < 0
          aIW.index = aIW.top_item-1 if aIW.top_item > 0
        else
          #If we have iScroll > 0 then we defined iIndex and iLimit for sure; also, bFound is false
          if aMousePos[1] < (iLimit+iH)
            iIndex = iIndex+1
            iIndex = iMax if iIndex > iMax
            aIW.index = iIndex
          end
        end
      end
    end
  end
  
  def aMouseHover()
    return if @sprites["helpwindow"].visible #An item is selected
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    aIW = @sprites["itemwindow"]
    aMouseOverItemList(aMousePos, aIW)
  end
  #####/MODDED
  
  def update
    aMouseHover() #####MODDED
    pbUpdateSpriteHash(@sprites)
    @subscene.update if @subscene
  end
end

#####################      13      ######################
#Pokemon summary

class PokemonSummaryScene
#Page
  #####MODDED
  def aMouseHover(selmove, maxmove, moveToLearn)
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return false if aMousePos == nil
    
    bRetVal = false
    
    #Got the coordinates directly from the bitmap
    if Input.triggerex?(Input::LeftMouseKey) && !@sprites["movesel"].visible
      if (aMousePos[1] > 20) && (aMousePos[1] < 42)
        if (aMousePos[0] > 285) && (aMousePos[0] < 320)
          $aInterceptMouseClick = true
          if @page != 0
            @page = 0
            drawPageOne(@pokemon)
          end
        elsif (aMousePos[0] > 330) && (aMousePos[0] < 366)
          $aInterceptMouseClick = true
          if @page != 1
            @page = 1
            drawPageTwo(@pokemon)
          end
        elsif (aMousePos[0] > 376) && (aMousePos[0] < 412)
          $aInterceptMouseClick = true
          if @page != 2
            @page = 2
            drawPageThree(@pokemon)
          end
        elsif (aMousePos[0] > 422) && (aMousePos[0] < 458)
          $aInterceptMouseClick = true
          if @page != 3
            @page = 3
            drawPageFour(@pokemon)
          end
        elsif (aMousePos[0] > 468) && (aMousePos[0] < 502)
          $aInterceptMouseClick = true
          if @page != 4
            @page = 4
            drawPageFive(@pokemon)
          end
        end
      end
    elsif selmove > -2
      if (aMousePos[0] > 240) && (aMousePos[0] < 490)
        iSel = -1
        if aMousePos[1] < 280
          if aMousePos[1] > 20
            iSel = 0
          end
          if aMousePos[1] > 85
            iSel = 1
          end
          if aMousePos[1] > 149
            iSel = 2
          end
          if aMousePos[1] > 213
            iSel = 3
          end
        elsif aMousePos[1] > 290
          if aMousePos[1] < 365
            iSel = 4
          end
        end
        
        if (iSel <= maxmove) && (iSel != selmove) && (iSel >= 0)
          bRetVal = true
          @sprites["movesel"].index = iSel
          newmove=(iSel==4) ? moveToLearn : @pokemon.moves[iSel].id
          drawSelectedMove(@pokemon, moveToLearn, newmove)
        end
      end
    end
    
    return bRetVal
  end
  #####/MODDED

  def pbUpdate(selmove = -2, maxmove = 3, moveToLearn = -1) #####MODDED, was def pbUpdate
    bRetVal = aMouseHover(selmove, maxmove, moveToLearn) #####MODDED
    pbUpdateSpriteHash(@sprites)
    return bRetVal #####MODDED
  end
  
  def pbChooseMoveToForget(moveToLearn)
    selmove=0
    ret=0
    maxmove=(moveToLearn>0) ? 4 : 3
    loop do
      Graphics.update
      Input.update
      #####MODDED, was pbUpdate
      #####MODDED
      if pbUpdate(selmove, maxmove, moveToLearn)
        selmove = @sprites["movesel"].index
        ret = selmove
      end
      #####/MODDED
      if Input.trigger?(Input::B)
        ret=4
        break
      end
      if Input.trigger?(Input::C)
        break
      end
      if Input.trigger?(Input::DOWN)
        selmove+=1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove=(moveToLearn>0) ? maxmove : 0
        end
        selmove=0 if selmove>maxmove
        @sprites["movesel"].index=selmove
        newmove=(selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(@pokemon,moveToLearn,newmove)
        ret=selmove
      end
      if Input.trigger?(Input::UP)
        selmove-=1
        selmove=maxmove if selmove<0
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove=@pokemon.numMoves-1
        end
        @sprites["movesel"].index=selmove
        newmove=(selmove==4) ? moveToLearn : @pokemon.moves[selmove].id
        drawSelectedMove(@pokemon,moveToLearn,newmove)
        ret=selmove
      end
    end
    return (ret==4) ? -1 : ret
  end
  
#Moves
  #####MODDED
  def aMouseHoverMoves(rSel)
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return rSel if aMousePos == nil
    
    iSel = rSel
    
    if (aMousePos[0] > 245) && (aMousePos[0] < 486)
      if (aMousePos[1] > 96) && (aMousePos[1] < 352)
        iTSel = 0
        if aMousePos[1] > 160
          iTSel = 1
        end
        if aMousePos[1] > 224
          iTSel = 2
        end
        if aMousePos[1] > 288
          iTSel = 3
        end
        
        if (iTSel != rSel) && (iTSel < @pokemon.numMoves)
          iSel = iTSel
          @sprites["movesel"].index = iTSel
          newmove = @pokemon.moves[iTSel].id
          drawSelectedMove(@pokemon, 0, newmove)
        end
      end
    end
    
    return iSel
  end
  #####/MODDED
  
  def pbMoveSelection
    @sprites["movesel"].visible=true
    @sprites["movesel"].index=0
    selmove=0
    oldselmove=0
    switching=false
    drawSelectedMove(@pokemon,0,@pokemon.moves[selmove].id)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      selmove = aMouseHoverMoves(selmove) #####MODDED
      if @sprites["movepresel"].index==@sprites["movesel"].index
        @sprites["movepresel"].z=@sprites["movesel"].z+1
      else
        @sprites["movepresel"].z=@sprites["movesel"].z
      end
      if Input.trigger?(Input::B)
        break if !switching
        @sprites["movepresel"].visible=false
        switching=false
      end
      if Input.trigger?(Input::C)
        if selmove==4
          break if !switching
          @sprites["movepresel"].visible=false
          switching=false
        else
          if !(@pokemon.isShadow? rescue false)
            if !switching
              @sprites["movepresel"].index=selmove
              oldselmove=selmove
              @sprites["movepresel"].visible=true
              switching=true
            else
              tmpmove=@pokemon.moves[oldselmove]
              @pokemon.moves[oldselmove]=@pokemon.moves[selmove]
              @pokemon.moves[selmove]=tmpmove
              @sprites["movepresel"].visible=false
              switching=false
              drawSelectedMove(@pokemon,0,@pokemon.moves[selmove].id)
            end
          end
        end
      end
      if Input.trigger?(Input::DOWN)
        selmove+=1
        selmove=0 if selmove<4 && selmove>=@pokemon.numMoves
        selmove=0 if selmove>=4
        selmove=4 if selmove<0
        @sprites["movesel"].index=selmove
        newmove=@pokemon.moves[selmove].id
        pbPlayCursorSE()
        drawSelectedMove(@pokemon,0,newmove)
      end
      if Input.trigger?(Input::UP)
        selmove-=1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove=@pokemon.numMoves-1
        end
        selmove=0 if selmove>=4
        selmove=@pokemon.numMoves-1 if selmove<0
        @sprites["movesel"].index=selmove
        newmove=@pokemon.moves[selmove].id
        pbPlayCursorSE()
        drawSelectedMove(@pokemon,0,newmove)
      end
    end 
    @sprites["movesel"].visible=false
  end
end

#####################      14      ######################
#Tile puzzles

class TilePuzzleScene
  #####MODDED
  def aMouseHover()
    return if @game == 3 #Hovering is just too clunky there
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    aCursor = @sprites["cursor"]
    
    iY0 = ((Graphics.height-(@tileheight*@boardheight))/2)-32
    iY1 = iY0+@tileheight*@boardheight
    if (aMousePos[1] > iY0) && (aMousePos[1] < iY1)
      iX0 = (Graphics.width-(@tilewidth*@boardwidth))/2
      iX1 = iX0+@tilewidth*@boardwidth
      if (aMousePos[0] > iX0) && (aMousePos[0] < iX1)
        bNearOnly = ((@game > 3) && (@game <= 6))
        
        iPosX = aMousePos[0]-iX0
        iPosY = aMousePos[1]-iY0
        
        iX = (iPosX/@tilewidth).floor
        iY = (iPosY/@tileheight).floor
        
        iX = 0 if iX <0
        iX = @boardwidth-1 if iX >= @boardwidth
        iY = 0 if iY <0
        iY = @boardheight-1 if iY >= @boardheight
        
        iDir = 0
        if bNearOnly && aCursor.selected
          iOldY = (aCursor.position/@boardwidth).floor
          iOldX = aCursor.position-iOldY*@boardwidth
          
          if iOldY > iY
            iDY = iOldY-iY
            iDir = 8
          else
            iDY = iY-iOldY
            iDir = 2
          end
          if iOldX > iX
            iDX = iOldX-iX
            iDir = 4 if iDY == 0
          else
            iDX = iX-iOldX
            iDir = 6 if iDY == 0
          end
          
          bContinue = (((iDY == 0) && (iDX < 2)) || ((iDX == 0) && (iDY < 2)))
        else
          bContinue = true
        end
        
        if bContinue
          iSel = iX+iY*@boardwidth
          
          if iSel != aCursor.position
            if (iDir > 0) && aCursor.selected
              pbSwapTiles(iDir)
            else
              aCursor.position = iSel
            end
          end
        end
      elsif (@game == 1) || (@game == 2) # -> bNearOnly = false
        #Extended tiles
        iXE0 = (iX0-(@tilewidth*(@boardwidth/2).ceil))/2-10
        iXE1 = iXE0+(@tilewidth*2)
        
        bContinue = false
        if (aMousePos[0] > iXE0) && (aMousePos[0] < iXE1)
          iPosY = aMousePos[1]-iY0
          iY = (iPosY/@tileheight).floor
          
          iPosX = aMousePos[0]-iXE0
          iX = (iPosX/@tilewidth).floor
          
          iX = 0 if iX <0
          iX = @boardwidth-1 if iX >= @boardwidth
          iY = 0 if iY <0
          iY = @boardheight-1 if iY >= @boardheight
          
          bContinue = true
        else
          iXE2 = Graphics.width-iXE0-@tilewidth*(@boardwidth-2)
          iXE3 = iXE2+(@tilewidth*2)
          if (aMousePos[0] > iXE2) && (aMousePos[0] < iXE3)
            iPosY = aMousePos[1]-iY0
            iY = (iPosY/@tileheight).floor
            
            iPosX = iXE3-aMousePos[0]
            iX = @boardwidth-1-(iPosX/@tilewidth).floor
            
            iX = 0 if iX <0
            iX = @boardwidth-1 if iX >= @boardwidth
            iY = 0 if iY <0
            iY = @boardheight-1 if iY >= @boardheight
            
            bContinue = true
          end
        end
        
        if bContinue
          iSel = iX+@boardwidth*(iY+@boardheight)
          
          if iSel != aCursor.position
            aCursor.position = iSel
          end
        end
      end
    end
  end
  #####/MODDED
  
  def updateCursor
    aMouseHover() #####MODDED
    arrows=[]
    for i in 0...4
      arrows.push(pbCanMoveInDir?(@sprites["cursor"].position,(i+1)*2,@game==6))
    end
    @sprites["cursor"].arrows=arrows
  end
  
  def pbMain
    loop do
      update
      Graphics.update
      Input.update
      # Check end conditions
      if pbCheckWin
        @sprites["cursor"].visible=false
        if @game==3
          extratile=@sprites["tile#{@boardwidth*@boardheight-1}"]
          extratile.bitmap.clear
          extratile.bitmap.blt(0,0,@tilebitmap.bitmap,
             Rect.new(@tilewidth*(@boardwidth-1),@tileheight*(@boardheight-1),
             @tilewidth,@tileheight))
          extratile.opacity=0
          32.times do
            extratile.opacity+=8
            Graphics.update
            Input.update
          end
        else
          pbWait(20)
        end
        loop do
          Graphics.update
          Input.update
          break if Input.trigger?(Input::C) || Input.trigger?(Input::B)
        end
        return true
      end
      # Input
      @sprites["cursor"].selected=(Input.press?(Input::C) && @game>=3 && @game<=6)
      dir=0
      dir=2 if Input.trigger?(Input::DOWN) || Input.repeat?(Input::DOWN)
      dir=4 if Input.trigger?(Input::LEFT) || Input.repeat?(Input::LEFT)
      dir=6 if Input.trigger?(Input::RIGHT) || Input.repeat?(Input::RIGHT)
      dir=8 if Input.trigger?(Input::UP) || Input.repeat?(Input::UP)
      if dir>0
        if @game==3 || (@game!=3 && @sprites["cursor"].selected)
          if pbCanMoveInDir?(@sprites["cursor"].position,dir,true)
            pbSEPlay("Choose")
            pbSwapTiles(dir)
          end
        else
          if pbCanMoveInDir?(@sprites["cursor"].position,dir,false)
            pbSEPlay("Choose")
            @sprites["cursor"].position=pbMoveCursor(@sprites["cursor"].position,dir)
          end
        end
      elsif (@game==1 || @game==2) && Input.trigger?(Input::C)
        pbGrabTile(@sprites["cursor"].position)
      elsif (@game==2 && Input.trigger?(Input::F5)) ||
            (@game==5 && Input.trigger?(Input::F5)) ||
            (@game==7 && Input.trigger?(Input::C))
        pbRotateTile(@sprites["cursor"].position)
      elsif Input.trigger?(Input::B)
        return false
      end
      @sprites["cursor"].selected=(Input.pressex?(Input::LeftMouseKey) && @game>3 && @game<=6) #####MODDED
    end
  end
end

#####################      15      ######################
#Mining

class MiningGameScene
  #####MODDED
  def aInterceptClick()
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return false if aMousePos == nil
    
    bRetVal = false
    
    #Got coordinates from the unmodded script and directly from the bitmap
    if Input.triggerex?(Input::LeftMouseKey)
      if (aMousePos[0] > 430)
        if (aMousePos[0] < 505)
          aCursor = @sprites["cursor"]
          aTool = @sprites["tool"]
          
          newmode=2
          if (aMousePos[1] > 105) && (aMousePos[1] < 215)
            newmode=1
          elsif (aMousePos[1] > 250) && (aMousePos[1] < 355)
            newmode=0
          end
        
          if newmode < 2
            bRetVal = true
            
            if newmode != aCursor.mode
              aCursor.mode=newmode
              aTool.src_rect.set(newmode*68,0,68,100)
              aTool.y=254-144*newmode
            end
          end
        end
      end
    end
    
    return bRetVal
  end
  
  def aMouseHover()
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    #Got coordinates from the unmodded script and directly from the bitmap
    if (aMousePos[0] < 430)
      aCursor = @sprites["cursor"]
      iTileL = 32
      
      iX0 = 0
      iY0 = 64
      iX = ((aMousePos[0]-iX0)/iTileL).floor
      iY = ((aMousePos[1]-iY0)/iTileL).floor
      
      if (iX >= 0) && (iX < BOARDWIDTH)
        if (iY >= 0) && (iY < BOARDHEIGHT)
          iNewPos = iX+iY*BOARDWIDTH
          
          if iNewPos != aCursor.position
            aCursor.position = iNewPos
          end
        end
      end
    end
  end
  #####/MODDED
  
  def update
    aMouseHover() #####MODDED
    pbUpdateSpriteHash(@sprites)
  end
  
  def pbHit
    return if aInterceptClick() #####MODDED
    hittype=0
    position=@sprites["cursor"].position
    if @sprites["cursor"].mode==1   # Hammer
      pattern=[1,2,1,
               2,2,2,
               1,2,1]
      @sprites["crack"].hits+=2 if !($DEBUG && Input.press?(Input::CTRL))
    else                            # Pick
      pattern=[0,1,0,
               1,2,1,
               0,1,0]
      @sprites["crack"].hits+=1 if !($DEBUG && Input.press?(Input::CTRL))
    end
    #####MODDED
    #Ensure compatibility with MiningForRich
    if defined?(aPayToMine())
      aPayToMine()
    end
    #####/MODDED
    if @sprites["tile#{position}"].layer<=pattern[4] && pbIsIronThere?(position)
      @sprites["tile#{position}"].layer-=pattern[4]
      pbSEPlay("MiningIron")
      hittype=2
    else
      for i in 0..2
        ytile=i-1+position/BOARDWIDTH
        next if ytile<0 || ytile>=BOARDHEIGHT
        for j in 0..2
          xtile=j-1+position%BOARDWIDTH
          next if xtile<0 || xtile>=BOARDWIDTH
          @sprites["tile#{xtile+ytile*BOARDWIDTH}"].layer-=pattern[j+i*3]
        end
      end
      if @sprites["cursor"].mode==1   # Hammer
        pbSEPlay("MiningHammer")
      else
        pbSEPlay("MiningPick")
      end
    end
    update
    Graphics.update
    hititem=(@sprites["tile#{position}"].layer==0 && pbIsItemThere?(position))
    hittype=1 if hititem
    @sprites["cursor"].animate(hittype)
    revealed=pbCheckRevealed
    if revealed.length>0
      pbSEPlay("MiningFullyRevealItem")
      pbFlashItems(revealed)
    elsif hititem
      pbSEPlay("MiningRevealItem")
    end
  end
end

#####################      16      ######################
#Pokedex (search and scrollbar)

class PokemonPokedexScene
  #####MODDED
  def aMouseHoverDex()
    if @sprites["searchbg"].visible
      #We're in the search scene
      if @sprites["auxlist"].commands.length > 0
        @sprites["auxlist"].aMouseHover(true)
      else
        aSL = @sprites["searchlist"]
        
        iInd = aSL.aMouseHover(false)
        
        if (iInd > 0) && (iInd < 10)
          if iInd != 7
            aSL.index = iInd
          end
        end
      end
      
      $aDexSearchDone = true
    else
      #We're in the pokedex
      if Input.repeatex?(Input::LeftMouseKey)
        aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
        return if aMousePos == nil
        
        if (aMousePos[0] > 465) && (aMousePos[0] < 505)
          if (aMousePos[1] > 65) && (aMousePos[1] < 300)
            iMax = @sprites["pokedex"].itemCount-1
            iY = aMousePos[1]-@sprites["slider"].bitmap.height/2
            iIndex = (iY-62)*iMax/188
            iIndex = 0 if iIndex < 0
            iIndex = iMax if iIndex > iMax
            
            if iIndex != @sprites["pokedex"].index
              @sprites["pokedex"].index = iIndex
              @sprites["slider"].y = iY
            end
            
            $aInterceptMouseClick = true
          elsif (aMousePos[1] > 40) && (aMousePos[1] <= 65)
            iMax = @sprites["pokedex"].itemCount-1
            if iMax > 0
              iIndex = @sprites["pokedex"].index-@sprites["pokedex"].page_item_max
              iIndex = 0 if iIndex < 0
              iIndex = iMax if iIndex > iMax
              
              iY = 62+188.0 * iIndex/iMax
              
              if iIndex != @sprites["pokedex"].index
                @sprites["pokedex"].index = iIndex
                @sprites["slider"].y = iY
              end
              
              $aInterceptMouseClick = true
            end
          elsif (aMousePos[1] >= 300) && (aMousePos[1] < 325)
            iMax = @sprites["pokedex"].itemCount-1
            if iMax > 0
              iIndex = @sprites["pokedex"].index+@sprites["pokedex"].page_item_max
              iIndex = 0 if iIndex < 0
              iIndex = iMax if iIndex > iMax
              
              iY = 62+188.0 * iIndex/iMax
              
              if iIndex != @sprites["pokedex"].index
                @sprites["pokedex"].index = iIndex
                @sprites["slider"].y = iY
              end
              
              $aInterceptMouseClick = true
            end
          end
        end
      end
    end
  end
  
  def aMouseTabSelectDex(iPage)
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return iPage if aMousePos == nil
    
    iNewPage = iPage
    if Input.triggerex?(Input::LeftMouseKey)
      #Got coordinates directly from the bitmap
      if aMousePos[1] < 25
        if aMousePos[0] < 150
          if aMousePos[0] > 35
            iNewPage = 1
          end
          if aMousePos[0] > 70
            iNewPage = 2
          end
          if aMousePos[0] > 110
            iNewPage = 3
          end
        end
      end
    end
    
    return iNewPage
  end
  #####/MODDED
  
  def pbUpdate(bDoHover = true) #####MODDED, was def pbUpdate
    aMouseHoverDex() if bDoHover #####MODDED
    pbUpdateSpriteHash(@sprites)
  end
  
  def pbDexEntry(index)
    oldsprites=pbFadeOutAndHide(@sprites)
    pbChangeToDexEntry(@dexlist[index][0])
    pbFadeInAndShow(@sprites)
    curindex=index
    page=1
    newpage=0
    ret=0
    pbActivateWindow(@sprites,nil){
       loop do
         Graphics.update if page==1
         Input.update
         pbUpdate(false) #####MODDED, was pbUpdate
         newpage = aMouseTabSelectDex(newpage) #####MODDED
         if Input.trigger?(Input::B) || ret==1
           if page==1
             pbPlayCancelSE()
             pbFadeOutAndHide(@sprites)
           end
           break
         elsif Input.trigger?(Input::UP) || ret==8
           nextindex=-1
           i=curindex-1; loop do break unless i>=0
             if $Trainer.seen[@dexlist[i][0]]
               nextindex=i
               break
             end
             i-=1
           end
           if nextindex>=0
             curindex=nextindex
             newpage=page
           end
           pbPlayCursorSE() if newpage>1
         elsif Input.trigger?(Input::DOWN) || ret==2
           nextindex=-1
           for i in curindex+1...@dexlist.length
             if $Trainer.seen[@dexlist[i][0]]
               nextindex=i
               break
             end
           end
           if nextindex>=0
             curindex=nextindex
             newpage=page
           end
           pbPlayCursorSE() if newpage>1
         elsif Input.trigger?(Input::LEFT) || ret==4
           newpage=page-1 if page>1
           pbPlayCursorSE() if newpage>1
         elsif Input.trigger?(Input::RIGHT) || ret==6
           newpage=page+1 if page<3
           pbPlayCursorSE() if newpage>1
         elsif Input.trigger?(Input::A)
           pbPlayCry(@dexlist[curindex][0])
         end
         ret=0
         if newpage>0
           page=newpage
           newpage=0
           listlimits=0
           listlimits+=1 if curindex==0                 # At top of list
           listlimits+=2 if curindex==@dexlist.length-1 # At bottom of list
           case page
             when 1 # Show entry
               pbChangeToDexEntry(@dexlist[curindex][0])
             when 2 # Show nest
               region=-1
               if !DEXDEPENDSONLOCATION
                 dexnames=pbDexNames
                 if dexnames[pbGetSavePositionIndex].is_a?(Array)
                   region=dexnames[pbGetSavePositionIndex][1]
                 end
               end
               scene=PokemonNestMapScene.new
               screen=PokemonNestMap.new(scene)
               #####MODDED, was ret=screen.pbStartScreen(@dexlist[curindex][0],region,listlimits)
               #####MODDED
                 aRet = screen.pbStartScreen(@dexlist[curindex][0],region,listlimits)
                 ret = aRet[0]
                 newpage = aRet[1] if aRet[1] > 0
               #####/MODDED
             when 3 # Show forms
               scene=PokedexFormScene.new
               screen=PokedexForm.new(scene)
               #####MODDED, was ret=screen.pbStartScreen(@dexlist[curindex][0],listlimits)
               #####MODDED
                 aRet = screen.pbStartScreen(@dexlist[curindex][0],listlimits)
                 ret = aRet[0]
                 newpage = aRet[1] if aRet[1] > 0
               #####/MODDED
           end
         end
       end
    }
    $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex]=curindex if !@searchResults
    @sprites["pokedex"].index=curindex
    @sprites["pokedex"].refresh
    iconspecies=@sprites["pokedex"].species
    iconspecies=0 if !$Trainer.seen[iconspecies]
    setIconBitmap(pbPokemonBitmapFile(iconspecies,false))
    if iconspecies>0
      @sprites["species"].text=_ISPRINTF("<ac>{1:s}</ac>",PBSpecies.getName(iconspecies))
    else
      @sprites["species"].text=_ISPRINTF("")
    end
    # Update the slider
    ycoord=62
    if @sprites["pokedex"].itemCount>1
      ycoord+=188.0 * @sprites["pokedex"].index/(@sprites["pokedex"].itemCount-1)
    end
    @sprites["slider"].y=ycoord
    pbFadeInAndShow(@sprites,oldsprites)
  end
end

class PokemonNestMapScene
  #####MODDED
  def aMouseTabSelectDexScene()
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return -1 if aMousePos == nil
    
    iNewPage = -1
    if Input.triggerex?(Input::LeftMouseKey)
      #Got coordinates directly from the bitmap
      if aMousePos[1] < 25
        if aMousePos[0] < 150
          if aMousePos[0] > 35
            iNewPage = 1
          end
          if aMousePos[0] > 70
            iNewPage = 2
          end
          if aMousePos[0] > 110
            iNewPage = 3
          end
        end
      end
    end
    
    return iNewPage
  end
  #####/MODDED
  
  def pbMapScene(listlimits)
    Graphics.transition
    ret=0
    iPage=-1 #####MODDED
    loop do
      Graphics.update
      Input.update
      pbUpdate
      #####MODDED
      iPage = aMouseTabSelectDexScene()
      if iPage > 0
        ret=0
        break
      end
      #####/MODDED
      if Input.trigger?(Input::LEFT)
        ret=4
        break
      elsif Input.trigger?(Input::RIGHT)
        ret=6
        break
      elsif Input.trigger?(Input::UP) && listlimits&1==0 # If not at top of list
        ret=8
        break
      elsif Input.trigger?(Input::DOWN) && listlimits&2==0 # If not at end of list
        ret=2
        break
      elsif Input.trigger?(Input::B)
        ret=1
        pbPlayCancelSE()
        pbFadeOutAndHide(@sprites)
        break
      end
    end
    return [ret, iPage] #####MODDED, was return ret
  end
end

class PokedexFormScene
  #####MODDED
  def aMouseTabSelectDexScene()
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return -1 if aMousePos == nil
    
    iNewPage = -1
    if Input.triggerex?(Input::LeftMouseKey)
      #Got coordinates directly from the bitmap
      if aMousePos[1] < 25
        if aMousePos[0] < 150
          if aMousePos[0] > 35
            iNewPage = 1
          end
          if aMousePos[0] > 70
            iNewPage = 2
          end
          if aMousePos[0] > 110
            iNewPage = 3
          end
        end
      end
    end
    
    return iNewPage
  end
  #####/MODDED
  
  def pbControls(listlimits)
    Graphics.transition
    ret=0
    iPage=-1 #####MODDED
    loop do
      Graphics.update
      Input.update
      @sprites["icon"].update
      #####MODDED
      iPage = aMouseTabSelectDexScene()
      if iPage > 0
        ret=0
        break
      end
      #####/MODDED
      if Input.trigger?(Input::C)
        pbChooseForm
      elsif Input.trigger?(Input::LEFT)
        ret=4
        break
      elsif Input.trigger?(Input::UP) && listlimits&1==0 # If not at top of list
        ret=8
        break
      elsif Input.trigger?(Input::DOWN) && listlimits&2==0 # If not at end of list
        ret=2
        break
      elsif Input.trigger?(Input::B)
        ret=1
        pbPlayCancelSE()
        pbFadeOutAndHide(@sprites)
        break
      end
    end
    $Trainer.formlastseen[@species][0]=@gender
    $Trainer.formlastseen[@species][1]=@form
    return [ret, iPage] #####MODDED, was return ret
  end
end

#####################      17      ######################
#Voltorb flip

class VoltorbFlip
  #####MODDED
  def aMouseHover()
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    #Values copied from the unmodded script
    iSquareL = 64
    
    if aMousePos[0] < (@squares[0][0]-iSquareL/4)
      #Click Memo
      if Input.triggerex?(Input::LeftMouseKey)
        if (aMousePos[1] > @squares[15][1]) && (aMousePos[1] < (@squares[15][1]+(2*iSquareL)))
          $aInterceptMouseClick = true
          @sprites["cursor"].bitmap.clear
          if @cursor[0][3]==0 # If in normal mode
            @cursor[0]=[@directory+"cursor",128,0,64,0,64,64]
            @sprites["memo"].visible=true
          else # Mark mode
            @cursor[0]=[@directory+"cursor",128,0,0,0,64,64]
            @sprites["memo"].visible=false
          end
        end
      end
    else
      #Hover tile
      aCursor = @sprites["cursor"]
      
      iX = ((aMousePos[0]-@squares[0][0])/iSquareL).floor
      iY = ((aMousePos[1]-@squares[0][1])/iSquareL).floor
      
      if (iX >= 0) && (iX < 5)
        if (iY >= 0) && (iY < 5)
          @index[0] = iX
          @index[1] = iY
          aCursor.x = iX*iSquareL
          aCursor.y = iY*iSquareL
        end
      end
    end
  end
  #####/MODDED
  
  def pbScene
    loop do
      Graphics.update
      Input.update
      aMouseHover() #####MODDED
      getInput
      if @quit
        break
      end
    end
  end
end

#####################      18      ######################
#Field notes tab click

class Scene_FieldNotes_Info
  #####MODDED
  def aMouseHover()
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    $aFieldNotesClickLeft = false
    $aFieldNotesClickRight = false
    
    if Input.triggerex?(Input::LeftMouseKey)
      if aMousePos[1] < 30
        if aMousePos[0] < 150
           $aFieldNotesClickLeft = true
           $aInterceptMouseClick = true
        elsif aMousePos[0] > 425
           $aFieldNotesClickRight = true
           $aInterceptMouseClick = true
        end
      end
    end
  end
  #####/MODDED
  
  def update
    aMouseHover() #####MODDED
    pbUpdateSpriteHash(@sprites)
    update_command
  end
end

#####################      18      ######################
#Move relearner
class MoveRelearnerScene
  #####MODDED
  def aMouseHover()
    aMousePos = Mouse.getMousePos(false) #array, x:0 y:1
    return if aMousePos == nil
    
    if Input.triggerex?(Input::LeftMouseKey)
      if (aMousePos[1] > 350) && (aMousePos[1] < 380)
        if (aMousePos[0] > 48) && (aMousePos[0] < 124)
          iSel = @sprites["commands"].index+VISIBLEMOVES
          iSel = @moves.length-1 if iSel >= @moves.length
          @sprites["commands"].index = iSel if iSel != @sprites["commands"].index
          $aInterceptMouseClick = true
        elsif (aMousePos[0] > 133) && (aMousePos[0] < 209)
          iSel = @sprites["commands"].index-VISIBLEMOVES
          iSel = 0 if iSel < 0
          @sprites["commands"].index = iSel if iSel != @sprites["commands"].index
          $aInterceptMouseClick = true
        end
      end
    else
      if aMousePos[0] < 255
        iSel = -1
        if aMousePos[1] > 80
          if aMousePos[1] < 148
            iSel = 0
          elsif aMousePos[1] < 212
            iSel = 1
          elsif aMousePos[1] < 276
            iSel = 2
          elsif aMousePos[1] < 340
            iSel = 3
          end
        end
        
        if iSel >= 0
          iIndex = @sprites["commands"].top_item+iSel
          if iIndex != @sprites["commands"].index
            @sprites["commands"].index = iIndex
          end
        end
      end
    end
  end
  #####/MODDED
  
  def pbUpdate
    aMouseHover() #####MODDED
    pbUpdateSpriteHash(@sprites)
  end
end

#####################      End      ######################

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
