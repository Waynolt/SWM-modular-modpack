#####MODDED
if defined?($hitsRemoved)
  $hitsRemoved=0
end

def swm_getDrawnTextWOutline(outline, text, fontSize)
  height=(fontSize*4/3).round
  bitmap=Bitmap.new(Graphics.width, height)
  bitmap.font.name='Arial Black' # $VersionStyles[$PokemonSystem.font]
  bitmap.font.size=fontSize
  bitmap.font.color.set(0, 0, 0)
  bitmap.draw_text(0, 0, bitmap.width, bitmap.height, text, 0)
  
  bitmap2=Bitmap.new(Graphics.width, height)
  for i in 0...(outline*2+1)
    bitmap2.blt(0, i, bitmap, bitmap.rect)
  end
  
  bitmap3 = Bitmap.new(Graphics.width, height)
  bitmap3.blt(0, 0, bitmap2, bitmap2.rect)
  
  for i in 0...(outline*2+1)
    bitmap2.blt(i, 0, bitmap3, bitmap3.rect)
  end
  
  bitmap.font.color.set(255, 255, 255)
  bitmap.draw_text(outline, outline, bitmap.width, bitmap.height, text, 0)
  bitmap2.blt(0, 0, bitmap, bitmap.rect)
  
  return bitmap2
end

def swm_getHitCost(hitsToRemove, registerNewCount)
  baseCost=swm_getBaseHitCost
  count=swm_getHitsCount(hitsToRemove, registerNewCount)
  return count*baseCost
end

def swm_getHitsCount(hitsToRemove, registerNewCount)
  if defined?($hitsRemoved)
    count=$hitsRemoved
  else
    count=0
  end
  count+=hitsToRemove
  $hitsRemoved=count if registerNewCount
  return count
end

def swm_getBaseHitCost
  return 10 if !defined?($idk[:settings].amb_additionalMiningCost)
  return $idk[:settings].amb_additionalMiningCost
end
#####/MODDED

class MiningGameCounter < BitmapSprite
  #####MODDED
  def swm_resetMiningCounters
    @swm_oldCost=nil
    $hitsRemoved=0
  end

  def swm_notifyNextHit
    bmps=swm_getMiningBmps
    self.bitmap.blt(5, 0, bmps[0], bmps[0].rect)
    self.bitmap.blt(5, 25, bmps[1], bmps[1].rect)
  end

  def swm_getMiningBmps
    return @swm_miningBmps if !swm_shouldResetMiningBmps?
    lines=swm_getMiningCostLines
    bmps=[
      swm_getDrawnTextWOutline(2, lines[0], 18),
      swm_getDrawnTextWOutline(2, lines[1], 18)
    ]
    @swm_miningBmps=bmps
    return @swm_miningBmps
  end

  def swm_shouldResetMiningBmps?
    return true if swm_checkCostChanged?
    return true if !defined?(@swm_miningBmps)
    return true if @swm_miningBmps[0].disposed?
    return true if @swm_miningBmps[1].disposed?
    return false
  end

  def swm_checkCostChanged?
    cost=swm_getHitCost(0, false)
    return false if defined?(@swm_oldCost) && @swm_oldCost == cost
    @swm_oldCost=cost
    return true
  end

  def swm_getMiningCostLines
    hitsRemoved=swm_getHitsCount(0, false)
    return ['', ''] if hitsRemoved <= 0
    pickaxeHits=1
    hammerHits=2
    pickaxeCost=swm_getHitCost(pickaxeHits, false)
    hammerCost=swm_getHitCost(hammerHits, false)
    textA=_INTL(
      'Next hit will cost ${1} (pick) or ${2} (hammer)',
      pickaxeCost,
      hammerCost
    )
    textB=_INTL('You still have ${1}', $Trainer.money)
    return [textA, textB]
  end

  if !defined?(swm_miningForRich_oldInitialize)
    alias :swm_miningForRich_oldInitialize :initialize
  end

  if !defined?(swm_miningForRich_oldUpdate)
    alias :swm_miningForRich_oldUpdate :update
  end
  #####/MODDED

  def initialize(*args, **kwargs)
    result=swm_miningForRich_oldInitialize(*args, **kwargs)
    swm_resetMiningCounters
    return result
  end

  def update(*args, **kwargs)
    result=swm_miningForRich_oldUpdate(*args, **kwargs)
    swm_notifyNextHit
    return result
  end
end

class MiningGameScene
  #####MODDED
  def swm_payToMine
    hitsToRemove=swm_getHitsToRemove
    return nil if hitsToRemove <= 0
    cost=swm_getHitCost(hitsToRemove, true)
    if $Trainer.money < cost
      Kernel.pbMessage(_INTL('You can\'t afford to mine any more!'))
      return nil
    end
    @sprites["crack"].hits-=hitsToRemove
    $Trainer.money-=cost
  end

  def swm_getHitsToRemove
    return @sprites["crack"].hits-48
  end

  if !defined?(swm_miningForRich_oldPbHit)
    alias :swm_miningForRich_oldPbHit :pbHit
  end
  #####/MODDED

  def pbHit(*args, **kwargs)
    result=swm_miningForRich_oldPbHit(*args, **kwargs)
    swm_payToMine
    return result
  end
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version='19'
if !getversion().start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
