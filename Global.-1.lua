--[[ Scripted version of Sheepshead built inside of Tabletop Simulator By: WardLordRuby
     Scoring currently uses a modified version of the blackjack counting script by: MrStump
     I liked how EpicWolverine handled rebuilding the deck so I modified his code ]]--

DEBUG = true

GUID = {
  TRICK_ZONE_WHITE = "70f1a5",
  TRICK_ZONE_RED = "b14dc7",
  TRICK_ZONE_YELLOW = "db8133",
  TRICK_ZONE_GREEN = "85fad3",
  TRICK_ZONE_BLUE = "69cfb0",
  TRICK_ZONE_PINK = "de62ee",
  HAND_ZONE_WHITE = "f01eb8",
  HAND_ZONE_RED = "c57287",
  HAND_ZONE_YELLOW = "bfea25",
  HAND_ZONE_GREEN = "98ae00",
  HAND_ZONE_BLUE = "1222be",
  HAND_ZONE_PINK = "166a59",
  CENTER_ZONE = "548811",
  TABLE_ZONE = "3c99b3",
  DROP_ZONE = "ba398c",
  HIDDEN_BAG = "b3d3a5",
  TABLE_BLOCK = "8e445a",
  DEALER_CHIP = "e18594",
  SET_BURIED_BUTTON = "37d199",
  DECK_COPY = "f247a7"
}

ALL_PLAYERS = {"White", "Red", "Yellow", "Green", "Blue", "Pink"}

SPAWN_POS = {
  tableBlock = Vector(0, 3.96, 0),
  pickerCounter = Vector(0, 1.83, -4.04),
  tableCounter = Vector(0, 1.83, 4.04),
  ruleBook = Vector(0, 0.96, -9.5),
  dealerChip = Vector(4, -2.58, 7),
  deck = Vector(2, -2.5, 5),
  setBuriedButton = Vector(0, 0.96, -8),
  blinds = {
    Vector(-0.7, 1, 0),
    Vector(0.8, 1, 0)
  },
  chips = {
    Vector(4.62, -2, 3),
    Vector(6.12, -2, 3.13),
    Vector(5.31, -2, 4.35)
  }
}

ROTATION = {
  color = {
    White = 0,
    Red = 60,
    Yellow = 120,
    Green = 180,
    Blue = 240,
    Pink = 300
  },
  block = {
    Pink = 30,
    Yellow = 30,
    White = 270,
    Green = 270,
    Red = 330,
    Blue = 330
  }
}

COIN_PRAM = {
  mesh = "http://cloud-3.steamusercontent.com/ugc/2205135744307283952/DEF0BF91642CF5636724CA3A37083385C810BA06/",
  diffuse = "http://cloud-3.steamusercontent.com/ugc/2288456143464578824/E739670FE62B8267C90E54D4B786C1C83BA7CC22/",
  type = 5,
  material = 2,
  specular_sharpness = 5
}

function onLoad()
  trickZone = {
    White = getObjectFromGUID(GUID.TRICK_ZONE_WHITE),
    Red = getObjectFromGUID(GUID.TRICK_ZONE_RED),
    Yellow = getObjectFromGUID(GUID.TRICK_ZONE_YELLOW),
    Green = getObjectFromGUID(GUID.TRICK_ZONE_GREEN),
    Blue = getObjectFromGUID(GUID.TRICK_ZONE_BLUE),
    Pink = getObjectFromGUID(GUID.TRICK_ZONE_PINK)
  }
  handZone = {
    White = getObjectFromGUID(GUID.HAND_ZONE_WHITE),
    Red = getObjectFromGUID(GUID.HAND_ZONE_RED),
    Yellow = getObjectFromGUID(GUID.HAND_ZONE_YELLOW),
    Green = getObjectFromGUID(GUID.HAND_ZONE_GREEN),
    Blue = getObjectFromGUID(GUID.HAND_ZONE_BLUE),
    Pink = getObjectFromGUID(GUID.HAND_ZONE_PINK)
  }
  scriptZone = {
    center = getObjectFromGUID(GUID.CENTER_ZONE),
    table = getObjectFromGUID(GUID.TABLE_ZONE),
    drop = getObjectFromGUID(GUID.DROP_ZONE)
  }
  staticObject = {
    hiddenBag = getObjectFromGUID(GUID.HIDDEN_BAG),
    dealerChip = getObjectFromGUID(GUID.DEALER_CHIP),
    setBuriedButton = getObjectFromGUID(GUID.SET_BURIED_BUTTON)
  }
  staticObject.hiddenBag.interactable = false
  staticObject.dealerChip.interactable = false
  staticObject.setBuriedButton.interactable = false
  staticObject.hiddenBag.setInvisibleTo(ALL_PLAYERS)
  staticObject.setBuriedButton.setInvisibleTo(ALL_PLAYERS)

  flag = {
    gameSetup = {
      inProgress = false,
      ran = false
    },
    trick = {
      inProgress = false,
      handOut = false
    },
    stopCoroutine = false,
    dealInProgress = false,
    lookForPlayerText = false,
    continue = false,
    cardsToBeBuried = false,
    counterVisible = false,
    firstDealOfGame = false,
    allowGrouping = true
  }

  if DEBUG then
    UI.show("playerUp")
    UI.show("playerDown")
    UI.show("test")
  end

  displayRules()
end

--[[Utility functions]]--

---Checks dealInProgress, trick.handOut, and gameSetup.inProgress
function safeToContinue()
  if flag.dealInProgress or flag.trick.handOut or flag.gameSetup.inProgress then
    return false
  end
  return true
end

---Pauses script, must be called from within a coroutine
---@param time integer_seconds
function pause(time)
  local start = Time.time
  repeat coroutine.yield(0) until Time.time > start + time
end

--[[String manipulation]]--

---@return string
function getLastWord(str)
  return str:match("%S+$") --%S+ = one or more non-space characters, $ = match end of string
end

---@param str string
function upperFirstChar(str)
  return str:sub(1, 1):upper() .. str:sub(2)
end

---@param str string
function lowerFirstChar(str)
  return str:sub(1, 1):lower() .. str:sub(2)
end

---Inserts a space before every capital letter in string
---@param str string
---@return string
function insertSpaces(str)
  return str:gsub("(%u)", " %1") --(%u) = capture group match upperCase letter, %1 = link to capture group
end

---@param str string
---@return string
function removeSpaces(str)
  return str:gsub("%s", "") --%s = space character
end

--[[Table manipulation]]--

---Copys input table and removes input color, if color not found returns original table
---@param color string
---@param list table<"colors">
---@return table <"colors">
function removeColorFromList(color, list)
  local currentIndex
  local json = JSON.encode(list)
  local modifiedList = JSON.decode(json)
  for i, colors in ipairs(modifiedList) do
    if colors == color then
      currentIndex = i
      break
    end
  end
  if currentIndex then
    table.remove(modifiedList, currentIndex)
    return modifiedList
  end
  return list
end

---@param color string
---@param pipeList string
function addColorToPipeList(color, pipeList)
  if pipeList == nil or pipeList == "" then
    pipeList = color
  else
    pipeList = pipeList .. "|" .. color
  end
  return pipeList
end

---@param color string
---@param pipeList string
function removeColorFromPipeList(color, pipeList)
  pipeList = string.gsub(pipeList, color .. "|", "")
  pipeList = string.gsub(pipeList, "|" .. color, "")
  pipeList = string.gsub(pipeList, color, "")
  return pipeList
end

--[[Data retrieval]]--

---@param object object_item
---@param zone object
function isInZone(object, zone)
  local occupiedZones = object.getZones()
  for _, zoneObject in ipairs(occupiedZones) do
    if zoneObject == zone then
      return true
    end
  end
  return false
end

---Used to ensure 0 is returned if table empty or nil,<br>
---or used if you want to get number of elements in table with non integer keys
---@param table table<any>
function tableLength(table)
  local count = 0
  if table == {} or table == nil then
    return 0
  end
  for _, _ in pairs(table) do
    count = count + 1
  end
  return count
end

---@param table table<any>
---@param value any
function tableContains(table, value)
  for _, v in pairs(table) do
    if v == value then
      return true
    end
  end
  return false
end

---Returns the deck from given zone
---If you are aware of more than one deck in a given zone
---getDeck() can return the smaller or larger of the decks found
---@param zone object
---@param size optional_string <"big"|"small">
---@return object_deck
function getDeck(zone, size)
  local decks = {}
  for _, obj in ipairs(zone.getObjects()) do
    if obj.type == 'Deck' then
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
    group(decks)
    pause(1)
    return getDeck(zone)
  end
end

---@param zone object
---@return table<card_Objects_and_deck_Objects>
function getLooseCards(zone)
  local looseCards = {}
  for _, obj in ipairs(zone.getObjects()) do
    if obj.type == "Deck" or obj.type == "Card" then
      table.insert(looseCards, obj)
    end
  end
  return looseCards
end

---Just checks to make sure cards are all there
---@param type string<"table"|"deck">
function verifyCardCount(type)
  local cardCount
  if type == "table" then
    cardCount = countCards(scriptZone.table)
  elseif getDeck(scriptZone.table) then
    cardCount = getDeck(scriptZone.table).getQuantity()
  else
    respawnDeckCoroutine()
    return false
  end
  if playerCount == 4 then
    if cardCount ~= 30 then
      respawnDeckCoroutine()
      return false
    end
  else
    if cardCount ~= 32 then
      respawnDeckCoroutine()
      return false
    end
  end
  return true
end

---@param colorOrVar string_color|integer_index
---@param list table <"colors">
---@return object_player
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

---Returns the index location of a color in a list
---@param color string
---@param list table_colors
function getColorVal(color, list)
  for i, colors in ipairs(list) do
    if colors == color then
      return i
    end
  end
end

---Returns the index of the player seated clockwise from given index
---@param index integer
---@param list table <"colors">
---@return integer <index>
function getNextColorValInList(index, list)
  local listLength = #list
  for i = 1, listLength, 1 do
    if i == index then
      local nextColorVal = (index % listLength) + 1
      while list[nextColorVal] == "Blinds" do
        nextColorVal = (nextColorVal % listLength) + 1
      end
      return nextColorVal
    end
  end
end

---Returns the index of the player seated counter-clockwise from given index
---@param index integer
---@param list table_colors
---@return integer_index
function getPreviousColorValInList(index, list)
  local listLength = #list
  for i = listLength, 1, -1 do
    if i == index then
      local previousColorVal = (index - 2) % listLength + 1
      while list[previousColorVal] == "Blinds" do
        previousColorVal = (previousColorVal - 2) % listLength + 1
      end
      return previousColorVal
    end
  end
end

---Checks if a deck exists on the table
function deckExists()
  return getDeck(scriptZone.table) ~= nil
end

---Returns the rotationValue.z associated for cards if more cards are face up or face down in a given zone
---@param zone object
---@return integer_0|integer_180
function moreFaceUpOrDown(zone)
  local total, faceDownCount = countCards(zone, true)
  local halfOfTotal = math.floor(total / 2)
  if halfOfTotal >= faceDownCount then
    return 0
  else
    return 180
  end
end

---Returns the number of cards in a given zone, can also return faceDownCount
---@param zone object
---@param countFaceDown boolean
---@return integer <numCards | numCards_and_numFaceDown>
function countCards(zone, countFaceDown)
  local objects = zone.getObjects()
  local cardCount, faceDownCount = 0, 0
  for _, obj in ipairs(objects) do
    if obj.type == 'Deck' then
      cardCount = cardCount + obj.getQuantity()
      if countFaceDown then
        if obj.is_face_down then
          faceDownCount = faceDownCount + obj.getQuantity()
        end
      end
    elseif obj.type == 'Card' then
      cardCount = cardCount + 1
      if obj.is_face_down then
        faceDownCount = faceDownCount + 1
      end
    end
  end
  if countFaceDown then
    return cardCount, faceDownCount
  else
    return cardCount
  end
end

---Checks the given card count of a given zone, returns true or false
---@param zone object
---@param count integer
function checkCardCount(zone, count)
  local cardCount = countCards(zone)
  if cardCount == count then
    return true
  end
  return false
end

---@param player object
---@param cardName string
function doesPlayerPossessCard(player, cardName)
  local playerCards = getPlayerCards(player)
  for _, name in ipairs(playerCards) do
    if name == cardName then
      return true
    end
  end
  return false
end

---Searches player handZone and trickZone
---@param player object
---@return table <"cardNames">
function getPlayerCards(player)
  local cards = {}
  for _, card in ipairs(getLooseCards(handZone[player.color])) do
    table.insert(cards, card.getName())
  end
  for _, object in ipairs(getLooseCards(trickZone[player.color])) do
    if object.type == 'Card' then
      table.insert(cards, object.getName())
    else
      for _, card in ipairs(object.getObjects()) do
        table.insert(cards, card.name)
      end
    end
  end
  return cards
end

---Filters cards relevant to determining Call an Ace conditions or finding next highest card to call
---@param player object
---@param scheme string <"suitableFail"|"Ace"|"Ten"|"Jack"|"Queen">
---@param doNotInclude string
---@return table <"cardNames">
function filterPlayerCards(player, scheme, doNotInclude)
  local schemes = {
    suitableFail = {"Seven", "Eight", "Nine", "Ten", "King"},
    Ace = {"Ace"},
    Ten = {"Ten"},
    Jack = {"Jack"},
    Queen = {"Queen"}
  }
  local playerCards = getPlayerCards(player)
  local filteredCards = {}
  for _, name in ipairs(playerCards) do
    for _, findName in ipairs(schemes[scheme]) do
      if string.find(name, findName) and not string.find(name, doNotInclude) then
        table.insert(filteredCards, name)
      end
    end
  end
  return filteredCards
end

---@param color string
---@return integer_rotationAngle, vector_playerPosition
function getItemMoveData(color)
  local rotationAngle = ROTATION.color[color]
  local playerPos = Player[color].getHandTransform().position
  return rotationAngle, playerPos
end

--[[Object manipulation]]--

---Checks if a deck in the given zone is face up, if so it flips the deck
---@param zone object
function flipDeck(zone)
  local deck = getDeck(zone)
  if not deck.is_face_down then
    deck.flip()
  end
end

---Checks if cards in the given zone are face up, if so it flips cards
---@param zone object
function flipCards(zone)
  local cards = getLooseCards(zone)
  for _, card in ipairs(cards) do
    if not card.is_face_down then
      card.flip()
    end
  end
end

---Called to reset the game space<br>
---Removes all chips
function resetBoard()
  for _, obj in ipairs(scriptZone.table.getObjects()) do
    if obj.type == "Chip" then
      obj.destruct()
      pause(0.06)
    end
  end
end

---Moves deck and dealer chip in front of a given color
---@param color string
function moveDeckAndDealerChip()
  local rotationAngle, playerPos = getItemMoveData(sortedSeatedPlayers[dealerColorVal])
  local rotatedChipOffset = SPAWN_POS.dealerChip:copy():rotateOver('y', rotationAngle)
  local rotatedDeckOffset = SPAWN_POS.deck:copy():rotateOver('y', rotationAngle)
  local chipRotation = staticObject.dealerChip.getRotation()
  repeat coroutine.yield(0) until getDeck(scriptZone.table) ~= nil
  local deck = getDeck(scriptZone.table)
  staticObject.dealerChip.setRotationSmooth({ chipRotation.x, rotationAngle - 90, chipRotation.z })
  staticObject.dealerChip.setPositionSmooth(playerPos + rotatedChipOffset)
  deck.setRotationSmooth({ deck.getRotation().x, rotationAngle, 180 })
  deck.setPositionSmooth(playerPos + rotatedDeckOffset)
end

---Spreads cards out over the center of the table, makes sure they are face down, and groups cards
function rebuildDeck()
  flag.allowGrouping = false
  local faceRotation = moreFaceUpOrDown(scriptZone.table)
  for _, object in ipairs(getLooseCards(scriptZone.table)) do
    if object.type == 'Deck' then
      for _, card in ipairs(object.getObjects()) do
        object.takeObject({
          rotation = { 0, math.random(0, 360), faceRotation },
          position = { math.random(-5.75, 5.75), 1.4, math.random(-5.75, 5.75) },
          guid = card.guid
        })
        pause(0.03)
      end
    else
      object.setRotation({ 0, math.random(0, 360), faceRotation })
      object.setPosition({ math.random(-5.75, 5.75), 1.4, math.random(-5.75, 5.75) })
      pause(0.03)
    end
  end
  pause(0.25)
  flipCards(scriptZone.table)
  flag.allowGrouping = true
  pause(0.5)
  group(getLooseCards(scriptZone.table))
  pause(0.5)
  group(getLooseCards(scriptZone.table))
  pause(0.5)
end

--[[Start of functions used by Set Up Game event]]--

---Runs everytime a chat occurs.
---<br>Return: true, hides player msg | false, shows player msg
---@param message string_from_player
---@param player object_of_player
function onChat(message, player)
  --Sets flags for determining if to reset gameboard
  if flag.lookForPlayerText then
    local lowerMessage = string.lower(message)
    if lowerMessage == "y" then
      if player.steam_name == gameSetupPlayer.steam_name then
        print("[21AF21]" .. player.steam_name .. " selected new game.[-]")
        print("[21AF21]New game is being set up.[-]")
        flag.continue = true
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
      print(table.concat(CHAT_COMMANDS, ""))
    elseif command == "rules" then
      getRuleBook(player.color)
    elseif command == "hiderules" then
      hideRuleBook()
    elseif command == "respawndeck" then
      if adminCheck(player) then
        respawnDeck()
      end
    elseif command == "settings" then
      if adminCheck(player) then
        UI.show("settingsWindow")
      end
    else
      print("[DC0000]Command not found.[-]")
    end
    return false
  end
end

---@param player object
function adminCheck(player)
  if player.admin then
    return true
  else
    print("[DC0000]You do not have permission to access this feature.[-]")
    return false
  end
end

---Spawns a rule book in front of player color
---@param color string
function getRuleBook(color)
  local playerRotation = ROTATION.color[color]
  local ruleBookPos = SPAWN_POS.ruleBook:copy():rotateOver('y', playerRotation)
  local myjson = [[{
    "Name": "Custom_PDF",
    "Transform": {
      "posX": 0.0,
      "posY": 0.0,
      "posZ": 0.0,
      "rotX": 0.0,
      "rotY": 0.0,
      "rotZ": 0.0,
      "scaleX": 1.0,
      "scaleY": 1.0,
      "scaleZ": 1.0
    },
    "Nickname": "Rules and Tips",
    "Description": "",
    "GMNotes": "",
    "ColorDiffuse": {
      "r": 1.0,
      "g": 1.0,
      "b": 1.0
    },
    "Locked": false,
    "Grid": true,
    "Snap": true,
    "IgnoreFoW": false,
    "Autoraise": true,
    "Sticky": true,
    "Tooltip": true,
    "GridProjection": false,
    "HideWhenFaceDown": false,
    "Hands": false,
    "CustomPDF": {
      "PDFUrl": "http://cloud-3.steamusercontent.com/ugc/2288456143469151321/BB82096AE4DD8D9295A3B9062729704F9B5A2A5B/",
      "PDFPassword": "",
      "PDFPage": 0,
      "PDFPageOffset": 0
    },
    "XmlUI": "<!-- -->",
    "LuaScript": "--foo",
    "LuaScriptState": "",
    "GUID": "pdf001"
  }]]
  spawnObjectJSON({
    json = myjson,
    position = {ruleBookPos.x, 1.5, ruleBookPos.z},
    rotation = {0, playerRotation - 180, 0}
  })
end

---Deletes all rulebooks from table
function hideRuleBook()
  for _, tableObject in ipairs(scriptZone.table.getObjects()) do
    if tableObject.type == 'Tile' then
      tableObject.destruct()
    end
  end
end

---Removes any cards on the table and respawns the deck
function respawnDeck()
  if not safeToContinue() then
    print("[DC0000]Please wait till event is over and try again.[-]")
    return
  end
  startLuaCoroutine(self, 'respawnDeckCoroutine')
end

function respawnDeckCoroutine()
  local remainingTableCards = getLooseCards(scriptZone.table)
  if tableLength(remainingTableCards) > 0 then
    for _, card in ipairs(remainingTableCards) do
      card.destruct()
    end
  end
  staticObject.hiddenBag.takeObject({
    guid = GUID.DECK_COPY,
    position = {3, 2, 0},
    rotation = {0, 0, 180},
    smooth = false
  })
  local deckCopy = getObjectFromGUID(GUID.DECK_COPY)
  deckCopy.setInvisibleTo(ALL_PLAYERS)
  local newDeck = deckCopy.clone({
    position = {0, -3, 0}
  })
  staticObject.hiddenBag.putObject(deckCopy)
  if blackSevens then
    staticObject.hiddenBag.takeObject({
      guid = blackSevens,
      position = {5, 2, 0},
      rotation = {0, 0, 180},
      smooth = false
    })
    getObjectFromGUID(blackSevens).destruct()
  end
  if playerCount and playerCount == 4 then
    pause(0.2)
    blackSevens = removeBlackSevens(newDeck)
  end
  if flag.gameSetup.ran and flag.firstDealOfGame then
    pause(0.4)
    moveDeckAndDealerChip()
  end
  pause(0.75)
  return 1
end

---Builds a global table of all seated players [sortedSeatedPlayers]
function populatePlayers()
  sortedSeatedPlayers = {}
  for _, color in ipairs(ALL_PLAYERS) do
    if Player[color].seated then
      table.insert(sortedSeatedPlayers, color)
    end
  end
end

---Prints the current game settings<br>
---Gets the correct deck for the number of seated players<br>
---Will stop setUpGameCoroutine if there is less than 3 seated players
function printGameSettings()
  if #sortedSeatedPlayers < 3 then
    print("[DC0000]Sheepshead requires 3 to 6 players.[-]")
    flag.stopCoroutine = true
    return
  end

  playerCount = #sortedSeatedPlayers
  dealerColorVal = getColorVal(gameSetupPlayer.color, sortedSeatedPlayers)

  if settings.dealerSitsOut and playerCount == 6 then
    stateChangeDealerSitsOut(settings.dealerSitsOut)
  end

  if playerCount == 3 then
    updateRules("threeHanded", true)
    broadcastToAll("[21AF21]Picker plays Alone, Leasters enabled by default")
  end

  if settings.threeHanded and playerCount ~= 3 then
    updateRules("threeHanded", false)
    UI.setAttribute("settingsButtonjdPartnerOn", "tooltip", "")
    UI.setAttribute("settingsButtonjdPartnerOff", "tooltip", "")
  end

  while not verifyCardCount("deck") do
    pause(1)
  end

  deck = getDeck(scriptZone.table)
  if playerCount == 4 then
    if deck.getQuantity() == 32 then
      blackSevens = removeBlackSevens(deck)
    end
  else
    if deck.getQuantity() == 30 then
      returnDecktoPiquet(deck)
    end
  end

  moveDeckAndDealerChip()
  print("[21AF21]Sheepshead set up for [-]", #sortedSeatedPlayers, " players!")
end

---Called to add the blackSevens to a given deck<br>
---Function uses global string blackSevens provided by removeBlackSevens() to locate<br>
---blackSevens.guid within staticObject.hiddenBag, then moves them to the current deck position
---@param deck object
function returnDecktoPiquet(deck)
  staticObject.hiddenBag.takeObject({
    guid = blackSevens,
    position = deck.getPosition(),
    rotation = deck.getRotation(),
    smooth = false
  })
  pause(0.3)
  print("[21AF21]The two black sevens have been added to the deck.[-]")
  blackSevens = nil
end

---Called to remove the blackSevens from a given deck<br>
---Finds the blackSevens inside the given deck and moves them into staticObject.hiddenBag<br>
---Returns the guid of a deck the blackSevens are located in inside staticObject.hiddenBag
---@param deck object
---@return string_guid
function removeBlackSevens(deck)
  local centerPos = Vector(0, 1.5, 0)
  deck.setPosition(centerPos)
  deck.setRotation({0, 0, 180})
  local cardsToRemove = {'Seven of Clubs', 'Seven of Spades'}
  for _, card in ipairs(deck.getObjects()) do
    for _, cardName in ipairs(cardsToRemove) do
      if card.name == cardName then
        deck.takeObject({
          guid = card.guid,
          position = centerPos + Vector(2.75, 1, 0),
          smooth = false
        })
      end
    end
  end
  print("[21AF21]The two black sevens have been removed from the deck.[-]")
  pause(0.25)
  local smallDeck = getDeck(scriptZone.table, "small")
  smallDeck.setInvisibleTo(ALL_PLAYERS)
  staticObject.hiddenBag.putObject(smallDeck)
  pause(0.25)
  return smallDeck.guid
end

---Called during New Game Set Up event to deal chips to all seated players
---@param rotationAngle integer
---@param playerPos vector
function spawnChips(rotationAngle, playerPos)
  local rotatedOffset
  for c = 1, 15 do
    if c % 5 == 1 then
      local offsetIndex = math.floor((c - 1) / 5) + 1
      rotatedOffset = SPAWN_POS.chips[offsetIndex]:copy():rotateOver('y', rotationAngle)
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

---Start of game setup event
---@param player object<event_Trigger>
function setUpGameEvent(player)
  if not safeToContinue() then
    return
  end
  if player.admin then
    flag.gameSetup.inProgress = true
    gameSetupPlayer = player
    startLuaCoroutine(self, 'setUpGameCoroutine')
  else
    broadcastToColor("[DC0000]You do not have permission to access this feature.", player.color, "[-]")
  end
end

---Start of order of opperations for setUpGame
function setUpGameCoroutine()
  if flag.gameSetup.ran and #sortedSeatedPlayers < 3 then
    print("[DC0000]Sheepshead requires 3 to 6 players.[-]")
    flag.gameSetup.inProgress = false
    return 1
  elseif flag.gameSetup.ran then
    Player[gameSetupPlayer.color].broadcast("[b415ff]You are trying to set up a new game for [-]"
      .. #sortedSeatedPlayers .. " players.")
    pause(1.5)
    Player[gameSetupPlayer.color].broadcast("[b415ff]Are you sure you want to continue?[-] (y/n)")
    flag.lookForPlayerText = true
    pause(6)
    if flag.continue then
      flag.lookForPlayerText, flag.continue = false, false
      resetBoard()
    else
      print("[21AF21]New game was not selected.[-]")
      flag.lookForPlayerText, flag.continue = false, false
      flag.gameSetup.inProgress = false
      return 1
    end
  end

  if flag.counterVisible then
    toggleCounterVisibility()
  end

  --start of debug code
  --This is how Number of players is mannaged in debug mode
  --Happens in place of populatePlayers
  if DEBUG then
    if sortedSeatedPlayers == nil then
      local json = JSON.encode(ALL_PLAYERS)
      sortedSeatedPlayers = JSON.decode(json)
      flag.gameSetup.inProgress = false
      return 1
    end
  else
    populatePlayers()
  end
  --end of debug code

  printGameSettings()

  if flag.stopCoroutine then
    flag.stopCoroutine, flag.gameSetup.inProgress = false, false
    return 1
  end

  for _, color in ipairs(sortedSeatedPlayers) do
    local rotationAngle, playerPos = getItemMoveData(color)
    spawnChips(rotationAngle, playerPos)
  end

  flag.gameSetup.inProgress = false
  flag.gameSetup.ran, flag.firstDealOfGame = true, true
  return 1
end

--[[End of order of opperations for setUpGame]]--
--[[End of functions used by Set Up Game event]]--


--[[Start of functions used by New Hand event]]--

---Called to build dealOrder correctly<br>
---Adds "Blinds" to the dealOrder table in the position directly after the current dealer<br>
---If dealer sits out replaces dealer with blinds
function calculateDealOrder()
  local json = JSON.encode(sortedSeatedPlayers)
  dealOrder = JSON.decode(json)
  local blinds = "Blinds"
  if playerCount == #sortedSeatedPlayers then
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

---Start of New Hand event
function setUpHandEvent()
  if not safeToContinue() then
    return
  end
  if not flag.gameSetup.ran then
    print("[21AF21]Press Set Up Game First.[-]")
    return
  end
  flag.dealInProgress = true
  if flag.cardsToBeBuried then
    staticObject.setBuriedButton.UI.setAttribute("setUpBuriedButton", "visibility", "")
    staticObject.setBuriedButton.UI.setAttribute("setUpBuriedButton", "active", "false")
    flag.cardsToBeBuried = false
  end
  pickingPlayer, leadOutPlayer, holdCards = nil, nil, nil
  flag.trick.inProgress = false
  currentTrick = {}
  
  startLuaCoroutine(self, 'dealCardsCoroutine')
end

---Order of opperations for dealing
function dealCardsCoroutine()
  if flag.counterVisible then
    toggleCounterVisibility()
  end

  if not flag.firstDealOfGame then
    while not verifyCardCount("table") do
      pause(0.5)
    end
    dealerColorVal = getNextColorValInList(dealerColorVal, sortedSeatedPlayers)
    if tableLength(getLooseCards(scriptZone.table)) > 1 then
      rebuildDeck()
    end
    pause(0.3)

    moveDeckAndDealerChip()
    pause(0.4)
  else
    while not verifyCardCount("deck") do
      pause(0.5)
    end
    flag.firstDealOfGame = false
  end

  calculateDealOrder()

  flipDeck(scriptZone.table)
  pause(0.35)

  local count = getNextColorValInList(dealerColorVal, dealOrder)
  local roundTrigger = 1
  local round = 1
  local target = dealOrder[count]

  local deck = getDeck(scriptZone.table)
  local rotationVal = deck.getRotation()

  flipDeck(scriptZone.table)
  pause(0.15)
  deck.randomize()
  pause(0.35)

  while deckExists() do
    if count > #dealOrder then
      count = 1
      target = dealOrder[count]
    end
    if roundTrigger > #dealOrder then
      roundTrigger = 1
      round = round + 1
    end

    if DEBUG then print(playerCount .. " " .. count .. " " .. target .. " " .. round) end

    dealLogic(playerCount, target, round, deck, rotationVal)
    pause(0.25)
    count = count + 1
    roundTrigger = roundTrigger + 1
    target = dealOrder[count]
  end

  flag.dealInProgress = false
  return 1
end

--End of order of opperations for dealing

---Contains the logic to deal correctly based on the number of
---players seated and the number of times players have recieved cards
---@param p integer_number_of_players
---@param t string_target_color
---@param r integer_round_number
---@param deck object
---@param rotationVal vector
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

---Deals 2 cards to the blinds
---@param deck object
---@param rotationVal vector
function dealToBlinds(deck, rotationVal)
  for i = 1, 2 do
    deck.takeObject({
      position = SPAWN_POS.blinds[i]:copy():rotateOver('y', rotationVal.y),
      rotation = {rotationVal.x, rotationVal.y, 180}
    })
    pause(0.15)
  end
end

--[[End of functions used by New Hand event]]--

---Prints a message if player passes or is forced to pick
---@param player object<event_Trigger>
function passEvent(player)
  if not dealerColorVal then
    return
  end
  local dealer = getPlayerObject(dealerColorVal, sortedSeatedPlayers)
  if playerCount ~= #sortedSeatedPlayers then
    if player.color == dealer.color then
      broadcastToColor("[DC0000]You can not pass while sitting out.[-]", player.color)
      return
    end
  end
  if not flag.dealInProgress and checkCardCount(scriptZone.center, 2) then
    if player.color == dealer.color then
      if not DEBUG then
        if callSettings.leaster then
          broadcastToColor("[DC0000]Dealer can not pass. Pick your own or Call a Leaster.[-]", player.color)
        else
          broadcastToColor("[DC0000]Dealer can not pass. Pick your own![-]", player.color)
        end
      else
        print("[DC0000]Dealer can not pass. " .. dealer.color .. " pick your own![-]")
      end
    else
      broadcastToAll(player.steam_name .. " passed")
      local rightOfDealerColor = sortedSeatedPlayers[getPreviousColorValInList(dealerColorVal, sortedSeatedPlayers)]
      if player.color == rightOfDealerColor then
        if callSettings.leaster then
          broadcastToColor("[21AF21]You have the option to call a leaster.[-]", dealer.color)
          if not string.find(UI.getAttribute("callsWindow", "visibility"), dealer.color) then
            toggleWindowVisibility(dealer, "callsWindow")
          end
        end
      end
    end
  end
end

---Moves the blinds into the pickers hand, sets player to pickingPlayer
---Sets flag cardsToBeBuried to trigger buryCards logic
---@param player object<event_Trigger>
function pickBlindsEvent(player)
  if playerCount == 5 and #sortedSeatedPlayers == 6 then
    if player.color == getPlayerObject(dealerColorVal, sortedSeatedPlayers).color then
      broadcastToColor("[DC0000]You can not pick while sitting out.[-]", player.color)
      return
    end
  end
  if flag.dealInProgress then
    return
  end
  if countCards(scriptZone.center) ~= 2 then
    return
  end
  pickingPlayer = player
  startLuaCoroutine(self, 'pickBlindsCoroutine')
end

function pickBlindsCoroutine()
  broadcastToAll("[21AF21]" .. pickingPlayer.steam_name .. " Picks![-]")
  local blinds = getLooseCards(scriptZone.center)
  local playerPosition = Player[pickingPlayer.color].getHandTransform().position
  local playerRotation = Player[pickingPlayer.color].getHandTransform().rotation
  if blinds[1].type == 'Deck' then
    blinds[1].takeObject({
      position = playerPosition,
      rotation = playerRotation
    })
    pause(0.2)
  end
  blinds = getLooseCards(scriptZone.center)
  for _, card in ipairs(blinds) do
    card.setPositionSmooth(playerPosition)
    card.setRotationSmooth(playerRotation)
  end
  Wait.time(
    function()
      for _, card in ipairs(Player[pickingPlayer.color].getHandObjects()) do
        if card.is_face_down then
          card.flip()
        end
        flag.cardsToBeBuried = true
      end
    end,
    0.35
  )
  local pickerRotation = ROTATION.color[pickingPlayer.color]
  local setBuriedButtonPos = SPAWN_POS.setBuriedButton:copy():rotateOver('y', pickerRotation)
  staticObject.setBuriedButton.setPosition(setBuriedButtonPos)
  staticObject.setBuriedButton.setRotation({0, pickerRotation, 0})
  staticObject.setBuriedButton.UI.setAttribute("setUpBuriedButton", "visibility", pickingPlayer.color)
  staticObject.setBuriedButton.UI.setAttribute("setUpBuriedButton", "active", "true")

  if settings.jdPartner == true then
    local dealer = getPlayerObject(dealerColorVal, sortedSeatedPlayers)
    if pickingPlayer.color == dealer.color then
      if doesPlayerPossessCard(pickingPlayer, "Jack of Diamonds") then
        if not string.find(UI.getAttribute("playAloneWindow", "visibility"), pickingPlayer.color) then
          toggleWindowVisibility(pickingPlayer, "playAloneWindow")
        end
      end
      if callSettings.leaster then
        if not string.find(UI.getAttribute("callsWindow", "visibility"), pickingPlayer.color) then
          broadcastToColor("[21AF21]You have the option to call a leaster.[-]", pickingPlayer.color)
          toggleWindowVisibility(pickingPlayer, "callsWindow")
        end
      end
    end
  elseif settings.jdPartner == false then --Call an Ace
    pause(0.5)
    holdCards = buildPartnerChoices(pickingPlayer)
    pause(0.25)
    if holdCards then
      --buryCardsEvent needs access to holdCards
      toggleWindowVisibility(pickingPlayer, "selectPartnerWindow")
    else
      --Unknown event
      print("Unknown event triggered")
    end
  end
  return 1
end

---Toggles the spawning and deletion of counters.<br> On counter spawn will spawn
---a counter in front of pickingPlayer<br> and player accross from color.
---Flips over pickers tricks to see score of hand
function toggleCounterVisibility()
  if not flag.counterVisible then
    local pickerColor = pickingPlayer.color
    local pickerRotation = ROTATION.color[pickerColor]
    local blockRotation = ROTATION.block[pickerColor]
    local tCounter, pCounter
    local tCounterPos = SPAWN_POS.tableCounter:copy():rotateOver('y', pickerRotation)
    local pCounterPos = SPAWN_POS.pickerCounter:copy():rotateOver('y', pickerRotation)
    local blockPos = SPAWN_POS.tableBlock:copy():rotateOver('y', blockRotation)
    local block = staticObject.hiddenBag.takeObject({
      position = blockPos,
      rotation = {0, blockRotation, 0},
      smooth = false,
      guid = GUID.TABLE_BLOCK
    })
    block.setLock(true)
    block.setInvisibleTo(ALL_PLAYERS)
    Wait.frames(
      function()
        tCounter = spawnObject({
          type = 'Counter',
          position = tCounterPos,
          rotation = {295, pickerRotation - 180, 0},
        })
        pCounter = spawnObject({
          type = 'Counter',
          position = pCounterPos,
          rotation = {295, pickerRotation, 0},
        })
        flag.counterVisible = true
      end,
      3
    )
    local pickerZone = trickZone[pickerColor]
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
    Wait.frames(function() setupGuidTable(tCounter.guid, pCounter.guid) end, 22)
    Wait.time(displayWonOrLossText, 1.35)
  else
    for _, tableObject in ipairs(scriptZone.table.getObjects()) do
      if tableObject.type == 'Counter' then
        tableObject.destruct()
      end
    end
    staticObject.hiddenBag.putObject(getObjectFromGUID(GUID.TABLE_BLOCK))
    flag.counterVisible = false
    trickCountStop()
  end
end

---Makes sure buried cards are face down and unhides blinds and pickingPlayers<br>
---hand objects. Calculates global leadOutPlayer, hides Set Buried button
---@param player object<event_Trigger>
function setBuriedEvent(player)
  if player.color ~= pickingPlayer.color then
    return
  end
  if not checkCardCount(trickZone[pickingPlayer.color], 2) then
    return
  end
  local buriedCards = getLooseCards(trickZone[pickingPlayer.color])
  for _, card in ipairs(buriedCards) do
    if not card.is_face_down then
      card.flip()
    end
  end
  Wait.time(function() group(buriedCards) end, 0.8)
  Wait.time(
    function()
      getDeck(trickZone[pickingPlayer.color]).setInvisibleTo()
      for _, card in ipairs(Player[pickingPlayer.color].getHandObjects()) do
        card.setInvisibleTo()
      end
    end,
    1.6
  )
  flag.cardsToBeBuried = false
  local leadOutVal = getNextColorValInList(dealerColorVal, sortedSeatedPlayers)
  leadOutPlayer = getPlayerObject(leadOutVal, sortedSeatedPlayers)
  if not DEBUG then
    broadcastToAll("[21AF21]" .. leadOutPlayer.steam_name .. " leads out.[-]")
  else
    print("[21AF21]" .. leadOutPlayer.color .. " leads out.[-]")
  end
  staticObject.setBuriedButton.UI.setAttribute("setUpBuriedButton", "visibility", "")
  staticObject.setBuriedButton.UI.setAttribute("setUpBuriedButton", "active", "false")
end

---Runs when an object tries to enter a container<br>
---Doesn't allow card grouping during trickInProgress or cardsToBeBuried<br>
---Return: true, allows object to enter | false, does not allow object to enter
---@param container type_object
---@param object object_item
function tryObjectEnterContainer(container, object)
  if not flag.allowGrouping then
    return false
  end
  if flag.cardsToBeBuried then
    if isInZone(object, trickZone[pickingPlayer.color]) then
      return false
    end
  end
  if flag.trick.inProgress then
    if isInZone(object, scriptZone.center) then
      return false
    end
  end
  return true
end

---Runs when an object enters a zone
---@param zone object
---@param object object_item
function onObjectEnterZone(zone, object)
  --Makes sure items stay on the table if dropped
  if zone == scriptZone.drop then
    object.setPosition({0, 3, 0})
  end
  --Makes sure other players can not see what cards the picker is burying
  if flag.cardsToBeBuried then
    if zone == trickZone[pickingPlayer.color] and object.type == 'Card' then
      local hideFrom = removeColorFromList(pickingPlayer.color, sortedSeatedPlayers)
      object.setInvisibleTo(hideFrom)
    end
  end
end

---Runs when an object leaves a zone
---@param zone object
---@param object object_item
function onObjectLeaveZone(zone, object)
  --Starts trick
  if safeToContinue() and not flag.cardsToBeBuried then
    if leadOutPlayer then
      if zone == handZone[leadOutPlayer.color] then
        flag.trick.inProgress = true
      end
    end
  end
end

---Runs when a player pickes up an object<br>
---If someone plays the wrong card, Ex. Player didn't see they have to follow suit
---and needs to remove a card from the currentTrick
---@param playerColor string
---@param object object_item
function onObjectPickUp(playerColor, object)
  if flag.trick.inProgress then
    if object.type == 'Card' and isInZone(object, scriptZone.center) then
      if tableLength(currentTrick) > 1 then
        local objectName = object.getName()
        for i = 2, #currentTrick do
          if objectName == currentTrick[i].cardName and playerColor == currentTrick[i].playedByColor then
            reCalculateCurrentTrick(currentTrick[i].index)
            break
          end
        end
      end
    end
  end
end

---Runs when a player drops an object<br>
---Gaurd clauses don't work in onEvents() otherwise I would use them here<br>
---Builds the table currentTrick to keep track of cardNames and player color who laid them in the scriptZone.center
---@param playerColor string
---@param object object_item
function onObjectDrop(playerColor, object)
  if flag.trick.inProgress then
    if object.type == 'Card' then
      --Wait function allows script to continue in the case of a player throwing a card into scriptZone.center
      Wait.time(
        function()
          if isInZone(object, scriptZone.center) then
            if not DEBUG and playerColor ~= leadOutPlayer.color then
              broadcastToAll("[21AF21]" .. leadOutPlayer.steam_name .. " leads out.[-]")
            else
              addCardDataToCurrentTrick(playerColor, object)
              if #currentTrick == playerCount + 1 then
                calculateTrickWinner()
              end
            end
          end
        end,
        0.5
      )
    end
  end
end

---@param indexToRemove integer
---@param indexToUpdate optional <integer>
function removeCardFromTrick(indexToRemove, indexToUpdate)
  local highCardName
  if indexToUpdate then
    highCardName = currentTrick[indexToUpdate].cardName
  end

  if DEBUG then print("[21AF21]" .. currentTrick[indexToRemove].cardName .. " removed from trick[-]") end

  table.remove(currentTrick, indexToRemove)
  for i = 2, #currentTrick do
    if indexToUpdate then
      if highCardName == currentTrick[i].cardName then
        currentTrick[1].highStrengthIndex = i
      end
    end
    currentTrick[i].index = i
  end
end

---@param indexToRemove integer
function reCalculateCurrentTrick(indexToRemove)
  --Remove card from trick and update location of current high card
  if indexToRemove ~= currentTrick[1].highStrengthIndex then
    removeCardFromTrick(indexToRemove, currentTrick[1].highStrengthIndex)
    return
  end
  --Remove card from trick and find the high card in remaining cards
  removeCardFromTrick(indexToRemove)
  if #currentTrick > 1 then
    currentTrick[1].currentHighStrength = 1
    setLeadOutCardProperties(currentTrick[2].cardName, isTrump(currentTrick[2].cardName))
    if #currentTrick > 2 then
      for i = 3, #currentTrick do
        calculateCardData(i, isTrump(currentTrick[i].cardName))
      end
    end
  end
end

---@param playerColor string
---@param object object
function addCardDataToCurrentTrick(playerColor, object)
  --Check if object is trump
  local objectName = object.getName()
  local objectIsTrump = isTrump(objectName)
  if tableLength(currentTrick) < 2 then
    --Creates currentTrick properties stored at index 1
    initializeCurrentTrick(objectName, objectIsTrump)
  end
  local cardData = {
    playedByColor = playerColor,
    cardName = objectName,
    index = #currentTrick + 1,
    guid = object.guid
  }
  table.insert(currentTrick, cardData)
  if DEBUG then
    if #currentTrick == 2 then
      print("[21AF21]Card led out is: " .. currentTrick[currentTrick[1].highStrengthIndex].cardName .. "[-]")
    else
      print("[21AF21]" .. currentTrick[#currentTrick].cardName .. " added to trick[-]")
    end
  end
  calculateCardData(#currentTrick, objectIsTrump)
end

---Function will return early if card does not need to be compared to currentHighStrength
---@param cardIndex integer
---@param objectIsTrump boolean
function calculateCardData(cardIndex, objectIsTrump)
  if not currentTrick[1].trump then --No trump in currentTrick
    if not objectIsTrump then       --Not trump and not suit led out
      if getLastWord(currentTrick[cardIndex].cardName) ~= currentTrick[1].ledSuit then
        return
      end
    else --No trump in currentTrick but objectIsTrump make sure trumpStrength is greater
      currentTrick[1].currentHighStrength = 0
    end
  else --Trump is in the currentTrick
    if not objectIsTrump then
      return
    end
  end
  local strengthVal = quickSearch(currentTrick[cardIndex].cardName, objectIsTrump)
  if strengthVal > currentTrick[1].currentHighStrength then
    updateCurrentTrickProperties(objectIsTrump, strengthVal, cardIndex)
  end
end

---@param objectName string
---@param isTrump boolean
function initializeCurrentTrick(objectName, isTrump)
  currentTrick = {}
  setLeadOutCardProperties(objectName, isTrump)
end

---Trick properties stored in currentTrick[1]
---@param objectName string
---@param isTrump boolean
function setLeadOutCardProperties(objectName, isTrump)
  local trickProperties = {
    ledSuit = getLastWord(objectName),
    trump = isTrump,
    currentHighStrength = quickSearch(objectName, isTrump),
    highStrengthIndex = 2
  }
  if tableLength(currentTrick) == 0 then
    table.insert(currentTrick, trickProperties)
  else
    currentTrick[1].ledSuit = trickProperties.ledSuit
    currentTrick[1].trump = isTrump
    currentTrick[1].currentHighStrength = trickProperties.currentHighStrength
    currentTrick[1].highStrengthIndex = 2
  end
end

---Trick properties stored in currentTrick[1]
---@param isTrump boolean
---@param strengthVal integer
---@param index integer
function updateCurrentTrickProperties(isTrump, strengthVal, index)
  if isTrump then
    currentTrick[1].trump = true
  end
  currentTrick[1].currentHighStrength = strengthVal
  currentTrick[1].highStrengthIndex = index

  if DEBUG then print("[21AF21]Current high Card is: " ..
    currentTrick[currentTrick[1].highStrengthIndex].cardName .. "[-]") end
end

---@param objectName string
function isTrump(objectName)
  local trumpIdentifier = {"Diamonds", "Jack", "Queen"}
  for _, word in ipairs(trumpIdentifier) do
    if string.find(objectName, word) then
      return true
    end
  end
  return false
end

---Only search for strengths higher than currentHighStrength
---@param objectName string
---@param isTrump boolean
function quickSearch(objectName, isTrump)
  local strengthList
  if isTrump then
    strengthList = {"Seven of Diamonds", "Eight of Diamonds", "Nine of Diamonds", "King of Diamonds", "Ten of Diamonds",
      "Ace of Diamonds", "Jack of Diamonds", "Jack of Hearts", "Jack of Spades", "Jack of Clubs", "Queen of Diamonds",
      "Queen of Hearts", "Queen of Spades", "Queen of Clubs"}
  else
    strengthList = {"Seven", "Eight", "Nine", "King", "Ten", "Ace"}
  end

  local startIndex
  if not currentTrick[1] or currentTrick[1].currentHighStrength == 0 then
    startIndex = 1
  else
    startIndex = currentTrick[1].currentHighStrength
  end
  for i = startIndex, #strengthList do
    if isTrump then
      if objectName == strengthList[i] then
        return i
      end
    else
      if string.find(objectName, strengthList[i]) then
        return i
      end
    end
  end
  return 1
end

---Calculates player to give trick to. Sets global leadOutPlayer
function calculateTrickWinner()
  flag.trick.handOut = true
  flag.trick.inProgress = false
  local trickWinner = getPlayerObject(currentTrick[currentTrick[1].highStrengthIndex].playedByColor, sortedSeatedPlayers)
  leadOutPlayer = trickWinner
  broadcastToAll("[21AF21]" ..
  trickWinner.steam_name .. " takes the trick with " .. currentTrick[currentTrick[1].highStrengthIndex].cardName .. "[-]")
  Wait.time(function() giveTrickToWinner(trickWinner) end, 1.75)
end

---Resets trick flag and data then moves Trick to trickZone of trickWinner
---Shows card counters if hand is over
---@param player object
function giveTrickToWinner(player)
  local trick = {}
  for i = 2, #currentTrick do
    table.insert(trick, getObjectFromGUID(currentTrick[i].guid))
  end
  currentTrick = {}
  local playerTrickZone = trickZone[player.color]
  trick = group(trick)[1]
  Wait.time(function() trick.flip(); flag.trick.handOut = false end, 0.6)
  Wait.time(
    function()
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
    Wait.time(function() toggleCounterVisibility() end, 2.2)
    leadOutPlayer = nil
  end
end

--[[New functions to adapt Blackjack Card Counter]]--

---Returns the color of the handposition located across the table from given color (pickingPlayer)
---@param color string
---@return string <"color">
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

---Creates two global tables.<br> 1: of the entity of each zone and counter. 2: of each zoneObject
---and its associated counterObject, then starts the loop
---@param tCounterGUID string
---@param pCounterGUID string
function setupGuidTable(tCounterGUID, pCounterGUID)
  local pickerZoneGuid = trickZone[pickingPlayer.color].guid
  local colorAcrossFromPicker = findColorAcrossTable(pickingPlayer.color)
  local tableGuid = trickZone[colorAcrossFromPicker].guid

  guidTable = {
    [pickerZoneGuid] = pCounterGUID,
    [tableGuid] = tCounterGUID
  }

  objectSets = {}
  for zoneGUID, counterGUID in pairs(guidTable) do
    table.insert(objectSets, {z = getObjectFromGUID(zoneGUID), c = getObjectFromGUID(counterGUID)})
  end
  SheepsheadGlobalTimer = Wait.time(countTricks, 1)
end

---------------------------------------------------------------
--[[    Universal Blackjack Card Counter    by: MrStump    ]]--
---------------------------------------------------------------

--The names (in quotes) should all match the names on your cards.
--The values should match the value of those cards.

cardNameTable = {
  ["Seven"] = 0, ["Eight"] = 0, ["Nine"] = 0,
  ["Ten"] = 10, ["Jack"] = 2, ["Queen"] = 3,
  ["King"] = 4, ["Ace"] = 11
}

----------------------------------------------------------
--[[    END OF CODE TO EDIT, unless you know Lua    ]]--
----------------------------------------------------------

---Looks for any cards in the scripting zones and sends them on to obtainCardValue
---Looks for any decks in the scripting zones and sends them on to obtainDeckValue
---Triggers next step, addValues(), after that
function countTricks()
  values = {}
  hiddenValue = nil
  for i, set in ipairs(objectSets) do
    values[i] = {}
    local objectsInZone = set.z.getObjects()
    for j, object in ipairs(objectsInZone) do
      if object.type == "Card" then
        obtainCardValue(i, object)
      elseif object.type == "Deck" then
        local z = object.getRotation().z
        if z > 345 or z < 15 then
          obtainDeckValue(i, object)
        end
      end
    end
  end
  addValues()
end

---Checks cards sent to it and, if their name contains cardNameTable, it adds the value to a table
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

---Checks decks sent to it and, if their cards names contains cardNameTable, it adds the values to a table
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

---Totals up values in the tables from the 2 above functions
function addValues()
  totals = {}
  --For non-ace cards
  for i, v in ipairs(values) do
    totals[i] = 0
    for j = 1, #v do
      if v[j] ~= 99 then
        totals[i] = totals[i] + v[j]
      end
    end
  end
  displayResults()
end

---Sends totaled values to the counters. It also color codes the counters to match
function displayResults()
  for i, set in pairs(objectSets) do
    set.c.setValue(totals[i])
    local total = totals[i]
    if i == 1 and (total < 61 and total > 30) then
      set.c.setColorTint({1, 250 / 255, 160 / 255})
    elseif i == 2 and (total < 60 and total > 29) then
      set.c.setColorTint({1, 250 / 255, 160 / 255})
    elseif i == 2 and total == 60 then
      set.c.setColorTint({0, 1, 0})
    elseif total > 60 then
      set.c.setColorTint({0, 1, 0})
    else
      set.c.setColorTint({0, 0, 0})
    end
  end
  trickCountStart()
end


---Restarts loop back up at countTricks
function trickCountStart()
  if SheepsheadGlobalTimer then
    Wait.stop(SheepsheadGlobalTimer); SheepsheadGlobalTimer = nil
  end
  SheepsheadGlobalTimer = Wait.time(countTricks, 1)
end

---Stops the trickCount Loop
function trickCountStop()
  if SheepsheadGlobalTimer then
    Wait.stop(SheepsheadGlobalTimer); SheepsheadGlobalTimer = nil
  end
end

---If no params function runs a setup to create params and feeds them back into itself<br>
---runs while SheepsheadGlobalTimer loop is running
---@param textObject object
---@param score integer
---@param cardCount integer
function displayWonOrLossText(textObject, score, cardCount)
  local wonOrLoss
  if not textObject then
    local pickerColor = pickingPlayer.color
    local pickerRotation = ROTATION.color[pickerColor] --Shares the same positionData as setBuriedButton
    local textPosition = SPAWN_POS.setBuriedButton:copy():rotateOver('y', pickerRotation)
    wonOrLoss = spawnObject({
      type = '3DText',
      position = textPosition,
      rotation = {90, pickerRotation, 0}
    })
    wonOrLoss.interactable = false
    wonOrLoss.setValue("")
  else
    wonOrLoss = textObject
  end
  
  if SheepsheadGlobalTimer then
    local pickerScore = objectSets[1].c.getValue()
    local pickerTrickCardCount = countCards(objectSets[1].z)
    local cardStateChange, totalCards = false
    if playerCount == 4 then
      totalCards = 30
    else
      totalCards = 32
    end
    if cardCount and cardCount ~= pickerTrickCardCount then
      if pickerTrickCardCount == totalCards or pickerTrickCardCount == (totalCards - 1) or pickerTrickCardCount == 3 or pickerTrickCardCount == 2 then
        cardStateChange = true
      end
    end
    if not score or score ~= pickerScore or cardStateChange then
      local text
      if pickerScore == 120 and pickerTrickCardCount == totalCards then
        text = "+3 Chips!"
      elseif pickerScore > 90 then
        text = "+2 Chips!"
      elseif pickerScore > 60 then
        text = "+1 Chip"
      elseif pickerScore > 30 then
        text = "-1 Chip"
      elseif pickerScore < 31 and pickerTrickCardCount > 2 then
        text = "-2 Chips"
      else
        text = "-3 Chips"
      end
      if text ~= wonOrLoss.getValue() then
        wonOrLoss.setValue(text)
      end
    end
    if displayWonOrLossTimer then
      Wait.stop(displayWonOrLossTimer); displayWonOrLossTimer = nil
    end
    displayWonOrLossTimer = Wait.frames(function() displayWonOrLossText(wonOrLoss, pickerScore, pickerTrickCardCount) end, 15)
  else
    wonOrLoss.destruct()
    Wait.stop(displayWonOrLossTimer); displayWonOrLossTimer = nil
  end
end

--[[END OF CARD SCORING]]--

--Settings flags and associated outputs to user
settings = {
  dealerSitsOut = false,
  calls = false,
  threeHanded = false,
  jdPartner = true
}

callSettings = {
  sheepshead = false,
  blitz = false,
  leaster = false,
  crack = false,
  crackBack = false,
  crackAroundTheCorner = false
}
currentRules = {
  "\n\n\n\n\n\n\n",
  "[21AF21]Welcome to Scripted Sheepshead!\n",
  "By: WardLordRuby           [-]\n",
  "[b415ff]Features:                   [-]\n",
  "Will Auto Adjust for 3-6 Players\n",
  "Scripted Dealing, Picking,     \n",
  "Taking Tricks, Burying        \n",
  "Card Counters for Each Team \n",
  "Custom Game Settings       \n",
  "Custom Schrute Silver Coins   \n",
  "Gameplay Rules and Tips    \n",
  "Use ([fc8803].help[-]) for Commands    \n\n",
  "[b415ff]Current Sheepshead Rules:   [-]\n",
  "Jack of Diamonds Partner    \n",
  "Dealer Pick your Own       \n",
  "Can Call if Forced to Pick    \n",
  "6 Handed - Normal        \n",
  "Extra Calls Disabled       "
}

CHAT_COMMANDS = {
  "[b415ff]Sheepshead Console Help[-]\n",
  "[21AF21].rules[-] [Displays Rule and Gameplay Tip Booklet][-]\n",
  "[21AF21].hiderules[-] [Hides Rule and Gameplay Tip Booklet][-]\n",
  "[21AF21].respawndeck[-] [Removes all Cards and Spawns a Fresh Deck][-]\n",
  "[21AF21].settings[-] [Opens Window to Change Game Settings][-]"
}

---Prints currentRules to the screen
function displayRules()
  setNotes(table.concat(currentRules, ""))
end

--[[Start of functions used by settings window]]--

---Updates position of buttons for all enabled calls and<br>
---updates height of panel to fit all buttons
function buildCallPanel()
  local numOfCallsEnabled = 0
  local currentoffsetY = -5
  local buttonoffsetY = -53
  for key, value in pairs(callSettings) do
    local attributeID = key .. "Button"
    if value == true then
      numOfCallsEnabled = numOfCallsEnabled + 1
      currentoffsetY = currentoffsetY + buttonoffsetY
      local currentoffsetXY = "00 " .. currentoffsetY
      UI.setAttribute(attributeID, "active", "true")
      UI.setAttribute(attributeID, "offsetXY", currentoffsetXY)
    else
      UI.setAttribute(attributeID, "active", "false")
    end
  end
  local initialFrameSizeY = 58
  currentoffsetY = initialFrameSizeY + (numOfCallsEnabled * math.abs(buttonoffsetY))
  UI.setAttribute("callsWindow", "height", currentoffsetY)
  UI.setAttribute("callsWindowBackground", "height", currentoffsetY)
end

---@param rule string <"settings.rule">
---@param bool boolean
function updateRules(rule, bool)
  local ruleTable = {
    dealerSitsOut = {
      [true] = "6 Handed - Dealer Sits Out   \n",
      [false] = "6 Handed - Normal        \n",
      ruleIndex = 17,
      execute = stateChangeDealerSitsOut
    },
    calls = {
      [true] = "Extra Calls Enabled        ",
      [false] = "Extra Calls Disabled       ",
      ruleIndex = 18,
      execute = stateChangeCalls
    },
    threeHanded = {
      [true] = "Picker Plays Alone         \n",
      ruleIndex = 14,
      execute = stateChangeThreeHanded
    },
    jdPartner = {
      [true] = "Jack of Diamonds Partner    \n",
      [false] = "Call an Ace                \n",
      ruleIndex = 14
    },
  }
  settings[rule] = bool
  if ruleTable[rule].execute then
    ruleTable[rule].execute(bool)
  end
  if ruleTable[rule][bool] then
    currentRules[ruleTable[rule].ruleIndex] = ruleTable[rule][bool]
    displayRules()
  end
end

---@param call string <"callSettings.call">
---@param bool boolean
function updateCalls(call, bool)
  local callTable = {
    crack = {
      execute = stateChangeCrack
    },
    crackBack = {
      execute = stateChangeCrackSubSet
    },
    crackAroundTheCorner = {
      execute = stateChangeCrackSubSet
    }
  }
  callSettings[call] = bool
  if callTable[call] then
    callTable[call].execute(bool, call)
  end
  buildCallPanel()
end

---Abstracted gaurd clause for determining if settings window toggle is not valid
---@param id string
---@param state boolean
---@return boolean
function toggleNotValid(id, state)
  local lowerID = string.lower(id)
  if not settings.calls and state then
    for key in pairs(callSettings) do
      local lowerKey = string.lower(key)
      if string.find(lowerID, lowerKey) then
        return true
      end
    end
  end
  if not callSettings.crack and state then
    if string.find(lowerID, "crack.") then
      return true
    end
  end
  if id == "jdPartner" or lowerID == "dealersitsout" then
    if not safeToContinue() then
      print("[DC0000]Please wait and try again[-]")
      return true
    end
  end
  if id == "jdPartner" and settings.jdPartner == nil then
    return true
  end
  return false
end

---Toggle setting via formatted id
---@param player nil
---@param val nil
---@param id string <"turnOnSettingName" | "turnOffSettingName">
function toggleSetting(player, val, id)
  local idName, state
  if string.find(id, "turnOn") then
    idName = string.gsub(id, "turnOn", "")
    state = true
  else
    idName = string.gsub(id, "turnOff", "")
    state = false
  end
  if toggleNotValid(idName, state) then
    return
  end
  local parentID1 = "settingsButton" .. idName .. "On"
  local parentID2 = "settingsButton" .. idName .. "Off"
  idName = lowerFirstChar(idName)
  for key in pairs(settings) do
    if key == idName then
      updateRules(idName, state)
    end
  end
  for key in pairs(callSettings) do
    if key == idName then
      updateCalls(idName, state)
    end
  end
  UI.setAttribute(parentID1, "active", state)
  UI.setAttribute(parentID2, "active", not state)
end

---@param bool boolean
function stateChangeCalls(bool)
  if bool == true then
    UI.setAttribute("callSettingsBackground", "image", "crackDisabled")
  else
    UI.setAttribute("callSettingsBackground", "image", "callsDisabled")
    for key, value in pairs(callSettings) do
      if value == true then
        local formatKey = "turnOff" .. key
        toggleSetting(player, val, formatKey)
      end
    end
  end
end

---@param bool boolean
function stateChangeDealerSitsOut(bool)
  if sortedSeatedPlayers == nil then
    return
  end
  if bool == true then
    if #sortedSeatedPlayers == 6 then
      playerCount = 5
      print("[21AF21]Dealer will sit out every hand.[-]")
    end
  else
    if #sortedSeatedPlayers == 6 then
      playerCount = #sortedSeatedPlayers
      print("[21AF21]Dealer will no longer sit out.[-]")
    end
  end
end

---@param bool boolean
function stateChangeThreeHanded(bool)
  local jdPartnerID = UI.getAttribute("settingsButtonjdPartnerOff", "active")
  local jdPartner
  if jdPartnerID == "false" then
    jdPartner = true
    jdPartnerID = "settingsButtonjdPartnerOn"
  else
    jdPartner = false
    jdPartnerID = "settingsButtonjdPartnerOff"
  end
  if bool == true then
    settings.jdPartner = nil
    if not settings.calls then
      Wait.time(function() toggleSetting(player, val, "turnOnCalls") end, 3)
    end
    if not callSettings.leaster then
      Wait.time(function() toggleSetting(player, val, "turnOnLeaster") end, 3)
    end
    UI.setAttribute(jdPartnerID, "tooltip", "Can not change setting, No partner playing 3 handed")
  else
    if settings.jdPartner == nil then
      local callCount = 0
      for _, bool in pairs(callSettings) do
        if bool == true then
          callCount = callCount + 1
          if callCount > 1 then
            break
          end
        end
      end
      if callCount == 1 then
        Wait.time(function() toggleSetting(player, val, "turnOffCalls") end, 3)
      end
    end
    updateRules("jdPartner", jdPartner)
  end
end

---@param bool boolean
function stateChangeCrack(bool)
  if bool == true then
    UI.setAttribute("callSettingsBackground", "image", "callPanel")
  else
    if settings.calls then
      UI.setAttribute("callSettingsBackground", "image", "crackDisabled")
    end
    for key, value in pairs(callSettings) do
      local lowerKey = string.lower(key)
      if value == true and string.find(lowerKey, "crack.") then
        local formatKey = "turnOff" .. key
        toggleSetting(player, val, formatKey)
      end
    end
  end
end

---@param bool boolean
---@param call string
function stateChangeCrackSubSet(bool, call)
  if bool == true then
    for key, value in pairs(callSettings) do
      local lowerKey = string.lower(key)
      if value == true and string.find(lowerKey, "crack.") and key ~= call then
        local formatKey = "turnOff" .. key
        toggleSetting(player, val, formatKey)
      end
    end
  end
end

--[[End of functions for settings window]]--

---@param player object
---@param window string<"widnowID">
function toggleWindowVisibility(player, window)
  local visibility = UI.getAttribute(window, "visibility")
  if string.find(visibility, player.color) then
    if visibility == player.color then
      UI.setAttribute(window, "visibility", "")
      UI.Hide(window)
    else
      visibility = removeColorFromPipeList(player.color, visibility)
      UI.setAttribute(window, "visibility", visibility)
    end
  else
    visibility = addColorToPipeList(player.color, visibility)
    UI.setAttribute(window, "visibility", visibility)
    UI.show(window)
  end
end

--[[Start of functions and buttons for calls window]]--

function showCallsEvent(player)
  toggleWindowVisibility(player, "callsWindow")
end

---@param player object<event_Trigger>
function callPartnerEvent(player)
  if not pickingPlayer then
    return
  end
  local player = player
  Wait.time(
    function() 
      if settings.jdPartner == true then
        local dealer = getPlayerObject(dealerColorVal, sortedSeatedPlayers)
        if player.color == dealer.color and player.color == pickingPlayer.color then
          if doesPlayerPossessCard(player, "Jack of Diamonds") then
            toggleWindowVisibility(player, "playAloneWindow")
          else
            broadcastToColor("[DC0000]Jack of Diamonds will be your partner[-]", player.color)
          end
        else
          broadcastToColor("[DC0000]You can only call up if you are forced to pick and have the Jack[-]", player.color)
        end
      elseif settings.jdPartner == false then --Call an Ace
        if player.color == pickingPlayer.color then
          toggleWindowVisibility(player, "selectPartnerWindow")
        else
          broadcastToColor("[DC0000]Only the picker can call their partner[-]", player.color)
        end
      end
      toggleWindowVisibility(player, "callsWindow")
    end, 
    0.13
  )
  --Show call partner window for selected parter mode
end

---@param player object<event_Trigger>
---@param val nil
---@param id string<"eventID">
function playerCallsEvent(player, val, id)
  if not pickingPlayer then
    return
  end
  local player = player
  Wait.time(function() toggleWindowVisibility(player, "callsWindow") end, 0.13)
  local id = string.gsub(id, "Button", "")
  id = upperFirstChar(id)
  if id == "Leaster" then
    broadcastToAll("[21AF21]" .. player.steam_name .. " calls for a " .. id .. "[-]")
  elseif id:sub(1, 5) == "Crack" then
    id = insertSpaces(id)
    id = string.gsub(id, "Crack", "Crack's")
    broadcastToAll("[21AF21]" .. player.steam_name .. id .. "![-]")
  else
    broadcastToAll("[21AF21]" .. player.steam_name .. " calls " .. id .. "![-]")
  end
end

--[[End of functions and buttons for calls window]]--

--[[Start of functions and buttons for playAloneWindow/selectPartnerWindow window]]--

---@param player object<event_Trigger>
function callUpEvent(player)
  toggleWindowVisibility(player, "playAloneWindow")
  local tryOrder = {"Jack", "Queen"}
  local callCard
  for _, tryCard in ipairs(tryOrder) do
    callCard = findCardToCall(filterPlayerCards(player, tryCard, "nil"), tryCard)
    if callCard then
      break
    end
  end
  if not callCard then
    broadcastToColor("[DC0000]No suitable card to Call. Try your luck playing alone![-]", player.color)
    return
  end
  broadcastToAll("[21AF21]" .. player.steam_name .. " calls " .. callCard .. " to be their partner![-]")
end

---Finds next highest card that is not in passed in table
---@param cards table <"cardNames">
---@param name string <"Jack"|"Queen">
---@return string cardName
function findCardToCall(cards, name)
  local callCard
  if tableLength(cards) == 0 then
    callCard = name .. " of Diamonds"
    return callCard
  end
  if #cards > 3 then
    return nil
  end
  local nextHigh = { "Diamonds", "Hearts", "Spades", "Clubs" }
  for _, cardInHand in ipairs(cards) do
    for i, suit in ipairs(nextHigh) do
      if string.find(cardInHand, suit) then
        table.remove(nextHigh, i)
      end
    end
  end
  callCard = name .. " of " .. nextHigh[1]
  return callCard
end

---if valid holdCards found in player hand will enable corresponding buttons in selectPartnerWindow<br>
---and return holdCards | if no valid holdCards will return nil
---@param player object
---@return nil|table<"cardNames">
function buildPartnerChoices(player)
  --failCards = all suitableFail including ten's
  local failCards = filterPlayerCards(player, "suitableFail", "Diamonds")
  local failSuits, holdCards, partnerChoices = {}, {}, {}
  if tableLength(failCards) > 0 then
    --failSuits = only unique suits in failCards
    for _, cardName in ipairs(failCards) do
      local cardSuit = getLastWord(cardName)
      if not tableContains(failSuits, cardSuit) then
        table.insert(failSuits, cardSuit)
      end
    end
    local tryOrder = {"Ace", "Ten"}
    --notPartnerChoices = Aces or Tens player has
    local notPartnerChoices, card
    for _, tryCard in ipairs(tryOrder) do
      card = tryCard
      notPartnerChoices = filterPlayerCards(player, tryCard, "Diamonds")
      if tableLength(notPartnerChoices) < 3 then
        break
      end
    end
    --calculate partnerChoices by removing held aces or tens from list(failSuits)
    if card == "Ten" then --player has 3 aces --Hold card must be the ace
      failSuits = {"Hearts", "Spades", "Clubs"}
      holdCards = {"Ace of Hearts", "Ace of Spades", "Ace of Clubs"}
    end
    if tableLength(notPartnerChoices) > 0 then
      for _, cardToRemove in ipairs(notPartnerChoices) do
        for i, suit in ipairs(failSuits) do
          if string.find(cardToRemove, suit) then
            table.remove(failSuits, i)
          end
        end
      end
    end
    --compile list of valid partnerChoices and valid holdCards
    if tableLength(failSuits) > 0 then
      for _, suit in ipairs(failSuits) do
        table.insert(partnerChoices, card .. " of " .. suit)
      end
      if card == "Ace" then
        for _, cardName in ipairs(failCards) do
          for _, suit in ipairs(failSuits) do
            if string.find(cardName, suit) and not tableContains(notPartnerChoices, cardName) then
              table.insert(holdCards, cardName)
            end
          end
        end
      end
      if DEBUG then
        print("Valid cards for player to call: " .. table.concat(partnerChoices, ", "))
        print("Valid holdCards are: " .. table.concat(holdCards, ", "))
      end
    end
  end 
  --nil = unknown mode 
  if tableLength(failCards) == 0 or tableLength(failSuits) == 0 then
    return nil
  end
  setActivePartnerButtons(partnerChoices)
  return holdCards
end


---@param list table <"cardNames">
function setActivePartnerButtons(list)
  local xmlTable = UI.getXmlTable()
  local selectPartnerWindow = findPanelElement("selectPartnerWindow", xmlTable)
  resetSelectPartnerWindow(selectPartnerWindow, xmlTable)
  xmlTable = UI.getXmlTable()
  local formattedList = {}
  for _, cardName in ipairs(list) do
    local formattedName = cardName:gsub(" ", "-")
    table.insert(formattedList, formattedName)
  end
  for _, childrenButtons in pairs(xmlTable[selectPartnerWindow].children[1].children) do
    local buttonID = childrenButtons.attributes.id
    if tableContains(formattedList, buttonID) then
      UI.setAttribute(buttonID, "active", "true")
    end
  end
end

---@param id string
---@param table xmlTable
function findPanelElement(id, table)
  for i, element in ipairs(table) do
    if element.tag == "Panel" and element.attributes.id == id then
      return i
    end
  end
end

---Hides all cardButtons in selectPartnerWindow
---@param id string
---@param table xmlTable
function resetSelectPartnerWindow(id, table)
  for _, childrenButtons in pairs(table[id].children[1].children) do
    if childrenButtons.attributes.active == "true" then
      UI.setAttribute(childrenButtons.attributes.id, "active", "false")
    end
  end
end

---@param player object<event_Trigger>
function selectPartnerEvent(player, val, id)
  local formattedID = id:gsub("-", " ")
  broadcastToAll("[21AF21]" .. player.steam_name .. " Picks " .. formattedID .. " as their parnter")
  toggleWindowVisibility(player, "selectPartnerWindow")
  Wait.time(
    function ()
      local validSuit = getLastWord(formattedID)
      local validCards = {}
      for _, cardName in ipairs(holdCards) do
        if string.find(cardName, validSuit) then
          table.insert(validCards, cardName)
        end
      end
      local numOfValidCards = #validCards
      if numOfValidCards > 1 then
        table.insert(validCards, #validCards, "or")
      end
      validCards = table.concat(validCards, " ")
      if numOfValidCards > 2 then
        validCards = validCards:gsub(validSuit .. "([^,])", validSuit .. ",%1")
      end
      broadcastToColor("[21AF21]Remember to play the " .. validCards .. " the first time " .. validSuit .. " is played[-]", pickingPlayer.color)
    end,
    2
  )
end
--[[End of functions and buttons for playAloneWindow/selectPartnerWindow window]]--



--[[Start of graphic anamations]]--

function closeSettingsButtonAnimateEnter(player, val, id)
  local id = id .. "Button"
  UI.setAttribute(id, "image", "closeButtonHover")
end

function closeSettingsButtonAnimateExit(player, val, id)
  local id = id .. "Button"
  UI.setAttribute(id, "image", "closeButton")
end

function closeSettingsButtonAnimateDown(player, val, id)
  local id = id .. "Button"
  UI.setAttribute(id, "image", "closeButtonPressed")
end

function closeWindow(player, val, id)
  if id == "yesButton" then
    id = "playAloneWindowExit"
  end
  local id1 = id .. "Button"
  local id2 = string.gsub(id, "Exit", "")
  if id ~= "settingsWindowExit" then
    UI.setAttribute(id2, "visibility", "")
  end
  
  UI.setAttribute(id1, "image", "closeButton")
  UI.hide(id2)
end

function animateButtonEnter(player, val, id)
  local state = id .. "Hover"
  UI.setAttribute(id, "image", state)
end

function animateButtonExit(player, val, id)
  UI.setAttribute(id, "image", id)
end

function animateButtonDown(player, val, id)
  local state = id .. "Pressed"
  UI.setAttribute(id, "image", state)
end

function animateButtonUp(player, val, id)
  UI.setAttribute(id, "image", id)
end

--[[End of graphic anamations]]--

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

function test(player)

end
