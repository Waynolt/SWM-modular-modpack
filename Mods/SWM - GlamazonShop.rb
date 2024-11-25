#####MODDED
# This section was supposed to spawn the courier as a real dependentEvent
# Not worth the effort tbh - keeping it in in case I want to get back here later
# Missing: overworld animation for the event, ability to interact with it
=begin
SWM_GLAMAZONSHOP_COURIERS_ID = 1
SWM_GLAMAZONSHOP_COURIERS_NAME = 'SWM_Glamazon_Courier'
SWM_GLAMAZONSHOP_COURIERS = [
  {
    :species => :ABRA,
    :event_id => SWM_GLAMAZONSHOP_COURIERS_ID,
    :event_name => SWM_GLAMAZONSHOP_COURIERS_NAME
  }
]

def swm_GlamazonShop_spawn_courier
  courier = SWM_GLAMAZONSHOP_COURIERS.sample
	new_event = RPG::Event.new($game_player.x, $game_player.y)
	new_event.id = courier[:event_id]
	new_event.name = courier[:event_name]
	new_game_event = Game_Event.new(
	  $game_map.map_id,
	  new_event,
	  $MapFactory.getMap($game_map.map_id)
	)
	new_game_event.character_name = courier[:event_name]
	$PokemonTemp.dependentEvents.addEvent(new_game_event, new_game_event.name) # pbAddDependency(new_game_event)
	pbFlash(Color.new(248, 88, 136, 50), 5)
end

def swm_GlamazonShop_despawn_courier(event_name)
	pbFlash(Color.new(255, 255, 255, 100), 5)
  pbRemoveDependency2(event_name)
end
=end
#####/MODDED

class Game_Map
  #####MODDED
  def swm_GlamazonShop_stop_scrolling
    @scroll_rest = 0
  end
  #####/MODDED
end

$swm_GlamazonShop_topMeUp_items_to_be_checked = nil #####MODDED
class Game_Screen
  #####MODDED
  attr_accessor :swm_GlamazonShop_topMeUp_data
  
  def swm_GlamazonShop_topMeUp_check_next_item
    return nil if $game_system.map_interpreter.running? ||
           $game_player.move_route_forcing || $game_temp.message_window_showing ||
           $PokemonTemp.miniupdate
    item = swm_GlamazonShop_topMeUp_get_next_item_to_be_checked
    return nil if item.nil?
    order = swm_GlamazonShop_topMeUp_get_order_for_one_item(item)
    return nil if order == 0
    orders = [{:item => item, :order => order}]
    # Is it possible that maybe many items were used? Check everything...
    swm_GlamazonShop_topMeUp_get_all_items_to_be_checked.each do |itm|
      next if itm == item
      order = swm_GlamazonShop_topMeUp_get_order_for_one_item(itm)
      next if order == 0
      orders.push({:item => itm, :order => order})
    end
    orders_fixed, player_final_money = swm_GlamazonShop_topMeUp_ensure_orders_are_possible(*orders)
    # Apply the changes
    player_starting_money = $Trainer.money
    $Trainer.money = player_final_money
    messages_buy = []
    orders_fixed[:buy].each do |entry|
      $PokemonBag.pbStoreItem(entry[:item], entry[:qty])
      messages_buy.push(_INTL('{1} x {2} for ${3}', entry[:qty], getItemName(entry[:item]), entry[:price]))
    end
    Kernel.pbMessage(_INTL('TopMeUp service: auto-buying {1}.', messages_buy.join(', '))) if messages_buy.length > 0
    messages_sell = []
    orders_fixed[:sell].each do |entry|
      $PokemonBag.pbDeleteItem(entry[:item], entry[:qty])
      messages_sell.push(_INTL('{1} x {2} for ${3}', entry[:qty], getItemName(entry[:item]), entry[:price]))
    end
    Kernel.pbMessage(_INTL('TopMeUp service: auto-selling {1}.', messages_sell.join(', '))) if messages_sell.length > 0
    Kernel.pbMessage(_INTL("Starting account balance: ${1}\r\nUpdated account balance: ${2}", player_starting_money, player_final_money)) if messages_buy.length > 0 || messages_sell.length > 0
  end
  
  def swm_GlamazonShop_topMeUp_get_order_for_one_item(item)
    current_quantity = $PokemonBag.pbQuantity(item)
    next_order = 0
    lower_limit = swm_GlamazonShop_topMeUp_get_item_lower_limit(item)
    next_order += lower_limit - current_quantity if !lower_limit.nil? && current_quantity < lower_limit
    upper_limit = swm_GlamazonShop_topMeUp_get_item_upper_limit(item)
    next_order += upper_limit - current_quantity if !upper_limit.nil? && current_quantity > upper_limit
    while next_order > 0 && !$PokemonBag.pbCanStore?(item)
      next_order -= 1
    end
    return next_order
  end
  
  def swm_GlamazonShop_topMeUp_ensure_orders_are_possible(*orders)
    player_money = $Trainer.money
    retval = {
      :sell => [],
      :buy => []
    }
    temp_buy_orders = []
    orders.each do |entry|
      if entry[:order] > 0
        temp_buy_orders.push(entry) # Check them last
        next
      end
      price = swm_GlamazonShop_topMeUp_get_item_sell_price(entry[:item])
      next_order_price = entry[:order] * price
      player_money -= next_order_price
      retval[:sell].push({:item => entry[:item], :qty => entry[:order].abs, :price => next_order_price.abs})
    end
    temp_buy_orders.each do |entry|
      price = swm_GlamazonShop_topMeUp_get_item_buy_price(entry[:item])
      qty = [player_money.div(price), entry[:order]].min
      while qty > 0 && !$PokemonBag.pbCanStore?(entry[:item])
        qty -= 1
      end
      next if qty <= 0
      next_order_price = entry[:order] * price
      player_money -= next_order_price
      retval[:buy].push({:item => entry[:item], :qty => qty, :price => next_order_price})
    end
    return retval, player_money
  end
  
  def swm_GlamazonShop_topMeUp_get_item_sell_price(item)
    return ($game_temp.mart_sell[item] || $cache.items[item].price || 0) / 2
  end
  
  def swm_GlamazonShop_topMeUp_get_item_buy_price(item)
    return $game_temp.mart_buy[item] || $cache.items[item].price || 0
  end

  def swm_GlamazonShop_topMeUp_get_item_lower_limit(item)
    return swm_GlamazonShop_topMeUp_get_item_limit(item, :lower)
  end
  
  def swm_GlamazonShop_topMeUp_get_item_upper_limit(item)
    return swm_GlamazonShop_topMeUp_get_item_limit(item, :upper)
  end
  
  def swm_GlamazonShop_topMeUp_get_item_limit(item, limit)
    return nil if !defined?(@swm_GlamazonShop_topMeUp_data) || @swm_GlamazonShop_topMeUp_data.nil?
    return nil if !defined?(@swm_GlamazonShop_topMeUp_data[item]) || @swm_GlamazonShop_topMeUp_data[item].nil?
    return @swm_GlamazonShop_topMeUp_data[item][limit]
  end
  
  def swm_GlamazonShop_topMeUp_get_next_item_to_be_checked
    @swm_GlamazonShop_topMeUp_data = {} if !defined?(@swm_GlamazonShop_topMeUp_data) || @swm_GlamazonShop_topMeUp_data.nil?
    $swm_GlamazonShop_topMeUp_items_to_be_checked = swm_GlamazonShop_topMeUp_get_all_items_to_be_checked.shuffle if !defined?($swm_GlamazonShop_topMeUp_items_to_be_checked) || $swm_GlamazonShop_topMeUp_items_to_be_checked.nil? || $swm_GlamazonShop_topMeUp_items_to_be_checked.length <= 0
    return nil if $swm_GlamazonShop_topMeUp_items_to_be_checked.length <= 0
    return $swm_GlamazonShop_topMeUp_items_to_be_checked.pop
  end
  
  def swm_GlamazonShop_topMeUp_get_all_items_to_be_checked
    @swm_GlamazonShop_topMeUp_data = {} if !defined?(@swm_GlamazonShop_topMeUp_data) || @swm_GlamazonShop_topMeUp_data.nil?
    return [*@swm_GlamazonShop_topMeUp_data.keys]
  end
  
  def swm_GlamazonShop_topMeUp_set_item_lower_limit(item, qty)
    swm_GlamazonShop_topMeUp_set_item_limit(item, :lower, qty)
  end
  
  def swm_GlamazonShop_topMeUp_set_item_upper_limit(item, qty)
    swm_GlamazonShop_topMeUp_set_item_limit(item, :upper, qty)
  end
  
  def swm_GlamazonShop_topMeUp_set_item_limit(item, limit, qty)
    @swm_GlamazonShop_topMeUp_data = {} if !defined?(@swm_GlamazonShop_topMeUp_data) || @swm_GlamazonShop_topMeUp_data.nil?
    @swm_GlamazonShop_topMeUp_data[item] = {} if !defined?(@swm_GlamazonShop_topMeUp_data[item]) || @swm_GlamazonShop_topMeUp_data[item].nil?
    @swm_GlamazonShop_topMeUp_data[item][limit] = qty
  end
  
  def swm_GlamazonShop_topMeUp_reset_item_limits(item)
    return if !defined?(@swm_GlamazonShop_topMeUp_data) || @swm_GlamazonShop_topMeUp_data.nil?
    return if !defined?(@swm_GlamazonShop_topMeUp_data[item]) || @swm_GlamazonShop_topMeUp_data[item].nil?
    @swm_GlamazonShop_topMeUp_data.delete(item)
  end
  #####/MODDED
end

#####MODDED
Events.onStepTaken += proc {
  $game_screen.swm_GlamazonShop_topMeUp_check_next_item
}

class Swm_GlamazonShop_PC
  def shouldShow?
    return false if $game_switches[:NotPlayerCharacter] && !$game_switches[:InterceptorsWish]
    return true
  end

  def name
    return _INTL('Glamazon Shop')
  end

  def access
    # maybe one time payment would be better, else there would be no point in setting an upper limit...
    Kernel.pbMessage(_INTL('Connecting to glamazon.pkm'))
    loop do
      choice = swm_GlamazonShop_show_menu(
        _INTL('What do you wish to do?'),
        [
          [:OnlineShop, 'Online Shop'],
          [:TopMeUp, 'TopMeUp'],
          [:CANCEL, 'Disconnect']
        ]
      )
      break if choice.nil? || choice == :CANCEL
      swm_GlamazonShop_online_shop if choice == :OnlineShop
      swm_GlamazonShop_topMeUp_service if choice == :TopMeUp
    end
  end
  
  def swm_GlamazonShop_online_shop
    loop do
      choice = swm_GlamazonShop_show_menu(
        'Online Shop: which vendor?',
        [
          #[:DefaultMart, 'PokéMart'],
          *swm_GlamazonShop_online_shop_by_option,
          [:CANCEL, 'Back']
        ]
      )
      break if choice.nil? || choice == :CANCEL
      # pbDefaultMart('PokéMart: please choose an option') if choice == :DefaultMart
      shop = swm_GlamazonShop_online_shop_by_option(choice)
      pbPokemonMart(shop[:stock], shop[:speech])
      $game_map.swm_GlamazonShop_stop_scrolling # Prevent scrolling in case we weren't able to scroll during the Mart sequence
    end
  end
  
  def swm_GlamazonShop_online_shop_by_option(option = nil)
    stickers = swm_GlamazonShop_get_num_of_department_store_stickers
    city_restored = swm_GlamazonShop_get_city_is_restored
    options_map = {
      :DefaultMart => {
        :option => 'PokéMart',
        :speech => 'PokéMart: please choose an option',
        :stock => swm_GlamazonShop_get_DefaultMart_stock
      },
      :CandyShop => {
        :option => 'Sweet Kiss',
        :speech => 'Sweet Kiss: please choose an option',
        :stock => [
          :WHIPPEDDREAM, :PEPPERMINT, :CHEWINGGUM, :POPROCKS, :SALTWATERTAFFY, :REDHOTS, :COTTONCANDY, :COMMONCANDY, :RARECANDY, :EXPCANDYXS,
          *(stickers >= 2 ? [:EXPCANDYS] : []),
          *(stickers >= 4 ? [:EXPCANDYM] : []),
          *(stickers >= 7 ? [:EXPCANDYL] : []),
          *(stickers >= 9 ? [:EXPCANDYXL] : []),
          :VANILLAIC,
          :CHOCOLATEIC,
          :STRAWBIC
        ]
      },
      :TheSpyce => {
        :option => 'The Spyce',
        :speech => 'The Spyce: please choose an option',
        :stock => [:FRESHWATER, :SODAPOP, :LEMONADE]
      },
      :Pokeballs => {
        :option => 'Critical Capture',
        :speech => 'Critical Capture: please choose an option',
        :stock => [
          :HEAVYBALL, :MOONBALL, :FASTBALL, :LOVEBALL, :NESTBALL, :NETBALL, :DIVEBALL, :TIMERBALL, :FRIENDBALL,
          *(city_restored ? [:REPEATBALL, :LUXURYBALL, :DUSKBALL, :HEALBALL, :QUICKBALL, :DREAMBALL, :CHERISHBALL, :LEVELBALL, :LUREBALL] : [])
        ]
      },
      :SweetScent => {
        :option => 'Sweet Scent',
        :speech => 'Sweet Scent: please choose an option',
        :stock => [
          *(city_restored ? [:ELEMENTALSEED, :MAGICALSEED, :TELLURICSEED, :SYNTHETICSEED] : []),
          :HONEY, :ORANBERRY, :ROSEINCENSE, :FLORALCHARM, :SACHET, :POKESNAX
        ]
      },
      **(city_restored ? {:MadameMeganium => {
        :option => 'Madame Meganium',
        :speech => 'Madame Meganium: please choose an option',
        :stock => [:ENERGYROOT, :ENERGYPOWDER, :HEALPOWDER, :REVIVALHERB, :POWERHERB, :WHITEHERB]
      }} : {}),
      **(stickers >= 1 ? {:FriendshipBerries => {
        :option => 'Friendship Berries',
        :speech => 'Friendship Berries: please choose an option',
        :stock => [:POMEGBERRY, :KELPSYBERRY, :QUALOTBERRY, :TAMATOBERRY, :HONDEWBERRY, :GREPABERRY]
      }} : {}),
      **(stickers >= 1 ? {:StatusBerries => {
        :option => 'Status Berries',
        :speech => 'Status Berries: please choose an option',
        :stock => [:ORANBERRY, :CHERIBERRY, :PECHABERRY, :RAWSTBERRY, :CHESTOBERRY, :ASPEARBERRY, :PERSIMBERRY]
      }} : {}),
      **(stickers >= 1 ? {:TypeBerries => {
        :option => 'Type Berries',
        :speech => 'Type Berries: please choose an option',
        :stock => [:OCCABERRY, :PASSHOBERRY, :WACANBERRY, :RINDOBERRY, :YACHEBERRY, :PAYAPABERRY, :TANGABERRY, :CHARTIBERRY, :CHOPLEBERRY, :KEBIABERRY, :SHUCABERRY, :COBABERRY, :HABANBERRY, :KASIBBERRY, :COLBURBERRY, :BABIRIBERRY, :CHILANBERRY, :ROSELIBERRY]
      }} : {}),
      **(stickers >= 1 ? {:TypeGems => {
        :option => 'Type Gems',
        :speech => 'Type Gems: please choose an option',
        :stock => [:FIREGEM, :WATERGEM, :NORMALGEM, :GRASSGEM, :ELECTRICGEM, :POISONGEM, :GROUNDGEM, :FIGHTINGGEM, :FLYINGGEM, :PSYCHICGEM, :BUGGEM, :ROCKGEM, :GHOSTGEM, :DARKGEM, :DRAGONGEM, :STEELGEM, :ICEGEM, :FAIRYGEM]
      }} : {}),
      **(stickers >= 3 ? {:Consumables => {
        :option => 'Consumables',
        :speech => 'Consumables: please choose an option',
        :stock => [:BLASTPOWDER, :AIRBALLOON, :WHITEHERB, :MENTALHERB, :POWERHERB, :ABSORBBULB, :SNOWBALL]
      }} : {}),
      **(stickers >= 7 ? {:BattleItems => {
        :option => 'Battle Items',
        :speech => 'Battle Items: please choose an option',
        :stock => [:XATTACK, :XDEFEND, :XSPECIAL, :XSPEED, :XSPDEF, :GUARDSPEC, :XACCURACY, :DIREHIT]
      }} : {})
    }
    return options_map.map { |key, val| [key, val[:option]] } if option.nil?
    return options_map[option]
  end
  
  def swm_GlamazonShop_get_city_is_restored
    return $Trainer.numbadges >= 13
  end
  
  def swm_GlamazonShop_get_num_of_department_store_stickers
    var_name = 'Department Stickers'
    id = $cache.RXsystem.variables.index(var_name)
    return $game_variables[id] || 0
  end
  
  def swm_GlamazonShop_get_DefaultMart_stock
    case $Trainer.numbadges
      when 0
        stock = [:POTION, :ANTIDOTE, :POKEBALL]
      when 1
        stock = [:POTION, :ANTIDOTE, :PARLYZHEAL, :BURNHEAL, :ESCAPEROPE, :REPEL, :POKEBALL]
      when 2..5
        stock = [:SUPERPOTION, :ANTIDOTE, :PARLYZHEAL, :BURNHEAL, :ESCAPEROPE, :SUPERREPEL, :POKEBALL]
      when 6..9
        stock = [:SUPERPOTION, :ANTIDOTE, :PARLYZHEAL, :BURNHEAL, :ESCAPEROPE, :SUPERREPEL, :POKEBALL, :GREATBALL]
      when 10..12
        stock = [:POKEBALL, :GREATBALL, :ULTRABALL, :SUPERREPEL, :MAXREPEL, :ESCAPEROPE, :FULLHEAL, :HYPERPOTION]
      when 13..16
        stock = [:POKEBALL, :GREATBALL, :ULTRABALL, :SUPERREPEL, :MAXREPEL, :ESCAPEROPE, :FULLHEAL, :ULTRAPOTION]
      when 17
        stock = [:POKEBALL, :GREATBALL, :ULTRABALL, :SUPERREPEL, :MAXREPEL, :ESCAPEROPE, :FULLHEAL, :ULTRAPOTION,
                 :MAXPOTION]
      when 18
        stock = [:POKEBALL, :GREATBALL, :ULTRABALL, :SUPERREPEL, :MAXREPEL, :ESCAPEROPE, :FULLHEAL, :HYPERPOTION,
                 :ULTRAPOTION, :MAXPOTION, :FULLRESTORE, :REVIVE]
      else
        stock = [:POTION, :ANTIDOTE, :POKEBALL]
    end
    return stock
  end
  
  def swm_GlamazonShop_topMeUp_service
    loop do
      choice = swm_GlamazonShop_show_menu(
        _INTL('TopMeUp: which vendor?'),
        [
          #[:DefaultMart, 'PokéMart'],
          *swm_GlamazonShop_topMeUp_service_shops_texts(*swm_GlamazonShop_online_shop_by_option),
          [:CANCEL, 'Back']
        ]
      )
      break if choice.nil? || choice == :CANCEL
      shop = swm_GlamazonShop_online_shop_by_option(choice)
      swm_GlamazonShop_topMeUp_service_shop(shop)
    end
  end
  
  def swm_GlamazonShop_topMeUp_service_shops_texts(*shops)
    shops.each do |shop_entry|
      shop = swm_GlamazonShop_online_shop_by_option(shop_entry[0])
      count = 0
      total = 0
      shop[:stock].each do |itm|
        total += 1
        limit_lower = $game_screen.swm_GlamazonShop_topMeUp_get_item_lower_limit(itm)
        if !limit_lower.nil?
          count += 1
          next
        end
        limit_upper = $game_screen.swm_GlamazonShop_topMeUp_get_item_upper_limit(itm)
        if !limit_upper.nil?
          count += 1
          next
        end
      end
      if count != 0
        shop_entry[1] = _INTL('{1} ({2}/{3})', shop_entry[1], count, total)
      end
    end
  end
  
  def swm_GlamazonShop_topMeUp_service_shop(shop)
    loop do
      choice = swm_GlamazonShop_show_menu(
        _INTL('{1}: which item?', shop[:option]),
        [
          *shop[:stock].map { |itm| [itm, _INTL('{1}{2}', getItemName(itm), swm_GlamazonShop_topMeUp_service_item_limits_text(itm))] },
          [:CANCEL, 'Back']
        ]
      )
      break if choice.nil? || choice == :CANCEL
      swm_GlamazonShop_topMeUp_service_item(choice)
    end
  end
  
  def swm_GlamazonShop_topMeUp_service_item_limits_text(itm)
    limit_lower = $game_screen.swm_GlamazonShop_topMeUp_get_item_lower_limit(itm)
    limit_upper = $game_screen.swm_GlamazonShop_topMeUp_get_item_upper_limit(itm)
    return '' if limit_lower.nil? && limit_upper.nil?
    return _INTL(' (< {1})', limit_upper) if limit_lower.nil?
    return _INTL(' (> {1})', limit_lower) if limit_upper.nil?
    return _INTL(' ({1} < {2})', limit_lower, limit_upper)
  end
  
  def swm_GlamazonShop_topMeUp_service_item(item)
    price = $game_screen.swm_GlamazonShop_topMeUp_get_item_buy_price(item)
    current_qty = $PokemonBag.pbQuantity(item)
    loop do
      limit_lower = $game_screen.swm_GlamazonShop_topMeUp_get_item_lower_limit(item)
      limit_upper = $game_screen.swm_GlamazonShop_topMeUp_get_item_upper_limit(item)
      choice = swm_GlamazonShop_show_menu(
        _INTL('{1} (${2}) (in bag: {3}): which limit to edit?', getItemName(item), price, current_qty),
        [
          [:reset, 'Reset'],
          [:upper, limit_upper.nil? ? 'Upper' : _INTL('Upper ({1})', limit_upper)],
          [:lower, limit_lower.nil? ? 'Lower' : _INTL('Lower ({1})', limit_lower)],
          [:CANCEL, 'Back']
        ]
      )
      break if choice.nil? || choice == :CANCEL
      if choice == :reset
        $game_screen.swm_GlamazonShop_topMeUp_reset_item_limits(item)
        next
      end
      params = ChooseNumberParams.new
      params.setRange(0, 999)
      params.setDefaultValue(choice == :upper ? limit_upper : limit_lower)
      new_limit = Kernel.pbMessageChooseNumber(_INTL('Select a new {1} limit for {2}', choice == :upper ? 'upper' : 'lower', getItemName(item)), params)
      $game_screen.swm_GlamazonShop_topMeUp_set_item_lower_limit(item, new_limit) if choice == :lower
      $game_screen.swm_GlamazonShop_topMeUp_set_item_upper_limit(item, new_limit) if choice == :upper
    end
  end
  
  def swm_GlamazonShop_show_menu(title, items) # items is an array of [retval, text]
    options, choices = swm_GlamazonShop_menu_options(*items)
    choice = Kernel.pbMessage(
      title,
      choices,
      -1
    )
    return nil if choice < 0
    return options[choice]
  end
  
  def swm_GlamazonShop_menu_options(*items) # items is an array of [retval, text]
    options = []
    choices = []
    items.each do |itm|
      choices.push(options.push(itm[0]) && itm[1])
    end
    return options, choices
  end
end

PokemonPCList.registerPC(Swm_GlamazonShop_PC.new)

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
