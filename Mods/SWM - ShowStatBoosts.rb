class AnimatedBitmap
  #####MODDED
  def aSetBitmap(bitmap)
    @bitmap.aSetBitmap(bitmap)
  end
  #####/MODDED
end
class GifBitmap
  #####MODDED
  def aSetBitmap(bitmap)
    @gifbitmaps[@currentIndex] = bitmap
  end
  #####/MODDED
end

class PokemonDataBox < SpriteWrapper
  #####MODDED
  def aGetStage(i)
    if i == 3
      return -6 if @battler.pbOpposingSide.effects[PBEffects::LuckyChant] > 0
      return 6 if @battler.effects[PBEffects::LaserFocus]
      return @battler.effects[PBEffects::FocusEnergy]
    else
      case i
        when 0
          stat = PBStats::SPATK
        when 1
          stat = PBStats::SPDEF
        when 2
          stat = PBStats::SPEED
        when 4
          stat = PBStats::ATTACK
        when 5
          stat = PBStats::DEFENSE
        when 6
          stat = PBStats::EVASION
        when 7
          stat = PBStats::ACCURACY
      end
      
      return @battler.stages[stat]
    end
  end
  
  def aShowStatBoosts
    #Init
    bIsFoe = ((@battler.index == 1) || (@battler.index == 3))
    
    if defined?(@aStatBoostsG) && defined?(@aStatBoostsN) && defined?(@aStatBoostsL)
      #Build bitmap
      aBitmap = Bitmap.new(83, 50)
      
      for i in 0...8
        iStage = aGetStage(i)
        
        if bIsFoe
          iOffsetX = 2
        else
          iOffsetX = 0
        end
        
        if i < 4
          iCol = 21+iOffsetX
          iRow = i
        else
          iCol = 31+iOffsetX
          iRow = i-4
        end
        
        if iStage == 0
          aBitmap.blt(0, 0, @aStatBoostsN[i], aBitmap.rect)
        elsif iStage > 0
          iNum = iStage-1
          aBitmap.blt(0, 0, @aStatBoostsG[i], aBitmap.rect)
          aBitmap.blt(iCol, 4+12*iRow, @aStatBoostsNumG[iNum], @aStatBoostsNumG[iNum].rect)
        elsif iStage < 0
          iNum = -iStage-1
          aBitmap.blt(0, 0, @aStatBoostsL[i], aBitmap.rect)
          aBitmap.blt(iCol, 4+12*iRow, @aStatBoostsNumL[iNum], @aStatBoostsNumL[iNum].rect)
        end
      end
      
      #Draw tab
      if self.bitmap.width == 260
        if !bIsFoe && false
          #Adding to the left is more difficult
          aTemp = Bitmap.new(@databox.bitmap.width+56-@spritebaseX, @databox.bitmap.height)
          iDiff = aTemp.width-@databox.bitmap.width
          
          @spritebaseX = @spritebaseX+iDiff
          @spriteX = @spriteX-iDiff
          aTemp.blt(iDiff, 0, @databox.bitmap, @databox.bitmap.rect)
          
          @databox.aSetBitmap(aTemp)
        end
        
        aTemp = Bitmap.new(@spritebaseX+228+56, self.bitmap.height)
        aTemp.blt(0, 0, self.bitmap, self.bitmap.rect)
        
        self.bitmap = aTemp
      else
        if bIsFoe
          self.bitmap.blt(@spritebaseX+228, 0, aBitmap, aBitmap.rect)
        else
          self.bitmap.blt(@spritebaseX-56, 0, aBitmap, aBitmap.rect)
        end
      end
    else
      if (!bIsFoe) && (@databox.bitmap.width == 260)
        #Adding to the left is more difficult
        aTemp = Bitmap.new(@databox.bitmap.width+56-@spritebaseX, @databox.bitmap.height)
        iDiff = aTemp.width-@databox.bitmap.width
        
        @spritebaseX = @spritebaseX+iDiff
        @spriteX = @spriteX-iDiff
        aTemp.blt(iDiff, 0, @databox.bitmap, @databox.bitmap.rect)
        
        @databox.aSetBitmap(aTemp)
      end
      
      aInitStatsTab(bIsFoe)
    end
  end
  
  def aInitStatsTab(bIsFoe)
    aBitmap = AnimatedBitmap.new(_INTL("Data/Mods/SWM - ShowStatBoosts"))
    
    #Constants
    iWidth_Full = 56
    iHeight_Full = 50
    
    iLeft1 = 0
    iLeft2P = 27
    iLeft2F = 29
    
    iRow_Dist = 12
    iRow_Height = 14
    
    iCol_WidthL = 31
    iCol_WidthR = 27
    iCol_WidthP = 29
    
    iBorder = 2
    
    iLeft_NF1 = 0
    iLeft_LF1 = iWidth_Full+iLeft_NF1
    iLeft_GF1 = iWidth_Full+iLeft_LF1
    iLeft_NF2 = iLeft_NF1+iCol_WidthL-iBorder
    iLeft_LF2 = iWidth_Full+iLeft_NF2
    iLeft_GF2 = iWidth_Full+iLeft_LF2
    
    iLeft_NP1 = 2
    iLeft_LP1 = iWidth_Full+iLeft_NP1
    iLeft_GP1 = iWidth_Full+iLeft_LP1
    iLeft_NP2 = iLeft_NP1+iCol_WidthP-iBorder
    iLeft_LP2 = iWidth_Full+iLeft_NP2
    iLeft_GP2 = iWidth_Full+iLeft_LP2
    
    #Get bitmaps
    @aStatBoostsG = [] #Greater
    @aStatBoostsN = [] #None
    @aStatBoostsL = [] #Lower
    for i in 0...8
      @aStatBoostsG[i] = Bitmap.new(iWidth_Full, iHeight_Full)
      @aStatBoostsN[i] = Bitmap.new(iWidth_Full, iHeight_Full)
      @aStatBoostsL[i] = Bitmap.new(iWidth_Full, iHeight_Full)
    end
    
    @aStatBoostsNumG = []
    @aStatBoostsNumL = []
    
    for i in 0...4
      i2 = 4+i #Right half of the tab
      
      iHL = i*12
      iHL2 = iHL+iHeight_Full
      
      if bIsFoe
        aRect = Rect.new(iLeft_GF1, iHL, iCol_WidthL, iRow_Height)
        @aStatBoostsG[i].blt(iLeft1, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_NF1, iHL, iCol_WidthL, iRow_Height)
        @aStatBoostsN[i].blt(iLeft1, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_LF1 , iHL, iCol_WidthL, iRow_Height)
        @aStatBoostsL[i].blt(iLeft1, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_GF2, iHL, iCol_WidthR, iRow_Height)
        @aStatBoostsG[i2].blt(iLeft2F, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_NF2, iHL, iCol_WidthR, iRow_Height)
        @aStatBoostsN[i2].blt(iLeft2F, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_LF2, iHL, iCol_WidthR, iRow_Height)
        @aStatBoostsL[i2].blt(iLeft2F, iHL, aBitmap.bitmap, aRect)
      else
        aRect = Rect.new(iLeft_GP1, iHL2, iCol_WidthP, iRow_Height)
        @aStatBoostsG[i].blt(iLeft1, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_NP1, iHL2, iCol_WidthP, iRow_Height)
        @aStatBoostsN[i].blt(iLeft1, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_LP1, iHL2, iCol_WidthP, iRow_Height)
        @aStatBoostsL[i].blt(iLeft1, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_GP2, iHL2, iCol_WidthP, iRow_Height)
        @aStatBoostsG[i2].blt(iLeft2P, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_NP2, iHL2, iCol_WidthP, iRow_Height)
        @aStatBoostsN[i2].blt(iLeft2P, iHL, aBitmap.bitmap, aRect)
        
        aRect = Rect.new(iLeft_LP2, iHL2, iCol_WidthP, iRow_Height)
        @aStatBoostsL[i2].blt(iLeft2P, iHL, aBitmap.bitmap, aRect)
      end
    end
    for i in 0...6
      @aStatBoostsNumG[i] = Bitmap.new(4, 6)
      aRect = Rect.new(172, 1+(i*7), 4, 6)
      @aStatBoostsNumG[i].blt(0, 0, aBitmap.bitmap, aRect)
      
      @aStatBoostsNumL[i] = Bitmap.new(4, 6)
      aRect = Rect.new(168, 1+(i*7), 4, 6)
      @aStatBoostsNumL[i].blt(0, 0, aBitmap.bitmap, aRect)
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
    aTypeBattleIcons if defined?(aTypeBattleIcons)
    aShowStatBoosts
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
