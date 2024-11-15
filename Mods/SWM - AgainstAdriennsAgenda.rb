
#####MODDED
if defined?($swm_againstAdriennsAgenda_possibleMessages) # Ensures this will only run when resetting the game, and never on game start
  if rand(12) < 1
    $swm_againstAdriennsAgenda_possibleMessages.sample.each { |swm_againstAdriennsAgenda_msg|
      Kernel.pbMessage(_INTL(swm_againstAdriennsAgenda_msg))
    }
  end
end
$swm_againstAdriennsAgenda_possibleMessages = [
  ['No trashcan on the street? Throw it on the ground.', 'Found a trashcan? Throw that down too!'],
  ['It\'s not a landfill, my room is art.', 'I\'m an artist.'],
  ['Come on, you can do it!', 'It\'s garbage CAN, not garbage cannot!'],
  ['You should\'t throw yourself away just because you got refused.'],
  ['Not all who wander are lost.', 'Some are just searching for something.', 'Me, for the bathroom.', 'There\'s a gray lining hidden within the clouds.', 'And beyond the horizon lies the light that shall shine beneath the surface.', 'Ok, I\'m lost. What were we talking about?'],
  ['Why clean up?', 'No, seriously, it\'s just my natural musk!'],
  ['If you don\'t like the mess, you\'re just not trying hard enough.'],
  ['Someday you may feel like garbage.', 'Sometimes you should enjoy it!'],
  ['Muk. Seriously, niaC?', 'Are you that happy to see me?'],
  ['RAWRRRRRRRRR'],
  ['Going to the gym by car is harmful to yourself and the environment.', 'Do another lap!'],
  ['Obiter, quid de El et Latine?', 'Creditne eius quod Giratina ivit ad Arceum medio quadraginta dierum in Tournaline dicens, "Scis quid? Latinum! Id est OPTIMUM stercore semper!"?'],
  ['Hello there!', 'Resetting again?', 'So uncivilized...'],
  ['Warning: One of the components in the SWM modpack has to be removed', 'Please refer to the file ReadMe.pdf for further information on each one', 'Exiting the game now.', '', '', '', 'Just kidding!', 'Do read the ReadMe tho, please.', 'Lots of garbage in there.']
]
#####/MODDED

# Pls stop using the wrong SWM version on the wrong Reborn Episode :(
swm_target_version = '19'
if !GAMEVERSION.start_with?(swm_target_version)
  Kernel.pbMessage(_INTL('Sorry, but this version of SWM was designed for Pokemon Reborn Episode {1}', swm_target_version))
  Kernel.pbMessage(_INTL('Using SWM in an episode it was not designed for is no longer allowed.'))
  Kernel.pbMessage(_INTL('It simply causes too many problems.'))
  exit
end
