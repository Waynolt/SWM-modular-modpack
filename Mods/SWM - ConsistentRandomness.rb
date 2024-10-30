#####MODDED
SWM_MIN_RANDOM_NUMBERS_LIST = 252

if !defined?(swm_consistentRandomness_oldrand)
  alias :swm_consistentRandomness_oldrand :rand # Just in case
end

$swm_consistentRandomness_oldRandom = Random if !defined?($swm_consistentRandomness_oldRandom) # Just in case

def rand(arg)
  return $game_screen.swm_consistentRandomness_getRandomNumber(arg)
end

class Random
  attr_accessor :swm_consistentRandomness_seed
  
  def initialize(*args, **kwargs)
    super(*args, **kwargs)
    @swm_consistentRandomness_seed = nil
  end
  
  def new_seed(*args, **kwargs)
    return @swm_consistentRandomness_seed if defined?(@swm_consistentRandomness_seed) && !@swm_consistentRandomness_seed.nil?
    @swm_consistentRandomness_seed = super(*args, **kwargs)
    return @swm_consistentRandomness_seed
  end
  
  def rand(arg)
    return $game_screen.swm_consistentRandomness_getRandomNumber(arg)
  end
end
#####/MODDED

# $swm_consistentRandomness_randomNumbers_persist Exists only to preserve randomness on the mod's first run when resetting
$game_screen.swm_consistentRandomness_reloadRandomNumber if defined?($game_screen)

class Game_Screen
  #####MODDED
  attr_accessor :swm_consistentRandomness_randomNumbers
  
  def initialize(*args, **kwargs)
    super(*args, **kwargs)
    if defined?(@swm_consistentRandomness_randomNumbers) && !@swm_consistentRandomness_randomNumbers.nil?
      swm_consistentRandomness_saveGlobalAndReturn(nil)
    else
      swm_consistentRandomness_reloadRandomNumber
    end
  end
  
  def swm_consistentRandomness_reloadRandomNumber
    if defined?($swm_consistentRandomness_randomNumbers_persist) && !$swm_consistentRandomness_randomNumbers_persist.nil?
      @swm_consistentRandomness_randomNumbers = Marshal.load(Marshal.dump($swm_consistentRandomness_randomNumbers_persist))
    else
      swm_consistentRandomness_saveGlobalAndReturn(nil)
    end
  end
  
  def swm_consistentRandomness_getRandomNumber(arg)
    return $game_screen.swm_consistentRandomness_getRandomNumberFromRange(0, arg) if arg.is_a?(Integer)
    if arg.is_a?(Range)
      arg_list = arg.to_a
      return $game_screen.swm_consistentRandomness_getRandomNumberFromRange(arg_list[0], arg_list[-1])
    end
    raise ArgumentError, "Unsupported argument type for rand: #{arg.class}"
  end
  
  def swm_consistentRandomness_getRandomNumberFromRange(min_num, max_num)
    key = "#{min_num}_#{max_num}"
    @swm_consistentRandomness_randomNumbers = {} if !defined?(@swm_consistentRandomness_randomNumbers) || @swm_consistentRandomness_randomNumbers.nil?
    return swm_consistentRandomness_saveGlobalAndReturn(swm_consistentRandomness_popFromArrAndEnsureLength(@swm_consistentRandomness_randomNumbers[key], min_num, max_num), key) if defined?(@swm_consistentRandomness_randomNumbers[key]) && !@swm_consistentRandomness_randomNumbers[key].nil? && @swm_consistentRandomness_randomNumbers[key] && @swm_consistentRandomness_randomNumbers[key].length > 0
    new_arr = []
    retval = swm_consistentRandomness_popFromArrAndEnsureLength(new_arr, min_num, max_num)
    @swm_consistentRandomness_randomNumbers[key] = new_arr
    return swm_consistentRandomness_saveGlobalAndReturn(retval, key)
  end
  
  def swm_consistentRandomness_popFromArrAndEnsureLength(arr_out, min_num, max_num)
    min_list_length = [max_num - min_num + 1, SWM_MIN_RANDOM_NUMBERS_LIST].max # This ensures that we'll pretty much never find a situation where a new range is generated and then immediately used
    while arr_out.length <= min_list_length do
      # Generate a new range and the add it at the start of the array
      arr_out.unshift(*(min_num...max_num).to_a.shuffle)
    end
    return arr_out.pop
  end
  
  def swm_consistentRandomness_saveGlobalAndReturn(retval, key = nil)
    $swm_consistentRandomness_randomNumbers_persist = Marshal.load(Marshal.dump(@swm_consistentRandomness_randomNumbers)) if !defined?($swm_consistentRandomness_randomNumbers_persist) || $swm_consistentRandomness_randomNumbers_persist.nil?
    return retval if key.nil?
    $swm_consistentRandomness_randomNumbers_persist[key] = Marshal.load(Marshal.dump(@swm_consistentRandomness_randomNumbers[key])) if !defined?($swm_consistentRandomness_randomNumbers_persist[key]) || $swm_consistentRandomness_randomNumbers_persist[key].nil? || !$swm_consistentRandomness_randomNumbers_persist[key] || $swm_consistentRandomness_randomNumbers_persist[key].length <= 0
    return retval
  end
  #####/MODDED
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_consistentRandomness_target_version = '19'
if !GAMEVERSION.start_with?(swm_consistentRandomness_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_consistentRandomness_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
