def pbSetSpritesToColor(sprites,color)
  return if !sprites||!color
  colors={}
  for i in sprites
    next if !i[1] || pbDisposed?(i[1])
    colors[i[0]]=i[1].color.clone
    i[1].color=pbSrcOver(i[1].color,color)
  end
  #####MODDED, was Graphics.update
  #####MODDED, was Input.update
  for i in colors
    next if !sprites[i[0]]
    sprites[i[0]].color=i[1]
  end
end

def pbFadeOutIn(z)
  col=Color.new(0,0,0,0)
  viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z=z
  for j in 0..17
    col.set(0,0,0,j*15)
    viewport.color=col
    #####MODDED, was Graphics.update
    #####MODDED, was Input.update
  end
  Graphics.update #####MODDED
  Input.update #####MODDED
  pbPushFade
  begin
    yield if block_given?
  ensure
    pbPopFade
    for j in 0..17
      col.set(0,0,0,(17-j)*15)
      viewport.color=col
      #####MODDED, was Graphics.update
      #####MODDED, was Input.update
    end
    Graphics.update #####MODDED
    Input.update #####MODDED
    viewport.dispose
  end
end

module Graphics
  #####MODDED
  if !defined?(self.swm_snappyMenus_oldTransition)
    class <<self
      alias_method :swm_snappyMenus_oldTransition, :transition
    end
  end
  def self.transition(*args, **kwargs)
    return self.swm_snappyMenus_oldTransition(0)
  end
  #####/MODDED
end

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
