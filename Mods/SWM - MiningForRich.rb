class MiningGameScene
  def pbHit
    #####MODDED
    #Ensure compatibility with the mouse mod
    if defined?(aInterceptClick())
      return if aInterceptClick()
    end
    #####/MODDED
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
    aPayToMine() #####MODDED
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
  
  #####MODDED
  def aPayToMine()
    if @sprites["crack"].hits < 15
      #We're just starting mining
      $aMiningCost = 0
    end
    if @sprites["crack"].hits >= 49
      if defined?($PokemonSystem.additionalMiningCost)
        aMineCost = $PokemonSystem.additionalMiningCost
      else
        aMineCost = 10
      end
      $aMiningCost = $aMiningCost+(@sprites["crack"].hits-48)*aMineCost
      
      if $Trainer.money >= $aMiningCost
        @sprites["crack"].hits = 48
        $Trainer.money = $Trainer.money-$aMiningCost
      else
        Kernel.pbMessage("You can't afford to mine any more!")
      end
    end
  end
  #####/MODDED
end

#####MODDED
def aGetDrawnTextWOutline(outline, sText)
	bitmap = Bitmap.new(Graphics.width, 24)
	bitmap.font.name = $VersionStyles[$PokemonSystem.font]
	bitmap.font.size = 24
	bitmap.font.color.set(0, 0, 0)
	bitmap.draw_text(0, 0, bitmap.width, bitmap.height, sText, 0)
	
	
	bitmap2 = Bitmap.new(Graphics.width, 24)
	for i in 0...(outline*2+1)
		bitmap2.blt(0, i, bitmap, bitmap.rect)
	end
	
	bitmap3 = Bitmap.new(Graphics.width, 24)
	bitmap3.blt(0, 0, bitmap2, bitmap2.rect)
	
	for i in 0...(outline*2+1)
		bitmap2.blt(i, 0, bitmap3, bitmap3.rect)
	end
	
	bitmap.font.color.set(255, 255, 255)
	bitmap.draw_text(outline, outline, bitmap.width, bitmap.height, sText, 0)
	bitmap2.blt(0, 0, bitmap, bitmap.rect)
	
	return bitmap2
end
#####/MODDED

class MiningGameCounter < BitmapSprite
  def update
    self.bitmap.clear
    value=@hits
    startx=416-48
    while value>6
      self.bitmap.blt(startx,0,@image.bitmap,Rect.new(0,0,48,52))
      startx-=48
      value-=6
    end
    startx-=48
    if value>0
      self.bitmap.blt(startx,0,@image.bitmap,Rect.new(0,value*52,96,52))
    end
	
    #####MODDED
    #Let the player know what's happening
    if @hits >= 48 && defined?($aMiningCost)
      if $aMiningCost > 0
        #Next cost
        if defined?($PokemonSystem.additionalMiningCost)
          aMineCost = $PokemonSystem.additionalMiningCost
        else
          aMineCost = 10
        end
        sTxt1 = _INTL("Next hit will cost ${1} +${2} (pick) or +${3} (hammer)", $aMiningCost, aMineCost, 2*aMineCost)
        
        #Current money
        sTxt2 = _INTL("You still have ${1}", $Trainer.money)
        
        #Print it
        sTxt = sTxt1+sTxt2
        $aOldMiningTxt = "" if !defined?($aOldMiningTxt)
        if sTxt != $aOldMiningTxt
          $aOldMiningTxt = sTxt
          
          $aMiningBmp1 = aGetDrawnTextWOutline(2, sTxt1)
          $aMiningBmp2 = aGetDrawnTextWOutline(2, sTxt2)
        end
        self.bitmap.blt(5, 0, $aMiningBmp1, $aMiningBmp1.rect)
        self.bitmap.blt(5, 25, $aMiningBmp2, $aMiningBmp2.rect)
      end
    end
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
