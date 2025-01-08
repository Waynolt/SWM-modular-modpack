# Everything that is either tagged "MODDED" or between a "MODDED" and a "/MODDED" was added or changed compared to the original codebase
# If the method definition is included between the two tags then the method was added, else it was modified
# Every time an alias is used, it's because the original method only needed to be extended - and not modified


########################################################
####################  Base edits  ######################
########################################################


#####MODDED

MOUSE_UPDATE_HOVERING = true

#####/MODDED

module Mouse
  #####MODDED
  module Sauiw
    # Stands for "Sledgehammering away until it works"
    # Yes, seriously.

    @hover_callback_method = nil
    @hover_callback_args = nil
    def self.hover_callback_clear
      Mouse::Sauiw::hover_callback_set(nil, nil)
    end
    def self.hover_callback_set(callback_method, callback_args = nil)
      @hover_callback_method = callback_method
      @hover_callback_args = callback_args
    end
    def self.hover_callback_call
      return if @hover_callback_method.nil?
      args = @hover_callback_args.nil? ? [] : @hover_callback_args
      @hover_callback_method.call(*args)
    end

    def self.handle_callbacks(button)
      # This method handles mouse clicks by setting the appropriate flag in the checking function and translating it
      # into the appropriate keypress on input checking
      if button == Input::B # Back/Menu
        return Mouse::Sauiw::return_true_or_nil(
          Mouse::Sauiw::check_and_reset_callback(:EXIT_SCREEN) \
          || Input.triggerex?(Input::RightMouseKey) # Just in case self.press? missed this
        )
      end
      if button == Input::C # Action
        if $game_player && $scene && $scene.is_a?(Scene_Map) && !pbIsFaded?
          # We're in a Scene_map
          movement = Mouse::Sauiw::handle_movement()
          return movement if !movement.nil?
          # mouse_check_ticket_scene() # Since it's done as a map event, we're going to catch it this way # TODO test and re-enable this
        end
        retval = Mouse::Sauiw::return_true_or_nil(
          Input.triggerex?(Input::LeftMouseKey)
        )
        if retval
          Mouse::Sauiw::hover_callback_call()
          Mouse::Sauiw::hover_callback_clear()
        end
        return retval
      end
      if button == Input::LEFT
        return Mouse::Sauiw::return_true_or_nil(
          Mouse::Sauiw::check_and_reset_callback(:FIELD_NOTES_CLICK_LEFT)
        )
      end
      if button == Input::RIGHT
        return Mouse::Sauiw::return_true_or_nil(
          Mouse::Sauiw::check_and_reset_callback(:FIELD_NOTES_CLICK_RIGHT)
        )
      end
      if button == Input::A # Sort bag by name
        return Mouse::Sauiw::return_true_or_nil(
          Mouse::Sauiw::check_and_reset_callback(:BAG_SORT_BY_NAME)
        )
      end
      if button == Input::Z # Sort bag by type
        return Mouse::Sauiw::return_true_or_nil(
          Mouse::Sauiw::check_and_reset_callback(:BAG_SORT_BY_TYPE)
        )
      end
      return nil
    end

    @callback_input = {}
    def self.set_callback(*callback_types)
      callback_types.each do |callback_type|
        @callback_input[callback_type] = true
      end
    end
    def self.check_and_reset_callback(*callback_types)
      retval = Mouse::Sauiw::check_callback(*callback_types)
      Mouse::Sauiw::reset_callback(*callback_types)
      return retval
    end
    def self.check_callback(*callback_types)
      callback_types.each do |callback_type|
        return true if @callback_input[callback_type]
      end
      return false
    end
    def self.reset_callback(*callback_types)
      callback_types.each do |callback_type|
        @callback_input[callback_type] = false
      end
    end
    def self.return_true_or_nil(condition)
      return true if condition
      return nil
    end

    def self.get_cursor_position_on_screen() # As pixels, relative to the top-left corner of the screen
      mouse_position = Mouse.getMousePos(false) # array, x:0 y:1
      return nil if mouse_position.nil?
      return {
        :X => mouse_position[0],
        :Y => mouse_position[1]
      }
    end
  end
  #####/MODDED
end

module Input
  if !defined?(self.mouse_old_input_press?)
    class <<self
      alias_method :mouse_old_input_press?, :press?
    end
  end
  def self.press?(button)
    #####MODDED
    # The purpose of this is to make the right mouse click behave consistently like the Cancel keypress (default ESC)
    # This method is not in the game scripts - we're replacing a method of a base Ruby module
    return true if (button == Input::B) && Input.repeatex?(Input::RightMouseKey)
    #####/MODDED
    return self.mouse_old_input_press?(button)
  end

  if !defined?(self.mouse_old_input_trigger?)
    class <<self
      alias_method :mouse_old_input_trigger?, :trigger?
    end
  end
  def self.trigger?(button)
    #####MODDED
    # The purpose of this is to intercept keypress checks and interpret it as mouse clicks when appropriate
    # This method is not in the game scripts - we're replacing a method of a base Ruby module
    mouse_result = Mouse::Sauiw::handle_callbacks(button)
    return mouse_result if !mouse_result.nil?
    #####/MODDED
    return self.mouse_old_input_trigger?(button)
  end

  if !defined?(self.mouse_old_input_update)
    class <<self
      alias_method :mouse_old_input_update, :update
    end
  end
  def self.update
    self.mouse_old_input_update()
    #####MODDED
    Mouse::Sauiw::reset_callback(:POKEDEX_SEARCH_DONE) # The pokedex search is kind of a special case
    #####/MODDED
  end
end

########################################################
####################   Movement   ######################
########################################################

module Mouse
  #####MODDED
  module Sauiw
    # !Input.repeatex?(Input::LeftMouseKey) skips a few frames, which kills the whole movement logic
    # The mess with :MOVEMENT_xxx and @movement_player_xxx is due to that alone
    # It's ugly as hell, but at least it does seem to be working...
    @movement_player_last_x = nil
    @movement_player_last_y = nil
    @movement_player_last_direction = nil
    @movement_player_step_taken_cooldown = 10
    def self.handle_movement()
      step_was_taken = $game_player.x != @movement_player_last_x || $game_player.y != @movement_player_last_y
      @movement_player_step_taken_cooldown = 0 if step_was_taken
      if step_was_taken || @movement_player_last_direction != $game_player.direction
        Mouse::Sauiw::reset_callback(
          :MOVEMENT_DOWN,
          :MOVEMENT_LEFT,
          :MOVEMENT_RIGHT,
          :MOVEMENT_UP
        )
        @movement_player_last_x = $game_player.x
        @movement_player_last_y = $game_player.y
        @movement_player_last_direction = $game_player.direction
      end
      return false if !Input.repeatex?(Input::LeftMouseKey)
      return nil if Mouse::Sauiw::player_should_not_move?
      mouse_coordinates = Mouse::Sauiw::get_cursor_coordinates_on_screen()
      return false if mouse_coordinates.nil?
      x = mouse_coordinates[:X]
      y = mouse_coordinates[:Y]
      if x.abs < 2 && y.abs < 2
        Mouse::Sauiw::rotate_player_direction(x, y)
        return true
      end
      Mouse::Sauiw::move_player(x, y)
      return false
    end

    def self.player_should_not_move?()
      return (
        $game_system.map_interpreter.running? ||
        $game_temp.player_transferring ||
        $game_player.move_route_forcing ||
        $game_temp.message_window_showing ||
        $PokemonTemp.miniupdate ||
        $game_temp.transition_processing ||
        $game_temp.menu_calling
      )
    end

    def self.get_cursor_coordinates_on_screen() # As tiles, relative to the tile the player is standing on
      return nil if $game_map.map_id != $game_player.map.map_id
      mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
      return nil if mouse_position.nil?
      return {
        :X => Mouse::Sauiw::get_cursor_coordinate_on_screen_by_axis(:X, mouse_position[:X]),
        :Y => Mouse::Sauiw::get_cursor_coordinate_on_screen_by_axis(:Y, mouse_position[:Y])
      }
    end
    def self.get_cursor_coordinate_on_screen_by_axis(axis, cursor_position_on_axis)
      if axis == :X
        screen_dimension = Graphics.width
        tile_dimension = Game_Map::TILEWIDTH
        player_position_on_axis = $game_player.real_x
        player_coordinate_on_axis = $game_player.x
        subpixel_size = Game_Map::XSUBPIXEL
      elsif axis == :Y
        screen_dimension = Graphics.height
        tile_dimension = Game_Map::TILEHEIGHT
        player_position_on_axis = $game_player.real_y
        player_coordinate_on_axis = $game_player.y
        subpixel_size = Game_Map::YSUBPIXEL
      else
        raise StandardError.new "Unknown axis: #{axis}"
      end
      # First of all, let's consider the offset for when the player is moving
      offset = (player_position_on_axis / subpixel_size) - (player_coordinate_on_axis * tile_dimension)
      if offset > 0
        correction_factor =  1
      elsif offset < 0
        correction_factor = -1
      else
        correction_factor = 0
      end
      # The parentheses are not needed - they are there just to make the code more readable
      correction_screen_center = \
          (player_position_on_axis / subpixel_size) \
        - (player_coordinate_on_axis * tile_dimension) \
        - (correction_factor * tile_dimension)
      # Get the position of the screen center
      screen_center = (screen_dimension - tile_dimension) / 2 - correction_screen_center
      # Get the coordinate of the mouse relative to $game_player.x or $game_player.y
      # Essentially, relative_coordinate = 0 if the cursor is on the player in the game map,
      #  relative_coordinate = 1 or -1 if instead it's on the tile adjacent the one occupied by the player,
      #  and so on and so forth
      # For the real coordinate on the game map, add $game_player.x or $game_player.y to the relative coordinate
      relative_coordinate = ((cursor_position_on_axis - screen_center) / tile_dimension).floor + correction_factor
      return relative_coordinate
    end
      
    def self.rotate_player_direction(x, y, handle_corners = false)
      if x == 0 || y == 0
        # dir4
        $game_player.turn_down if y > 0
        $game_player.turn_left if x < 0
        $game_player.turn_right if x > 0
        $game_player.turn_up if y < 0
        return
      end
      return if !handle_corners
      if  @movement_player_step_taken_cooldown > 0
        @movement_player_step_taken_cooldown -= 1
        return
      end
      @movement_player_step_taken_cooldown = 10
      # Corners - this will alternate between the two valid directions adjacent to the corner
      # $game_player.direction:
      # 2 => down
      # 4 => left
      # 6 => right
      # 8 => up
      return $game_player.turn_right if x > 0 && $game_player.direction != 6 # right
      return $game_player.turn_left if x < 0 && $game_player.direction != 4 # left
      if y > 0
        return $game_player.turn_down
      end
      $game_player.turn_up
    end

    def self.move_player(x, y)
      # Determine where the player should look
      x_abs = x.abs
      y_abs = y.abs
      diff = (x_abs - y_abs).abs - 1 # This is used to widen the screen slice that is accepted as "oblique"
      common = [x_abs, y_abs].min
      common -= 1 if diff < common
      trans_x = ( x_abs - common ) * (x > 0 ? 1 : -1)
      trans_y = ( y_abs - common ) * (y > 0 ? 1 : -1)
      Mouse::Sauiw::rotate_player_direction(trans_x, trans_y, true)
      # Move that way
      case $game_player.direction
        when 2 # down
          Mouse::Sauiw::set_callback(:MOVEMENT_DOWN)
        when 4 # left
          Mouse::Sauiw::set_callback(:MOVEMENT_LEFT)
        when 6 # right
          Mouse::Sauiw::set_callback(:MOVEMENT_RIGHT)
        when 8 # up
          Mouse::Sauiw::set_callback(:MOVEMENT_UP)
      end
    end
  end
  #####/MODDED
end

module Input
  if !defined?(self.mouse_old_dir4)
    class <<self
      alias_method :mouse_old_dir4, :dir4
    end
  end
  def self.dir4
    #####MODDED
    [
      {:BTN => Input::DOWN,  :DIR => :MOVEMENT_DOWN},
      {:BTN => Input::LEFT,  :DIR => :MOVEMENT_LEFT},
      {:BTN => Input::RIGHT, :DIR => :MOVEMENT_RIGHT},
      {:BTN => Input::UP,    :DIR => :MOVEMENT_UP}
    ].each do |itm|
      return itm[:BTN] if Mouse::Sauiw::check_callback(itm[:DIR])
    end
    #####/MODDED
    return self.mouse_old_dir4()
  end
end


########################################################
###############   Messages/pause menu   ################
########################################################


class Window_DrawableCommand < SpriteWindow_Selectable
  if !defined?(mouse_old_update)
    alias :mouse_old_update :update
  end
  def update(*args, **kwargs)
    #####MODDED
    Mouse::Sauiw::hover_callback_set(method(:mouse_update_hover))
    mouse_update_hover() if MOUSE_UPDATE_HOVERING
    #####/MODDED
    return mouse_old_update(*args, **kwargs)
  end

  #####MODDED
  def mouse_update_hover
    pokedex_search_index = 0 # The pokedex search is kind of a special case
    return pokedex_search_index if Mouse::Sauiw::check_callback(:POKEDEX_SEARCH_DONE)
    return pokedex_search_index if !defined?(@commands)
    return pokedex_search_index if @commands.length <= 0
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return pokedex_search_index if mouse_position.nil?
    borderX_halved = borderX / 2
    return pokedex_search_index if mouse_position[:X] <= (@x + borderX_halved)
    return pokedex_search_index if mouse_position[:X] >= (@x + @width - borderX_halved)
    line_first = top_row - 1
    line_last = line_first + page_row_max + 3
    index_new = line_first + ((mouse_position[:Y] - @y + (borderY / 2)) / rowHeight).floor
    pokedex_search_index = index_new
    line_first = 0 if line_first < 0
    line_last = @commands.length-1 if line_last >= @commands.length
    if @index != index_new && !((index_new < line_first) || (index_new > line_last))
      @index = index_new
      update_cursor_rect
    end
    return pokedex_search_index
  end
  #####/MODDED
end


if false # TODO UPDATED UNTIL HERE

########################################################
####################   Hovering   ######################
########################################################

#####################      2      ######################
#Pokegear

class Scene_Pokegear
  #####MODDED
  def aMouseHover(aObjects)
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    iX0 = @sprites["button#{0}"].x
    iX1 = iX0+@sprites["button#{0}"].bitmap.rect.width
    
    if (mouse_position[:X] > iX0) && (mouse_position[:X] < iX1)
      iL = aObjects.commands.length-1
      for i in 0..iL
        if @sprites["button#{iL-i}"].y < mouse_position[:Y]
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    iX0 = @sprites["panel#{0}"].x
    iX1 = iX0+@sprites["panel#{0}"].bitmap.rect.width
    
    if (mouse_position[:X] > iX0) && (mouse_position[:X] < iX1)
      iL = aObjects.commands.length-1
      for i in 0..iL
        if @sprites["panel#{iL-i}"].y < mouse_position[:Y]
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

def mouse_check_ticket_scene()
  return if !Reborn
  return if $game_map.map_id != 51 # Ticket scene
  aPos = Mouse::Sauiw::get_cursor_position_on_screen()
  return if aPos.nil?
  idY = ((aPos[1]-((Graphics.height-Game_Map::TILEHEIGHT)/2))/Game_Map::TILEHEIGHT).to_i
  iY = $game_player.y+idY
  return if iY != 14
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
      return
  end
  if $game_variables[358] != iLook
    $game_variables[358] = iLook
    $game_screen.pictures[3].show(sTxt, 0, 0, 0, 100, 100, 255, 0)
  end
end

#####################      5      ######################
#Battle actions and moves

class PokeBattle_Scene
  #####MODDED
  def aMouseHover(aObjects)
    $aTargetCell[2] = 0 if defined?($aTargetCell) #Let battles cancel the mouse movement
    
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
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
    
    if (mouse_position[:X] > iX0) && (mouse_position[:X] < iX1) && (mouse_position[:Y] > iY0) && (mouse_position[:Y] < iY1)
      if mouse_position[:X] < iXh
        iIndex = 0
      else
        iIndex = 1
      end
      if mouse_position[:Y] > iYh
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
          if (mouse_position[:X] > 148) && (mouse_position[:X] < 242) && (mouse_position[:Y] > 251) && (mouse_position[:Y] < 288)
            bPlaySound = false
            iPlayerIndex = 0
            
            if aObjects.megaButton == 1
              @battle.pbRegisterMegaEvolution(iPlayerIndex)
              aObjects.megaButton = 2
              Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
              bPlaySound = true
            elsif aObjects.megaButton == 2
              aObjects.megaButton = 1
              Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
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
              Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
              bPlaySound = true
            elsif aObjects.ultraButton == 2
              aObjects.ultraButton = 1
              Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
              bPlaySound = true
              
              #Unregister ultra burst
              side=(@battle.pbIsOpposing?(iPlayerIndex)) ? 1 : 0
              owner=@battle.pbGetOwnerIndex(iPlayerIndex)
              @battle.ultraBurst[side][owner] = -1
            end
            if aObjects.zButton == 1
              @battle.pbRegisterZMove(iPlayerIndex)
              aObjects.zButton = 2
              Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
              bPlaySound = true
            elsif aObjects.zButton == 2
              aObjects.zButton = 1
              Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return index if mouse_position.nil?
    
    iRetVal = index
    
    iPart = Graphics.width/4
    
    if mouse_position[:X] > 0
      iX = 0
      for i in 0...4
        if mouse_position[:X] > iX
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
  def aMouseOverItemList(mouse_position, aIW)
    iBorder = aIW.borderX/2
    iX0 = aIW.x+iBorder
    iX1 = aIW.x+aIW.width-iBorder
    if (mouse_position[:X] > iX0) && (mouse_position[:X] < iX1)
      iLimit = aIW.y+aIW.borderY
      iScroll = 0
      if mouse_position[:Y] < iLimit
        iScroll = -1
      else
        iL = aIW.page_item_max
        iH = (aIW.height-aIW.borderY)/(iL+1)
        
        iIndex = aIW.top_item-1
        bFound = false
        for i in 0...iL
          iIndex = iIndex+1
          iLimit = iLimit+iH
          if mouse_position[:Y] < iLimit
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
          if mouse_position[:Y] < (iLimit+iH)
            iIndex = iIndex+1
            iIndex = @bag.pockets[aIW.pocket].length if iIndex > @bag.pockets[aIW.pocket].length
            aIW.index = iIndex
          end
        end
      end
    end
  end
  
  def aMouseOverPocket(mouse_position, aIW)
    Mouse::Sauiw::reset_callback(
      :BAG_SORT_BY_NAME,
      :BAG_SORT_BY_TYPE
    )
    
    if Input.triggerex?(Input::LeftMouseKey)
      #Got the coordinates directly from the background image
      if (mouse_position[:Y] > 145) && (mouse_position[:Y] < 180)
        if (mouse_position[:X] > 25) && (mouse_position[:X] < 150)
          #Sort
          Mouse::Sauiw::set_callback(
            :BAG_SORT_BY_NAME,
            # :BAG_SORT_BY_TYPE, # TODO check the coordinates and set the correct click event
            :INTERCEPT_CLICK
          )
        end
      elsif (mouse_position[:Y] > 230) && (mouse_position[:Y] < 250)
        iX0 = 5
        iX1 = 180
        if (mouse_position[:X] > iX0) && (mouse_position[:X] < iX1)
          #Pocket
          iL = PokemonBag.numPockets
          iW = (iX1-iX0)/iL
          iP = iL-((iX1-mouse_position[:X])/iW).floor
          
          #Check; shouldn't actually be needed, but better safe than sorry
          iP = 1 if iP < 1
          iP = iL if iP > iL
          
          #Finish
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          if iP != aIW.pocket
            aIW.pocket = iP
            @bag.lastpocket = aIW.pocket
            pbRefresh
          end
        end
      end
    end
  end
  
  def aMouseOverSlider(mouse_position, aIW)
    if Input.repeatex?(Input::LeftMouseKey)
      if (mouse_position[:X] > 470) && (mouse_position[:X] < 505)
        if (mouse_position[:Y] > 55) && (mouse_position[:Y] < 220)
          iMax = aIW.itemCount-1
          iY = mouse_position[:Y]-@sprites["slider"].bitmap.height/2
          iIndex = (iY-60)*iMax/116
          iIndex = 0 if iIndex < 0
          iIndex = iMax if iIndex > iMax
          
          if iIndex != aIW.index
            aIW.index = iIndex
            @sprites["slider"].y = iY
          end
          
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
        elsif (mouse_position[:Y] > 20) && (mouse_position[:Y] <= 55)
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
            
            Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          end
        elsif (mouse_position[:Y] >= 220) && (mouse_position[:Y] < 260)
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
            
            Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          end
        end
      end
    end
  end
  
  def aMouseHover()
    return if (@sprites["helpwindow"].visible) || (@sprites["msgwindow"].visible) #An item is selected
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    aIW = @sprites["itemwindow"]
    aMouseOverItemList(mouse_position, aIW)
    aMouseOverPocket(mouse_position, aIW)
    aMouseOverSlider(mouse_position, aIW)
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
  def aMouseSelMon(mouse_position)
    if Input.triggerex?(Input::LeftMouseKey)
      if mouse_position[:X] > 400
        if (mouse_position[:Y] > 330) && (mouse_position[:Y] < 375)
          Mouse::Sauiw::set_callback(
            :EXIT_SCREEN,
            :INTERCEPT_CLICK
          )
        end
      end
    else
      bFound = false
      for i in 0...@party.length
        aSprite = @sprites["pokemon#{i}"]
        if (mouse_position[:X] > aSprite.x) && (mouse_position[:X] < (aSprite.x+aSprite.bitmap.width))
          if (mouse_position[:Y] > aSprite.y) && (mouse_position[:Y] < (aSprite.y+aSprite.bitmap.height))
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    sTxt = @sprites["helpwindow"].text
    sTxt = sTxt[0..3]
    
    aMouseSelMon(mouse_position) if (sTxt == "Choo") || (sTxt == "Move") || (sTxt == "Give") || (sTxt == "Use ") || (sTxt == "Teac") || (sTxt == "Fuse") #"Choose a pokemon" or "Move to where?" etc
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    aMap = @sprites["map"]
    if (mouse_position[:X] > aMap.x) && (mouse_position[:X] < (aMap.x+aMap.bitmap.width))
      if (mouse_position[:Y] > aMap.y) && (mouse_position[:Y] < (aMap.y+aMap.bitmap.height))
        xOffset = mouse_position[:X]-aMap.x
        yOffset = mouse_position[:Y]-aMap.y
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return rSel if mouse_position.nil?
    
    iSel = rSel
    
    aTab = @sprites["boxparty"]
    iMX = mouse_position[:X]-aTab.x
    if (iMX > 16) && (iMX < aTab.bitmap.width)
      iMY = mouse_position[:Y]-aTab.y
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return rSel if mouse_position.nil?
    iSel = rSel
    
    #Coordinates taken directly from the bitmap
    if (mouse_position[:Y] > 20) && (mouse_position[:Y] < 60)
      #Upper bar
      if (mouse_position[:X] > 185) && (mouse_position[:X] < 220)
        if Input.triggerex?(Input::LeftMouseKey)
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          iSel = -4 # Move to previous box
        end
      elsif (mouse_position[:X] > 230) && (mouse_position[:X] < 460)
        iSel = -1 # Box name
      elsif (mouse_position[:X] > 470) && (mouse_position[:X] < 505)
        if Input.triggerex?(Input::LeftMouseKey)
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          iSel = -5 # Move to next box
        end
      end
    elsif (mouse_position[:Y] > 64) && (mouse_position[:Y] < 304)
      if mouse_position[:X] > 202
        if mouse_position[:X] < 490
          #Box
          #Squares' edges: 48
          
          iX = ((mouse_position[:X]-202)/48).floor
          iY = ((mouse_position[:Y]-64)/48).floor
          
          iSel = iX+iY*6
        end
      end
    elsif (mouse_position[:Y] > 325) && (mouse_position[:Y] < 365)
      #Lower bar
      if (mouse_position[:X] > 185) && (mouse_position[:X] < 355)
        iSel = -2 # Party
      elsif (mouse_position[:X] > 385) && (mouse_position[:X] < 505)
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
  def aMouseOverItemList(mouse_position, aIW)
    iBorder = aIW.borderX/2
    iX0 = aIW.x+iBorder
    iX1 = aIW.x+aIW.width-iBorder
    if (mouse_position[:X] > iX0) && (mouse_position[:X] < iX1)
      iLimit = aIW.y+aIW.borderY
      iScroll = 0
      if mouse_position[:Y] < iLimit
        iScroll = -1
      else
        iL = aIW.page_item_max
        iH = (aIW.height-aIW.borderY)/(iL+1)
        
        iIndex = aIW.top_item-1
        bFound = false
        for i in 0...iL
          iIndex = iIndex+1
          iLimit = iLimit+iH
          if mouse_position[:Y] < iLimit
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
          if mouse_position[:Y] < (iLimit+iH)
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    aIW = @sprites["itemwindow"]
    aMouseOverItemList(mouse_position, aIW)
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
  def aMouseOverItemList(mouse_position, aIW)
    iBorder = aIW.borderX/2
    iX0 = aIW.x+iBorder
    iX1 = aIW.x+aIW.width-iBorder
    if (mouse_position[:X] > iX0) && (mouse_position[:X] < iX1)
      iMax = aIW.itemCount-1
      
      iLimit = aIW.y+aIW.borderY
      iScroll = 0
      if mouse_position[:Y] < iLimit
        iScroll = -1
      else
        iL = aIW.page_item_max
        iH = (aIW.height-aIW.borderY)/(iL+1)
        
        iIndex = aIW.top_item-1
        bFound = false
        for i in 0...iL
          iIndex = iIndex+1
          iLimit = iLimit+iH
          if mouse_position[:Y] < iLimit
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
          if mouse_position[:Y] < (iLimit+iH)
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    aIW = @sprites["itemwindow"]
    aMouseOverItemList(mouse_position, aIW)
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return false if mouse_position.nil?
    
    bRetVal = false
    
    #Got the coordinates directly from the bitmap
    if Input.triggerex?(Input::LeftMouseKey) && !@sprites["movesel"].visible
      if (mouse_position[:Y] > 20) && (mouse_position[:Y] < 42)
        if (mouse_position[:X] > 285) && (mouse_position[:X] < 320)
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          if @page != 0
            @page = 0
            drawPageOne(@pokemon)
          end
        elsif (mouse_position[:X] > 330) && (mouse_position[:X] < 366)
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          if @page != 1
            @page = 1
            drawPageTwo(@pokemon)
          end
        elsif (mouse_position[:X] > 376) && (mouse_position[:X] < 412)
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          if @page != 2
            @page = 2
            drawPageThree(@pokemon)
          end
        elsif (mouse_position[:X] > 422) && (mouse_position[:X] < 458)
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          if @page != 3
            @page = 3
            drawPageFour(@pokemon)
          end
        elsif (mouse_position[:X] > 468) && (mouse_position[:X] < 502)
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          if @page != 4
            @page = 4
            drawPageFive(@pokemon)
          end
        end
      end
    elsif selmove > -2
      if (mouse_position[:X] > 240) && (mouse_position[:X] < 490)
        iSel = -1
        if mouse_position[:Y] < 280
          if mouse_position[:Y] > 20
            iSel = 0
          end
          if mouse_position[:Y] > 85
            iSel = 1
          end
          if mouse_position[:Y] > 149
            iSel = 2
          end
          if mouse_position[:Y] > 213
            iSel = 3
          end
        elsif mouse_position[:Y] > 290
          if mouse_position[:Y] < 365
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return rSel if mouse_position.nil?
    
    iSel = rSel
    
    if (mouse_position[:X] > 245) && (mouse_position[:X] < 486)
      if (mouse_position[:Y] > 96) && (mouse_position[:Y] < 352)
        iTSel = 0
        if mouse_position[:Y] > 160
          iTSel = 1
        end
        if mouse_position[:Y] > 224
          iTSel = 2
        end
        if mouse_position[:Y] > 288
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    aCursor = @sprites["cursor"]
    
    iY0 = ((Graphics.height-(@tileheight*@boardheight))/2)-32
    iY1 = iY0+@tileheight*@boardheight
    if (mouse_position[:Y] > iY0) && (mouse_position[:Y] < iY1)
      iX0 = (Graphics.width-(@tilewidth*@boardwidth))/2
      iX1 = iX0+@tilewidth*@boardwidth
      if (mouse_position[:X] > iX0) && (mouse_position[:X] < iX1)
        bNearOnly = ((@game > 3) && (@game <= 6))
        
        iPosX = mouse_position[:X]-iX0
        iPosY = mouse_position[:Y]-iY0
        
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
        if (mouse_position[:X] > iXE0) && (mouse_position[:X] < iXE1)
          iPosY = mouse_position[:Y]-iY0
          iY = (iPosY/@tileheight).floor
          
          iPosX = mouse_position[:X]-iXE0
          iX = (iPosX/@tilewidth).floor
          
          iX = 0 if iX <0
          iX = @boardwidth-1 if iX >= @boardwidth
          iY = 0 if iY <0
          iY = @boardheight-1 if iY >= @boardheight
          
          bContinue = true
        else
          iXE2 = Graphics.width-iXE0-@tilewidth*(@boardwidth-2)
          iXE3 = iXE2+(@tilewidth*2)
          if (mouse_position[:X] > iXE2) && (mouse_position[:X] < iXE3)
            iPosY = mouse_position[:Y]-iY0
            iY = (iPosY/@tileheight).floor
            
            iPosX = iXE3-mouse_position[:X]
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return false if mouse_position.nil?
    
    bRetVal = false
    
    #Got coordinates from the unmodded script and directly from the bitmap
    if Input.triggerex?(Input::LeftMouseKey)
      if (mouse_position[:X] > 430)
        if (mouse_position[:X] < 505)
          aCursor = @sprites["cursor"]
          aTool = @sprites["tool"]
          
          newmode=2
          if (mouse_position[:Y] > 105) && (mouse_position[:Y] < 215)
            newmode=1
          elsif (mouse_position[:Y] > 250) && (mouse_position[:Y] < 355)
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    #Got coordinates from the unmodded script and directly from the bitmap
    if (mouse_position[:X] < 430)
      aCursor = @sprites["cursor"]
      iTileL = 32
      
      iX0 = 0
      iY0 = 64
      iX = ((mouse_position[:X]-iX0)/iTileL).floor
      iY = ((mouse_position[:Y]-iY0)/iTileL).floor
      
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
      
      Mouse::Sauiw::set_callback(:POKEDEX_SEARCH_DONE)
    else
      #We're in the pokedex
      if Input.repeatex?(Input::LeftMouseKey)
        mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
        return if mouse_position.nil?
        
        if (mouse_position[:X] > 465) && (mouse_position[:X] < 505)
          if (mouse_position[:Y] > 65) && (mouse_position[:Y] < 300)
            iMax = @sprites["pokedex"].itemCount-1
            iY = mouse_position[:Y]-@sprites["slider"].bitmap.height/2
            iIndex = (iY-62)*iMax/188
            iIndex = 0 if iIndex < 0
            iIndex = iMax if iIndex > iMax
            
            if iIndex != @sprites["pokedex"].index
              @sprites["pokedex"].index = iIndex
              @sprites["slider"].y = iY
            end
            
            Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
          elsif (mouse_position[:Y] > 40) && (mouse_position[:Y] <= 65)
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
              
              Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
            end
          elsif (mouse_position[:Y] >= 300) && (mouse_position[:Y] < 325)
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
              
              Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
            end
          end
        end
      end
    end
  end
  
  def aMouseTabSelectDex(iPage)
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return iPage if mouse_position.nil?
    
    iNewPage = iPage
    if Input.triggerex?(Input::LeftMouseKey)
      #Got coordinates directly from the bitmap
      if mouse_position[:Y] < 25
        if mouse_position[:X] < 150
          if mouse_position[:X] > 35
            iNewPage = 1
          end
          if mouse_position[:X] > 70
            iNewPage = 2
          end
          if mouse_position[:X] > 110
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return -1 if mouse_position.nil?
    
    iNewPage = -1
    if Input.triggerex?(Input::LeftMouseKey)
      #Got coordinates directly from the bitmap
      if mouse_position[:Y] < 25
        if mouse_position[:X] < 150
          if mouse_position[:X] > 35
            iNewPage = 1
          end
          if mouse_position[:X] > 70
            iNewPage = 2
          end
          if mouse_position[:X] > 110
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return -1 if mouse_position.nil?
    
    iNewPage = -1
    if Input.triggerex?(Input::LeftMouseKey)
      #Got coordinates directly from the bitmap
      if mouse_position[:Y] < 25
        if mouse_position[:X] < 150
          if mouse_position[:X] > 35
            iNewPage = 1
          end
          if mouse_position[:X] > 70
            iNewPage = 2
          end
          if mouse_position[:X] > 110
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    #Values copied from the unmodded script
    iSquareL = 64
    
    if mouse_position[:X] < (@squares[0][0]-iSquareL/4)
      #Click Memo
      if Input.triggerex?(Input::LeftMouseKey)
        if (mouse_position[:Y] > @squares[15][1]) && (mouse_position[:Y] < (@squares[15][1]+(2*iSquareL)))
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
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
      
      iX = ((mouse_position[:X]-@squares[0][0])/iSquareL).floor
      iY = ((mouse_position[:Y]-@squares[0][1])/iSquareL).floor
      
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?

    Mouse::Sauiw::reset_callback(
      :FIELD_NOTES_CLICK_LEFT,
      :FIELD_NOTES_CLICK_RIGHT
    )
    
    if Input.triggerex?(Input::LeftMouseKey)
      if mouse_position[:Y] < 30
        if mouse_position[:X] < 150
           Mouse::Sauiw::set_callback(
            :FIELD_NOTES_CLICK_LEFT,
            :INTERCEPT_CLICK
          )
        elsif mouse_position[:X] > 425
           Mouse::Sauiw::set_callback(
            :FIELD_NOTES_CLICK_RIGHT,
            :INTERCEPT_CLICK
          )
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
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    
    if Input.triggerex?(Input::LeftMouseKey)
      if (mouse_position[:Y] > 350) && (mouse_position[:Y] < 380)
        if (mouse_position[:X] > 48) && (mouse_position[:X] < 124)
          iSel = @sprites["commands"].index+VISIBLEMOVES
          iSel = @moves.length-1 if iSel >= @moves.length
          @sprites["commands"].index = iSel if iSel != @sprites["commands"].index
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
        elsif (mouse_position[:X] > 133) && (mouse_position[:X] < 209)
          iSel = @sprites["commands"].index-VISIBLEMOVES
          iSel = 0 if iSel < 0
          @sprites["commands"].index = iSel if iSel != @sprites["commands"].index
          Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
        end
      end
    else
      if mouse_position[:X] < 255
        iSel = -1
        if mouse_position[:Y] > 80
          if mouse_position[:Y] < 148
            iSel = 0
          elsif mouse_position[:Y] < 212
            iSel = 1
          elsif mouse_position[:Y] < 276
            iSel = 2
          elsif mouse_position[:Y] < 340
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

end
