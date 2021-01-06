class PokemonDataBox < SpriteWrapper
  #####MODDED
  def aTypeBattleIcons
    typebitmap=AnimatedBitmap.new(_INTL("Data/Mods/SWM - TypeBattleIcons"))
    
    if isConst?(@battler.ability,PBAbilities,:ILLUSION)
      if @battler.effects[PBEffects::Illusion] == nil
        aType1 = @battler.type1
        aType2 = @battler.type2
      else
        aType1 = @battler.effects[PBEffects::Illusion].type1
        aType2 = @battler.effects[PBEffects::Illusion].type2
      end
    else
      aType1 = @battler.type1
      aType2 = @battler.type2
    end
    
    type1rect=Rect.new(0,aType1*14+3,32,8)
    type2rect=Rect.new(0,aType2*14+3,32,8)
    
    if aType1==aType2
      self.bitmap.blt(@spritebaseX+8,3,typebitmap.bitmap,type1rect)
    else
      self.bitmap.blt(@spritebaseX+8,3,typebitmap.bitmap,type1rect)
      self.bitmap.blt(@spritebaseX+42,3,typebitmap.bitmap,type2rect)
    end
  end
  #####/MODDED
  
  def refresh
    self.bitmap.clear
    return if !@battler.pokemon
    self.bitmap.blt(0,0,@databox.bitmap,Rect.new(0,0,@databox.width,@databox.height))
    base=PokeBattle_SceneConstants::BOXTEXTBASECOLOR
    shadow=PokeBattle_SceneConstants::BOXTEXTSHADOWCOLOR
    pokename=@battler.name
    pbSetSystemFont(self.bitmap)
    textpos=[
       [pokename,@spritebaseX+8,6,false,base,shadow]
    ]
    genderX=self.bitmap.text_size(pokename).width
    genderX+=@spritebaseX+14
    if @battler.gender==0 # Male
      textpos.push([_INTL("♂"),genderX,6,false,Color.new(48,96,216),shadow])
    elsif @battler.gender==1 # Female
      textpos.push([_INTL("♀"),genderX,6,false,Color.new(248,88,40),shadow])
    end
    pbDrawTextPositions(self.bitmap,textpos)
    pbSetSmallFont(self.bitmap)
    if !$MKXP
        textpos=[[_INTL("Lv{1}",@battler.level),@spritebaseX+202,8,true,base,shadow]]
      else
        textpos=[[_INTL("Lv{1}",@battler.level),@spritebaseX+202,12,true,base,shadow]]
      end
    
    if @showhp
      hpstring=_ISPRINTF("{1: 2d}/{2: 2d}",self.hp,@battler.totalhp)
      if !$MKXP
        textpos.push([hpstring,@spritebaseX+188,48,true,base,shadow])
      else
        textpos.push([hpstring,@spritebaseX+188,52,true,base,shadow])
      end
    end
    pbDrawTextPositions(self.bitmap,textpos)
    imagepos=[]
    if @battler.pokemon.isShiny?
      shinyX=206
      shinyX=2 if (@battler.index&1)==0 # If player's Pokémon
      imagepos.push(["Graphics/Pictures/shiny.png",@spritebaseX+shinyX,36,0,0,-1,-1])
    end
    megaY=34
    megaY=50 if (@battler.index&1)==0 # If player's Pokémon
    megaX=8
    megaX=12 if (@battler.index&1)==0 # If player's Pokémon
    if @battler.isMega? && @battler.item==606 && $game_switches[457] ==  true
      imagepos.push(["Graphics/Pictures/battlePulseEvoBox.png",@spritebaseX+megaX,megaY,0,0,-1,-1])
    elsif @battler.isMega?
      imagepos.push(["Graphics/Pictures/battleMegaEvoBox.png",@spritebaseX+megaX,megaY,0,0,-1,-1])
    elsif @battler.isUltra? # Maybe temporary until new icon
      imagepos.push(["Graphics/Pictures/battleMegaEvoBox.png",@spritebaseX+megaX,megaY,0,0,-1,-1])      
    end
    if @battler.owned && (@battler.index&1)==1
      imagepos.push(["Graphics/Pictures/battleBoxOwned.png",@spritebaseX+8,36,0,0,-1,-1])
    end
    pbDrawImagePositions(self.bitmap,imagepos)
    if @battler.status>0
      self.bitmap.blt(@spritebaseX+24,36,@statuses.bitmap,
         Rect.new(0,(@battler.status-1)*16,44,16))
    end
    hpGaugeSize=PokeBattle_SceneConstants::HPGAUGESIZE
    hpgauge=@battler.totalhp==0 ? 0 : (self.hp*hpGaugeSize/@battler.totalhp)
    hpgauge=2 if hpgauge==0 && self.hp>0
    hpzone=0
    hpzone=1 if self.hp<=(@battler.totalhp/2).floor
    hpzone=2 if self.hp<=(@battler.totalhp/4).floor
    hpcolors=[
       PokeBattle_SceneConstants::HPCOLORGREENDARK,
       PokeBattle_SceneConstants::HPCOLORGREEN,
       PokeBattle_SceneConstants::HPCOLORYELLOWDARK,
       PokeBattle_SceneConstants::HPCOLORYELLOW,
       PokeBattle_SceneConstants::HPCOLORREDDARK,
       PokeBattle_SceneConstants::HPCOLORRED
    ]
    # fill with black (shows what the HP used to be)
    hpGaugeX=PokeBattle_SceneConstants::HPGAUGE_X
    hpGaugeY=PokeBattle_SceneConstants::HPGAUGE_Y
    if @animatingHP && self.hp>0
      self.bitmap.fill_rect(@spritebaseX+hpGaugeX,hpGaugeY,
         @starthp*hpGaugeSize/@battler.totalhp,6,Color.new(0,0,0))
    end
    # fill with HP color
    self.bitmap.fill_rect(@spritebaseX+hpGaugeX,hpGaugeY,hpgauge,2,hpcolors[hpzone*2])
    self.bitmap.fill_rect(@spritebaseX+hpGaugeX,hpGaugeY+2,hpgauge,4,hpcolors[hpzone*2+1])
    if @showexp
      # fill with EXP color
      expGaugeX=PokeBattle_SceneConstants::EXPGAUGE_X
      expGaugeY=PokeBattle_SceneConstants::EXPGAUGE_Y
      self.bitmap.fill_rect(@spritebaseX+expGaugeX,expGaugeY,self.exp,2,
         PokeBattle_SceneConstants::EXPCOLORSHADOW)
      self.bitmap.fill_rect(@spritebaseX+expGaugeX,expGaugeY+2,self.exp,2,
         PokeBattle_SceneConstants::EXPCOLORBASE)
    end
    
    #####MODDED
    aTypeBattleIcons
    aShowStatBoosts if defined?(aShowStatBoosts)
    #####/MODDED
  end
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
