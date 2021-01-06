class PokemonBag_Scene
  #####MODDED
  def aGetSortOrder(bForEditing)
    aRetVal = []
        
    sFile = RTP.getSaveFileName("BagSortByType_Order.txt")
    if safeExists?(sFile)
      File.open(sFile).each do |line|
        iStart = 0
        iEnd = -1
        for i in 0...line.length
          iC = line[i..i]
          
          if (iC == ",") || (iC == "]")
            iEnd = i
            break
          elsif iC == "["
            iStart = i+1
          end
        end
        
        if iEnd >= 0
          if iStart == 0
            aRetVal[aRetVal.length] = line[iStart...iEnd].to_i
          else
            if bForEditing
              aRetVal[aRetVal.length] = ""
              aRetVal[aRetVal.length] = line[iStart...iEnd]
            end
          end
        end
      end
      
      aRetVal[aRetVal.length] = "" if bForEditing
    else
      if bForEditing
        aRetVal = aGetDefaultOrder()
      else
        aTemp = aGetDefaultOrder()
        for i in 1...aTemp.length
          if !(aTemp[i] == "") && !(aTemp[i-1] == "")
            aRetVal[aRetVal.length] = aTemp[i]
          end
        end
      end
    end
    
    return aRetVal
  end
  
  def aSaveSortOrder(aOrder)
    File.open(RTP.getSaveFileName("BagSortByType_Order.txt"),"wb"){|f|
      #Skip first and last; they should always be "", and skipping them allows for an easier i+1 or i-1 check
      for i in 1...aOrder.length-1
        if aOrder[i] == ""
          sTxt = "\r\n"
        else
          if aOrder[i+1] == ""
            sSep = "]"
          else
            sSep = ","
          end
          
          if aOrder[i-1] == ""
            sTxt = _INTL("[{1}{2} # {3}\r\n", aOrder[i], sSep, "Type name")
          else
            if pbIsTechnicalMachine?(aOrder[i])
              sTxt = _INTL("{1}{2} # {3} {4}\r\n", aOrder[i], sSep, $ItemData[aOrder[i]][ITEMNAME], PBMoves.getName($ItemData[aOrder[i]][ITEMMACHINE]))
            else
              sTxt = _INTL("{1}{2} # {3}\r\n", aOrder[i], sSep, $ItemData[aOrder[i]][ITEMNAME])
            end
          end
        end
        
        f << sTxt
      end
    }
  end
  
  def aEditSortOrder()
    aOrder = aGetSortOrder(true)
    
    loop do
      aTypes = []
      aTypesID = []
      for i in 1...aOrder.length
        if aOrder[i-1] == ""
          aTypes[aTypes.length] = aOrder[i]
          aTypesID[aTypesID.length] = i
        end
      end
      aTypesID[aTypesID.length] = aOrder.length
      
      for i in 0...aTypes.length
        aTypes[i] = _INTL("{1} ({2})", aTypes[i], aTypesID[i+1]-aTypesID[i]-2)
      end
      
      aTypes[aTypes.length] = ""
      aTypes[aTypes.length] = "Add type"
      aTypes[aTypes.length] = "Save order"
      aTypes[aTypes.length] = "Exit"
      
      iT = Kernel.pbMessage("Item types", aTypes, aTypes.length)
      
      if aTypes[iT] == "Exit"
        aConf = ["Save and exit", "Exit", "Back"]
        iD = Kernel.pbMessage("Are you sure?", aConf, aConf.length)
        
        if aConf[iD] == "Save and exit"
          aSaveSortOrder(aOrder)
          Kernel.pbMessage("Custom order saved")
          break
        elsif aConf[iD] == "Exit"
          break
        end
      elsif aTypes[iT] == "Save order"
        aSaveSortOrder(aOrder)
        Kernel.pbMessage("Custom order saved")
      elsif aTypes[iT] == "Add type"
        sName = pbEnterText("Choose a name for the new type", 0, 99, "")
        if !(sName == "")
          aOrder[aOrder.length] = sName
          aOrder[aOrder.length] = ""
        end
      elsif !(aTypes[iT] == "")
        aConf = ["Move type", "Edit type", "Delete type", "Back"]
        iD = Kernel.pbMessage(_INTL("What to do with {1}?", aTypes[iT]), aConf, aConf.length)
        
        if aConf[iD] == "Edit type"
          aItConf = ["Add an item before this", "Delete this item", "Back"]
          iStart = aTypesID[iT]
          
          loop do
            aConf2 = [_INTL("[ {1} ]", aOrder[iStart])]
            for i in (iStart+1)...aOrder.length
              if aOrder[i] == ""
                break
              else
                if pbIsTechnicalMachine?(aOrder[i])
                  aConf2[aConf2.length] = _INTL("{1} {2}", $ItemData[aOrder[i]][ITEMNAME], PBMoves.getName($ItemData[aOrder[i]][ITEMMACHINE]))
                else
                  aConf2[aConf2.length] = $ItemData[aOrder[i]][ITEMNAME]
                end
              end 
            end
            aConf2[aConf2.length] = ""
            aConf2[aConf2.length] = "Back"
            
            iI = Kernel.pbMessage(_INTL("Editing {1} ({2})", aOrder[iStart], aConf2.length-3), aConf2, aConf2.length)
            
            if iI == 0
              sName = pbEnterText("Choose a new name", 0, 99, aOrder[iStart])
              if !(sName == "")
                aOrder[iStart] = sName
              end
            else
              if aConf2[iI] == "Back"
                break
              else
                iItem = iStart+iI
                
                iIC = Kernel.pbMessage(_INTL("Do what with {1}", aConf2[iI]), aItConf, aItConf.length)
                
                if aItConf[iIC] == "Add an item before this"
                  sTxt0 = pbEnterText("Write the first letters", 0, 99, "")
                  sTxt = sTxt0.downcase
                  
                  aMatches = []
                  aMatchesNames = []
                  
                  for i in 1...$ItemData.length
                    sTxt2 = $ItemData[i][1]
                    if sTxt2.length >= sTxt.length
                      sTxt2 = sTxt2[0...sTxt.length]
                      sTxt2 = sTxt2.downcase
                      if sTxt == sTxt2
                        aMatches[aMatches.length] = i
                        aMatchesNames[aMatchesNames.length] = $ItemData[i][1]
                      end
                    end
                  end
                  
                  if aMatches.length > 0
                    iNewItem = aMatches[Kernel.pbMessage(_INTL("Found {1} items, please select one", aMatchesNames.length), aMatchesNames, 0)]
                    sNewItem = $ItemData[iNewItem][1]
                    
                    bAdd = true
                  
                    #Look for duplicates
                    sTxt = aOrder[0]
                    for i in 1...aOrder.length
                      if !(aOrder[i] == "")
                        if aOrder[i-1] == ""
                          sTxt = aOrder[i]
                        else
                          if aOrder[i] == iNewItem
                            if Kernel.pbMessage(_INTL("{1} already contains {2}\r\nWhat to do?", sTxt, sNewItem), ["Delete the other one", "Do not add this one"], 2) == 0
                              bAdd = true
                              
                              aTemp = []
                              for i2 in 0...aOrder.length
                                if (i2 != i)
                                  aTemp[aTemp.length] = aOrder[i2]
                                end
                              end
                              
                              aOrder = []
                              for i2 in 0...aTemp.length
                                aOrder[aOrder.length] = aTemp[i2]
                              end
                              
                              iItem = iItem-1 if iItem >= i
                              iStart = iStart-1 if iStart >= i
                            else
                              bAdd = false
                            end
                            
                            break
                          end
                        end
                      end
                    end
                    
                    #Add the item
                    if bAdd
                      for i in iItem..aOrder.length
                        i2 = aOrder.length+iItem-i
                        aOrder[i2] = aOrder[i2-1]
                      end
                      
                      aOrder[iItem] = iNewItem
                    end
                  else
                    Kernel.pbMessage(_INTL("Found 0 items beginning with {1}", sTxt0))
                  end
                elsif aItConf[iIC] == "Delete this item"
                  if aConf2[iI] == ""
                    Kernel.pbMessage("Ok, delet... wait, this is not an item!")
                    Kernel.pbMessage("Do you have any idea of what would have happened?")
                    Kernel.pbMessage("I COULD HAVE CRASHED!")
                    Kernel.pbMessage("But you don't care about me, do you? :( ")
                  else
                    aTemp = []
                    for i in 0...aOrder.length
                      if (i != iItem)
                        aTemp[aTemp.length] = aOrder[i]
                      end
                    end
                    
                    aOrder = []
                    for i in 0...aTemp.length
                      aOrder[aOrder.length] = aTemp[i]
                    end
                  end
                end
              end
            end
          end
        elsif aConf[iD] == "Delete type"
          iStart = aTypesID[iT]
          iEnd = aTypesID[iT+1]-1
          
          aTemp = []
          for i in 0...aOrder.length
            if (i < iStart) || (i > iEnd)
              aTemp[aTemp.length] = aOrder[i]
            end
          end
          
          aOrder = []
          for i in 0...aTemp.length
            aOrder[aOrder.length] = aTemp[i]
          end
        elsif aConf[iD] == "Move type"
          aConf2 = aTypes[0...aTypes.length-3]
          aConf2[aConf2.length] = "Back"
          
          aConf2[iT] = _INTL(">> {1} <<", aConf2[iT])
          
          iT2 = Kernel.pbMessage("Move before which type?", aConf2, aConf2.length)
          if (iT2 != iT) && !(aConf2[iT2] == "Back")
            aTemp = aOrder[aTypesID[iT]..(aTypesID[iT+1]-1)]
            
            iStart = aTypesID[iT]
            iEnd = aTypesID[iT2]
            
            if iEnd > iStart
              for i in iStart...iEnd
                aOrder[i] = aOrder[i+aTemp.length]
              end
              
              for i in 0...aTemp.length
                aOrder[iEnd-aTemp.length+i] = aTemp[i]
              end
            else
              for i in iEnd...iStart
                i2 = iEnd+iStart-1-i
                aOrder[i2+aTemp.length] = aOrder[i2]
              end
              
              for i in 0...aTemp.length
                aOrder[iEnd+i] = aTemp[i]
              end
            end
          end
        end
      end
    end
  end
  
  def aSortByType(aItems)
    aOrder = aGetSortOrder(false)
    
    aTempBag = [] #Result
    
    #Get all the ids to sort
    aToSort = []
    for i in 0...aItems.length
      aToSort[aToSort.length] = i
    end
    iMaxSort = aToSort.length-1
    
    #Sort by type
    for i2 in 0...aOrder.length
      i = 0
      while i <= iMaxSort
        if aItems[aToSort[i]][ITEMID] == aOrder[i2]
          aTempBag[aTempBag.length] = aItems[aToSort[i]]
          aToSort[i] = aToSort[iMaxSort]
          iMaxSort = iMaxSort-1
          #Don't break the loop: there may be more than 1 stack of the same item
        else
          i += 1
        end
      end
    end
    
    #Now add in the rest
    for i in 0..iMaxSort
      aTempBag[aTempBag.length] = aItems[aToSort[i]]
    end
    
    #And copy the result over; no need to check the length: if there is no error then it hasn't changed
    for i in 0...aTempBag.length
      aItems[i] = aTempBag[i]
    end
  end
  
  def aSortByMoveName(aItems)
    counter = 1
    while counter < aItems.length
      index     = counter
      while index > 0
        indexPrev = index - 1
        
        firstName  = PBMoves.getName($ItemData[aItems[indexPrev][ITEMID]][ITEMMACHINE])
        secondName = PBMoves.getName($ItemData[aItems[index][ITEMID]][ITEMMACHINE])     
        
        if firstName > secondName
          aux               = aItems[index] 
          aItems[index]     = aItems[indexPrev]
          aItems[indexPrev] = aux
        end
        index -= 1
      end
      counter += 1
    end
  end
  #####/MODDED
  
  def pbChooseItem
    pbRefresh
    @sprites["helpwindow"].visible=false
    itemwindow=@sprites["itemwindow"]
    itemwindow.refresh
    sorting=false
    sortindex=-1
    pbActivateWindow(@sprites,"itemwindow"){
       loop do
         Graphics.update
         Input.update
         olditem=itemwindow.item
         oldindex=itemwindow.index
         self.update
         if itemwindow.item!=olditem
           # Update slider position
           ycoord=60
           if itemwindow.itemCount>1
             ycoord+=116.0 * itemwindow.index/(itemwindow.itemCount-1)
           end
           @sprites["slider"].y=ycoord
           # Update item icon and description
           filename=pbItemIconFile(itemwindow.item)
           @sprites["icon"].setBitmap(filename)
           @sprites["itemtextwindow"].text=(itemwindow.item==0) ? _INTL("Close bag.") :
              pbGetMessage(MessageTypes::ItemDescriptions,itemwindow.item)
         end
         if itemwindow.index!=oldindex
           # Update selected item for current pocket
           @bag.setChoice(itemwindow.pocket,itemwindow.index)
         end
         # Change pockets if Left/Right pressed
         numpockets=PokemonBag.numPockets
         if Input.trigger?(Input::LEFT)
           if !sorting
             itemwindow.pocket=(itemwindow.pocket==1) ? numpockets : itemwindow.pocket-1
             @bag.lastpocket=itemwindow.pocket
             pbRefresh
           end
         elsif Input.trigger?(Input::RIGHT)
           if !sorting
             itemwindow.pocket=(itemwindow.pocket==numpockets) ? 1 : itemwindow.pocket+1
             @bag.lastpocket=itemwindow.pocket
             pbRefresh
           end
         end
         if Input.trigger?(Input::X)
           #####MODDED
           if itemwindow.pocket == 4
             aSortChoices = ["By type", "By TM number", "By move name", "Edit type sort order", "Cancel"]
           else
             aSortChoices = ["By type", "By name", "Edit type sort order", "Cancel"]
           end
           iSortChoice = Kernel.pbMessage(_INTL("Sort how?"), aSortChoices, aSortChoices.length)
           
           if aSortChoices[iSortChoice] == "Edit type sort order"
             aEditSortOrder()
           end
					 if aSortChoices[iSortChoice] == "By type"
             aSortByType(@bag.pockets[itemwindow.pocket])
             pbRefresh
           end
           if aSortChoices[iSortChoice] == "By move name"
             aSortByMoveName(@bag.pockets[itemwindow.pocket])
             pbRefresh
           end
           if (aSortChoices[iSortChoice] == "By name") || (aSortChoices[iSortChoice] == "By TM number")
           #####/MODDED
           pocket  = @bag.pockets[itemwindow.pocket]
           counter = 1
           while counter < pocket.length
             index     = counter
             while index > 0
               indexPrev = index - 1
               if itemwindow.pocket==4
                 firstName  = (((PBItems.getName(pocket[indexPrev][0])).sub("TM","00")).sub("X","100")).to_i
                 secondName = (((PBItems.getName(pocket[index][0])).sub("TM","00")).sub("X","100")).to_i                 
               else                 
                 firstName  = PBItems.getName(pocket[indexPrev][0])
                 secondName = PBItems.getName(pocket[index][0])               
               end               
               if firstName > secondName
                 aux               = pocket[index] 
                 pocket[index]     = pocket[indexPrev]
                 pocket[indexPrev] = aux
               end
               index -= 1
             end
             counter += 1
           end
           pbRefresh
           end #####MODDED
         end
# Select item for switching if A is pressed
         if Input.trigger?(Input::F5)
           thispocket=@bag.pockets[itemwindow.pocket]
           if itemwindow.index<thispocket.length && thispocket.length>1 &&
              !POCKETAUTOSORT[itemwindow.pocket]
             sortindex=itemwindow.index
             sorting=true
             @sprites["itemwindow"].sortIndex=sortindex
           else
             next
           end
         end
         # Cancel switching or cancel the item screen
         if Input.trigger?(Input::B)
           if sorting
             sorting=false
             @sprites["itemwindow"].sortIndex=-1
           else
             return 0
           end
         end
         # Confirm selection or item switch
         if Input.trigger?(Input::C)
           thispocket=@bag.pockets[itemwindow.pocket]
           if itemwindow.index<thispocket.length
             if sorting
               sorting=false
               tmp=thispocket[itemwindow.index]
               thispocket[itemwindow.index]=thispocket[sortindex]
               thispocket[sortindex]=tmp
               @sprites["itemwindow"].sortIndex=-1
               pbRefresh
               next
             else
               pbRefresh
               return thispocket[itemwindow.index][0]
             end
           else
             return 0
           end
         end
       end
    }
  end
  
  #####MODDED
  def aGetDefaultOrder()
    #Courtesy of DreamblitzX
    return ["",
    "Overworld items", # Type name
    1, # Repel
    2, # Super Repel
    3, # Max Repel
    4, # Black Flute
    5, # White Flute
    6, # Honey
    7, # Escape Rope
    8, # Red Shard
    9, # Purple Shard
    10, # Blue Shard
    11, # Green Shard
    49, # Heart Scale
    690, # Adrenaline Orb

    "",
    "Evolution items", # Type name
    202, # Everstone
    12, # Fire Stone
    13, # Thunder Stone
    14, # Water Stone
    15, # Leaf Stone
    16, # Moon Stone
    17, # Sun Stone
    18, # Dusk Stone
    19, # Dawn Stone
    20, # Shiny Stone
    692, # Ice Stone
    520, # Link Stone
    203, # Dragon Scale
    204, # Up-Grade
    205, # Dubious Disc
    206, # Protector
    207, # Electirizer
    208, # Magmarizer
    209, # Reaper Cloth
    210, # Prism Scale
    211, # Oval Stone
    580, # Whipped Dream
    572, # Sachet
    193, # DeepSeaTooth
    194, # DeepSeaScale
    109, # King's Rock
    110, # Razor Fang
    105, # Razor Claw

    "",
    "Held items - utility", # Type name
    76, # Lucky Egg
    77, # Exp. Share
    78, # Amulet Coin
    75, # Smoke Ball
    70, # Destiny Knot
    79, # Soothe Bell
    120, # Macho Brace
    121, # Power Weight
    122, # Power Bracer
    123, # Power Belt
    124, # Power Lens
    125, # Power Band
    126, # Power Anklet

    "",
    "Held items - battle", # Type name
    68, # Eviolite
    71, # Rocky Helmet
    93, # Leftovers
    94, # Shell Bell
    92, # Black Sludge
    100, # Life Orb
    115, # Flame Orb
    116, # Toxic Orb
    543, # Assault Vest
    573, # Safety Goggles
    693, # Protective Pads
    81, # Choice Band
    82, # Choice Specs
    83, # Choice Scarf
    84, # Heat Rock
    85, # Damp Rock
    86, # Smooth Rock
    87, # Icy Rock
    648, # Amplifield Rock
    112, # Quick Claw
    106, # Scope Lens
    107, # Wide Lens
    108, # Zoom Lens
    101, # Expert Belt
    102, # Metronome
    103, # Muscle Band
    104, # Wise Glasses
    88, # Light Clay
    74, # Shed Shell
    89, # Grip Claw
    90, # Binding Band
    91, # Big Root
    67, # Bright Powder
    69, # Float Stone
    80, # Cleanse Tag
    111, # Lagging Tail
    117, # Sticky Barb
    118, # Iron Ball
    119, # Ring Target
    113, # Focus Band

    "",
    "Held items - consumable", # Type name
    114, # Focus Sash
    579, # Weakness Policy
    66, # Air Balloon
    72, # Eject Button
    73, # Red Card
    95, # Mental Herb
    96, # White Herb
    97, # Power Herb
    98, # Absorb Bulb
    99, # Cell Battery
    560, # Luminous Moss
    576, # Snowball
    774, # Elemental Seed
    775, # Magical Seed
    776, # Telluric Seed
    777, # Synthetic Seed

    "",
    "Incenses", # Type name
    127, # Lax Incense
    128, # Full Incense
    129, # Luck Incense
    130, # Pure Incense
    131, # Sea Incense
    132, # Wave Incense
    133, # Rose Incense
    134, # Odd Incense
    135, # Rock Incense

    "",
    "Type boosters", # Type name
    136, # Charcoal
    137, # Mystic Water
    138, # Magnet
    139, # Miracle Seed
    140, # Never-Melt Ice
    141, # Black Belt
    142, # Poison Barb
    143, # Soft Sand
    144, # Sharp Beak
    145, # Twisted Spoon
    146, # Silver Powder
    147, # Hard Stone
    148, # Spell Tag
    149, # Dragon Fang
    150, # Black Glasses
    151, # Metal Coat
    152, # Silk Scarf

    "",
    "Plates", # Type name
    153, # Flame Plate
    154, # Splash Plate
    155, # Zap Plate
    156, # Meadow Plate
    157, # Icicle Plate
    158, # Fist Plate
    159, # Toxic Plate
    160, # Earth Plate
    161, # Sky Plate
    162, # Mind Plate
    163, # Insect Plate
    164, # Stone Plate
    165, # Spooky Plate
    166, # Draco Plate
    167, # Dread Plate
    168, # Iron Plate
    570, # Pixie Plate

    "",
    "Memories", # Type name
    694, # Fire Memory
    695, # Water Memory
    696, # Electric Memory
    697, # Grass Memory
    698, # Ice Memory
    699, # Fighting Memory
    700, # Poison Memory
    701, # Ground Memory
    702, # Flying Memory
    703, # Psychic Memory
    704, # Bug Memory
    705, # Rock Memory
    706, # Ghost Memory
    707, # Dragon Memory
    708, # Dark Memory
    709, # Steel Memory
    710, # Fairy Memory

    "",
    "Gems", # Type name
    169, # Fire Gem
    170, # Water Gem
    171, # Electric Gem
    172, # Grass Gem
    173, # Ice Gem
    174, # Fighting Gem
    175, # Poison Gem
    176, # Ground Gem
    177, # Flying Gem
    178, # Psychic Gem
    179, # Bug Gem
    180, # Rock Gem
    181, # Ghost Gem
    182, # Dragon Gem
    183, # Dark Gem
    184, # Steel Gem
    185, # Normal Gem
    660, # Fairy Gem

    "",
    "Quest items", # Type name
    40, # Balm Mushroom
    50, # Slowpoketail
    59, # Growth Mulch
    60, # Damp Mulch
    61, # Stable Mulch
    62, # Gooey Mulch
    65, # Odd Keystone
    592, # Magnet Powder
    594, # Data Chip
    595, # Soul Candle
    597, # Floral Charm
    598, # Blast Powder
    604, # Oddishweed
    607, # Dark Material
    611, # Tech Glasses
    614, # Ill-Fated Doll

    "",
    "Applications", # Type name
    669, # Spyce Application
    670, # Library Application
    671, # Sweet Application
    672, # Critical Application
    673, # Medicine Application
    674, # Salon Application
    675, # Glamazonia App
    676, # Nightclub Application
    677, # Cycle Application
    678, # Silph Application
    679, # Circus Application
    680, # SOLICE Application
    681, # Construction App
    682, # Apophyll Application

    "",
    "Fossils", # Type name
    28, # Helix Fossil
    29, # Dome Fossil
    30, # Old Amber
    31, # Root Fossil
    32, # Claw Fossil
    33, # Skull Fossil
    34, # Armor Fossil
    35, # Cover Fossil
    36, # Plume Fossil
    556, # Jaw Fossil
    574, # Sail Fossil

    "",
    "Nectars", # Type name
    713, # Red Nectar
    714, # Yellow Nectar
    715, # Pink Nectar
    716, # Purple Nectar

    "",
    "Apricorns", # Type name
    21, # Red Apricorn
    22, # Ylw Apricorn
    23, # Blu Apricorn
    24, # Grn Apricorn
    25, # Pnk Apricorn
    26, # Wht Apricorn
    27, # Blk Apricorn

    "",
    "Sell/useless items", # Type name
    47, # Nugget
    48, # Big Nugget
    41, # Pearl
    42, # Big Pearl
    43, # Pearl String
    44, # Stardust
    45, # Star Piece
    46, # Comet Shard
    37, # Pretty Wing
    38, # Tiny Mushroom
    39, # Big Mushroom
    51, # Rare Bone
    52, # Relic Copper
    53, # Relic Silver
    54, # Relic Gold
    55, # Relic Vase
    56, # Relic Band
    57, # Relic Statue
    58, # Relic Crown
    63, # Shoal Salt
    64, # Shoal Shell
    212, # Red Scarf
    213, # Blue Scarf
    214, # Pink Scarf
    215, # Green Scarf
    216, # Yellow Scarf

    "",
    "Pokemon-specific", # Type name
    186, # Light Ball
    187, # Lucky Punch
    188, # Metal Powder
    189, # Quick Powder
    190, # Thick Club
    191, # Stick

    "",
    "Legendary Items", # Type name 
    192, # Soul Dew
    195, # Adamant Orb
    196, # Lustrous Orb
    197, # Griseous Orb
    198, # Douse Drive
    199, # Shock Drive
    200, # Burn Drive
    201, # Chill Drive

    "",
    "Healing items", # Type name
    217, # Potion
    218, # Super Potion
    219, # Hyper Potion
    612, # Ultra Potion
    220, # Max Potion
    221, # Full Restore
    234, # Berry Juice
    237, # Fresh Water
    238, # Soda Pop
    239, # Lemonade
    711, # Blue Moon Lemonade
    240, # Moomoo Milk
    241, # Energy Powder
    242, # Energy Root
    533, # Vanilla Ice Cream
    523, # Choc Ice Cream
    524, # Berry Ice Cream
    605, # BlueMoon Ice Cream
    236, # Sweet Heart (quest item)
    593, # PokeSnax

    "",
    "Revival items", # Type name
    532, # Cotton Candy
    232, # Revive
    233, # Max Revive
    244, # Revival Herb
    222, # Sacred Ash

    "",
    "Status items", # Type name
    228, # Full Heal
    243, # Heal Powder
    235, # RageCandyBar
    229, # Lava Cookie
    230, # Old Gateau
    231, # Casteliacone
    561, # Lumiose Galette
    691, # Big Malasada
    223, # Awakening
    224, # Antidote
    225, # Burn Heal
    226, # Paralyze Heal
    227, # Ice Heal
    527, # Pop Rocks
    528, # Peppermint
    529, # Salt-Water Taffy
    530, # Chewing Gum
    531, # Red-Hots

    "",
    "PP items", # Type name
    245, # Ether
    246, # Max Ether
    247, # Elixir
    248, # Max Elixir

    "",
    "Level consumables", # Type name
    526, # Common Candy
    263, # Rare Candy
    581, # Ability Capsule

    "",
    "EV consumables", # Type name
    249, # PP Up
    250, # PP Max
    251, # HP Up
    252, # Protein
    253, # Iron
    254, # Calcium
    255, # Zinc
    256, # Carbos
    257, # Health Wing
    258, # Muscle Wing
    259, # Resist Wing
    260, # Genius Wing
    261, # Clever Wing
    262, # Swift Wing
    642, # HP Reset Disc
    643, # Attack Reset Disc
    644, # Defense Reset Disc
    645, # Sp.Atk Reset Disc
    646, # Sp.Def Reset Disc
    647, # Speed Reset Disc

    "",
    "Poké Balls", # Type name
    #sorted roughly by catchrate
    610, # Corrupted Poké Ball 
    267, # Poké Ball 
    266, # Great Ball 
    265, # Ultra Ball 
    279, # Quick Ball
    283, # Lure Ball
    272, # Nest Ball 
    282, # Level Ball
    274, # Timer Ball
    277, # Dusk Ball
    270, # Net Ball
    271, # Dive Ball
    273, # Repeat Ball
    281, # Fast Ball
    284, # Heavy Ball
    287, # Moon Ball 
    285, # Love Ball
    268, # Safari Ball 
    269, # Sport Ball 
    275, # Luxury Ball 
    286, # Friend Ball 
    278, # Heal Ball 
    276, # Premier Ball 
    280, # Cherish Ball 
    712, # Beast Ball 
    264, # Reborn Ball 255, at bottom to reduce accidental use

    "",
    "TMs & HMs", # Type name
    383, # TMX1 Cut
    384, # TMX2 Fly
    385, # TMX3 Surf
    386, # TMX4 Strength
    387, # TMX5 Waterfall
    388, # TMX6 Dive
    381, # TMX7 Rock Smash
    357, # TMX8 Flash
    793, # TMX9 Rock Climb
    288, # TM01 Work Up
    289, # TM02 Dragon Claw
    290, # TM03 Psyshock
    291, # TM04 Calm Mind
    292, # TM05 Roar
    293, # TM06 Toxic
    294, # TM07 Hail
    295, # TM08 Bulk Up
    296, # TM09 Venoshock
    297, # TM10 Hidden Power
    298, # TM11 Sunny Day
    299, # TM12 Taunt
    300, # TM13 Ice Beam
    301, # TM14 Blizzard
    302, # TM15 Hyper Beam
    303, # TM16 Light Screen
    304, # TM17 Protect
    305, # TM18 Rain Dance
    306, # TM19 Roost
    307, # TM20 Safeguard
    308, # TM21 Frustration
    309, # TM22 Solar Beam
    310, # TM23 Smack Down
    311, # TM24 Thunderbolt
    312, # TM25 Thunder
    313, # TM26 Earthquake
    314, # TM27 Return
    315, # TM28 Leech Life
    316, # TM29 Psychic
    317, # TM30 Shadow Ball
    318, # TM31 Brick Break
    319, # TM32 Double Team
    320, # TM33 Reflect
    321, # TM34 Sludge Wave
    322, # TM35 Flamethrower
    323, # TM36 Sludge Bomb
    324, # TM37 Sandstorm
    325, # TM38 Fire Blast
    326, # TM39 Rock Tomb
    327, # TM40 Aerial Ace
    328, # TM41 Torment
    329, # TM42 Facade
    330, # TM43 Flame Charge
    331, # TM44 Rest
    332, # TM45 Attract
    333, # TM46 Thief
    334, # TM47 Low Sweep
    335, # TM48 Round
    336, # TM49 Echoed Voice
    337, # TM50 Overheat
    338, # TM51 Steel Wing
    339, # TM52 Focus Blast
    340, # TM53 Energy Ball
    341, # TM54 False Swipe
    342, # TM55 Scald
    343, # TM56 Fling
    344, # TM57 Charge Beam
    345, # TM58 Sky Drop
    346, # TM59 Brutal Swing
    347, # TM60 Quash
    348, # TM61 Will-O-Wisp
    349, # TM62 Acrobatics
    350, # TM63 Embargo
    351, # TM64 Explosion
    352, # TM65 Shadow Claw
    353, # TM66 Payback
    354, # TM67 Smart Strike
    355, # TM68 Giga Impact
    356, # TM69 Rock Polish
    717, # TM70 Aurora Veil
    358, # TM71 Stone Edge
    359, # TM72 Volt Switch
    360, # TM73 Thunder Wave
    361, # TM74 Gyro Ball
    362, # TM75 Swords Dance
    363, # TM76 Struggle Bug
    364, # TM77 Psych Up
    365, # TM78 Bulldoze
    366, # TM79 Frost Breath
    367, # TM80 Rock Slide
    368, # TM81 X-Scissor
    369, # TM82 Dragon Tail
    370, # TM83 Infestation
    371, # TM84 Poison Jab
    372, # TM85 Dream Eater
    373, # TM86 Grass Knot
    374, # TM87 Swagger
    375, # TM88 Sleep Talk
    376, # TM89 U-turn
    377, # TM90 Substitute
    378, # TM91 Flash Cannon
    379, # TM92 Trick Room
    380, # TM93 Wild Charge
    639, # TM94 Secret Power
    382, # TM95 Snarl
    582, # TM96 Nature Power
    583, # TM97 Dark Pulse
    584, # TM98 Power-Up Punch
    585, # TM99 Dazzling Gleam
    586, # TM100 Confide

    "",
    "Berries", # Type name
    389, # Cheri Berry
    390, # Chesto Berry
    391, # Pecha Berry
    392, # Rawst Berry
    393, # Aspear Berry
    394, # Leppa Berry
    395, # Oran Berry
    396, # Persim Berry
    397, # Lum Berry
    398, # Sitrus Berry
    399, # Figy Berry
    400, # Wiki Berry
    401, # Mago Berry
    402, # Aguav Berry
    403, # Iapapa Berry
    404, # Razz Berry
    405, # Bluk Berry
    406, # Nanab Berry
    407, # Wepear Berry
    408, # Pinap Berry
    409, # Pomeg Berry
    410, # Kelpsy Berry
    411, # Qualot Berry
    412, # Hondew Berry
    413, # Grepa Berry
    414, # Tamato Berry
    415, # Cornn Berry
    416, # Magost Berry
    417, # Rabuta Berry
    418, # Nomel Berry
    419, # Spelon Berry
    420, # Pamtre Berry
    421, # Watmel Berry
    422, # Durin Berry
    423, # Belue Berry
    424, # Occa Berry
    425, # Passho Berry
    426, # Wacan Berry
    427, # Rindo Berry
    428, # Yache Berry
    429, # Chople Berry
    430, # Kebia Berry
    431, # Shuca Berry
    432, # Coba Berry
    433, # Payapa Berry
    434, # Tanga Berry
    435, # Charti Berry
    436, # Kasib Berry
    437, # Haban Berry
    438, # Colbur Berry
    439, # Babiri Berry
    440, # Chilan Berry
    441, # Liechi Berry
    442, # Ganlon Berry
    443, # Salac Berry
    444, # Petaya Berry
    445, # Apicot Berry
    446, # Lansat Berry
    447, # Starf Berry
    448, # Enigma Berry
    449, # Micle Berry
    450, # Custap Berry
    451, # Jaboca Berry
    452, # Rowap Berry
    558, # Kee Berry
    563, # Maranga Berry
    571, # Roseli Berry

    "",
    "Z crystals - type", # Type name
    742, 743, # Normalium-Z
    730, 731, # Firium-Z
    752, 753, # Waterium-Z
    736, 737, # Grassium-Z
    724, 725, # Electrium-Z
    718, 719, # Buginium-Z
    732, 733, # Flyinium-Z
    738, 739, # Groundium-Z
    748, 749, # Rockium-Z
    728, 729, # Fightinium-Z
    746, 747, # Psychium-Z
    734, 735, # Ghostium-Z
    720, 721, # Darkinium-Z
    726, 727, # Fairium-Z
    744, 745, # Poisonium-Z
    750, 751, # Steelium-Z
    722, 723, # Dragonium-Z
    740, 741, # Icium-Z

    "",
    "Z crytals - pokemon", # Type name
    762, 763, # Eevium-Z
    764, 765, # Pikanium-Z
    754, 755, # Aloraichium-Z
    766, 767, # Snorlium-Z
    756, 757, # Decidium-Z
    758, 759, # Incinium-Z
    760, 761, # Primarium-Z
    781, 782, # Kommonium-Z
    783, 784, # Lycanium-Z
    785, 786, # Mimikium-Z
    768, 769, # Mewnium-Z
    770, 771, # Tapunium-Z
    772, 773, # Marshadium-Z
    787, 788, # Solganium-Z
    789, 790, # Lunalium-Z
    791, 792, # Ultranecrozium-Z

    "",
    "Mega stones", # Type name
    537, # Abomasite
    538, # Absolite
    539, # Aerodactylite
    540, # Aggronite
    541, # Alakazite
    623, # Altarianite
    542, # Ampharosite
    622, # Audinite
    544, # Banettite
    621, # Beedrillite
    545, # Blastoisinite
    546, # Blazikenite
    626, # Cameruptite
    547, # Charizardite X
    548, # Charizardite Y
    624, # Diancite
    617, # Galladite
    549, # Garchompite
    550, # Gardevoirite
    551, # Gengarite
    618, # Glalitite
    552, # Gyaradosite
    553, # Heracronite
    554, # Houndoominite
    557, # Kangaskhanite
    634, # Latiasite
    635, # Latiosite
    629, # Lopunnite
    559, # Lucarionite
    562, # Manectite
    564, # Mawilite
    565, # Medichamite
    630, # Metagrossite
    567, # Mewtwonite X
    568, # Mewtwonite Y
    627, # Pidgeotite
    569, # Pinsirite
    632, # Sablenite
    628, # Salamencite
    620, # Sceptilite
    575, # Scizorite
    619, # Sharpedonite
    631, # Slowbronite
    625, # Steelixite
    633, # Swampertite
    577, # Tyranitarite
    578, # Venusaurite

    "",
    "Mails", # Type name
    636, # Red Orb
    637, # Blue Orb
    453, # Grass Mail
    454, # Flame Mail
    455, # Bubble Mail
    456, # Bloom Mail
    457, # Tunnel Mail
    458, # Steel Mail
    459, # Heart Mail
    460, # Snow Mail
    461, # Space Mail
    462, # Air Mail
    463, # Mosaic Mail
    464, # Brick Mail

    "",
    "Battle Items", # Type name
    500, # Poké Doll
    501, # Fluffy Tail
    502, # Poké Toy
    497, # Blue Flute
    498, # Yellow Flute
    499, # Red Flute
    465, # X Attack
    466, # X Attack 2
    467, # X Attack 3
    468, # X Attack 6
    469, # X Defend
    470, # X Defend 2
    471, # X Defend 3
    472, # X Defend 6
    473, # X Special
    474, # X Special 2
    475, # X Special 3
    476, # X Special 6
    477, # X Sp. Def
    478, # X Sp. Def 2
    479, # X Sp. Def 3
    480, # X Sp. Def 6
    481, # X Speed
    482, # X Speed 2
    483, # X Speed 3
    484, # X Speed 6
    485, # X Accuracy
    486, # X Accuracy 2
    487, # X Accuracy 3
    488, # X Accuracy 6
    489, # Dire Hit
    490, # Dire Hit 2
    491, # Dire Hit 3
    492, # Guard Spec.
    493, # Reset Urge
    494, # Ability Urge
    495, # Item Urge
    496, # Item Drop
    
    "",
    "General use", # Type name
    606, # PULSE
    566, # Mega-Z Ring
    516, # Bike Voucher #to remind people, and be directly replaced with the bike when swapped
    503, # Bicycle
    507, # Itemfinder
    508, # Dowsing MCHN
    509, # Poké Radar
    510, # Town Map
    517, # Mining Kit
    518, # Wailmer Pail
    504, # Old Rod
    505, # Good Rod
    506, # Super Rod

    "",
    "Misc important", # Type name
    514, # Membership Card
    512, # Coin Case
    589, # Oval Charm
    590, # Shiny Charm

    "",
    "Niche items", # Type name
    511, # Poké Flute
    513, # Soot Sack
    608, # Powder Vial
    687, # Devon Scope Model
    688, # Silvon Scope
    689, # Radio Transceiver
    
    "",
    "Story based items", # Type name
    525, # Medicine
    535, # Ruby Ring
    778, # Sapphire Bracelets
    #emerald brooch will go here
    534, # Amethyst Pendant
    609, # Battle Pass- Fury
    616, # Battle Pass- Gravity
    641, # Battle Pass- Suspension

    "",
    "Sidequest items", # Type name
    555, # Intriguing Stone
    596, # Silver Ring
    613, # Silver Card
    599, # 'Rare Candy'
    661, # Diamond Ring
    683, # Classified Information
    684, # Pink Pearl
    685, # Crystal Ball
    665, # ID Tag
    666, # DJ Arc Autograph
    667, # McKrezzy Autograph
    668, # Headphones
    795, # Meteor Card
    796, # Family Picture?

    "",
    "Keys", # Type name
    515, # Warehouse Key
    521, # Harbor Key
    522, # Railnet Key
    536, # Yureyu Key
    591, # Dull Key
    600, # Crystal Key
    601, # Crystal Key
    602, # Crystal Key
    603, # Crystal Key
    615, # House Key
    640, # Beryl Grid Key
    686, # 'R' Key
    662, # Sanctum Key
    663, # GUM Key
    664, # Coral Key
    794, # Cage Key
    649, # K2 Key
    650, # K5 Key
    651, # K22 Key
    652, # K33 Key
    653, # S4 Key
    654, # S9 Key
    655, # S12 Key
    656, # F1 Key
    657, # F10 Key
    658, # F14 Key
    659, # F34 Key

    "",
    "Legendary things", # Type name
    519, # Gracidea
    587, # DNA Splicers
    588, # Reveal Glass
    638, # Prison Bottle
    779, # N-Solarizer
    780, # N-Lunarizer
    ""]
  end
  #####/MODDED
end

#Pls stop using the wrong SWM version on the wrong Reborn Episode :(
if !(getversion[0..1] == "18")
  Kernel.pbMessage("Sorry, but this version of SWM was designed for Pokemon Reborn Episode 18")
  Kernel.pbMessage("Using SWM in an episode it was not designed for is no longer allowed.")
  Kernel.pbMessage("It simply causes too many problems.")
  exit
end
