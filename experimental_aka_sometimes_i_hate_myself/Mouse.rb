# Everything that is either tagged "MODDED" or between a "MODDED" and a "/MODDED" was added or changed compared to the original codebase
# If the method definition is included between the two tags then the method was added, else it was modified
# Every time an alias is used, it's because the original method only needed to be extended - and not modified
# When instead the tag MODDED_OBLIGATORY is used, it means that I was unable to find a way to implement mouse tracking without editing the original method


########################################################
####################  Base edits  ######################
########################################################
# These are the edits and changes that are common to all of the game's systems
# Specific changes to each system will be handled in the code after this section


#####MODDED
require 'set'

MOUSE_UPDATE_HOVERING = true
MOUSE_IGNORE_HOVER_ERRORS = false

#####/MODDED

if !defined?(Mouse::Sauiw::hover_callback_clear)
module Mouse
  #####MODDED
  module Sauiw
    # Stands for "Sledgehammering away until it works"
    # Yes, seriously.

    # Left clicking will call the "Action" keypress, which is appropriate only as long as the hovered option is correctly selected
    # This system ensures that the hovering detection is being run at least once just before the "Action" keypress
    # It exists to ensure compatibility with Joiplay, that does not have any real hovering prior to the click
    @hover_callback_method = nil
    @hover_callback_args = nil
    @hover_callback_call_only_on_click = true
    def self.hover_callback_clear
      Mouse::Sauiw::hover_callback_set(nil, nil, true)
    end
    def self.hover_callback_set(callback_method, callback_args = nil, call_only_on_click = true)
      @hover_callback_method = callback_method
      @hover_callback_args = callback_args
      @hover_callback_call_only_on_click = call_only_on_click
    end
    def self.hover_callback_call(click_action)
      return if @hover_callback_call_only_on_click && !click_action
      return if @hover_callback_method.nil?
      args = @hover_callback_args.nil? ? [] : @hover_callback_args
      if MOUSE_IGNORE_HOVER_ERRORS
        begin
          @hover_callback_method.call(*args)
        rescue
          # Catch instances where the player used the keyboard to press "Action" instead of clicking
          # This will hide genuine errors as a side effect!
        end
      else
        @hover_callback_method.call(*args)
      end
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
          return movement || Input.mouse_old_input_trigger?(Input::C) if !movement.nil?
          Mouse::Sauiw::ticket_scene_handle_hover() # Since it's done as a map event, we're going to catch it this way
        end
        retval = Mouse::Sauiw::return_true_or_nil(
          Input.triggerex?(Input::LeftMouseKey)
        )
        if retval
          Mouse::Sauiw::hover_callback_call(true)
          Mouse::Sauiw::hover_callback_clear()
          return nil if Mouse::Sauiw::check_and_reset_callback(:INTERCEPT_CLICK) # :INTERCEPT_CLICK prevents the click from being interpreted as an activation
        else
          Mouse::Sauiw::hover_callback_call(false)
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
      return nil
    end

    @callback_input = {}
    def self.set_callback(*callback_types)
      callback_types.each do |itm|
        @callback_input[itm] = true
      end
    end
    def self.check_and_reset_callback(*callback_types)
      retval = Mouse::Sauiw::check_callback(*callback_types)
      Mouse::Sauiw::reset_callback(*callback_types)
      return retval
    end
    def self.check_callback(*callback_types)
      callback_types.each do |itm|
        return true if @callback_input[itm]
      end
      return false
    end
    def self.reset_callback(*callback_types)
      callback_types.each do |itm|
        @callback_input[itm] = false
      end
    end
    def self.return_true_or_nil(condition)
      return true if condition
      return nil
    end

    def self.clear_all_callbacks()
      @callback_input = {}
      @hover_callback_method = nil
      @hover_callback_args = nil
      @hover_callback_call_only_on_click = true
    end

    @mouse_offset_x = $joiplay ? -7 : 0 # On joyplay, there's an X offset of +7
    def self.get_cursor_position_on_screen() # As pixels, relative to the top-left corner of the screen
      mouse_position = Mouse.getMousePos(false) # array, x:0 y:1
      return nil if mouse_position.nil?
      # On desktop, Graphics.width = 512 and Graphics.height = 384
      return {
        :X => mouse_position[0] + @mouse_offset_x,
        :Y => mouse_position[1]
      }
    end
  end
  #####/MODDED
end
end

module Input
  if !defined?(self.mouse_old_input_update)
    class <<self
      alias_method :mouse_old_input_update, :update
    end
  end
  def self.update(*args, **kwargs)
    #####MODDED
    Mouse::Sauiw::reset_callback(:POKEDEX_SEARCH_DONE) # The pokedex search is kind of a special case
    #####/MODDED
    return self.mouse_old_input_update(*args, **kwargs)
  end

  if !defined?(self.mouse_old_input_press?)
    class <<self
      alias_method :mouse_old_input_press?, :press?
    end
  end
  def self.press?(button)
    #####MODDED
    # The purpose of this is to make the right mouse click behave consistently like the Cancel keypress (default ESC)
    # This method is not in the game scripts - we're replacing a method of a base Ruby module
    return true if (button == Input::B) && Input.pressex?(Input::RightMouseKey)
    #####/MODDED
    return self.mouse_old_input_press?(button)
  end

  if !defined?(self.mouse_old_input_repeat?)
    class <<self
      alias_method :mouse_old_input_repeat?, :repeat?
    end
  end
  def self.repeat?(button)
    retval = self.mouse_old_input_repeat?(button)
    #####MODDED
    # This method is not in the game scripts - we're replacing a method of a base Ruby module
    if !retval
      return true if (button == Input::UP) && Mouse::Sauiw::check_callback(:PC_SELECT_PARTY_INTERNAL, :PC_SELECT_BOX_INTERNAL)
    end
    #####/MODDED
    return retval
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
end

class PokemonLoad
  if !defined?(mouse_old_pbStartLoadScreen)
  alias :mouse_old_pbStartLoadScreen :pbStartLoadScreen
end
def pbStartLoadScreen(*args, **kwargs)
  #####MODDED
  Mouse::Sauiw::clear_all_callbacks()
  #####/MODDED
  return mouse_old_pbStartLoadScreen(*args, **kwargs)
end
end

########################################################
####################   Movement   ######################
########################################################

if !defined?(Mouse::Sauiw::handle_movement)
module Mouse
  #####MODDED
  module Sauiw
    @movement_player_last_x = nil
    @movement_player_last_y = nil
    @movement_player_step_taken_cooldown = 10
    def self.handle_movement()
      Mouse::Sauiw::reset_callback(
        :MOVEMENT_DOWN,
        :MOVEMENT_LEFT,
        :MOVEMENT_RIGHT,
        :MOVEMENT_UP
      )
      return false if !Input.pressex?(Input::LeftMouseKey)
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
      if $game_player.x != @movement_player_last_x || $game_player.y != @movement_player_last_y
        @movement_player_last_x = $game_player.x
        @movement_player_last_y = $game_player.y
        @movement_player_step_taken_cooldown = 0
      end
      if  @movement_player_step_taken_cooldown > 0
        @movement_player_step_taken_cooldown -= 1
        return
      end
      @movement_player_step_taken_cooldown = 21
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
end

module Input
  if !defined?(self.mouse_old_dir4)
    class <<self
      alias_method :mouse_old_dir4, :dir4
    end
  end
  def self.dir4
    #####MODDED
    Mouse::Sauiw::ticket_scene_update_hover() if MOUSE_UPDATE_HOVERING
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


# class Window_DrawableCommand < SpriteWindow_Selectable
#   #####MODDED
#   def mouse_update_hover
#     pokedex_search_index = 0 # The pokedex search is kind of a special case
#     return pokedex_search_index if Mouse::Sauiw::check_callback(:POKEDEX_SEARCH_DONE)
#     return pokedex_search_index if !defined?(@commands)
#     return pokedex_search_index if @commands.length <= 0
#     mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
#     return pokedex_search_index if mouse_position.nil?
#     borderX_halved = borderX / 2
#     return pokedex_search_index if mouse_position[:X] <= (@x + borderX_halved)
#     return pokedex_search_index if mouse_position[:X] >= (@x + @width - borderX_halved)
#     line_first = top_row - 1
#     line_last = line_first + page_row_max + 3
#     index_new = line_first + ((mouse_position[:Y] - @y + (borderY / 2)) / rowHeight).floor
#     pokedex_search_index = index_new
#     line_first = 0 if line_first < 0
#     line_last = @commands.length-1 if line_last >= @commands.length
#     if @index != index_new && !((index_new < line_first) || (index_new > line_last))
#       @index = index_new
#       update_cursor_rect
#     end
#     return pokedex_search_index
#   end
#   #####/MODDED
# end

# class PokemonMenu_Scene
#   #####MODDED
#   def mouse_update_hover
#     @sprites["cmdwindow"].mouse_update_hover() if !@sprites["cmdwindow"].nil?
#   end
#   #####/MODDED

#   def pbShowCommands(commands)
#     ret = -1
#     cmdwindow = @sprites["cmdwindow"]
#     cmdwindow.viewport = @viewport
#     cmdwindow.index = $PokemonTemp.menuLastChoice
#     cmdwindow.resizeToFit(commands)
#     cmdwindow.commands = commands
#     cmdwindow.x = Graphics.width - cmdwindow.width
#     cmdwindow.y = 0
#     cmdwindow.visible = true
#     lastread = nil
#     loop do
#       Mouse::Sauiw::hover_callback_set(method(:mouse_update_hover)) #####MODDED_OBLIGATORY
#       mouse_update_hover() if MOUSE_UPDATE_HOVERING #####MODDED_OBLIGATORY
#       cmdwindow.update
#       if commands[cmdwindow.index] != lastread
#         tts(commands[cmdwindow.index])
#         lastread = commands[cmdwindow.index]
#       end
#       Graphics.update
#       Input.update
#       pbUpdateSceneMap
#       if Input.trigger?(Input::B)
#         ret = -1
#         break
#       end
#       if Input.trigger?(Input::C)
#         ret = cmdwindow.index
#         $PokemonTemp.menuLastChoice = ret
#         break
#       end
#     end
#     return ret
#   end
# end

# class PokeBattle_Scene
#   #####MODDED
#   def mouse_update_hover_msg(cw)
#     cw.mouse_update_hover() if !cw.nil?
#   end
#   #####/MODDED

#   def pbShowCommands(msg, commands, defaultValue)
#     pbWaitMessage
#     pbRefresh
#     tts(msg)
#     pbShowWindow(MESSAGEBOX)
#     dw = @sprites["messagewindow"]
#     dw.text = msg
#     cw = Window_CommandPokemon.new(commands, tts: false)
#     cw.x = Graphics.width - cw.width
#     cw.y = Graphics.height - cw.height - dw.height
#     cw.index = 0
#     cw.viewport = @viewport
#     pbRefresh
#     update_menu = true
#     lastread = nil
#     loop do
#       cw.visible = !dw.busy?
#       pbGraphicsUpdate
#       Input.update
#       Mouse::Sauiw::hover_callback_set(method(:mouse_update_hover_msg), [cw]) #####MODDED_OBLIGATORY
#       mouse_update_hover_msg(cw) if MOUSE_UPDATE_HOVERING #####MODDED_OBLIGATORY
#       pbFrameUpdate(cw, update_menu, true) #####MODDED_OBLIGATORY, was pbFrameUpdate(cw, update_menu)
#       update_menu = false
#       dw.update
#       tts(commands[cw.index]) if commands[cw.index] != lastread
#       lastread = commands[cw.index]
#       if Input.trigger?(Input::B) && defaultValue >= 0
#         update_menu = true
#         if dw.busy?
#           pbPlayDecisionSE() if dw.pausing?
#           dw.resume
#         else
#           cw.dispose
#           dw.text = ""
#           return defaultValue
#         end
#       end
#       if Input.trigger?(Input::C)
#         update_menu = true
#         if dw.busy?
#           pbPlayDecisionSE() if dw.pausing?
#           dw.resume
#         else
#           cw.dispose
#           dw.text = ""
#           return cw.index
#         end
#       end
#       if Input.trigger?(Input::DOWN)
#         update_menu = true
#         cw.index = (cw.index + 1) % commands.length
#       end
#       if Input.trigger?(Input::UP)
#         update_menu = true
#         cw.index = (cw.index - 1) % commands.length
#       end
#     end
#   end
# end

class Window_CommandPokemon < Window_DrawableCommand
  # TODO with this implementation, the messages with options on the left (like the one for using registered items) ignores mouse clicks (but not the hovering)
  if !defined?(mouse_old_update_parent)
    alias :mouse_old_update_parent :update
  end
  def update(*args, **kwargs)
    #####MODDED
    begin
      mouse_update_hover_parent() if MOUSE_UPDATE_HOVERING || Input.pressex?(Input::LeftMouseKey)
    rescue
    end
    #####/MODDED
    return mouse_old_update_parent(*args, **kwargs)
  end

  #####MODDED
  def mouse_update_hover_parent
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


# TODO this interferes with EVERYTHING! With almost every single other hover_callback_set!
#    Also, Messages like "Pokemon wants to learn MOVE" ignore the mouse in battle because of a similar conflict...
#    The code before this attempts to avoid the issue
# class Window_DrawableCommand < SpriteWindow_Selectable # TODO this is the parent class, but even using Window_CommandPokemon instead conflicts just as well...
# class Window_CommandPokemon < Window_DrawableCommand
#   if !defined?(mouse_old_update)
#     alias :mouse_old_update :update
#   end
#   def update(*args, **kwargs)
#     #####MODDED
#     Mouse::Sauiw::hover_callback_set(method(:mouse_update_hover))
#     mouse_update_hover() if MOUSE_UPDATE_HOVERING
#     #####/MODDED
#     return mouse_old_update(*args, **kwargs)
#   end

#   #####MODDED
#   def mouse_update_hover
#     return if @commands.length <= 0
#     mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
#     return if mouse_position.nil?
#     borderX_halved = borderX / 2
#     return if mouse_position[:X] <= (@x + borderX_halved)
#     return if mouse_position[:X] >= (@x + @width - borderX_halved)
#     line_first = top_row - 1
#     line_last = line_first + page_row_max + 3
#     index_new = line_first + ((mouse_position[:Y] - @y + (borderY / 2)) / rowHeight).floor
#     line_first = 0 if line_first < 0
#     line_last = @commands.length-1 if line_last >= @commands.length
#     if @index != index_new && !((index_new < line_first) || (index_new > line_last))
#       @index = index_new
#       update_cursor_rect
#     end
#   end

#   # TODO remove this after updating the pokedex (class Window_Pokedex < Window_DrawableCommand ?)
#   # def mouse_update_hover
#   #   pokedex_search_index = 0 # The pokedex search is kind of a special case
#   #   return pokedex_search_index if Mouse::Sauiw::check_callback(:POKEDEX_SEARCH_DONE)
#   #   return pokedex_search_index if !defined?(@commands)
#   #   return pokedex_search_index if @commands.length <= 0
#   #   mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
#   #   return pokedex_search_index if mouse_position.nil?
#   #   borderX_halved = borderX / 2
#   #   return pokedex_search_index if mouse_position[:X] <= (@x + borderX_halved)
#   #   return pokedex_search_index if mouse_position[:X] >= (@x + @width - borderX_halved)
#   #   line_first = top_row - 1
#   #   line_last = line_first + page_row_max + 3
#   #   index_new = line_first + ((mouse_position[:Y] - @y + (borderY / 2)) / rowHeight).floor
#   #   pokedex_search_index = index_new
#   #   line_first = 0 if line_first < 0
#   #   line_last = @commands.length-1 if line_last >= @commands.length
#   #   if @index != index_new && !((index_new < line_first) || (index_new > line_last))
#   #     @index = index_new
#   #     update_cursor_rect
#   #   end
#   #   return pokedex_search_index
#   # end
#   #####/MODDED
# end


########################################################
####################   Pokegear   ######################
########################################################


class Scene_Pokegear
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
  def mouse_update_hover()
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    line_sprite = @sprites['button0']
    return if line_sprite.nil?
    line_start = line_sprite.x
    return if mouse_position[:X] <= line_start
    line_end = line_start + line_sprite.bitmap.rect.width
    return if mouse_position[:X] >= line_end
    command_window_sprite = @sprites["command_window"]
    commands_length = command_window_sprite.commands.length - 1
    for i in 0..commands_length
      if @sprites["button#{commands_length - i}"].y < mouse_position[:Y]
        command_window_sprite.index = commands_length - i
        break
      end
    end
  end
  #####/MODDED
end


########################################################
###################   Start menu   #####################
########################################################
# Skip options and controls, they're much better to navigate with the keyboard
# TODO figure out a way to handle the savegames selection submenu; it may not be possible without reworking pbStartLoadScreen


if !defined?(mouse_old_pbUpdateSpriteHash)
  alias :mouse_old_pbUpdateSpriteHash :pbUpdateSpriteHash
end
def pbUpdateSpriteHash(windows)
  retval = mouse_old_pbUpdateSpriteHash(windows)
  #####MODDED
  mouse_pokemon_load_scene_update_hover(windows) if Mouse::Sauiw::check_and_reset_callback(:POKEMON_LOAD_SCENE_SPRITES)
  #####/MODDED
  return retval
end

#####MODDED
def mouse_pokemon_load_scene_update_hover(windows)
  $mouse_method_mouse_pokemon_load_scene_savefiles_hover.call() if !$mouse_method_mouse_pokemon_load_scene_savefiles_hover.nil?
  mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
  return if mouse_position.nil?
  line_sprite = windows['panel0']
  return if line_sprite.nil?
  line_start = line_sprite.x
  return if mouse_position[:X] <= line_start
  line_end = line_start + line_sprite.bitmap.rect.width
  return if mouse_position[:X] >= line_end
  command_window_sprite = windows["cmdwindow"]
  commands_length = command_window_sprite.commands.length - 1
  for i in 0..commands_length
    if windows["panel#{commands_length - i}"].y < mouse_position[:Y]
      command_window_sprite.index = commands_length - i
      break
    end
  end
end
#####/MODDED

class PokemonLoadScene
  if !defined?(mouse_old_pbUpdate)
    alias :mouse_old_pbUpdate :pbUpdate
  end
  def pbUpdate(*args, **kwargs)
    #####MODDED
    Mouse::Sauiw::hover_callback_set(method(:mouse_pokemon_load_scene_update_hover), [@sprites])
    Mouse::Sauiw::set_callback(:POKEMON_LOAD_SCENE_SPRITES) if MOUSE_UPDATE_HOVERING
    #####/MODDED
    return mouse_old_pbUpdate(*args, **kwargs)
  end
end


########################################################
#############   Player's look selection   ##############
########################################################
# It is done as a map event, thus we'll catch it by trapping mouse clicks in that map
# During its selection it is stored in $game_variables[358], values 1->6
# Map: Map_id=51
# Coordinates from the corner:
# 1:  x=5 y=14
# 2:  x=7 y=14
# 3:  x=9 y=14
# 4: x=11 y=14
# 5: x=13 y=14
# 6: x=15 y=14
# TODO the hovered sprite does not animate

if !defined?(Mouse::Sauiw::ticket_scene_handle_hover)
module Mouse
  #####MODDED
  module Sauiw
    def self.ticket_scene_handle_hover
      return if !Reborn
      return if !Mouse::Sauiw::ticket_scene_is_mapid_correct?
      Mouse::Sauiw::hover_callback_set(method(:ticket_scene_update_hover))
    end
  
    def self.ticket_scene_update_hover
      return if !Reborn 
      return if !Mouse::Sauiw::ticket_scene_is_mapid_correct?
      mouse_position = Mouse::Sauiw::get_cursor_coordinates_on_screen()
      return if mouse_position.nil?
      look = Mouse::Sauiw::ticket_scene_coordinates_to_look(
        mouse_position[:X] + $game_player.x,
        mouse_position[:Y] + $game_player.y
      )
      Mouse::Sauiw::ticket_scene_set_look(look)
    end

    def self.ticket_scene_is_mapid_correct?
      return $game_map.map_id == 51
    end

    def self.ticket_scene_coordinates_to_look(x, y)
      return nil if y != 14
      case x
        when 5
          return 1
        when 7
          return 2
        when 9
          return 3
        when 11
          return 4
        when 13
          return 5
        when 15
          return 6
      end
      return nil
    end

    def self.ticket_scene_set_look(look)
      return if look.nil?
      return if $game_variables[358] == look
      $game_variables[358] = look # "Intro Cursor"
      $game_screen.pictures[3].show("introPlayer#{look}", 0, 0, 0, 100, 100, 255, 0)
    end
  end
  #####/MODDED
end
end


########################################################
############   Battle actions and moves   ##############
########################################################


class PokeBattle_Scene
  if !defined?(mouse_old_pbFrameUpdate)
    alias :mouse_old_pbFrameUpdate :pbFrameUpdate
  end
  def pbFrameUpdate(cw, update_cw = true, ignore_mouse_hover = false)
    #####MODDED
    if !ignore_mouse_hover
      Mouse::Sauiw::hover_callback_set(method(:mouse_update_hover), [cw, update_cw, true]) if update_cw
      mouse_update_hover(cw, update_cw, false) if MOUSE_UPDATE_HOVERING
    end
    #####/MODDED
    return mouse_old_pbFrameUpdate(cw, update_cw = true)
  end

  #####MODDED
  def mouse_update_hover(cw, update_cw, action_triggered)
    return if !cw
    # return if !update_cw
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    is_fight_menu = defined?(cw.setIndex)
    if is_fight_menu
      #Coordinates copied from class FightMenuButtons
      x_start = 4
      y_start = Graphics.height-90 # FightMenuButtons::UPPERGAP is re-added right after, thus there's no point in removing it here
      x_end = x_start+384
      y_end = y_start+94
      x_mid = x_start+192
      y_mid = y_start+47
    else
      #Coordinates copied from class CommandMenuButtons
      x_start = Graphics.width-260
      y_start = Graphics.height-96
      x_end = x_start+256
      y_end = y_start+94
      x_mid = x_start+128
      y_mid = y_start+47
    end
    if (mouse_position[:X] > x_start) && (mouse_position[:X] < x_end) && (mouse_position[:Y] > y_start) && (mouse_position[:Y] < y_end)
      index = mouse_position[:X] < x_mid ? 0 : 1
      index += 2 if mouse_position[:Y] > y_mid
      if is_fight_menu
        cw.setIndex(index)
      else
        cw.index = index
      end
      return
    end
    return if !is_fight_menu
    return if !action_triggered
    return if mouse_position[:X] <= 148
    return if mouse_position[:X] >= 242
    return if mouse_position[:Y] <= 251
    return if mouse_position[:Y] >= 288
    play_sound = false
    player_index = 0
    if cw.megaButton == 1
      play_sound = true
      tts("Mega Evolution activated")
      @battle.pbRegisterMegaEvolution(player_index)
      cw.megaButton = 2
    elsif cw.megaButton == 2
      play_sound = true
      tts("Mega Evolution deactivated")
      @battle.pbUnRegisterMegaEvolution(player_index)
      cw.megaButton = 1
    end
    if cw.ultraButton == 1
      play_sound = true
      tts("Ultra Burst activated")
      @battle.pbRegisterUltraBurst(player_index)
      cw.ultraButton = 2
    elsif cw.ultraButton == 2
      play_sound = true
      tts("Ultra Burst deactivated")
      @battle.pbUnRegisterUltraBurst(player_index)
      cw.ultraButton = 1
    end
    if cw.zButton == 1
      play_sound = true
      tts("Z-Moves activated")
      @battle.pbRegisterZMove(player_index)
      cw.zButton = 2
    elsif cw.zButton == 2
      play_sound = true
      tts("Z-Moves deactivated")
      @battle.pbUnRegisterZMove(player_index)
      cw.zButton = 1
    end
    if play_sound
      Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
      pbPlayDecisionSE()
    end
  end
  
  def mouse_update_hover_target(index)
    return index if index < 0
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return index if mouse_position.nil?
    return index if mouse_position[:X] < 0
    num_sections = @battle.doublebattle ? 4 : 2
    selection = (num_sections * mouse_position[:X] / Graphics.width).floor
    selection = [num_sections - 1, selection].min # Handles the edge case where mouse_position == Graphics.width
    return selection if !@battle.doublebattle
    # In doubles, the section % does not match the battler index
    case selection
      when 0
        return 0
      when 1
        return 2
      when 2
        return 3
      when 3
        return 1
    end
    raise StandardError.new "Unexpected selection: #{selection}"
  end
  #####/MODDED

  def pbChooseTarget(index)
    pbShowWindow(FIGHTBOX)
    curwindow = pbFirstTarget(index)
    if curwindow == -1
      raise RuntimeError.new(_INTL("No targets somehow..."))
    end
    tts(@battle.battlers[curwindow].name, true) if !@battle.battlers[curwindow].isFainted?

    loop do
      pbGraphicsUpdate
      Input.update
      curwindow = mouse_update_hover_target(curwindow) if MOUSE_UPDATE_HOVERING #####MODDED_OBLIGATORY
      pbUpdateSelected(curwindow)
      if Input.trigger?(Input::C)
        pbUpdateSelected(-1)
        return mouse_update_hover_target(curwindow) #####MODDED_OBLIGATORY
        return curwindow
      end
      if Input.trigger?(Input::B)
        pbUpdateSelected(-1)
        return -1
      end
      if curwindow >= 0
        if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::DOWN)
          loop do
            newcurwindow = 3 if curwindow == 0
            newcurwindow = 1 if curwindow == 3
            newcurwindow = 2 if curwindow == 1
            newcurwindow = 0 if curwindow == 2
            curwindow = newcurwindow
            next if curwindow == index
            break if !@battle.battlers[curwindow].isFainted?
          end
          tts(@battle.battlers[curwindow].name, true) if !@battle.battlers[curwindow].isFainted?
        elsif Input.trigger?(Input::LEFT) || Input.trigger?(Input::UP)
          loop do
            newcurwindow = 2 if curwindow == 0
            newcurwindow = 1 if curwindow == 2
            newcurwindow = 3 if curwindow == 1
            newcurwindow = 0 if curwindow == 3
            curwindow = newcurwindow
            next if curwindow == index
            break if !@battle.battlers[curwindow].isFainted?
          end
          tts(@battle.battlers[curwindow].name, true) if !@battle.battlers[curwindow].isFainted?
        end
      end
    end
  end

  def pbChooseTargetOneSide(index, target)
    pbShowWindow(FIGHTBOX)
    curwindow = target == :SingleOpposing ? pbFirstTarget(index) : pbAcupressureTarget(index)
    if curwindow == -1
      raise RuntimeError.new(_INTL("No targets somehow..."))
    end

    loop do
      pbGraphicsUpdate
      Input.update
      curwindow = mouse_update_hover_target(curwindow) if MOUSE_UPDATE_HOVERING #####MODDED_OBLIGATORY
      pbUpdateSelected(curwindow)
      if Input.trigger?(Input::C)
        pbUpdateSelected(-1)
        return mouse_update_hover_target(curwindow) #####MODDED_OBLIGATORY
        return curwindow
      end
      if Input.trigger?(Input::B)
        pbUpdateSelected(-1)
        return -1
      end
      if curwindow >= 0
        if Input.trigger?(Input::RIGHT) || Input.trigger?(Input::DOWN)
          loop do
            newcurwindow = 2 if curwindow == 0
            newcurwindow = 1 if curwindow == 3
            newcurwindow = 3 if curwindow == 1
            newcurwindow = 0 if curwindow == 2
            curwindow = newcurwindow
            break if !@battle.battlers[curwindow].isFainted?
          end
          tts(@battle.battlers[curwindow].name) if !@battle.battlers[curwindow].isFainted?
        elsif Input.trigger?(Input::LEFT) || Input.trigger?(Input::UP)
          loop do
            newcurwindow = 2 if curwindow == 0
            newcurwindow = 0 if curwindow == 2
            newcurwindow = 3 if curwindow == 1
            newcurwindow = 1 if curwindow == 3
            curwindow = newcurwindow
            break if !@battle.battlers[curwindow].isFainted?
          end
          tts(@battle.battlers[curwindow].name) if !@battle.battlers[curwindow].isFainted?
        end
      end
    end
  end
end


########################################################
######################   Bag   #########################
########################################################


class PokemonBag_Scene
  if !defined?(mouse_old_update)
    alias :mouse_old_update :update
  end
  def update(*args, **kwargs)
    #####MODDED
    Mouse::Sauiw::hover_callback_set(method(:mouse_update_hover), [true])
    mouse_update_hover(false) if MOUSE_UPDATE_HOVERING
    #####/MODDED
    return mouse_old_update(*args, **kwargs)
  end

  #####MODDED
  def mouse_update_hover(was_clicked)
    return if !@sprites["helpwindow"].nil? && @sprites["helpwindow"].visible # An item is selected
    return if !@sprites["msgwindow"].nil? && @sprites["msgwindow"].visible # An item is selected
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    iw = @sprites["itemwindow"]
    return if iw.nil?
    mouse_update_hover_item_list(mouse_position, iw)
    mouse_update_hover_slider(mouse_position, iw, was_clicked) # This will actually check for dragging input
    if was_clicked
      mouse_update_hover_sort(mouse_position, iw)
      mouse_update_hover_pocket(mouse_position, iw)
    end
  end

  def mouse_update_hover_item_list(mouse_position, iw)
    border_x_halved = iw.borderX/2
    return if mouse_position[:X] <= iw.x + border_x_halved
    return if mouse_position[:X] >= iw.x + iw.width - border_x_halved
    y_start = iw.y + iw.borderY
    if mouse_position[:Y] < y_start
      # Scroll up
      iw.index = iw.top_item - 1 if iw.top_item > 0
      return
    end
    items_max_per_page = iw.page_item_max
    row_height = (iw.height - iw.borderY) / (items_max_per_page + 1)
    visible_rows_above = ((mouse_position[:Y] - y_start)/ row_height).floor + 1
    index = [@bag.pockets[iw.pocket].length, iw.top_item - 1 + visible_rows_above].min
    if visible_rows_above < items_max_per_page
      # The hovered item is selected; no need for scrolling
      iw.index = index
      return
    end
    return if mouse_position[:Y] >= y_start + (visible_rows_above + 1) * row_height
    # Scroll down
    iw.index = [index + 1, @bag.pockets[iw.pocket].length].min
  end

  def mouse_update_hover_sort(mouse_position, iw)
    # Got these coordinates directly from the background image
    return if mouse_position[:Y] <= 155
    return if mouse_position[:Y] >= 175
    return if mouse_position[:X] <= 55
    return if mouse_position[:X] >= 175
    Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
    pbHandleSort(iw.pocket, mouse_position[:X] < 115 ? :name : :type)
    pbRefresh
  end

  def mouse_update_hover_pocket(mouse_position, iw)
    return if mouse_position[:Y] <= 230
    return if mouse_position[:Y] >= 250
    x_start = 5.0
    x_end = 180.0
    return if mouse_position[:X] <= x_start
    return if mouse_position[:X] >= x_end
    num_pockets = PokemonBag.numPockets
    pocket = ((mouse_position[:X] - x_start) / (x_end - x_start) * num_pockets).floor + 1
    pocket = [[pocket, 1].max, num_pockets].min
    Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
    return if pocket == iw.pocket
    iw.pocket = pocket
    @bag.lastpocket = iw.pocket
    pbRefresh
  end
  
  def mouse_update_hover_slider(mouse_position, iw, was_clicked)
    return if mouse_position[:X] <= 470
    return if mouse_position[:X] >= 505
    return if mouse_position[:Y] <= 20
    return if mouse_position[:Y] >= 260
    Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
    items_total = @bag.pockets[iw.pocket].length
    return if items_total <= 0
    bar_y_start = 60.0
    bar_y_end = 220.0
    bar_height = bar_y_end - bar_y_start
    slider_height = @sprites["slider"].bitmap.height
    slider_height_halved = slider_height / 2
    if mouse_position[:Y] < bar_y_start
      return if !was_clicked
      new_index = iw.index - iw.page_item_max
    elsif mouse_position[:Y] < bar_y_end
      return if !Input.pressex?(Input::LeftMouseKey) && !was_clicked
      new_index = ((mouse_position[:Y] - bar_y_start - slider_height_halved) / (bar_height - slider_height) * items_total).floor
    else
      return if !was_clicked
      new_index = iw.index + iw.page_item_max
    end
    new_index = [[new_index, 0].max, items_total].min
    return if new_index == iw.index
    iw.index = new_index
    @sprites["slider"].y = bar_y_start + (bar_height - slider_height) * new_index / items_total
  end
  #####/MODDED
end


########################################################
#####################   Party   ########################
########################################################


class PokemonScreen_Scene
  if !defined?(mouse_old_update)
    alias :mouse_old_update :update
  end
  def update(*args, **kwargs)
    #####MODDED
    Mouse::Sauiw::hover_callback_set(method(:mouse_update_hover), [true])
    mouse_update_hover(false) if MOUSE_UPDATE_HOVERING
    #####/MODDED
    return mouse_old_update(*args, **kwargs)
  end

  #####MODDED
  def mouse_update_hover(was_clicked)
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    hw = @sprites["helpwindow"]
    return if hw.nil?
    return if !Set[
      # "Choose a pokemon", or "Move to where?", etc
      'Choo',
      'Move',
      'Give',
      'Use ',
      'Teac',
      'Fuse'
    ].include?(hw.text[0..3])
    return if mouse_check_exit_screen(mouse_position, was_clicked)
    index = mouse_get_hovered_party_member(mouse_position)
    return if index.nil?
    return if index == @activecmd
    @sprites["pokemon#{@activecmd}"].selected = false
    @activecmd = index
    @sprites["pokemon#{index}"].selected = true
  end

  def mouse_check_exit_screen(mouse_position, was_clicked)
    return false if !was_clicked
    return false if mouse_position[:X] <= 400
    return false if mouse_position[:Y] <= 330
    return false if mouse_position[:Y] >= 375
    Mouse::Sauiw::set_callback(
      :EXIT_SCREEN,
      :INTERCEPT_CLICK
    )
    return true
  end

  def mouse_get_hovered_party_member(mouse_position)
    for i in 0...@party.length
      next if @party[i].nil?
      mon_sprite = @sprites["pokemon#{i}"]
      next if mon_sprite.nil?
      next if mon_sprite.bitmap.nil?
      next if mouse_position[:X] <= mon_sprite.x
      next if mouse_position[:X] >= mon_sprite.x + mon_sprite.bitmap.width
      next if mouse_position[:Y] <= mon_sprite.y
      next if mouse_position[:Y] >= mon_sprite.y + mon_sprite.bitmap.height
      return i
    end
    return nil
  end
  #####/MODDED
end


########################################################
######################   Map   #########################
########################################################


class PokemonRegionMapScene
  if !defined?(mouse_old_pbUpdate)
    alias :mouse_old_pbUpdate :pbUpdate
  end
  def pbUpdate(*args, **kwargs)
    #####MODDED
    Mouse::Sauiw::hover_callback_set(method(:mouse_update_hover))
    mouse_update_hover() if MOUSE_UPDATE_HOVERING
    #####/MODDED
    return mouse_old_pbUpdate(*args, **kwargs)
  end

  #####MODDED
  def mouse_update_hover()
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    map_sprite = @sprites["map"]
    return if map_sprite.nil?
    map_cursor = @sprites["cursor"]
    return if map_cursor.nil?
    x_offset = mouse_position[:X] - map_sprite.x
    return if x_offset <= 0
    return if x_offset >= map_sprite.bitmap.width
    y_offset = mouse_position[:Y] - map_sprite.y
    return if y_offset <= 0
    return if y_offset >= map_sprite.bitmap.height
    new_x = x_offset / SQUAREWIDTH
    if new_x != @mapX
      @mapX = new_x
      map_cursor.x = x_offset + (Graphics.width - map_sprite.bitmap.width - SQUAREWIDTH) / 2
    end
    new_y = y_offset / SQUAREHEIGHT
    if new_y != @mapY
      @mapY = new_y
      map_cursor.y = y_offset + (Graphics.height - map_sprite.bitmap.height - SQUAREHEIGHT) / 2
    end
  end
  #####/MODDED
end


########################################################
####################   Nyu's PC   ######################
########################################################


class PokemonStorageScene
  if !defined?(mouse_old_pbSelectPartyInternal)
    alias :mouse_old_pbSelectPartyInternal :pbSelectPartyInternal
  end
  def pbSelectPartyInternal(*args, **kwargs)
    Mouse::Sauiw::set_callback(:PC_SELECT_PARTY_INTERNAL) #####MODDED
    retval = mouse_old_pbSelectPartyInternal(*args, **kwargs)
    Mouse::Sauiw::reset_callback(:PC_SELECT_PARTY_INTERNAL) #####MODDED
    return retval
  end

  if !defined?(mouse_old_pbPartyChangeSelection)
    alias :mouse_old_pbPartyChangeSelection :pbPartyChangeSelection
  end
  def pbPartyChangeSelection(key, selection)
    #####MODDED
    actual_key = mouse_get_actual_key_repeat()
    return mouse_old_pbPartyChangeSelection(actual_key, selection) if !actual_key.nil?
    return mouse_update_hover_party(selection) if MOUSE_UPDATE_HOVERING || Input.pressex?(Input::LeftMouseKey)
    return selection
    #####/MODDED
  end

  if !defined?(mouse_old_pbSelectBoxInternal)
    alias :mouse_old_pbSelectBoxInternal :pbSelectBoxInternal
  end
  def pbSelectBoxInternal(*args, **kwargs)
    Mouse::Sauiw::set_callback(:PC_SELECT_BOX_INTERNAL) #####MODDED
    retval = mouse_old_pbSelectBoxInternal(*args, **kwargs)
    Mouse::Sauiw::reset_callback(:PC_SELECT_BOX_INTERNAL) #####MODDED
    return retval
  end

  if !defined?(mouse_old_pbChangeSelection)
    alias :mouse_old_pbChangeSelection :pbChangeSelection
  end
  def pbChangeSelection(key, selection)
    #####MODDED
    actual_key = mouse_get_actual_key_repeat()
    return mouse_old_pbChangeSelection(actual_key, selection) if !actual_key.nil?
    return mouse_update_hover_box(selection) if MOUSE_UPDATE_HOVERING || Input.pressex?(Input::LeftMouseKey)
    return selection
    #####/MODDED
  end

  #####MODDED
  def mouse_get_actual_key_repeat()
    [
      Input::UP,
      Input::RIGHT,
      Input::DOWN,
      Input::LEFT
    ].each do |key|
      return key if Input.mouse_old_input_repeat?(key)
    end
    return nil
  end

  def mouse_update_hover_party(selection)
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return selection if mouse_position.nil?
    box_party = @sprites["boxparty"]
    return selection if box_party.nil?
    x_adjusted = mouse_position[:X] - box_party.x
    return selection if x_adjusted <= 16
    return selection if x_adjusted >= box_party.bitmap.width
    y_adjusted = mouse_position[:Y] - box_party.y
    return selection if y_adjusted <= 0
    return selection if y_adjusted >= box_party.bitmap.height
    # Copied over from the actual code and adjusted
    return 6 if y_adjusted > 208 # 144 + 64
    if x_adjusted > 92
      index_offset = 1.0
      y_offset = 16.0
    else
      index_offset = 0.0
      y_offset = 0.0
    end
    return selection if y_adjusted <= y_offset
    i = [((y_adjusted - y_offset) / 64.0).floor, 2].min
    return i * 2 + index_offset
  end
  #####/MODDED
  
  def mouse_update_hover_box(selection)
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return selection if mouse_position.nil?
    #Coordinates taken directly from the bitmap
    if (mouse_position[:Y] > 20) && (mouse_position[:Y] < 60)
      #Upper bar
      return -1 if (mouse_position[:X] > 230) && (mouse_position[:X] < 460) # Box name
      return selection if !Input.triggerex?(Input::LeftMouseKey)
      Mouse::Sauiw::set_callback(:INTERCEPT_CLICK)
      return -4 if (mouse_position[:X] > 185) && (mouse_position[:X] < 220) # Move to previous box
      return -5 if (mouse_position[:X] > 470) && (mouse_position[:X] < 505) # Move to next box
      return selection
    end
    if (mouse_position[:Y] > 64) && (mouse_position[:Y] < 304) && (mouse_position[:X] > 202) && (mouse_position[:X] < 490)
      #Box
      #Squares' edges: 48
      hovered_x = ((mouse_position[:X] - 202.0) / 48.0).floor
      hovered_y = ((mouse_position[:Y] - 64.0) / 48.0).floor
      return hovered_x + hovered_y * 6
    end
    if (mouse_position[:Y] > 325) && (mouse_position[:Y] < 365)
      #Lower bar
      return -2 if (mouse_position[:X] > 185) && (mouse_position[:X] < 355) # Party
      return -3 if (mouse_position[:X] > 385) && (mouse_position[:X] < 505) # Close Box
      return selection
    end
    return selection
  end
  #####/MODDED
end


########################################################
####################   Buy menu   ######################
########################################################


class PokemonMartScene
  # TODO the menu for actually buying the item is not fully functional
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
  def mouse_update_hover()
    return if !@sprites["helpwindow"].nil? && @sprites["helpwindow"].visible #An item is selected
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    iw = @sprites["itemwindow"]
    return if iw.nil?
    mouse_update_hover_item_list(mouse_position, iw)
  end

  def mouse_update_hover_item_list(mouse_position, iw)
    border_x_halved = iw.borderX/2
    return if mouse_position[:X] <= iw.x + border_x_halved
    return if mouse_position[:X] >= iw.x + iw.width - border_x_halved
    y_start = iw.y + iw.borderY
    if mouse_position[:Y] < y_start
      # Scroll up
      iw.index = iw.top_item - 1 if iw.top_item > 0 && mouse_get_can_scroll?
      return
    end
    items_max_per_page = iw.page_item_max
    row_height = (iw.height - iw.borderY) / (items_max_per_page + 1)
    visible_rows_above = ((mouse_position[:Y] - y_start)/ row_height).floor + 1
    max_index = iw.itemCount - 1
    index = [max_index, iw.top_item - 1 + visible_rows_above].min
    if visible_rows_above < items_max_per_page
      # The hovered item is selected; no need for scrolling
      iw.index = index
      return
    end
    return if mouse_position[:Y] >= y_start + (visible_rows_above + 1) * row_height
    # Scroll down
    iw.index = [index + 1, max_index].min if mouse_get_can_scroll?
  end

  def mouse_get_can_scroll?
    $pokemon_mart_scene_scroll_cooldown = 0 if !defined?($pokemon_mart_scene_scroll_cooldown)
    if $pokemon_mart_scene_scroll_cooldown > 0
      $pokemon_mart_scene_scroll_cooldown -= 1
      return false
    end
    $pokemon_mart_scene_scroll_cooldown = 9
    return true
  end
  #####/MODDED
end


########################################################
#################   Pokemon summary   ##################
########################################################


class PokemonSummaryScene
  if !defined?(mouse_old_pbUpdate)
    alias :mouse_old_pbUpdate :pbUpdate
  end
  def pbUpdate(*args, **kwargs)
    #####MODDED
    mouse_update_hover_page()
    #####/MODDED
    return mouse_old_pbUpdate(*args, **kwargs)
  end

  #####MODDED
  def mouse_update_hover(selmove, maxmove, moveToLearn)
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return nil if mouse_position.nil?
    was_clicked = Input.triggerex?(Input::LeftMouseKey)
    return nil if !was_clicked && !MOUSE_UPDATE_HOVERING
    return nil if was_clicked && !@sprites["movesel"].visible
    # Got the coordinates directly from the bitmap
    return nil if selmove <= -2
    return nil if mouse_position[:X] <= 240
    return nil if mouse_position[:X] >= 490
    selected = mouse_update_hover_get_hovered_icon_id(mouse_position)
    return nil if selected.nil?
    return nil if selected > maxmove
    return nil if selected == selmove
    Mouse::Sauiw::set_callback(:INTERCEPT_CLICK) if was_clicked
    @sprites["movesel"].index = selected
    newmove = (selected == 4) ? moveToLearn : @pokemon.moves[selected].move
    drawSelectedMove(@pokemon, moveToLearn, newmove)
    return selected
  end

  def mouse_update_hover_get_hovered_icon_id(mouse_position)
    return nil if mouse_position[:Y] >= 365
    return 4 if mouse_position[:Y] > 290
    return nil if mouse_position[:Y] >= 280
    return 3 if mouse_position[:Y] > 213
    return 2 if mouse_position[:Y] > 149
    return 1 if mouse_position[:Y] > 85
    return 0 if mouse_position[:Y] > 20
    return nil
  end

  def mouse_update_hover_page()
    return if !@sprites["movesel"].nil? && @sprites["movesel"].visible
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return if mouse_position.nil?
    was_clicked = Input.triggerex?(Input::LeftMouseKey)
    return if !was_clicked
    Mouse::Sauiw::set_callback(:INTERCEPT_CLICK) if @page != 4 || !mouse_is_in_move_selection_area?(mouse_position)
    # Got the coordinates directly from the bitmap
    new_page = mouse_update_hover_get_hovered_page(mouse_position)
    return if new_page.nil?
    return if new_page == @page
    @page = new_page
    return drawPageOne(@pokemon) if @page == 0
    return drawPageTwo(@pokemon) if @page == 1
    return drawPageThree(@pokemon) if @page == 2
    return drawPageFour(@pokemon) if @page == 3
    return drawPageFive(@pokemon) if @page == 4
  end

  def mouse_update_hover_get_hovered_page(mouse_position)
    return nil if mouse_position[:Y] <= 20
    return nil if mouse_position[:Y] >= 42
    # x_distance = 10
    width = 36
    x_start = 284
    x_step = 46 # x_distance + width
    new_page = ((mouse_position[:X] - x_start) / x_step).floor
    return nil if new_page < 0
    return nil if new_page > 4
    x_difference = mouse_position[:X] - x_start - (new_page * x_step)
    return nil if x_difference > width
    return new_page
    # return 0 if (mouse_position[:X] > 285) && (mouse_position[:X] < 320)
    # return 1 if (mouse_position[:X] > 330) && (mouse_position[:X] < 366)
    # return 2 if (mouse_position[:X] > 376) && (mouse_position[:X] < 412)
    # return 3 if (mouse_position[:X] > 422) && (mouse_position[:X] < 458)
    # return 4 if (mouse_position[:X] > 468) && (mouse_position[:X] < 502)
    # return nil
  end

  def mouse_update_hover_move_selection(selmove, moves, zmoves)
    mouse_position = Mouse::Sauiw::get_cursor_position_on_screen()
    return selmove if mouse_position.nil?
    return selmove if !mouse_is_in_move_selection_area?(mouse_position)
    selected = mouse_update_hover_move_selection_get_hovered_move(mouse_position)
    return selmove if selected >= @pokemon.numMoves
    return selmove if selected == selmove
    @sprites["movesel"].index = selected
    if @zmovepage && !zmoves[selected].nil?
      drawSelectedZeeMove(@pokemon, moves[selected].move, zmoves[selected].move)
    else
      drawSelectedMove(@pokemon, 0, moves[selected].move)
    end
    return selected
  end

  def mouse_is_in_move_selection_area?(mouse_position)
    return false if mouse_position[:X] <= 245
    return false if mouse_position[:X] >= 486
    return false if mouse_position[:Y] <= 96
    return false if mouse_position[:Y] >= 352
    return true
  end

  def mouse_update_hover_move_selection_get_hovered_move(mouse_position)
    return 3 if mouse_position[:Y] > 288
    return 2 if mouse_position[:Y] > 224
    return 1 if mouse_position[:Y] > 160
    return 0
  end
  #####/MODDED

  def pbChooseMoveToForget(moveToLearn)
    selmove = 0
    ret = 0
    maxmove = (moveToLearn != 0) ? 4 : 3
    lastread = nil
    loop do
      Graphics.update
      Input.update
      #####MODDED_OBLIGATORY
      hovered = mouse_update_hover(selmove, maxmove, moveToLearn)
      ret = selmove = hovered if !hovered.nil?
      #####/MODDED_OBLIGATORY
      pbUpdate
      if lastread != selmove
        if selmove == 4
          readobj = PBMove.new(moveToLearn) if moveToLearn != 0
        else
          readobj = @pokemon.moves[selmove]
        end
        reading = (selmove == 4) ? moveToLearn : @pokemon.moves[selmove].move
        tts(moveToString(reading, readobj))
        lastread = selmove
      end
      if Input.trigger?(Input::B)
        ret = 4
        break
      end
      if Input.trigger?(Input::C)
        break
      end

      if Input.trigger?(Input::DOWN)
        selmove += 1
        if selmove < 4 && selmove >= @pokemon.numMoves
          selmove = (moveToLearn > 0) ? maxmove : 0
        end
        selmove = 0 if selmove > maxmove
        @sprites["movesel"].index = selmove
        newmove = (selmove == 4) ? moveToLearn : @pokemon.moves[selmove].move
        drawSelectedMove(@pokemon, moveToLearn, newmove)
        ret = selmove
      end
      if Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove < 0
        if selmove < 4 && selmove >= @pokemon.numMoves
          selmove = @pokemon.numMoves - 1
        end
        @sprites["movesel"].index = selmove
        newmove = (selmove == 4) ? moveToLearn : @pokemon.moves[selmove].move
        drawSelectedMove(@pokemon, moveToLearn, newmove)
        ret = selmove
      end
    end
    return (ret == 4) ? -1 : ret
  end

  def pbMoveSelection
    @sprites["movesel"].visible = true
    @sprites["movesel"].index = 0
    selmove = 0
    oldselmove = 0
    switching = false
    moves = @pokemon.moves # Remember this is a shallow copy
    zmoves = @pokemon.zmoves # Remember this is a shallow copy
    @zmovepage && !zmoves[selmove].nil? ? drawSelectedZeeMove(@pokemon, moves[selmove].move, zmoves[selmove].move) : drawSelectedMove(@pokemon, 0, moves[selmove].move)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      selmove = mouse_update_hover_move_selection(selmove, moves, zmoves) #####MODDED_OBLIGATORY
      @sprites["movepresel"].z = @sprites["movesel"].z
      @sprites["movepresel"].z += 1 if @sprites["movepresel"].index == @sprites["movesel"].index
      if Input.trigger?(Input::B)
        break if !switching

        @sprites["movepresel"].visible = false
        switching = false
      end
      if Input.trigger?(Input::C) && !(@pokemon.isShadow? rescue false)
        if !switching
          @sprites["movepresel"].index = selmove
          oldselmove = selmove
          @sprites["movepresel"].visible = true
          switching = true
        else
          tmpmove = moves[oldselmove]
          moves[oldselmove] = moves[selmove]
          moves[selmove] = tmpmove
          if !(zmoves.nil? || @pokemon.item == :INTERCEPTZ)
            tmpmove = zmoves[oldselmove]
            zmoves[oldselmove] = zmoves[selmove]
            zmoves[selmove] = tmpmove
          end
          @sprites["movepresel"].visible = false
          switching = false
          @zmovepage && !zmoves[selmove].nil? ? drawSelectedZeeMove(@pokemon, moves[selmove].move, zmoves[selmove].move) : drawSelectedMove(@pokemon, 0, moves[selmove].move)
        end
      end
      if Input.trigger?(Input::X) && zmoves != nil && zmoves.any? { |x| x != nil }
        @zmovepage = !@zmovepage
        @zmovepage && !zmoves[selmove].nil? ? drawSelectedZeeMove(@pokemon, moves[selmove].move, zmoves[selmove].move) : drawSelectedMove(@pokemon, 0, moves[selmove].move)
      end
      if Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove >= @pokemon.numMoves
        @sprites["movesel"].index = selmove
        pbPlayCursorSE()
        @zmovepage && !zmoves[selmove].nil? ? drawSelectedZeeMove(@pokemon, moves[selmove].move, zmoves[selmove].move) : drawSelectedMove(@pokemon, 0, moves[selmove].move)
      end
      if Input.trigger?(Input::UP)
        selmove -= 1
        selmove = @pokemon.numMoves - 1 if selmove < 0
        @sprites["movesel"].index = selmove
        pbPlayCursorSE()
        @zmovepage && !zmoves[selmove].nil? ? drawSelectedZeeMove(@pokemon, moves[selmove].move, zmoves[selmove].move) : drawSelectedMove(@pokemon, 0, moves[selmove].move)
      end
    end
    @sprites["movesel"].visible = false
  end
end


if false # TODO UPDATED UNTIL HERE
  ## TODO: check weather/time selection, field notes, pulse dex, pokegear->move tutor

########################################################
####################   Hovering   ######################
########################################################

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
