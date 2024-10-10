$swm_typeBitmaps = nil # Force the reloading of disposed graphics on soft resetting
class PokemonDataBox < SpriteWrapper
  #####MODDED
  def swm_setTypeBattleIcons
    swm_ensureTypeBitmaps
    type1, type2 = swm_getBattlerTyping
    baseX, baseY = swm_getBaseTypeCoords
    self.bitmap.blt(baseX,baseY,$swm_typeBitmaps[type1],$swm_typeBitmaps[type1].rect)
    if !type2.nil? && (type1 != type2)
      dist = $swm_typeBitmaps[type1].rect.width # +3
      self.bitmap.blt(baseX+dist,baseY,$swm_typeBitmaps[type2],$swm_typeBitmaps[type2].rect)
    end
  end

  def swm_getBaseTypeCoords
    if @doublebattle
      baseX = @spritebaseX+8
      baseY = @spritebaseY-1
    else
      baseX = @spritebaseX+8
      baseY = @spritebaseY-1
    end
    return baseX, baseY
  end

  def swm_ensureTypeBitmaps
    return nil if !swm_shouldLoadTypeBitmaps
    rawBmp = AnimatedBitmap.new('patch/Mods/SWM - TypeBattleIcons.png')
    retval = {}
    spriteWidth = 32
    spriteHeight = 12
    map = [
      :NORMAL,
      :FIGHTING,
      :FLYING,
      :POISON,
      :GROUND,
      :ROCK,
      :BUG,
      :GHOST,
      :STEEL,
      :QMARKS,
      :FIRE,
      :WATER,
      :GRASS,
      :ELECTRIC,
      :PSYCHIC,
      :ICE,
      :DRAGON,
      :DARK,
      :FAIRY,
      :SHADOW
    ]
    for i in 0..PBTypes.maxValue
      rect = Rect.new(0,i*spriteHeight,spriteWidth,spriteHeight)
      bitmap = Bitmap.new(rect.width, rect.height)
      bitmap.blt(0, 0, rawBmp.bitmap, rect)
      retval[map[i]] = bitmap
      retval[i] = bitmap
    end
    $swm_typeBitmaps = retval
  end

  def swm_shouldLoadTypeBitmaps
    return true if !defined?($swm_typeBitmaps)
    return true if !$swm_typeBitmaps
    for i in 0..PBTypes.maxValue
      return true if !$swm_typeBitmaps[i]
      return true if $swm_typeBitmaps[i].disposed?
    end
    return false
  end

  def swm_getBattlerTyping
    if (@battler.ability == :ILLUSION) && @battler.effects[:Illusion]
      # Zorua
      type1 = @battler.effects[:Illusion].type1
      type2 = @battler.effects[:Illusion].type2
    else
      type1 = @battler.type1
      type2 = @battler.type2
    end
    return type1, type2
  end

  if !defined?(swm_typeBattleIcons_oldRefresh)
    alias :swm_typeBattleIcons_oldRefresh :refresh
  end
  #####/MODDED

  def refresh(*args, **kwargs)
    #####MODDED
    result = swm_typeBattleIcons_oldRefresh(*args, **kwargs)
    swm_setTypeBattleIcons
    return result
    #####/MODDED
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
