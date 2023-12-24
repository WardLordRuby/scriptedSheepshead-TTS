--[[ Scripted version of Sheepshead built inside of Tabletop Simulator By: WardLordRuby
     Scoring currently uses this modified version of the blackjack counting script by: MrStump
     I liked how EpicWolverine handled rebuilding the deck so I modified his code ]]--

DEBUG = true

GUID = {
  DEALER_CHIP = "e18594",
  TRICK_ZONE_WHITE = "70f1a5",
  TRICK_ZONE_RED = "b14dc7",
  TRICK_ZONE_YELLOW = "db8133",
  TRICK_ZONE_GREEN = "85fad3",
  TRICK_ZONE_BLUE = "69cfb0",
  TRICK_ZONE_PINK = "de62ee",
  CENTER_ZONE = "548811",
  TABLE_ZONE = "3c99b3",
  HIDDEN_BAG = "b3d3a5",
  CARD_COUNTER_TABLE = "59655f",
  CARD_COUNTER_PICKER = "7d4cf1",
  TABLE_BLOCK = "8e445a",
  RULE_BOOK = "a243b6"
}

ALL_PLAYERS = {"White", "Red", "Yellow", "Green", "Blue", "Pink"}

COIN_PRAM = {
  mesh = "http://cloud-3.steamusercontent.com/ugc/2205135744307283952/DEF0BF91642CF5636724CA3A37083385C810BA06/",
  diffuse = "http://cloud-3.steamusercontent.com/ugc/2288456143464578824/E739670FE62B8267C90E54D4B786C1C83BA7CC22/",
  type = 5,
  material = 2,
  specular_sharpness = 5
}

function onLoad()
  dealerChip = getObjectFromGUID(GUID.DEALER_CHIP)
  trickZones = {
    White = getObjectFromGUID(GUID.TRICK_ZONE_WHITE),
    Red = getObjectFromGUID(GUID.TRICK_ZONE_RED),
    Yellow = getObjectFromGUID(GUID.TRICK_ZONE_YELLOW),
    Green = getObjectFromGUID(GUID.TRICK_ZONE_GREEN),
    Blue = getObjectFromGUID(GUID.TRICK_ZONE_BLUE),
    Pink = getObjectFromGUID(GUID.TRICK_ZONE_PINK)
  }
  centerZone = getObjectFromGUID(GUID.CENTER_ZONE)
  tableZone = getObjectFromGUID(GUID.TABLE_ZONE)
  hiddenBag = getObjectFromGUID(GUID.HIDDEN_BAG)
  hiddenBag.setInvisibleTo(ALL_PLAYERS)
  gameSetUpInProgress = false
  gameSetUpRan = false
  stopCoroutine = false
  passInProgress = false
  takeTrickInProgress = false
  varSetup = false
  continue = false
  cardsToBeBuried = false
  counterVisible = false
  if DEBUG then
    UI.show("playerUp")
    UI.show("playerDown")
    UI.show("test")
  end
  displayRules()
end

--Returns the deck from given zone
--If you are aware of more than one deck in a given zone
--getDeck() can return the smaller or larger of the decks found
--pass getDeck() the string "small" or "big" to compare
function getDeck(zone, size)
  local decks = {}
  for _, obj in ipairs(zone.getObjects()) do
    if obj.tag == 'Deck' then
      table.insert(decks, obj)
    end
  end
  if #decks == 0 then
    return nil
  elseif #decks == 1 then
    return decks[1]
  elseif size == "small" then
    local smallDeck = decks[1]
    for i = 2, #decks do
      if decks[i].getQuantity() < smallDeck.getQuantity() then
        smallDeck = decks[i]
      end
    end
    return smallDeck
  elseif size == "big" then
    local bigDeck = decks[1]
    for i = 2, #decks do
      if decks[i].getQuantity() > bigDeck.getQuantity() then
        bigDeck = decks[i]
      end
    end
    return bigDeck
  else
    print("[DC0000]Deck size not defined")
    return nil
  end
end

--Returns a table of cards or decks in a given zone
function getLooseCards(zone)
  local looseCards = {}
    for _, obj in pairs(zone.getObjects()) do
      if obj.tag == "Deck" or obj.tag == "Card" then
        looseCards[#looseCards+1] = obj
      end
    end
  return looseCards
end

--called to wait seconds
function pause(time)
  local start = os.time()
  repeat coroutine.yield(0) until os.time() > start + time
end

--Called to set global variables that other math functions use
--Variables are set based on the given player color
function retrieveItemMoveData(color)
  local rotationAngle = getColorRotation(color)
  local playerPos = getPlayerPos(color)
  return rotationAngle, playerPos
end

--Returns rotation angle in reference to given color
function getColorRotation(color)
  local colorToRotation = {
    White = 0,
    Red = 60,
    Yellow = 120,
    Green = 180,
    Blue = 240,
    Pink = 300
  }
  return colorToRotation[color]
end

--Returns the player position of given color
function getPlayerPos(color)
  if color then
    local position = Player[color].getHandTransform().position
    return position
  end
end

--Called to move the dealer chip in frot of a given player color
--On player change retrieveItemMoveData() must be called before running
function moveDealerChipInFrontOfPlayer(color, rotationAngle, playerPos)
  local originalOffset = vector(4, -2.58, 7)
  local rotatedOffset = originalOffset:rotateOver('y', rotationAngle)
  local currentRotation = dealerChip.getRotation()
  dealerChip.setRotationSmooth(
  {currentRotation.x, rotationAngle - 90, currentRotation.z}
  )
  dealerChip.setPositionSmooth(playerPos + rotatedOffset)
end

--Called to move the deck in frot of a given player color
--On player change retrieveItemMoveData() must be called before running
function moveDeckInFrontOfPlayer(color, rotationAngle, playerPos)
  local deck = getDeck(tableZone)
  local originalOffset = vector(2, -2.5, 5)
  local rotatedOffset = originalOffset:rotateOver('y', rotationAngle)
  local currentRotation = deck.getRotation()
  deck.setRotationSmooth({currentRotation.x, rotationAngle, 180})
  deck.setPositionSmooth(playerPos + rotatedOffset)
end

--Returns a table with the color removed from the given color 
function removeColorFromList(color, list)
  local json = JSON.encode(list)
  local removedColorList = JSON.decode(json)
  local currentIndex
  for i, colors in ipairs(removedColorList) do
    if colors == color then
      currentIndex = i
      break
    end
  end
  if currentIndex then
    table.remove(removedColorList, currentIndex)
    return removedColorList
  end
  return list
end

--Checks if a deck in the given zone is face up, if so it flips the deck
function flipDeck(zone)
  local deck = getDeck(zone)
  if not deck.is_face_down then
    deck.flip()
  end
end

--Called to combine all cards on the table into a deck
function rebuildDeck()
  for _, obj in pairs(getLooseCards(tableZone)) do
    local faceRotation = moreFaceUpOrDown(tableZone)
    if obj.tag == 'Card' then
      obj.setRotation({0,math.random(0,360),faceRotation})
      obj.setPosition({math.random(-5.75,5.75),3,math.random(-5.75,5.75)})
      pause(0.01)
    else
      for _, card in pairs(obj.getObjects()) do
        obj.takeObject({
          position = {math.random(-5.75,5.75),3,math.random(-5.75,5.75)},
          rotation = {0,math.random(0,360),faceRotation},
          guid = card.guid
        })
        pause(0.01)
      end
    end
  end
  pause(0.25)
  local looseCards = getLooseCards(tableZone)
  flipCards(looseCards)
  pause(0.5)
  group(looseCards)
  pause(0.5)
  looseCards = getLooseCards(tableZone)
  group(looseCards)
  pause(0.5)
end

--Returns the rotationValue associated for if more cards are face up or
--face down in a given zone
function moreFaceUpOrDown(zone)
  local faceUpCount, faceDownCount = 0, 0
  local objectsInZone = zone.getObjects()
  for _, obj in pairs(objectsInZone) do
    if obj.tag == 'Card' then
      if obj.is_face_down then
        faceDownCount = faceDownCount + 1
      else
        faceUpCount = faceUpCount + 1
      end
    elseif obj.tag == 'Deck' then
      if obj.is_face_down then
        faceDownCount = faceDownCount + obj.getQuantity()
      else
        faceUpCount = faceUpCount + obj.getQuantity()
      end
    end
  end
  if faceUpCount >= faceDownCount then
    return 0
  else
    return 180
  end
end

--Returns the zoneObject associated with a given color
function findZoneObject(color, zoneList)
  for colors, zoneObject in pairs(zoneList) do
    if color == colors then
      return zoneObject
    end
  end
end

--Returns the number of cards in a given zone
function countCards(zone)
  local objects = zone.getObjects()
  local cardCount = 0
  for _, obj in ipairs(objects) do
    if obj.tag == 'Deck' then
      cardCount = cardCount + obj.getQuantity()
    elseif obj.tag == 'Card' then
      cardCount = cardCount + 1
    end
  end
  return cardCount
end

--Checks the given card count of a given zone, returns true or false
function checkCardCount(zone, count)
  local cardCount = countCards(zone)
  if cardCount == count then
    return true
  end
  return false
end

--Returns player object from a given color or number
function getPlayerObject(colorOrVar, list)
  if colorOrVar == 0 then
    return Player[list[#list]]
  elseif colorOrVar == #list + 1 then
    return Player[list[1]]
  elseif tonumber(colorOrVar) then
    return Player[list[colorOrVar]]
  else
    return Player[colorOrVar]
  end
end

--start of functions used by Set Up Game event

--Runs everytime a chat occurs
--Sets flags for determining if to reset gameboard
function onChat(message, player)
  if lookForPlayerText then
    local lowerMessage = string.lower(message)
    if lowerMessage == "y" then
      if player.steam_name == gameSetUpPlayer.steam_name then
        print(player.steam_name .. " selected new game.")
        print("[21AF21]New game is being set up.")
        continue = true
        return false
      end
    else
      return true
    end
  end

  --Handles chat event for game commands
  if string.sub(message, 1, 1) == "." then
    local command = string.lower(string.sub(message, 2))
    if command == "help" then
      print("[b415ff]Sheepshead Console Help")
      print("[21AF21].rules[-] [Displays Rule and Gameplay Tip Booklet]")
      print("[21AF21].hiderules[-] [Hides Rule and Gameplay Tip Booklet]")
      print("[21AF21].settings[-] [Opens Window to Change Game Settings]")
    end
    if command == "rules" then
      getRuleBook(player.color)
    end
    if command == "hiderules" then
      hideRuleBook()
    end
    if command == "settings" then
      if player.admin then
        UI.show("settingsWindow")
      else
        print("[DC0000]You do not have permission to access this feature.")
      end
    end
    return false
  end
end

--Moves the rule book in front of player color from either the hiddenBag or tableZone
function getRuleBook(color)
  local playerRotation = getColorRotation(color)
  local ruleBookSpawnPos = vector(0, 0.96, -9.5)
  local ruleBookPos = ruleBookSpawnPos:rotateOver('y', playerRotation)
  for _, containedObject in pairs(hiddenBag.getObjects()) do
    if containedObject.guid == GUID.RULE_BOOK then
      hiddenBag.takeObject({
        position = ruleBookPos,
        rotation = {0, playerRotation -180 , 0},
        smooth = false,
        guid = GUID.RULE_BOOK
      })
      Wait.frames(
      function()
        local ruleBook = getObjectFromGUID(GUID.RULE_BOOK)
        ruleBook.setInvisibleTo()
      end,
      20
    )
    return
    end
  end
  for _, tableObject in pairs(tableZone.getObjects()) do
    if tableObject.guid == GUID.RULE_BOOK then
      tableObject.setPositionSmooth(ruleBookPos)
      tableObject.setRotationSmooth({0, playerRotation -180 , 0})
      break
    end
  end
end

--Moves the rule book back to hiddenBag
function hideRuleBook()
  for _, tableObject in pairs(tableZone.getObjects()) do
    if tableObject.guid == GUID.RULE_BOOK then
      tableObject.setInvisibleTo(ALL_PLAYERS)
      hiddenBag.putObject(tableObject)
      break
    end
  end
end

--Called to reset the game space
--Removes all chips and sets varSetup to false
function resetBoard()
  for _, obj in pairs(tableZone.getObjects()) do
    if obj.tag == "Chip" then
      obj.destruct()
      pause(0.06)
    end
  end
  varSetup = false
end

--Builds a table of all seated players [sortedSeatedPlayers]
function populatePlayers()
  sortedSeatedPlayers = {}
  for _, color in ipairs(ALL_PLAYERS) do
    if Player[color].seated then
      table.insert(sortedSeatedPlayers, color)
    end
  end
end

--Prints the current game settings
--Gets the correct deck for the number of seated players
--Will stop setUpGameCoroutine if there is less than 3 seated players
function printGameSettings()
  local deck = getDeck(tableZone)
  if not deck or deck.getQuantity() < 30 or deck.getQuantity() == 31 then
    rebuildDeck()
    pause(0.5)
    deck = getDeck(tableZone)
  end

  if #sortedSeatedPlayers < 3 then
    print("[DC0000]Sheepshead requires 3 to 6 players.")
    gameSetUpInProgress = false
    stopCoroutine = true
    return
  elseif #sortedSeatedPlayers == 4 then
    if deck.getQuantity() == 32 then
      blackSevens = removeBlackSevens(deck)
    end
  else
    if deck.getQuantity() == 30 then
      returnDecktoPiquet(deck)
    end
  end
  local rotationAngle, playerPos = retrieveItemMoveData(gameSetUpPlayer.color)
  moveDealerChipInFrontOfPlayer(gameSetUpPlayer.color, rotationAngle, playerPos)
  moveDeckInFrontOfPlayer(gameSetUpPlayer.color, rotationAngle, playerPos)
  print("[21AF21]Sheepshead set up for ",#sortedSeatedPlayers, " players!")
end

--Called to add the blackSevens to a given deck
--Uses the guid provided by removeBlackSevens() to locate the deck
--the blackSevens are located in, then moves them from hiddenBag
--to the current deck position
function returnDecktoPiquet(deck)
  hiddenBag.takeObject({
    guid = blackSevens,
    position = deck.getPosition(),
    roation = deck.getRotation(),
    smooth = false
  })
  pause(0.5)
  local decks = getLooseCards(tableZone)
  group(decks)
  pause(0.5)
  print("[21AF21]The two black sevens have been added to the deck.")
end

--Called to remove the blackSevens from a given deck
--Finds the blackSevens inside the given deck and moves them into hiddenBag
--Returns the guid of a deck the blackSevens are located in inside hiddenBag
function removeBlackSevens(deck)
  local cardsToRemove = {'Seven of Clubs', 'Seven of Spades'}
  for _, card in ipairs(deck.getObjects()) do
    for _, cardName in ipairs(cardsToRemove) do
      if card.name == cardName then
        deck.takeObject({
          guid = card.guid,
          position = deck.getPosition() + vector(2.75, 1, 0),
          smooth = false
        })
      end
    end
  end
  print("[21AF21]The two black sevens have been removed from the deck.")
  pause(0.25)
  local smallDeck = getDeck(tableZone, "small")
  hiddenBag.putObject(smallDeck)
  pause(0.25)
  return smallDeck.guid
end

--Called when New Game Set Up event to deal chips to all seated players
function spawnChips(rotationAngle, playerPos)
  local originalOffsets =  {
    vector(4.62, -2, 3),
    vector(6.12, -2, 3.13),
    vector(5.31, -2, 4.35)
  }
  local rotatedOffset
  for c = 1, 15 do
    if c % 5 == 1 then
      local offsetIndex = math.floor((c - 1) / 5) + 1
      rotatedOffset = originalOffsets[offsetIndex]:rotateOver('y', rotationAngle)
    end
    local customCoin = spawnObject({
      type = "Custom_Model",
      position = playerPos + rotatedOffset,
      rotation = {0, rotationAngle + 180, 0},
      scale = {0.6, 0.6, 0.6},
      sound = false
    })
    customCoin.setCustomObject(COIN_PRAM)
    customCoin.reload()
    pause(0.02)
  end
end

--Start of game setup event
function setUpGameEvent(player)
  if gameSetUpInProgress then
    return
  end
  if player.admin then
    gameSetUpInProgress = true
    gameSetUpPlayer = player
    startLuaCoroutine(self, 'setUpGameCoroutine')
  else
    broadcastToColor("[DC0000]You do not have permission to access this feature.", player.color)
  end
end

--start of order of opperations for setUpGame
function setUpGameCoroutine()
  if gameSetUpRan and #sortedSeatedPlayers < 3 then
    print("[DC0000]Sheepshead requires 3 to 6 players.")
    gameSetUpInProgress = false
    return 1
  elseif gameSetUpRan then
    Player[gameSetUpPlayer.color].broadcast("You are trying to set up a new game for "
    .. #sortedSeatedPlayers .. " players.")
    pause(1.5)
    Player[gameSetUpPlayer.color].broadcast("Are you sure you want to continue? (y/n)")
    lookForPlayerText = true
    pause(6)
    if continue then
      lookForPlayerText, continue = false, false
      resetBoard()
    else
      print("[21AF21]New game was not selected.")
      lookForPlayerText, continue = false, false
      gameSetUpInProgress = false
      return 1
    end
  end

  if counterVisible then
    toggleCounterVisibility()
  end

  --start of debug code
  --This is how Number of players is mannaged in debug mode
  --Happens in place of populatePlayers
  if DEBUG then
    if sortedSeatedPlayers == nil then
      local json = JSON.encode(ALL_PLAYERS)
      sortedSeatedPlayers = JSON.decode(json)
      gameSetUpInProgress = false
      return 1
    end
  else
    populatePlayers()
  end
  --end of debug code

  printGameSettings()

  if stopCoroutine then
    stopCoroutine = false
    return 1
  end

  for _, color in ipairs(sortedSeatedPlayers) do
    local rotationAngle, playerPos = retrieveItemMoveData(color)
    spawnChips(rotationAngle, playerPos)
  end

  gameSetUpInProgress = false
  gameSetUpRan, firstDealOfGame = true, true
  return 1
end
--end of order of opperations for setUpGame
--end of functions used by Set Up Game event


--start of functions used by New Hand event

--Sets up variables needed to deal cards for New Hand event
function setUpVar()
  if firstDealOfGame then
    dealerColorVal = getColorVal(gameSetUpPlayer.color, sortedSeatedPlayers)
  end
  varSetup = true
  if sixHandedToFive and #sortedSeatedPlayers == 6 then
    playerCount = 5
    dealSettings = "dealerSitsOut"
    print("[21AF21]Dealer will sit out every hand.")
    return
  end
  dealSettings = "normal"
  playerCount = #sortedSeatedPlayers
end

--Gets the index location of a color in a list
function getColorVal(color, list)
  for i, colors in ipairs(list) do
    if colors == color then
      return i
    end
  end
end

--Checks if a deck exists on the table
function deckExists()
  return getDeck(tableZone) ~= nil
end

--Called to flip over a table of cards
function flipCards(cards)
  for _, card in pairs(cards) do
    card.flip()
  end
end

--Called to build dealOrder correctly
--Adds "Blinds" to the dealOrder table in the position directly after the current dealer
--If dealer sits out replaces dealer with blinds
function calculateDealOrder(arg)
  local json = JSON.encode(sortedSeatedPlayers)
  dealOrder = JSON.decode(json)
  local blinds = "Blinds"
  if arg == "normal" then
    blindVal = dealerColorVal + 1
    if blindVal > #dealOrder + 1 then
      blindVal = 1
    end
    table.insert(dealOrder, blindVal, blinds)
  else
    table.remove(dealOrder, dealerColorVal)
    table.insert(dealOrder, dealerColorVal, blinds)
  end
end

--Start of New Hand event
function setUpHandEvent()
  if not passInProgress then
    passInProgress = true
    startLuaCoroutine(self, 'dealCardsCoroutine')
  end
end

--Order of opperations for dealing
function dealCardsCoroutine()
  if gameSetUpInProgress then
    print("[21AF21]Setup Is Currently In Progress.")
    passInProgress = false
    return 1
  end
  if not gameSetUpRan then
    print("[21AF21]Press Set Up Game First.")
    passInProgress = false
    return 1
  end
  if not varSetup then
    setUpVar()
  end

  if counterVisible then
    toggleCounterVisibility()
  end

  cardsToBeBuried = false

  if not firstDealOfGame then
    dealerColorVal = dealerColorVal + 1
    if dealerColorVal > #sortedSeatedPlayers then
      dealerColorVal = 1
    end

    local rotationAngle, playerPos = retrieveItemMoveData(sortedSeatedPlayers[dealerColorVal])
    pause(0.1)
    moveDealerChipInFrontOfPlayer(sortedSeatedPlayers[dealerColorVal], rotationAngle, playerPos)
    rebuildDeck()
    pause(0.20)
    moveDeckInFrontOfPlayer(sortedSeatedPlayers[dealerColorVal], rotationAngle, playerPos)
    pause(0.75)
    calculateDealOrder(dealSettings)
    pause(0.15)
  else
    calculateDealOrder(dealSettings)
    firstDealOfGame = false
  end

  flipDeck(tableZone)
  pause(0.35)

  local count = getNextColorValInList(dealerColorVal, dealOrder)
  local roundTrigger = 1
  local round = 1
  local target = dealOrder[count]

  flipDeck(tableZone)
  pause(0.15)
  getDeck(tableZone).randomize()
  pause(0.35)

  local deck = getDeck(tableZone)
  local rotationVal = deck.getRotation()
  
  while deckExists() do
    if count > #dealOrder then
      count = 1
      target = dealOrder[count]
    end
    if roundTrigger > #dealOrder then
      roundTrigger = 1
      round = round + 1
    end
    if DEBUG then
      print(playerCount .. " " .. count .. " " .. target .. " " .. round)
    end
    dealLogic(playerCount, target, round, deck, rotationVal)
    pause(0.25)
    count = count + 1
    roundTrigger = roundTrigger + 1
    target = dealOrder[count]
  end

  passInProgress = false
  return 1
end
--end of order of opperations for dealing

--Contains the logic to deal correctly based on the number of
--players seated and the number of times players have recieved cards
--Number of Players, target color, round number
function dealLogic(p, t, r, deck, rotationVal)
  if p == 3 then
    if t ~= "Blinds" and (r == 2 or r == 3) then
      deck.deal(3, t)
    elseif t ~= "Blinds" then
      deck.deal(2, t)
    elseif t == "Blinds" and r == 2 then
      dealToBlinds(deck, rotationVal)
    end
  elseif p == 4 then
    if t ~= "Blinds" and r == 2 then
      deck.deal(3, t)
    elseif t ~= "Blinds" then
      deck.deal(2, t)
    elseif t == "Blinds" and r == 1 then
      dealToBlinds(deck, rotationVal)
    end
  elseif p == 5 then
    if t ~= "Blinds" then
      deck.deal(2, t)
    elseif t == "Blinds" and r == 1 then
      dealToBlinds(deck, rotationVal)
    end
  elseif p == 6 then
    if t ~= "Blinds" and r == 2 then
      deck.deal(3, t)
    elseif t == "Blinds" and r == 1 then
      dealToBlinds(deck, rotationVal)
    elseif t ~= "Blinds" then
      deck.deal(2, t)
    end
  end
end

--Calculates the rotation of blinds and deals blinds
function dealToBlinds(deck, rotationVal)
  local rotatedPos = {
    vector(-0.7, 1, 0):rotateOver('y', rotationVal.y),
    vector(0.8, 1, 0):rotateOver('y', rotationVal.y)
  }
  deck.takeObject({
    position = rotatedPos[1],
    rotation = {rotationVal.x, rotationVal.y, 180}
  })
  pause(0.15)
  deck.takeObject({
    position = rotatedPos[2],
    rotation = {rotationVal.x, rotationVal.y, 180}
  })
end

--end of functions used by New Hand event

--Prints a message if player passes or is forced to pick
function passEvent(player)
  if sixHandedToFive and playerCount == 5 and #sortedSeatedPlayers == 6 then
    if player.color == getPlayerObject(dealerColorVal, sortedSeatedPlayers).color then
      broadcastToColor("[DC0000]You can not pass while sitting out.", player.color)
      return
    end
  end
  if not dealerColorVal then
    return
  end
  local dealerColor = getPlayerObject(dealerColorVal, sortedSeatedPlayers).color
  if not passInProgress  and checkCardCount(centerZone, 2) then
    if player.color == dealerColor then
      if not DEBUG then
        broadcastToColor("[DC0000]Dealer can not pass. Pick your own!", dealerColor)
      else
        print("[DC0000]Dealer can not pass. " .. dealerColor .. " pick your own!")
      end
    else
      broadcastToAll(player.steam_name .. " passed")
    end
  end
end

--Moves the blinds into the pickers hand, sets player to pickingPlayer
--Sets flag cardsToBeBuried to trigger buryCards logic
function pickBlindsEvent(player)
  if sixHandedToFive and playerCount == 5 and #sortedSeatedPlayers == 6 then
    if player.color == getPlayerObject(dealerColorVal, sortedSeatedPlayers).color then
      broadcastToColor("[DC0000]You can not pick while sitting out.", player.color)
      return
    end
  end
  if passInProgress then
    return
  end
  local blinds = getLooseCards(centerZone)
  if #blinds ~= 2 then
    return
  end
  pickingPlayer = player
  cardsToBeBuried = true
  broadcastToAll(player.steam_name .. " Picks!")
  for _, card in pairs(blinds) do
    card.setPositionSmooth(Player[player.color].getHandTransform().position)
    card.setRotationSmooth(Player[player.color].getHandTransform().rotation)
  end
  Wait.time(
    function()
      for _, card in pairs(Player[player.color].getHandObjects()) do
        if card.is_face_down then
          card.flip()
        end
      end
    end,
    0.35
  )
end

--Returns the color of the next seated player clockwise from given color
function getNextColorValInList(index, list)
  for i, colors in ipairs(list) do
    if i == index then
      local nextColorVal = i + 1
      if nextColorVal > #list then
        nextColorVal = 1
      end
      if list[nextColorVal] == "Blinds" then
        nextColorVal = nextColorVal + 1
      end
      return nextColorVal
    end
  end
end

--Checks the pickers trickZone for 2 cards, waits 4.5 seconds and
--checks again. If still 2 cards executes logic to end cardsToBeBuried
--Finds the player to lead out and prints a message
function doubleCheckBuriedCards()
  local firstCheck = checkCardCount(trickZones[pickingPlayer.color], 2)
  local secondCheck = false
  if firstCheck then
    doubleCheckBuriedID = Wait.time(
      function()
        secondCheck = checkCardCount(trickZones[pickingPlayer.color], 2)
      end,
      3
    )
    doubleCheckBuriedPartTwoID = Wait.time(
      function()
        if firstCheck == secondCheck then
          cardsToBeBuried = false
          local leadOutPlayer = getPlayerObject(dealerColorVal + 1, sortedSeatedPlayers)
          group(getLooseCards(trickZones[pickingPlayer.color]))
          if not DEBUG then
            broadcastToAll(leadOutPlayer.steam_name .. " leads out.")
          else
            print(leadOutPlayer.color .. " leads out.")
          end
        end
      end,
      3.1
    )
  end
end

--Moves the trick to the players trickZone who triggered the event
--Checks if hand is over by counting cards in playerHand if so triggers counterVisibility
function takeTrickEvent(player)
  if not checkCardCount(centerZone, playerCount) then
    return
  end
  if sixHandedToFive and playerCount == 5 and #sortedSeatedPlayers == 6 then
    if player.color == getPlayerObject(dealerColorVal, sortedSeatedPlayers).color then
      broadcastToColor("[DC0000]You can not take tricks while sitting out.", player.color)
      return
    end
  end
  if sortedSeatedPlayers == nil then
    return
  end
  if not takeTrickInProgress then
    takeTrickInProgress = true
    local playerTrickZone = findZoneObject(player.color, trickZones)
    group(getLooseCards(centerZone))
    Wait.time(function() flipDeck(centerZone) end, 0.6)
    Wait.time(
      function()
        local trick = getDeck(centerZone)
        local oldTricks = getDeck(playerTrickZone, "big")
        if oldTricks then
          local oldTricksPos = oldTricks.getPosition()
          local oldTricksRot = oldTricks.getRotation()
          trick.setPositionSmooth({oldTricksPos.x, oldTricksPos.y + 0.5, oldTricksPos.z})
          trick.setRotationSmooth({oldTricksRot.x, oldTricksRot.y, 180})
        else
          local zoneRotation = playerTrickZone.getRotation()
          local zonePos = playerTrickZone.getPosition()
          trick.setPositionSmooth({zonePos.x, zonePos.y - 2.7, zonePos.z})
          trick.setRotationSmooth({zoneRotation.x, zoneRotation.y + 180, 180})
        end
      end,
      1.5
    )
    Wait.time(function() group(getLooseCards(playerTrickZone)) end, 2)
    if #player.getHandObjects() == 0 then
      Wait.time(function() toggleCounterVisibility(pickingPlayer.color) end, 2)
    end
    Wait.time(function() takeTrickInProgress = false end, 2.5)
  end
end

--Returns the rotation value for the invisible block that holds up the counters
function getBlockRotation(color)
  local colorToRotation = {
    Pink = 30,
    Yellow = 30,
    White = 270,
    Green = 270,
    Red = 330,
    Blue = 330
  }
  return colorToRotation[color]
end

--Toggles the visibility of the counters, on counter spawn will spawn
--the counter in front of the given color (pickerColor)
--Flips over pickers tricks to see score of hand
function toggleCounterVisibility(color)
  if not counterVisible then
    local tableBlockSpawnPos = vector(0, 3.96, 0)
    local pickerCounterSpawnPos = vector(0, 1.83, -4.04)
    local tableCounterSpawnPos = vector(0, 1.83, 4.04)
    local pickerRotation = getColorRotation(color)
    local blockRotation = getBlockRotation(color)
    local tCounterPos = tableCounterSpawnPos:rotateOver('y', pickerRotation)
    local pCounterPos = pickerCounterSpawnPos:rotateOver('y', pickerRotation)
    local block = hiddenBag.takeObject({
      position = tableBlockSpawnPos,
      rotation = {0, blockRotation, 0},
      smooth = false,
      guid = GUID.TABLE_BLOCK
    })
    block.setLock(true)
    block.setInvisibleTo(ALL_PLAYERS)
    Wait.frames(
      function()
        hiddenBag.takeObject({
          position = tCounterPos,
          rotation = {295, pickerRotation - 180, 0},
          smooth = false,
          guid = GUID.CARD_COUNTER_TABLE
        })
        hiddenBag.takeObject({
          position = pCounterPos,
          rotation = {295, pickerRotation, 0},
          smooth = false,
          guid = GUID.CARD_COUNTER_PICKER
        })
      end,
      3
    )
    Wait.frames(
      function()
        local tCounter = getObjectFromGUID(GUID.CARD_COUNTER_TABLE)
        local pCounter = getObjectFromGUID(GUID.CARD_COUNTER_PICKER)
        tCounter.setInvisibleTo()
        pCounter.setInvisibleTo()
        counterVisible = true
      end,
      20
    )
    local pickerZone = findZoneObject(pickingPlayer.color, trickZones)
    local pickerCards = getLooseCards(pickerZone)
    if pickerCards then
      group(pickerCards)
      Wait.time(
        function()
          local pickerTricks = getDeck(pickerZone)
          pickerTricks.setPositionSmooth({pickerZone.getPosition().x, 1.25, pickerZone.getPosition().z})
          pickerTricks.setRotationSmooth({0, pickerTricks.getRotation().y, 0})
        end,
        0.6
      )
    end
    --Card counter Loop starts here with setupGuidTable()
    Wait.frames(function() setupGuidTable() end, 22)
  else
    local tCounter = getObjectFromGUID(GUID.CARD_COUNTER_TABLE)
    local pCounter = getObjectFromGUID(GUID.CARD_COUNTER_PICKER)
    local triangle = getObjectFromGUID(GUID.TABLE_BLOCK)
    tCounter.setInvisibleTo(ALL_PLAYERS)
    pCounter.setInvisibleTo(ALL_PLAYERS)
    hiddenBag.putObject(tCounter)
    hiddenBag.putObject(pCounter)
    hiddenBag.putObject(triangle)
    counterVisible = false
    trickCountStop()
  end
end

--Handles the event of when an object enters a scritping zone
function onObjectEnterScriptingZone(zone, object)
  --Setting cardsToBeBuried to true will trigger the following code
  --Looks for pickingPlayer trickZone then looks for cards and temporarily
  --hides from all other players but pickingPlayer waits 2 seconds,
  --makes sure cards are face down and shows to all players
  if cardsToBeBuried then
    local pickerZone = trickZones[pickingPlayer.color]
    if zone == pickerZone and object.tag == 'Card' then
      local hideFrom = removeColorFromList(pickingPlayer.color, sortedSeatedPlayers)
      object.setInvisibleTo(hideFrom)
      Wait.time(
        function()
          local objListUpdate = getLooseCards(pickerZone)
          for _, obj in pairs(objListUpdate) do
            if not obj.is_face_down then
              obj.flip()
            end
            obj.setInvisibleTo()
          end
        end,
        2
      )
    end
    --Where doubleCheckBuriedCards executes from
    if zone == pickerZone then
      doubleCheckBuriedCards()
    end
  end
  --More functions to run inside of onObjectEnterScriptingZone go here
end

--Handles the event of when an object leaves a scritping zone
function onObjectLeaveZone(zone, object)
  --Stops doubleCheckBuriedCards from running if the second of two
  --cards leaves the pickers trickZone
  if cardsToBeBuried then
    local pickerZone = trickZones[pickingPlayer.color]
    if zone == pickerZone then
      local checkBuried = checkCardCount(pickerZone, 1)
      if checkBuried and doubleCheckBuriedID then
        Wait.stop(doubleCheckBuriedID)
        Wait.stop(doubleCheckBuriedPartTwoID)
      elseif not doubleCheckBuriedID and countCards(pickerZone) > 1 then
        doubleCheckBuriedCards()
      end
    end
  end
end

--New functions to adapt Blackjack Card Counter
--Returns the color of the handposition located across the table from given color (pickingPlayer)
function findColorAcrossTable(color)
  for i, colors in ipairs(ALL_PLAYERS) do
    local acrossVal = 0
    if colors == color then
        if i > 3 then
          acrossVal = i - 3
        else
          acrossVal = i + 3
        end
      return ALL_PLAYERS[acrossVal]
    end
  end
end

--Creates two tables, of the entity of each zone and counter, of each zoneObject
--and its associated counterObject, then starts the loop
function setupGuidTable()
  local pickerZoneGuid = findZoneObject(pickingPlayer.color, trickZones).guid
  local colorAcrossFromPicker = findColorAcrossTable(pickingPlayer.color)
  local tableZoneGuid = findZoneObject(colorAcrossFromPicker, trickZones).guid

  guidTable = {
    [pickerZoneGuid] = GUID.CARD_COUNTER_PICKER,
    [tableZoneGuid] = GUID.CARD_COUNTER_TABLE
  }

  objectSets = {}
    for zoneGUID, counterGUID in pairs(guidTable) do
      table.insert(objectSets, {z=getObjectFromGUID(zoneGUID), c=getObjectFromGUID(counterGUID)})
  end
  countTricks()
end

---------------------------------------------------------------
--[[    Universal Blackjack Card Counter    by: MrStump    ]]--
---------------------------------------------------------------

--The names (in quotes) should all match the names on your cards.
--The values should match the value of those cards.

cardNameTable= {
  ["Seven"]=0, ["Eight"]=0, ["Nine"]=0,
  ["Ten"]=10, ["Jack"]=2, ["Queen"]=3, ["King"]=4,
  ["Ace"]=11
}

----------------------------------------------------------
--[[    END OF CODE TO EDIT, unless you know Lua    ]]----
----------------------------------------------------------

--Looks for any cards in the scripting zones and sends them on to obtainCardValue
--Looks for any decks in the scripting zones and sends them on to obtainDeckValue
--Triggers next step, addValues(), after that
function countTricks()
    values = {}
    hiddenValue = nil
    for i, set in ipairs(objectSets) do
        values[i] = {}
        local objectsInZone = set.z.getObjects()
        for j, object in ipairs(objectsInZone) do
            if object.tag == "Card" then
                obtainCardValue(i, object)
            elseif object.tag == "Deck" then
                local z = object.getRotation().z
                if z > 345 or z < 15 then
                    obtainDeckValue(i, object)
                end
            end
        end
    end
    addValues()
end

--Checks cards sent to it and, if their name contains cardNameTable, it adds the value to a table
function obtainCardValue(i, object)
    for name, val in pairs(cardNameTable) do
        if string.find(object.getName(), name) then
            local z = object.getRotation().z
            if z > 345 or z < 15 then
                table.insert(values[i], val)
            else
                hiddenValue = val
            end
        end
    end
end

--Checks decks sent to it and, if their cards names contains cardNameTable, it adds the values to a table
function obtainDeckValue(i, deck)
    local cards = deck.getObjects()
    for k, card in ipairs(cards) do
        for name, val in pairs(cardNameTable) do
            if string.find(card.nickname, name) then
                table.insert(values[i], val)
			end
        end
    end
end

--Totals up values in the tables from the 2 above functions
function addValues()
    totals = {}
    --For non-ace cards
    for i, v in ipairs(values) do
        totals[i] = 0
        for j=1, #v do
            if v[j] ~= 99 then
                totals[i] = totals[i] + v[j]
            end
        end
    end
    displayResults()
end

--Sends totaled values to the counters. It also color codes the counters to match
function displayResults()
    for i, set in pairs(objectSets) do
        set.c.setValue(totals[i])
        local total = totals[i]
        if i==1 and (total < 61 and total > 30) then
          set.c.setColorTint({1,250/255,160/255})
        elseif i==2 and (total < 60 and total > 29) then
          set.c.setColorTint({1,250/255,160/255})
        elseif i==2 and total == 60 then
          set.c.setColorTint({0,1,0})
        elseif total > 60 then
            set.c.setColorTint({0,1,0})
        else
            set.c.setColorTint({0,0,0})
        end
    end
    trickCountStart()
end

--Restarts loop back up at countTricks
function trickCountStart()
    Timer.destroy("SheepsheadGlobalTimer")
    Timer.create({identifier="SheepsheadGlobalTimer", function_name='countTricks', delay=1})
end

--Stops the trickCount Loop
function trickCountStop()
    Timer.destroy("SheepsheadGlobalTimer")
end
--END OF CARD SCORING

--Settings
sixHandedToFive = false
showCallsWindow = false
toBuildCallsPanel = false
callSettings = {
  sheepsheadCall = false,
  blitzCall = false,
  leasterCall = false,
  crackCall= false,
  crackBackCall = false,
  crackAroundCall = false
}
currentRules = {
  "\n\n\n\n\n\n\n",
  "[21AF21]Welcome to Scripted Sheepshead!\n",
  "By: WardLordRuby           \n",
  "[b415ff]Features:                   \n",
  "[FFFFFF]Will Auto Adjust for 3-6 Players\n",
  "Scripted Dealing, Picking,     \n",
  "Taking Tricks, Burying        \n",
  "Card Counters for Each Team \n",
  "Custom Game Settings       \n",
  "Custom Schrute Silver Coins   \n",
  "Gameplay Rules and Tips    \n",
  "Use (.help) for Commands    \n\n",
  "[b415ff]Current Sheepshead Rules:   \n",
  "[-]Jack of Diamonds Partner    \n",
  "Dealer Pick your Own       \n",
  "Can Call if Forced to Pick    \n",
  "6 Handed - Normal        \n",
  "Call Menu Disabled       "
}

--Prints currentRules to the screen
function displayRules()
  setNotes(table.concat(currentRules, ""))
end

--Disables all calls
function resetCalls()
  toBuildCallsPanel = false
  UI.setAttribute("callSettingsBackground", "image", "callsDisabled")
  --UI.hide("callsPanel")
  disableSheepshead()
  disableBlitz()
  disableLeaster()
  disableCrack()
  disableCrackBack()
  disableCrackAround()
end

--Start of buttons inside of settings window
function dealerSitsOut()
  if gameSetupInProgress or passInProgress then
    return
  end
  UI.setAttribute("settingsButtonDealerSitsOutOff", "active", "false")
  UI.setAttribute("settingsButtonDealerSitsOutOn", "active", "true")
  sixHandedToFive = true
  varSetup = false
  currentRules[17] = "6 Handed - Dealer Sits Out   \n"
  displayRules()
end

function dealerSitsOutOff()
  if gameSetupInProgress or passInProgress then
    return
  end
  UI.setAttribute("settingsButtonDealerSitsOutOff", "active", "true")
  UI.setAttribute("settingsButtonDealerSitsOutOn", "active", "false")
  sixHandedToFive = false
  varSetup = false
  currentRules[17] = "6 Handed - Normal        \n"
  displayRules()
end

function enableCalls()
  UI.setAttribute("settingsButtonCallsOff", "active", "false")
  UI.setAttribute("settingsButtonCallsOn", "active", "true")
  UI.setAttribute("callSettingsBackground", "image", "crackDisabled")
  toBuildCallsPanel = true
  currentRules[18] = "Call Menu Enabled        "
  displayRules()
end

function disableCalls()
  UI.setAttribute("settingsButtonCallsOff", "active", "true")
  UI.setAttribute("settingsButtonCallsOn", "active", "false")
  resetCalls()
  currentRules[18] = "Call Menu Disabled       "
  displayRules()
end

function enableSheepshead()
  if not toBuildCallsPanel then
    return
  end
  UI.setAttribute("settingsButtonSheepsheadOff", "active", "false")
  UI.setAttribute("settingsButtonSheepsheadOn", "active", "true")
  callSettings.sheepsheadCall = true
end

function disableSheepshead()
  UI.setAttribute("settingsButtonSheepsheadOff", "active", "true")
  UI.setAttribute("settingsButtonSheepsheadOn", "active", "false")
  callSettings.sheepsheadCall = false
end

function enableBlitz()
  if not toBuildCallsPanel then
    return
  end
  UI.setAttribute("settingsButtonBlitzOff", "active", "false")
  UI.setAttribute("settingsButtonBlitzOn", "active", "true")
  callSettings.blitzCall = true
end

function disableBlitz()
  UI.setAttribute("settingsButtonBlitzOff", "active", "true")
  UI.setAttribute("settingsButtonBlitzOn", "active", "false")
  callSettings.blitzCall = false
end

function enableLeaster()
  if not toBuildCallsPanel then
    return
  end
  UI.setAttribute("settingsButtonLeasterOff", "active", "false")
  UI.setAttribute("settingsButtonLeasterOn", "active", "true")
  callSettings.leasterCall = true
end

function disableLeaster()
  UI.setAttribute("settingsButtonLeasterOff", "active", "true")
  UI.setAttribute("settingsButtonLeasterOn", "active", "false")
  callSettings.leasterCall = false
end

function enableCrack()
  if not toBuildCallsPanel then
    return
  end
  UI.setAttribute("settingsButtonCrackOff", "active", "false")
  UI.setAttribute("settingsButtonCrackOn", "active", "true")
  UI.setAttribute("callSettingsBackground", "image", "callPanel")
  callSettings.crackCall = true
end

function disableCrack()
  UI.setAttribute("settingsButtonCrackOff", "active", "true")
  UI.setAttribute("settingsButtonCrackOn", "active", "false")
  if toBuildCallsPanel then
    UI.setAttribute("callSettingsBackground", "image", "crackDisabled")
  end
  disableCrackBack()
  disableCrackAround()
  callSettings.crackCall = false
end

function enableCrackBack()
  if not callSettings.crackCall then
    return
  end
  if callSettings.crackAroundCall then 
    disableCrackAround()
  end
  UI.setAttribute("settingsButtonCrackBackOff", "active", "false")
  UI.setAttribute("settingsButtonCrackBackOn", "active", "true")
  callSettings.crackBackCall = true
end

function disableCrackBack()
  UI.setAttribute("settingsButtonCrackBackOff", "active", "true")
  UI.setAttribute("settingsButtonCrackBackOn", "active", "false")
  callSettings.crackBackCall = false
end

function enableCrackAround()
  if not callSettings.crackCall then
    return
  end
  if callSettings.crackBackCall then 
    disableCrackBack()
  end
  UI.setAttribute("settingsButtonCrackAroundOff", "active", "false")
  UI.setAttribute("settingsButtonCrackAroundOn", "active", "true")
  callSettings.crackAroundCall = true
end

function disableCrackAround()
  UI.setAttribute("settingsButtonCrackAroundOff", "active", "true")
  UI.setAttribute("settingsButtonCrackAroundOn", "active", "false")
  callSettings.crackAroundCall = false
end

function closeSettingsWindow()
  UI.setAttribute("settingsWindowExitButton", "image", "closeButton")
  UI.hide("settingsWindow")
  if toBuildCallPanel then
    --buildCallsPanel()
  end
end
--End of buttons inside of settings window

--Start of graphic anamations
function passButtonAnimateEnter()
  UI.setAttribute("Pass", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731614/810B2AC159903904EBDB0531A5807A6A679DD8B4/")
end

function passButtonAnimateExit()
  UI.setAttribute("Pass", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731501/13B7D22788C1142BFC7852C48DFED46A5897C757/")
end

function passButtonAnimateDown()
  UI.setAttribute("Pass", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731566/5B95753A5AC0B64B37D4861AAF85C427C8F2E01C/")
end

function passButtonAnimateUp()
  UI.setAttribute("Pass", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731614/810B2AC159903904EBDB0531A5807A6A679DD8B4/")
end

function toolboxAnimateDown()
  UI.setAttribute("Toolbox", "image", "toolboxMainPressed")
end

function toolboxAnimateUp()
  UI.setAttribute("Toolbox", "image", "toolboxMain")
end

function dealButtonAnimateEnter()
  UI.setAttribute("Deal", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731456/E1D91D169AF5BEA05ACEB680DB0A784CD3537A51/")
end

function dealButtonAnimateExit()
  UI.setAttribute("Deal", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353654571/82CC6E88D206B72B2E0AE8DEF90887FFD6D20BB6/")
end

function dealButtonAnimateDown()
  UI.setAttribute("Deal", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731392/BE2E76F2FB88EF05D794D4BF094FEC6EF90D38B8/")
end

function dealButtonAnimateUp()
  UI.setAttribute("Deal", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731456/E1D91D169AF5BEA05ACEB680DB0A784CD3537A51/")
end

function pickButtonAnimateEnter()
  UI.setAttribute("Pick", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731729/BD02E7BFE2C75F3D8705FD90CF9B4B8483F0AF6D/")
end

function pickButtonAnimateExit()
  UI.setAttribute("Pick", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731650/2C7000D4525A18ADB4A361D6B1EC61EC38E02C91/")
end

function pickButtonAnimateDown()
  UI.setAttribute("Pick", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731687/0403B70DEE5F66118506F5C0D3BA3636F6036171/")
end

function pickButtonAnimateUp()
  UI.setAttribute("Pick", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731729/BD02E7BFE2C75F3D8705FD90CF9B4B8483F0AF6D/")
end

function takeTrickButtonAnimateEnter()
  UI.setAttribute("TakeTrick", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731853/1C182D56A0A7769737480158DC97C3468C16DEA8/")
end

function takeTrickButtonAnimateExit()
  UI.setAttribute("TakeTrick", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731772/C51F655BEE5CBF3E2F8202CFEAE85450948C392E/")
end

function takeTrickButtonAnimateDown()
  UI.setAttribute("TakeTrick", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731810/561076396C695877C8B4321D3FAD68B46B86B731/")
end

function takeTrickButtonAnimateUp()
  UI.setAttribute("TakeTrick", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353731853/1C182D56A0A7769737480158DC97C3468C16DEA8/")
end

function settingsButtonAnimateEnter()
  UI.setAttribute("Settings", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353654037/58CD87EEF6CEB3B846065CF643B7485071E6B8E7/")
end

function settingsButtonAnimateExit()
  UI.setAttribute("Settings", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353653899/8D89287896177F48C753C7435E8D224DE57632CF/")
end

function settingsButtonAnimateDown()
  UI.setAttribute("Settings", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353653970/67B6C0044AB08D7069D725D09A7513CD76DFB3A3/")
end

function settingsButtonAnimateUp()
  UI.setAttribute("Settings", "image", "http://cloud-3.steamusercontent.com/ugc/2233283965353654037/58CD87EEF6CEB3B846065CF643B7485071E6B8E7/")
end

function closeSettingsButtonAnimateEnter()
  UI.setAttribute("settingsWindowExitButton", "image", "closeButtonHover")
end

function closeSettingsButtonAnimateExit()
  UI.setAttribute("settingsWindowExitButton", "image", "closeButton")
end

function closeSettingsButtonAnimateDown()
  UI.setAttribute("settingsWindowExitButton", "image", "closeButtonPressed")
end
--End of graphic anamations

--Debug tools
function playerCountDebugUp()
  if DEBUG then
    if sortedSeatedPlayers == nil then
      print("[21AF21]Press Set Up Game to initialize variables before changing player count.")
    elseif #sortedSeatedPlayers > 0 and #sortedSeatedPlayers < 6 then
      table.insert(sortedSeatedPlayers, #sortedSeatedPlayers + 1,
      ALL_PLAYERS[#sortedSeatedPlayers + 1])
      print("Current players: ", table.concat(sortedSeatedPlayers, ", "))
    else
      print("Can not add any more players")
      print("Current players: ", table.concat(sortedSeatedPlayers, ", "))
    end
  end
end

function playerCountDebugDown()
  if DEBUG then
    if sortedSeatedPlayers == nil then
      print("[21AF21]Press Set Up Game to initialize variables before changing player count.")
    elseif #sortedSeatedPlayers == 1 then
      print("Can not remove any more players")
      print("Current players: ", table.concat(sortedSeatedPlayers, ", "))
    else
      table.remove(sortedSeatedPlayers, #sortedSeatedPlayers)
      print("Current players: ", table.concat(sortedSeatedPlayers, ", "))
    end
  end
end

function test()
  
end
