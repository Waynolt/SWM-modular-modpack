class PokemonBoxSprite < SpriteWrapper
  #####MODDED
  def aDoBlt(aBitmap, iIndex)
    aSprite = getPokemon(iIndex)
    @contents.blt(aSprite.x+(aSprite.bitmap.width/16)-self.x, aSprite.y+(aSprite.bitmap.height/3)-self.y, aBitmap.bitmap, aBitmap.bitmap.rect)
  end
  #####/MODDED
end

class PokemonStorageScene
  #####MODDED
  def aUpdateMultiSelectOverlay(iBox = @storage.currentBox)
    if defined?(@aMultiSelectedMons)
      @sprites["box"].refreshBox=true
      @sprites["box"].color=Color.new(248,248,248,0)
      
      if @aMultiSelectedMons.length > 0
        aBitmap = AnimatedBitmap.new(_INTL("Data/Mods/SWM - MultiSelectPC"))
        
        for aEntry in @aMultiSelectedMons
          if aEntry[0] == iBox
            @sprites["box"].aDoBlt(aBitmap, aEntry[1])
          end
        end
      end
    end
  end
  
  def aUpdateMultiSelArray(aNewArr)
    @aMultiSelectedMons = aNewArr
  end
  def aGetMultiSelArray
    @aMultiSelectedMons = [] if !defined?(@aMultiSelectedMons)
    return @aMultiSelectedMons
  end
  #####/MODDED
  
  def pbSelectBox(party)
    if @command==2 # Withdraw
      return pbSelectBoxInternal(party)
    else
      ret=nil
      loop do
        if !@choseFromParty
          ret=pbSelectBoxInternal(party)
        end
        if @choseFromParty || (ret && ret[0]==-2) # Party Pokémon
          if !@choseFromParty
            pbDropDownPartyTab
            @selection=0
          end
          ret=pbSelectPartyInternal(party,false)
          if ret<0
            pbHidePartyTab
            @selection=0
            @choseFromParty=false
          else
            @choseFromParty=true
            return [-1,ret]
          end
        else
          @choseFromParty=false
          #####MODDED
          if (ret != nil) && defined?(@aMultiSelectedMons)
            if (ret[0] >= 0) && !@storage[ret[0],ret[1]] && @aMultiSelectedMons.length > 0
              iCh = Kernel.pbMessage("What do you want to do?", ["Move multiselection", "Clear multiselection", "Cancel"], 3)
              
              if iCh != 2
                if iCh == 0
                  iBox = ret[0]
                  iIndex = ret[1]
                  
                  for aEntry in @aMultiSelectedMons
                    bFound = true
                    while @storage[iBox, iIndex]
                      iIndex = iIndex+1
                      if iIndex >= $PokemonStorage[iBox].length
                        iBox = iBox+1
                        iIndex = 0
                        
                        if iBox >= $PokemonStorage.maxBoxes
                          Kernel.pbMessage("There is not enough space here.")
                          bFound = false
                          break
                        end
                      end
                    end
                    
                    if bFound
                      $PokemonStorage[iBox][iIndex] = $PokemonStorage[aEntry[0]][aEntry[1]]
                      $PokemonStorage[aEntry[0]][aEntry[1]] = nil
                    else
                      break
                    end
                  end
                  
                  @sprites["box"].dispose
                  @sprites["box"] = PokemonBoxSprite.new(@storage, ret[0], @boxviewport)
                end
                
                @aMultiSelectedMons = []
                @sprites["box"].refreshBox=true
                @sprites["box"].color=Color.new(248,248,248,0)
                
                ret = [-2, -1] if !@sprites["arrow"].heldPokemon
              end
            end
          end
          #####/MODDED
          return ret
        end
      end
    end
  end
  
  def pbSwitchBoxToRight(newbox)
    iNewBox = newbox #####MODDED
    
    newbox=PokemonBoxSprite.new(@storage,newbox,@boxviewport)
    newbox.x=520
    Graphics.frame_reset
    begin
      Graphics.update
      Input.update
      @sprites["box"].x-=32
      newbox.x-=32
      pbUpdateSpriteHash(@sprites)
    end until newbox.x<=184
    diff=newbox.x-184
    newbox.x=184; @sprites["box"].x-=diff
    @sprites["box"].dispose
    @sprites["box"]=newbox
    
    aUpdateMultiSelectOverlay(iNewBox) #####MODDED
  end

  def pbSwitchBoxToLeft(newbox)
    iNewBox = newbox #####MODDED
    
    newbox=PokemonBoxSprite.new(@storage,newbox,@boxviewport)
    newbox.x=-152
    Graphics.frame_reset
    begin
      Graphics.update
      Input.update
      @sprites["box"].x+=32
      newbox.x+=32
      pbUpdateSpriteHash(@sprites)
    end until newbox.x>=184
    diff=newbox.x-184
    newbox.x=184; @sprites["box"].x-=diff
    @sprites["box"].dispose
    @sprites["box"]=newbox
    
    aUpdateMultiSelectOverlay(iNewBox) #####MODDED
  end
end
  
class PokemonStorageScreen
  def pbHold(selected)
    #####MODDED
    if (selected[0] >= 0) && Input.press?(Input::CTRL)
      aMultiSelectedMons = @scene.aGetMultiSelArray
      
      bShouldAdd = true
      aTemp = []
      for aEntry in aMultiSelectedMons
        bNotFound = true
        
        if aEntry[0] == selected[0] #Box
          if aEntry[1] == selected[1] #Index
            bNotFound = false
            bShouldAdd = false
          end
        end
        
        aTemp.push(aEntry) if bNotFound
      end
      
      aTemp.push(selected) if bShouldAdd
      
      @scene.aUpdateMultiSelArray(aTemp)
      
      @scene.aUpdateMultiSelectOverlay()
    else
    #####/MODDED
    box=selected[0]
    index=selected[1]
    if box==-1 && pbAble?(@storage[box,index]) && pbAbleCount<=1
      pbDisplay(_INTL("That's your last Pokémon!"))
      return
    end
    @scene.pbHold(selected)
    @heldpkmn=@storage[box,index]
    @storage.pbDelete(box,index) 
    @scene.pbRefresh
    end #####MODDED
  end
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
