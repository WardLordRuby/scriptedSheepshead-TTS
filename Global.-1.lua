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
  leasterCards = Vector(-3.84, 1, -6.63),
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
  mesh = "https://steamusercontent-a.akamaihd.net/ugc/2205135744307283952/DEF0BF91642CF5636724CA3A37083385C810BA06/",
  diffuse = "https://steamusercontent-a.akamaihd.net/ugc/2288456143464578824/E739670FE62B8267C90E54D4B786C1C83BA7CC22/",
  type = 5,
  material = 2,
  specular_sharpness = 5
}

function onLoad()
  TRICK_ZONE = {
    White = getObjectFromGUID(GUID.TRICK_ZONE_WHITE),
    Red = getObjectFromGUID(GUID.TRICK_ZONE_RED),
    Yellow = getObjectFromGUID(GUID.TRICK_ZONE_YELLOW),
    Green = getObjectFromGUID(GUID.TRICK_ZONE_GREEN),
    Blue = getObjectFromGUID(GUID.TRICK_ZONE_BLUE),
    Pink = getObjectFromGUID(GUID.TRICK_ZONE_PINK)
  }
  HAND_ZONE = {
    White = getObjectFromGUID(GUID.HAND_ZONE_WHITE),
    Red = getObjectFromGUID(GUID.HAND_ZONE_RED),
    Yellow = getObjectFromGUID(GUID.HAND_ZONE_YELLOW),
    Green = getObjectFromGUID(GUID.HAND_ZONE_GREEN),
    Blue = getObjectFromGUID(GUID.HAND_ZONE_BLUE),
    Pink = getObjectFromGUID(GUID.HAND_ZONE_PINK)
  }
  SCRIPT_ZONE = {
    center = getObjectFromGUID(GUID.CENTER_ZONE),
    table = getObjectFromGUID(GUID.TABLE_ZONE),
    drop = getObjectFromGUID(GUID.DROP_ZONE)
  }
  STATIC_OBJECT = {
    hiddenBag = getObjectFromGUID(GUID.HIDDEN_BAG),
    dealerChip = getObjectFromGUID(GUID.DEALER_CHIP),
    setBuriedButton = getObjectFromGUID(GUID.SET_BURIED_BUTTON)
  }
  STATIC_OBJECT.hiddenBag.interactable = false
  STATIC_OBJECT.dealerChip.interactable = false
  STATIC_OBJECT.setBuriedButton.interactable = false
  STATIC_OBJECT.hiddenBag.setInvisibleTo(ALL_PLAYERS)
  STATIC_OBJECT.setBuriedButton.setInvisibleTo(ALL_PLAYERS)

  FLAG = {
    gameSetup = {
      inProgress = false,
      ran = false
    },
    trick = {
      inProgress = false,
      handOut = false
    },
    leasterHand = false,
    stopCoroutine = false,
    dealInProgress = false,
    lookForPlayerText = false,
    continue = false,
    cardsToBeBuried = false,
    counterVisible = false,
    firstDealOfGame = false,
    allowGrouping = true,
    fnRunning = false
  }

  if DEBUG then
    UI.show("playerUp")
    UI.show("playerDown")
    UI.show("test")
    UI.show("settingsWindow")
  end

  displayRules()
end

--[[Utility functions]]--

---Checks dealInProgress, trick.handOut, gameSetup.inProgress, and fnRunning
function safeToContinue()
  if FLAG.dealInProgress or FLAG.trick.handOut or FLAG.gameSetup.inProgress or FLAG.fnRunning then
    return false
  end
  return true
end

---Sets the FLAG.fnRunning to true when safe this must be ran within a coroutine
function startFnRunFlag()
  while FLAG.fnRunning do
    coroutine.yield(0)
  end
  FLAG.fnRunning = true
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

---@param list table
---@return table
function copyTable(list)
  return JSON.decode(JSON.encode(list))
end

---Copys input table and removes input color, if color not found returns original table
---@param color string
---@param list table<"colors">
---@return table <"colors">
function removeColorFromList(color, list)
  local currentIndex
  local modifiedList = copyTable(list)
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

---@param object object
---@param zone object<zone>
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
  if table == {} or table == nil then
    return 0
  end
  return #table
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
---If you are aware of more than one deck in a given zone getDeck()<br> can return the smaller or larger
---of the decks found. This function has the possibility to error if not ran within a coroutine
---@param zone object<zone>
---@param size option_string <"big"|"small">
---@return object<deck>|nil
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
  end
  group(decks)
  pause(1)
  return getDeck(zone)
end

---getLooseCards also provieds a safe way to return a deck Object from outside of a coroutine<br>
---@param zone object<zone>
---@param returnFirstDeck option_bool
---@return table<card_Objects_and_deck_Objects>
function getLooseCards(zone, returnFirstDeck)
  local looseCards = {}
  for _, obj in ipairs(zone.getObjects()) do
    if obj.type == "Deck" or obj.type == "Card" then
      if returnFirstDeck and obj.type == "Deck" then
        return obj
      end
      table.insert(looseCards, obj)
    end
  end
  if not returnFirstDeck then    
    return looseCards
  end
  return nil
end

---Just checks to make sure cards are all there<br>
---Recomended to be ran from within a coroutine
function verifyCardCount()
  local cardCount = countCards(SCRIPT_ZONE.table)

  if PLAYER_COUNT == 4 then
    if cardCount ~= 30 then
      respawnDeckCoroutine()
      return
    end
  else
    if cardCount ~= 32 then
      respawnDeckCoroutine()
      return
    end
  end
end

---@param colorOrVar string<"color">|integer<index>
---@param list table<"colors">
---@return object<player>
function getPlayerObject(colorOrVar, list)
  if colorOrVar == 0 then
    return Player[list[#list]]
  elseif colorOrVar == #list + 1 then
    return Player[list[1]]
  elseif tonumber(colorOrVar) then
    return Player[list[colorOrVar]]
  end
  return Player[colorOrVar]
end

---Returns the index location of a color in a list
---@param color string
---@param list table<"colors">
function getColorVal(color, list)
  for i, colors in ipairs(list) do
    if colors == color then
      return i
    end
  end
end

---Returns the index of the player seated clockwise from given index
---@param index integer
---@param list table<"colors">
---@return integer<index>
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
---@param list table<"colors">
---@return integer<index>
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

---Checks if a deck exists on the table<br>
---Recomended to be ran from within a coroutine
function deckExists()
  return getDeck(SCRIPT_ZONE.table) ~= nil
end

---Returns the rotationValue.z associated for cards if more cards are face up or face down in a given zone
---@param zone object<zone>
---@return integer<0|180>
function moreFaceUpOrDown(zone)
  local total, faceDownCount = countCards(zone, true)
  local halfOfTotal = math.floor(total / 2)
  if halfOfTotal >= faceDownCount then
    return 0
  end
  return 180
end

---Returns the number of cards in a given zone, can also return faceDownCount
---@param zone object<zone>
---@param countFaceDown boolean
---@return integer<numCards>, integer<numCardsFaceDown>
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
  return cardCount, faceDownCount
end

---Checks the given card count of a given zone, returns true or false
---@param zone object<zone>
---@param count integer
function checkCardCount(zone, count)
  if countCards(zone) == count then
    return true
  end
  return false
end

---@param player object<player>
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

---Searches player HAND_ZONE and TRICK_ZONE
---@param player object
---@return table<"cardNames">
function getPlayerCards(player)
  local cards = {}
  for _, card in ipairs(getLooseCards(HAND_ZONE[player.color])) do
    table.insert(cards, card.getName())
  end
  for _, object in ipairs(getLooseCards(TRICK_ZONE[player.color])) do
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
---@param scheme string<"suitableFail"|"King"|"Ace"|"Ten"|"Jack"|"Queen">
---@param doNotInclude string
---@return table<"cardNames">
function filterPlayerCards(player, scheme, doNotInclude)
  local schemes = {
    suitableFail = {"Seven", "Eight", "Nine", "Ten", "King"},
    King = {"King"},
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
---@return integer<rotationAngle>, vector<playerPosition>
function getItemMoveData(color)
  return ROTATION.color[color], Player[color].getHandTransform().position
end

--[[Object manipulation]]--

---Checks if a deck in the given zone is face up, if so it flips the deck<br>
---Recomended to be ran from within a coroutine
---@param zone object<zone>
function flipDeck(zone)
  local deck = getDeck(zone)
  if not deck.is_face_down then
    deck.flip()
  end
end

---Checks if cards in the given zone are face up, if so it flips cards
---@param zone object<zone>
function flipCards(zone)
  for _, card in ipairs(getLooseCards(zone)) do
    if not card.is_face_down then
      card.flip()
    end
  end
end

---Called to remove items from a zone. Must be called from within a coroutine
---@param zone object<zone>
---@param item string<"Type">
---@param item2 option_string<"Type">
function resetBoard(zone, item, item2)
  if not item2 then
    item2 = item
  end
  local zoneObjects = zone.getObjects()
  for i = #zoneObjects, 1 , -1 do
    local object = zoneObjects[i]
    if object.type == item or object.type == item2 then
      object.destruct()
      pause(0.06)
    end
  end
end

---Moves deck and dealer chip in front of the next clockwise seated player<br>
---Needs to be ran from within a coroutine
function moveDeckAndDealerChip()
  local rotationAngle, playerPos = getItemMoveData(SORTED_SEATED_PLAYERS[DEALER_COLOR_VAL])
  local rotatedChipOffset = SPAWN_POS.dealerChip:copy():rotateOver('y', rotationAngle)
  local rotatedDeckOffset = SPAWN_POS.deck:copy():rotateOver('y', rotationAngle)
  local chipRotation = STATIC_OBJECT.dealerChip.getRotation()
  repeat coroutine.yield(0) until getDeck(SCRIPT_ZONE.table) ~= nil
  local deck = getDeck(SCRIPT_ZONE.table)
  STATIC_OBJECT.dealerChip.setRotationSmooth({ chipRotation.x, rotationAngle - 90, chipRotation.z })
  STATIC_OBJECT.dealerChip.setPositionSmooth(playerPos + rotatedChipOffset)
  deck.setRotationSmooth({ deck.getRotation().x, rotationAngle, 180 })
  deck.setPositionSmooth(playerPos + rotatedDeckOffset)
end

---Spreads cards out over the center of the table, makes sure they are face down, and groups cards
function rebuildDeck()
  FLAG.allowGrouping = false
  local faceRotation = moreFaceUpOrDown(SCRIPT_ZONE.table)
  for _, object in ipairs(getLooseCards(SCRIPT_ZONE.table)) do
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
  flipCards(SCRIPT_ZONE.table)
  FLAG.allowGrouping = true
  pause(0.5)
  group(getLooseCards(SCRIPT_ZONE.table))
  pause(0.5)
  group(getLooseCards(SCRIPT_ZONE.table))
  pause(0.5)
end

--[[Start of functions used by Set Up Game event]]--

---Runs everytime a chat occurs.
---<br>Return: true, hides player msg | false, shows player msg
---@param message string<playerInput>
---@param player object<player>
function onChat(message, player)
  --Sets flags for determining if to reset gameboard
  if FLAG.lookForPlayerText then
    local lowerMessage = string.lower(message)
    if lowerMessage == "y" then
      if player.steam_name == gameSetupPlayer.steam_name then
        print("[21AF21]" .. player.steam_name .. " selected new game.[-]")
        print("[21AF21]New game is being set up.[-]")
        FLAG.continue = true
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
    elseif command == "spawnchips" then
      startChipSpawn(player)
    else
      broadcastToColor("[DC0000]Command not found.[-]", player.color)
    end
    return false
  end
end

---@param player object
function adminCheck(player)
  if not player.admin then
    broadcastToColor("[DC0000]You do not have permission to access this feature.[-]", player.color)
    return false
  end
  return true
end

---Spawns a rule book in front of player color
---@param color string
function getRuleBook(color)
  local playerRotation = ROTATION.color[color]
  local ruleBookPos = SPAWN_POS.ruleBook:copy():rotateOver('y', playerRotation)
  local ruleBookJson = [[{
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
      "PDFUrl": "https://steamusercontent-a.akamaihd.net/ugc/2288456143469151321/BB82096AE4DD8D9295A3B9062729704F9B5A2A5B/",
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
    json = ruleBookJson,
    position = {ruleBookPos.x, 1.5, ruleBookPos.z},
    rotation = {0, playerRotation - 180, 0}
  })
end

---Deletes all rulebooks from table
function hideRuleBook()
  local tableObjects = SCRIPT_ZONE.table.getObjects()
  for i = #tableObjects, 1, -1 do
    local tableObject = tableObjects[i]
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
  local remainingTableCards = getLooseCards(SCRIPT_ZONE.table)
  if tableLength(remainingTableCards) > 0 then
    resetBoard(SCRIPT_ZONE.table, 'Card', 'Deck')
  end
  STATIC_OBJECT.hiddenBag.takeObject({
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
  STATIC_OBJECT.hiddenBag.putObject(deckCopy)
  if BLACK_SEVENS then
    STATIC_OBJECT.hiddenBag.takeObject({
      guid = BLACK_SEVENS,
      position = {5, 2, 0},
      rotation = {0, 0, 180},
      smooth = false
    })
    getObjectFromGUID(BLACK_SEVENS).destruct()
    BLACK_SEVENS = nil
  end
  if PLAYER_COUNT and PLAYER_COUNT == 4 then
    pause(0.2)
    removeBlackSevens(newDeck)
  end
  if FLAG.gameSetup.ran and FLAG.firstDealOfGame then
    pause(0.4)
    moveDeckAndDealerChip()
  end
  pause(0.75)
  return 1
end

---Builds a global table of all seated players [SORTED_SEATED_PLAYERS]
function populatePlayers()
  SORTED_SEATED_PLAYERS = {}
  for _, color in ipairs(ALL_PLAYERS) do
    if Player[color].seated then
      table.insert(SORTED_SEATED_PLAYERS, color)
    end
  end
end

---Prints the current game settings<br>
---Gets the correct deck for the number of seated players<br>
---Will stop setUpGameCoroutine if there is less than 3 seated players<br>
---Must be ran from within a coroutine
function printGameSettings()
  if #SORTED_SEATED_PLAYERS < 3 then
    broadcastToAll("[DC0000]Sheepshead requires 3 to 6 players.[-]")
    FLAG.stopCoroutine = true
    return
  end

  PLAYER_COUNT = #SORTED_SEATED_PLAYERS
  DEALER_COLOR_VAL = getColorVal(gameSetupPlayer.color, SORTED_SEATED_PLAYERS)

  if SETTINGS.dealerSitsOut and PLAYER_COUNT == 6 then
    stateChangeDealerSitsOut(SETTINGS.dealerSitsOut)
  end

  if PLAYER_COUNT == 3 then
    updateRules("threeHanded", true)
    broadcastToAll("[21AF21]Picker plays Alone, Leasters enabled by default")
  end

  if SETTINGS.threeHanded and PLAYER_COUNT ~= 3 then
    updateRules("threeHanded", false)
    UI.setAttribute("settingsButtonjdPartnerOn", "tooltip", "")
    UI.setAttribute("settingsButtonjdPartnerOff", "tooltip", "")
  end

  verifyCardCount()

  local deck = getDeck(SCRIPT_ZONE.table)
  if PLAYER_COUNT == 4 then
    if deck.getQuantity() == 32 then
      removeBlackSevens(deck)
    end
  else
    if deck.getQuantity() == 30 then
      returnDecktoPiquet(deck)
    end
  end

  moveDeckAndDealerChip()
  print("[21AF21]Sheepshead set up for [-]", #SORTED_SEATED_PLAYERS, " players!")
end

---Called to add the BLACK_SEVENS to a given deck<br>
---Function uses global string BLACK_SEVENS provided by removeBlackSevens() to locate<br>
---BLACK_SEVENS.guid within STATIC_OBJECT.hiddenBag, then moves them to the current deck position
---@param deck object<deck>
function returnDecktoPiquet(deck)
  STATIC_OBJECT.hiddenBag.takeObject({
    guid = BLACK_SEVENS,
    position = deck.getPosition(),
    rotation = deck.getRotation(),
    smooth = false
  })
  pause(0.3)
  print("[21AF21]The two black sevens have been added to the deck.[-]")
  BLACK_SEVENS = nil
end

---Called to remove the BLACK_SEVENS from a given deck<br>
---Finds the BLACK_SEVENS inside the given deck and moves them into STATIC_OBJECT.hiddenBag<br>
---Sets BLACK_SEVENS deck guid inside STATIC_OBJECT.hiddenBag<br>
---Must be ran from within a coroutine
---@param deck object<deck>
function removeBlackSevens(deck)
  local centerPos = Vector(0, 1.5, 0)
  deck.setPosition(centerPos)
  deck.setRotation({0, 0, 180})
  local cardsToRemove = {'Seven of Clubs', 'Seven of Spades'}
  local guids = {}
  for _, card in ipairs(deck.getObjects()) do
    for _, cardName in ipairs(cardsToRemove) do
      if card.name == cardName then
        table.insert(guids, card.guid)
      end
    end
  end
  for _, guid in ipairs(guids) do
    deck.takeObject({
      guid = guid,
      position = centerPos + Vector(2.75, 1, 0),
      smooth = false
    })
  end
  print("[21AF21]The two black sevens have been removed from the deck.[-]")
  pause(0.25)
  local smallDeck = getDeck(SCRIPT_ZONE.table, "small")
  smallDeck.setInvisibleTo(ALL_PLAYERS)
  STATIC_OBJECT.hiddenBag.putObject(smallDeck)
  pause(0.25)
  BLACK_SEVENS = smallDeck.guid
end

---Helper function for spawning chips from outside a coroutine
---@param player object<commandTrigger>
function startChipSpawn(player)
  if not adminCheck(player) then
    return
  end
  if not FLAG.gameSetup.ran then
    broadcastToColor("[DC0000]Setup game before spawning extra chips.[-]", player.color)
    return
  end
  if not safeToContinue() then
    broadcastToColor("[DC0000]Action in progress, wait and try this command again.[-]", player.color)
    return
  end
  FLAG.fnRunning = true
  startLuaCoroutine(self, 'spawnChips')
  FLAG.fnRunning = false
end

---Deals specified number of chips to all seated players<br>
---Requires: game is already setup & is ran from within a coroutine
function spawnChips()
  for _, color in ipairs(SORTED_SEATED_PLAYERS) do
    local rotatedOffset
    local rotationAngle, playerPos = getItemMoveData(color)
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
  return 1
end

---Start of game setup event
---@param player object<eventTrigger>
function setUpGameEvent(player)
  if not safeToContinue() then
    return
  end
  if player.admin then
    FLAG.gameSetup.inProgress = true
    gameSetupPlayer = player
    startLuaCoroutine(self, 'setUpGameCoroutine')
  else
    broadcastToColor("[DC0000]You do not have permission to access this feature.", player.color, "[-]")
  end
end

---Start of order of opperations for setUpGame
function setUpGameCoroutine()
  if FLAG.gameSetup.ran and #SORTED_SEATED_PLAYERS < 3 then
    broadcastToAll("[DC0000]Sheepshead requires 3 to 6 players.[-]")
    FLAG.gameSetup.inProgress = false
    return 1
  elseif FLAG.gameSetup.ran then
    Player[gameSetupPlayer.color].broadcast("[b415ff]You are trying to set up a new game for [-]"
      .. #SORTED_SEATED_PLAYERS .. " players.")
    pause(1.5)
    Player[gameSetupPlayer.color].broadcast("[b415ff]Are you sure you want to continue?[-] (y/n)")
    FLAG.lookForPlayerText = true
    pause(6)
    if FLAG.continue then
      FLAG.lookForPlayerText, FLAG.continue = false, false
      resetBoard(SCRIPT_ZONE.table, 'Chip')
    else
      print("[21AF21]New game was not selected.[-]")
      FLAG.lookForPlayerText, FLAG.continue = false, false
      FLAG.gameSetup.inProgress = false
      return 1
    end
  end

  if FLAG.counterVisible then
    toggleCounterVisibility()
  end

  --start of debug code
  --This is how Number of players is mannaged in debug mode
  --Happens in place of populatePlayers
  if DEBUG then
    if SORTED_SEATED_PLAYERS == nil then
      SORTED_SEATED_PLAYERS = copyTable(ALL_PLAYERS)
      FLAG.gameSetup.inProgress = false
      return 1
    end
  else
    populatePlayers()
  end
  --end of debug code

  printGameSettings()

  if FLAG.stopCoroutine then
    FLAG.stopCoroutine, FLAG.gameSetup.inProgress = false, false
    return 1
  end

  spawnChips()

  FLAG.gameSetup.inProgress = false
  FLAG.gameSetup.ran, FLAG.firstDealOfGame = true, true
  return 1
end

--[[End of order of opperations for setUpGame]]--
--[[End of functions used by Set Up Game event]]--


--[[Start of functions used by New Hand event]]--

---Called to build DEAL_ORDER correctly<br>
---Adds "Blinds" to the DEAL_ORDER table in the position directly after the current dealer<br>
---If dealer sits out replaces dealer with blinds
function calculateDealOrder()
  DEAL_ORDER = copyTable(SORTED_SEATED_PLAYERS)
  local blinds = "Blinds"
  if PLAYER_COUNT == #SORTED_SEATED_PLAYERS then
    blindVal = DEALER_COLOR_VAL + 1
    if blindVal > #DEAL_ORDER + 1 then
      blindVal = 1
    end
    table.insert(DEAL_ORDER, blindVal, blinds)
  else
    table.remove(DEAL_ORDER, DEALER_COLOR_VAL)
    table.insert(DEAL_ORDER, DEALER_COLOR_VAL, blinds)
  end
end

---Start of New Hand event
function setUpHandEvent()
  if not safeToContinue() then
    return
  end
  if not FLAG.gameSetup.ran then
    print("[21AF21]Press Set Up Game First.[-]")
    return
  end
  FLAG.dealInProgress = true
  if FLAG.cardsToBeBuried then
    STATIC_OBJECT.setBuriedButton.UI.setAttribute("setUpBuriedButton", "visibility", "")
    STATIC_OBJECT.setBuriedButton.UI.setAttribute("setUpBuriedButton", "active", "false")
    FLAG.cardsToBeBuried = false
  end
  PICKING_PLAYER, LEAD_OUT_PLAYER, HOLD_CARDS = nil, nil, nil
  FLAG.trick.inProgress, FLAG.leasterHand = false, false
  if UNKNOWN_TEXT then
    UNKNOWN_TEXT.destruct(); UNKNOWN_TEXT = nil
  end
  CURRENT_TRICK = {}
  
  local selectPartnerWindowOpen = UI.getAttribute("selectPartnerWindow", "visibility")
  local playAloneWindowOpen = UI.getAttribute("playAloneWindow", "visibility")
  if selectPartnerWindowOpen ~= "" then
    UI.hide("selectPartnerWindow")
    UI.setAttribute("selectPartnerWindow", "visibility", "")
  end
  if playAloneWindowOpen ~= "" then
    UI.hide("playAloneWindow")
    UI.setAttribute("playAloneWindow", "visibility", "")
  end
  
  startLuaCoroutine(self, 'dealCardsCoroutine')
end

---Order of opperations for dealing
function dealCardsCoroutine()
  if FLAG.counterVisible then
    toggleCounterVisibility()
  end

  if not FLAG.firstDealOfGame then
    verifyCardCount()

    DEALER_COLOR_VAL = getNextColorValInList(DEALER_COLOR_VAL, SORTED_SEATED_PLAYERS)
    if tableLength(getLooseCards(SCRIPT_ZONE.table)) > 1 then
      rebuildDeck()
    end
    pause(0.3)

    moveDeckAndDealerChip()
    pause(0.4)
  else
    verifyCardCount()

    FLAG.firstDealOfGame = false
  end

  calculateDealOrder()

  flipDeck(SCRIPT_ZONE.table)
  pause(0.35)

  local count = getNextColorValInList(DEALER_COLOR_VAL, DEAL_ORDER)
  local roundTrigger = 1
  local round = 1
  local target = DEAL_ORDER[count]

  local deck = getDeck(SCRIPT_ZONE.table)
  local rotationVal = deck.getRotation()

  flipDeck(SCRIPT_ZONE.table)
  pause(0.15)
  deck.randomize()
  pause(0.35)

  while deckExists() do
    if count > #DEAL_ORDER then
      count = 1
      target = DEAL_ORDER[count]
    end
    if roundTrigger > #DEAL_ORDER then
      roundTrigger = 1
      round = round + 1
    end

    if DEBUG then print(PLAYER_COUNT .. " " .. count .. " " .. target .. " " .. round) end

    dealLogic(PLAYER_COUNT, target, round, deck, rotationVal)
    pause(0.25)
    count = count + 1
    roundTrigger = roundTrigger + 1
    target = DEAL_ORDER[count]
  end

  FLAG.dealInProgress = false
  return 1
end

--End of order of opperations for dealing

---Contains the logic to deal correctly based on the number of
---players seated and the number of times players have recieved cards
---@param p integer<playerCount>
---@param t string<"targetColor">
---@param r integer<roundNum>
---@param deck object<deck>
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
---@param deck object<deck>
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
---@param player object<eventTrigger>
function passEvent(player)
  if not DEALER_COLOR_VAL then
    return
  end
  local dealer = getPlayerObject(DEALER_COLOR_VAL, SORTED_SEATED_PLAYERS)
  if PLAYER_COUNT ~= #SORTED_SEATED_PLAYERS then
    if player.color == dealer.color then
      broadcastToColor("[DC0000]You can not pass while sitting out.[-]", player.color)
      return
    end
  end
  if not FLAG.dealInProgress and checkCardCount(SCRIPT_ZONE.center, 2) then
    if player.color == dealer.color then
      if not DEBUG then
        if CALL_SETTINGS.leaster then
          broadcastToColor("[DC0000]Dealer can not pass. Pick your own or Call a Leaster.[-]", player.color)
        else
          broadcastToColor("[DC0000]Dealer can not pass. Pick your own![-]", player.color)
        end
      else
        print("[DC0000]Dealer can not pass. " .. dealer.color .. " pick your own![-]")
      end
    else
      broadcastToAll(player.steam_name .. " passed")
      local rightOfDealerColor = SORTED_SEATED_PLAYERS[getPreviousColorValInList(DEALER_COLOR_VAL, SORTED_SEATED_PLAYERS)]
      if player.color == rightOfDealerColor then
        if CALL_SETTINGS.leaster then
          broadcastToColor("[21AF21]You have the option to call a leaster.[-]", dealer.color)
          if not string.find(UI.getAttribute("callsWindow", "visibility"), dealer.color) then
            toggleWindowVisibility(dealer, "callsWindow")
          end
        end
      end
    end
  end
end

---Moves the blinds into the pickers hand, sets player to PICKING_PLAYER
---Sets FLAG cardsToBeBuried to trigger buryCards logic
---@param player object<eventTrigger>
function pickBlindsEvent(player)
  if PLAYER_COUNT == 5 and #SORTED_SEATED_PLAYERS == 6 then
    if player.color == getPlayerObject(DEALER_COLOR_VAL, SORTED_SEATED_PLAYERS).color then
      broadcastToColor("[DC0000]You can not pick while sitting out.[-]", player.color)
      return
    end
  end
  if FLAG.dealInProgress then
    return
  end
  if countCards(SCRIPT_ZONE.center) ~= 2 then
    return
  end
  PICKING_PLAYER = player
  startLuaCoroutine(self, 'pickBlindsCoroutine')
end

function pickBlindsCoroutine()
  startFnRunFlag()
  broadcastToAll("[21AF21]" .. PICKING_PLAYER.steam_name .. " Picks![-]")
  local blinds = getLooseCards(SCRIPT_ZONE.center)
  local playerPosition = Player[PICKING_PLAYER.color].getHandTransform().position
  local playerRotation = Player[PICKING_PLAYER.color].getHandTransform().rotation
  if blinds[1].type == 'Deck' then
    blinds[1].takeObject({
      position = playerPosition,
      rotation = playerRotation
    })
    pause(0.2)
  end
  blinds = getLooseCards(SCRIPT_ZONE.center)
  for _, card in ipairs(blinds) do
    card.setPositionSmooth(playerPosition)
    card.setRotationSmooth(playerRotation)
  end
  pause(0.35)
  for _, card in ipairs(Player[PICKING_PLAYER.color].getHandObjects()) do
    if card.is_face_down then
      card.flip()
    end
    FLAG.cardsToBeBuried = true
  end
  local pickerRotation = ROTATION.color[PICKING_PLAYER.color]
  local setBuriedButtonPos = SPAWN_POS.setBuriedButton:copy():rotateOver('y', pickerRotation)
  STATIC_OBJECT.setBuriedButton.setPosition(setBuriedButtonPos)
  STATIC_OBJECT.setBuriedButton.setRotation({0, pickerRotation, 0})
  STATIC_OBJECT.setBuriedButton.UI.setAttribute("setUpBuriedButton", "visibility", PICKING_PLAYER.color)
  STATIC_OBJECT.setBuriedButton.UI.setAttribute("setUpBuriedButton", "active", "true")

  if SETTINGS.jdPartner then
    local dealer = getPlayerObject(DEALER_COLOR_VAL, SORTED_SEATED_PLAYERS)
    if PICKING_PLAYER.color == dealer.color then
      pause(1.5)
      if doesPlayerPossessCard(PICKING_PLAYER, "Jack of Diamonds") then
        if not string.find(UI.getAttribute("playAloneWindow", "visibility"), PICKING_PLAYER.color) then
          toggleWindowVisibility(PICKING_PLAYER, "playAloneWindow")
        end
      end
    end
  else --Call an Ace
    pause(0.5)
    buildPartnerChoices(PICKING_PLAYER)
    pause(0.25)
    if HOLD_CARDS then
      toggleWindowVisibility(PICKING_PLAYER, "selectPartnerWindow")
    else --Unknown event
      unknownPartnerChoices(PICKING_PLAYER)
      pause(0.25)
      local unknownTextPos = SPAWN_POS.leasterCards:copy():rotateOver('y', pickerRotation)
      UNKNOWN_TEXT = spawnObject({ --Shares position data with leasterCards
        type = '3DText',
        position = unknownTextPos,
        rotation = {90, pickerRotation - 60, 0}
      })
      UNKNOWN_TEXT.interactable = false
      UNKNOWN_TEXT.TextTool.setFontSize(10)
      UNKNOWN_TEXT.TextTool.setFontColor("Green")
      UNKNOWN_TEXT.setValue("Place Unknown Card\nFacedown Here")
      toggleWindowVisibility(PICKING_PLAYER, "selectPartnerWindow")
    end
  end
  FLAG.fnRunning = false
  return 1
end

---Toggles the spawning and deletion of counters.<br> On counter spawn will spawn
---a counter in front of PICKING_PLAYER<br> and player accross from color.
---Flips over pickers tricks to see score of hand
function toggleCounterVisibility()
  startFnRunFlag()
  if not FLAG.counterVisible then
    local pickerColor = PICKING_PLAYER.color
    local pickerRotation = ROTATION.color[pickerColor]
    local blockRotation = ROTATION.block[pickerColor]
    local tCounter, pCounter
    local tCounterPos = SPAWN_POS.tableCounter:copy():rotateOver('y', pickerRotation)
    local pCounterPos = SPAWN_POS.pickerCounter:copy():rotateOver('y', pickerRotation)
    local blockPos = SPAWN_POS.tableBlock:copy():rotateOver('y', blockRotation)
    local block = STATIC_OBJECT.hiddenBag.takeObject({
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
        FLAG.counterVisible = true
      end,
      3
    )
    local pickerZone = TRICK_ZONE[pickerColor]
    local pickerCards = getLooseCards(pickerZone)
    if pickerCards then
      group(pickerCards)
      Wait.time(
        function()
          local pickerTricks = getLooseCards(pickerZone, true)
          pickerTricks.setPositionSmooth({pickerZone.getPosition().x, 1.25, pickerZone.getPosition().z})
          pickerTricks.setRotationSmooth({0, pickerTricks.getRotation().y, 0})
        end,
        0.6
      )
    end
    --Card counter Loop starts here with setupGuidTable()
    Wait.frames(function() setupGuidTable(tCounter.guid, pCounter.guid); FLAG.fnRunning = false end, 22)
    if not FLAG.leasterHand then
      Wait.time(displayWonOrLossText, 1.35)      
    end
  else
    local zoneObjects = SCRIPT_ZONE.table.getObjects()
    for i = #zoneObjects, 1, -1 do
      local tableObject = zoneObjects[i]
      if tableObject.type == 'Counter' then
        tableObject.destruct()
      end
    end
    STATIC_OBJECT.hiddenBag.putObject(getObjectFromGUID(GUID.TABLE_BLOCK))
    FLAG.counterVisible = false
    trickCountStop()
    FLAG.fnRunning = false
  end
end

---Makes sure buried cards are face down and unhides blinds and PICKING_PLAYERs<br>
---hand objects. Calculates global LEAD_OUT_PLAYER, hides Set Buried button
---@param player object<eventTrigger>
function setBuriedEvent(player)
  if player.color ~= PICKING_PLAYER.color then
    return
  end
  if not checkCardCount(TRICK_ZONE[PICKING_PLAYER.color], 2) then
    return
  end
  if not SETTINGS.jdPartner then
    local partnerWindowOpen = UI.getAttribute("selectPartnerWindow", "visibility")
    if partnerWindowOpen ~= "" then
      broadcastToColor("[DC0000]Select Partner before burying cards", player.color)
      return
    end
  end
  local buriedCards = getLooseCards(TRICK_ZONE[PICKING_PLAYER.color])
  if HOLD_CARDS then --callAnAce active, make sure holdCard(s) is not in burried cards
    if #HOLD_CARDS == 2 then
      local count = 0
      for _, card in ipairs(buriedCards) do
        for _, cardName in ipairs(HOLD_CARDS) do
          if card.getName() == cardName then
            count = count + 1
          end
        end
      end
      if count == 2 then
        broadcastToColor("[DC0000]You can not bury both of your hold cards", player.color)
        return
      end
    elseif #HOLD_CARDS == 1 then
      for _, card in ipairs(buriedCards) do
        if card.getName() == HOLD_CARDS[1] then
          broadcastToColor("[DC0000]You can not bury your hold card", player.color)
          return
        end
      end
    end
  end
  if UNKNOWN_TEXT then
    UNKNOWN_TEXT.destruct(); UNKNOWN_TEXT = nil
  end
  for _, card in ipairs(buriedCards) do
    if not card.is_face_down then
      card.flip()
    end
  end
  Wait.time(function() group(buriedCards) end, 0.8)
  Wait.time(
    function()
      for _, card in ipairs(getLooseCards(SCRIPT_ZONE.table)) do
        card.setInvisibleTo()
      end
    end,
    1.6
  )
  setLeadOutPlayer()
  STATIC_OBJECT.setBuriedButton.UI.setAttribute("setUpBuriedButton", "visibility", "")
  STATIC_OBJECT.setBuriedButton.UI.setAttribute("setUpBuriedButton", "active", "false")
end

function setLeadOutPlayer()
  FLAG.cardsToBeBuried = false
  local leadOutVal = getNextColorValInList(DEALER_COLOR_VAL, SORTED_SEATED_PLAYERS)
  LEAD_OUT_PLAYER = getPlayerObject(leadOutVal, SORTED_SEATED_PLAYERS)
  if not DEBUG then
    broadcastToAll("[21AF21]" .. LEAD_OUT_PLAYER.steam_name .. " leads out.[-]")
  else
    print("[21AF21]" .. LEAD_OUT_PLAYER.color .. " leads out.[-]")
  end
end

---Runs when an object tries to enter a container<br>
---Doesn't allow card grouping during trickInProgress or cardsToBeBuried<br>
---Return: true, allows object to enter | false, does not allow object to enter
---@param container object<container>
---@param object object
function tryObjectEnterContainer(container, object)
  if not FLAG.allowGrouping then
    return false
  end
  if FLAG.cardsToBeBuried then
    if isInZone(object, TRICK_ZONE[PICKING_PLAYER.color]) then
      return false
    end
  end
  if FLAG.trick.inProgress then
    if isInZone(object, SCRIPT_ZONE.center) then
      return false
    end
  end
  return true
end

---Runs when an object enters a zone
---@param zone object<zone>
---@param object object
function onObjectEnterZone(zone, object)
  --Makes sure items stay on the table if dropped
  if zone == SCRIPT_ZONE.drop then
    object.setPosition({0, 3, 0})
  end
  --Makes sure other players can not see what cards the picker is burying
  if FLAG.cardsToBeBuried then
    if zone == TRICK_ZONE[PICKING_PLAYER.color] and object.type == 'Card' then
      local hideFrom = removeColorFromList(PICKING_PLAYER.color, SORTED_SEATED_PLAYERS)
      object.setInvisibleTo(hideFrom)
    end
  end
end

---Runs when an object leaves a zone
---@param zone object<zone>
---@param object object
function onObjectLeaveZone(zone, object)
  --Starts trick
  if safeToContinue() and not FLAG.cardsToBeBuried then
    if LEAD_OUT_PLAYER then
      if zone == HAND_ZONE[LEAD_OUT_PLAYER.color] then
        FLAG.trick.inProgress = true
      end
    end
  end
end

---Runs when a player pickes up an object<br>
---If someone plays the wrong card, Ex. Player didn't see they have to follow suit
---and needs to remove a card from the CURRENT_TRICK
---@param playerColor string
---@param object object
function onObjectPickUp(playerColor, object)
  if FLAG.trick.inProgress then
    if object.type == 'Card' and isInZone(object, SCRIPT_ZONE.center) then
      if tableLength(CURRENT_TRICK) > 1 then
        local objectName = object.getName()
        for i = 2, #CURRENT_TRICK do
          if objectName == CURRENT_TRICK[i].cardName and playerColor == CURRENT_TRICK[i].playedByColor then
            reCalculateCurrentTrick(CURRENT_TRICK[i].index)
            break
          end
        end
      end
    end
  end
end

---Runs when a player drops an object<br>
---Gaurd clauses don't work in onEvents() otherwise I would use them here<br>
---Builds the table CURRENT_TRICK to keep track of cardNames and player color who laid them in the SCRIPT_ZONE.center
---@param playerColor string
---@param object object
function onObjectDrop(playerColor, object)
  if FLAG.trick.inProgress then
    if object.type == 'Card' then
      --Wait function allows script to continue in the case of a player throwing a card into SCRIPT_ZONE.center
      Wait.time(
        function()
          if isInZone(object, SCRIPT_ZONE.center) then
            if not DEBUG and playerColor ~= LEAD_OUT_PLAYER.color then
              broadcastToAll("[21AF21]" .. LEAD_OUT_PLAYER.steam_name .. " leads out.[-]")
            else
              addCardDataToCurrentTrick(playerColor, object)
              if #CURRENT_TRICK == PLAYER_COUNT + 1 then
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
---@param indexToUpdate option_integer
function removeCardFromTrick(indexToRemove, indexToUpdate)
  local highCardName
  if indexToUpdate then
    highCardName = CURRENT_TRICK[indexToUpdate].cardName
  end

  if DEBUG then print("[21AF21]" .. CURRENT_TRICK[indexToRemove].cardName .. " removed from trick[-]") end

  table.remove(CURRENT_TRICK, indexToRemove)
  for i = 2, #CURRENT_TRICK do
    if indexToUpdate then
      if highCardName == CURRENT_TRICK[i].cardName then
        CURRENT_TRICK[1].highStrengthIndex = i
      end
    end
    CURRENT_TRICK[i].index = i
  end
end

---@param indexToRemove integer
function reCalculateCurrentTrick(indexToRemove)
  --Remove card from trick and update location of current high card
  if indexToRemove ~= CURRENT_TRICK[1].highStrengthIndex then
    removeCardFromTrick(indexToRemove, CURRENT_TRICK[1].highStrengthIndex)
    return
  end
  --Remove card from trick and find the high card in remaining cards
  removeCardFromTrick(indexToRemove)
  if #CURRENT_TRICK > 1 then
    CURRENT_TRICK[1].currentHighStrength = 1
    setLeadOutCardProperties(CURRENT_TRICK[2].cardName, isTrump(CURRENT_TRICK[2].cardName))
    if #CURRENT_TRICK > 2 then
      for i = 3, #CURRENT_TRICK do
        calculateCardData(i, isTrump(CURRENT_TRICK[i].cardName))
      end
    end
  end
end

---@param playerColor string
---@param object object<card>
function addCardDataToCurrentTrick(playerColor, object)
  --Check if object is trump
  local objectName = object.getName()
  local objectIsTrump = isTrump(objectName)
  if tableLength(CURRENT_TRICK) < 2 then
    --Creates CURRENT_TRICK properties stored at index 1
    initializeCurrentTrick(objectName, objectIsTrump)
  end
  local cardData = {
    playedByColor = playerColor,
    cardName = objectName,
    index = #CURRENT_TRICK + 1,
    guid = object.guid
  }
  table.insert(CURRENT_TRICK, cardData)
  if DEBUG then
    if #CURRENT_TRICK == 2 then
      print("[21AF21]Card led out is: " .. CURRENT_TRICK[CURRENT_TRICK[1].highStrengthIndex].cardName .. "[-]")
    else
      print("[21AF21]" .. CURRENT_TRICK[#CURRENT_TRICK].cardName .. " added to trick[-]")
    end
  end
  calculateCardData(#CURRENT_TRICK, objectIsTrump, object.is_face_down)
end

---Function will return early if card does not need to be compared to currentHighStrength
---@param cardIndex integer
---@param objectIsTrump boolean
---@param isFaceDown boolean
function calculateCardData(cardIndex, objectIsTrump, isFaceDown)
  if not CURRENT_TRICK[1].trump then --No trump in CURRENT_TRICK
    if not objectIsTrump then       --Not trump and not suit led out
      if getLastWord(CURRENT_TRICK[cardIndex].cardName) ~= CURRENT_TRICK[1].ledSuit then
        return
      end
    else --No trump in CURRENT_TRICK but objectIsTrump make sure trumpStrength is greater
      CURRENT_TRICK[1].currentHighStrength = 0
    end
  else --Trump is in the CURRENT_TRICK
    if not objectIsTrump then
      return
    end
  end
  local strengthVal
  if isFaceDown then
    strengthVal = 0
  else
    strengthVal = quickSearch(CURRENT_TRICK[cardIndex].cardName, objectIsTrump)
  end
  if strengthVal > CURRENT_TRICK[1].currentHighStrength then
    updateCurrentTrickProperties(objectIsTrump, strengthVal, cardIndex)
  end
end

---@param objectName string
---@param isTrump boolean
function initializeCurrentTrick(objectName, isTrump)
  CURRENT_TRICK = {}
  setLeadOutCardProperties(objectName, isTrump)
end

---Trick properties stored in CURRENT_TRICK[1]
---@param objectName string
---@param isTrump boolean
function setLeadOutCardProperties(objectName, isTrump)
  local trickProperties = {
    ledSuit = getLastWord(objectName),
    trump = isTrump,
    currentHighStrength = quickSearch(objectName, isTrump),
    highStrengthIndex = 2
  }
  if tableLength(CURRENT_TRICK) == 0 then
    table.insert(CURRENT_TRICK, trickProperties)
    return
  end
  CURRENT_TRICK[1].ledSuit = trickProperties.ledSuit
  CURRENT_TRICK[1].trump = isTrump
  CURRENT_TRICK[1].currentHighStrength = trickProperties.currentHighStrength
  CURRENT_TRICK[1].highStrengthIndex = 2
end

---Trick properties stored in CURRENT_TRICK[1]
---@param isTrump boolean
---@param strengthVal integer
---@param index integer
function updateCurrentTrickProperties(isTrump, strengthVal, index)
  if isTrump then
    CURRENT_TRICK[1].trump = true
  end
  CURRENT_TRICK[1].currentHighStrength = strengthVal
  CURRENT_TRICK[1].highStrengthIndex = index

  if DEBUG then print("[21AF21]Current high Card is: " ..
    CURRENT_TRICK[CURRENT_TRICK[1].highStrengthIndex].cardName .. "[-]")
  end
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
  if not CURRENT_TRICK[1] or CURRENT_TRICK[1].currentHighStrength == 0 then
    startIndex = 1
  else
    startIndex = CURRENT_TRICK[1].currentHighStrength
  end
  if isTrump then
    for i = startIndex, #strengthList do
      if objectName == strengthList[i] then
        return i
      end
    end
  else
    for i = startIndex, #strengthList do
      if string.find(objectName, strengthList[i]) then
        return i
      end
    end
  end
  return 0
end

---Calculates player to give trick to. Sets global LEAD_OUT_PLAYER
function calculateTrickWinner()
  FLAG.trick.handOut = true
  FLAG.trick.inProgress, FLAG.allowGrouping = false, false
  local trickWinner = getPlayerObject(CURRENT_TRICK[CURRENT_TRICK[1].highStrengthIndex].playedByColor, SORTED_SEATED_PLAYERS)
  LEAD_OUT_PLAYER = trickWinner
  broadcastToAll("[21AF21]" ..
  trickWinner.steam_name .. " takes the trick with " .. CURRENT_TRICK[CURRENT_TRICK[1].highStrengthIndex].cardName .. "[-]")
  startLuaCoroutine(self, 'giveTrickToWinnerCoroutine')
end

---Resets trick FLAG and data then moves Trick to TRICK_ZONE of trickWinner
---Shows card counters if hand is over
---@param player object
function giveTrickToWinnerCoroutine()
  local lastTrick = false
  if #LEAD_OUT_PLAYER.getHandObjects() == 0 then
    lastTrick = true
  end
  pause(1.75)
  FLAG.allowGrouping = true
  local trick = {}
  for i = 2, #CURRENT_TRICK do
    table.insert(trick, getObjectFromGUID(CURRENT_TRICK[i].guid))
  end
  CURRENT_TRICK = {}
  local playerTrickZone = TRICK_ZONE[LEAD_OUT_PLAYER.color]
  trick = group(trick)[1]
  pause(0.6)
  trick.flip(); FLAG.trick.handOut = false
  pause(0.9)
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
  pause(0.5)
  group(getLooseCards(playerTrickZone))
  if lastTrick then
    local delay = 0
    if FLAG.leasterHand then
      delay = delay + 1.5
      LAST_LEASTER_TRICK.interactable = true
      pause(0.5)
      LAST_LEASTER_TRICK.setPositionSmooth(getDeck(playerTrickZone).getPosition())
      LAST_LEASTER_TRICK.setRotationSmooth(getDeck(playerTrickZone).getRotation())
      LAST_LEASTER_TRICK = nil
    end
    pause(delay)
    LEAD_OUT_PLAYER = nil
    toggleCounterVisibility()
  else
    FLAG.fnRunning = false
  end
  return 1
end

--[[New functions to adapt Blackjack Card Counter]]--

---Returns the color of the handposition located across the table from given color (PICKING_PLAYER)
---@param color string
---@return string<"color">
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
  local pickerZoneGuid = TRICK_ZONE[PICKING_PLAYER.color].guid
  local colorAcrossFromPicker = findColorAcrossTable(PICKING_PLAYER.color)
  local tableGuid = TRICK_ZONE[colorAcrossFromPicker].guid

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
function displayWonOrLossText(textObject, score, cardCount, numCardInDeck)
  local wonOrLoss, totalCards
  if not textObject then
    local pickerColor = PICKING_PLAYER.color
    local pickerRotation = ROTATION.color[pickerColor] --Shares the same positionData as setBuriedButton
    local textPosition = SPAWN_POS.setBuriedButton:copy():rotateOver('y', pickerRotation)
    wonOrLoss = spawnObject({
      type = '3DText',
      position = textPosition,
      rotation = {90, pickerRotation, 0}
    })
    wonOrLoss.interactable = false
    wonOrLoss.setValue("")
    if PLAYER_COUNT == 4 then
      totalCards = 30
    else
      totalCards = 32
    end
  else
    wonOrLoss = textObject
    totalCards = numCardInDeck
  end
  
  if SheepsheadGlobalTimer then
    local pickerScore = objectSets[1].c.getValue()
    local pickerTrickCardCount = countCards(objectSets[1].z)
    local cardStateChange = false
    if cardCount and cardCount ~= pickerTrickCardCount then
      if cardCount == totalCards or (cardCount ~= totalCards and pickerScore == 120) or 
      (cardCount > 2 and pickerTrickCardCount < 3) or (cardCount < 3 and pickerTrickCardCount > 2) then
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
    displayWonOrLossTimer = Wait.frames(function() displayWonOrLossText(wonOrLoss, pickerScore, pickerTrickCardCount, totalCards) end, 15)
  else
    wonOrLoss.destruct()
    Wait.stop(displayWonOrLossTimer); displayWonOrLossTimer = nil
  end
end

--[[END OF CARD SCORING]]--

--Settings flags and associated outputs to user
SETTINGS = {
  dealerSitsOut = false,
  calls = false,
  threeHanded = false,
  jdPartner = true
}

CALL_SETTINGS = {
  sheepshead = false,
  blitz = false,
  leaster = false,
  crack = false,
  crackBack = false,
  crackAroundTheCorner = false
}

CURRENT_RULES = {
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
  "[21AF21].spawnchips[-] [Gives all seated players 15 additional chips][-]\n",
  "[21AF21].settings[-] [Opens Window to Change Game Settings][-]"
}

---Prints CURRENT_RULES to the screen
function displayRules()
  setNotes(table.concat(CURRENT_RULES, ""))
end

--[[Start of functions used by settings window]]--

---Updates position of buttons for all enabled calls and<br>
---updates height of panel to fit all buttons
function buildCallPanel()
  local numOfCallsEnabled = 0
  local currentoffsetY = -5
  local buttonoffsetY = -53
  for key, value in pairs(CALL_SETTINGS) do
    local attributeID = key .. "Button"
    if value then
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

---@param rule string <"SETTINGS.rule">
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
  SETTINGS[rule] = bool
  if ruleTable[rule].execute then
    ruleTable[rule].execute(bool)
  end
  if ruleTable[rule][bool] then
    CURRENT_RULES[ruleTable[rule].ruleIndex] = ruleTable[rule][bool]
    displayRules()
  end
end

---@param call string <"CALL_SETTINGS.call">
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
  CALL_SETTINGS[call] = bool
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
  if not SETTINGS.calls and state then
    for key in pairs(CALL_SETTINGS) do
      local lowerKey = string.lower(key)
      if string.find(lowerID, lowerKey) then
        return true
      end
    end
  end
  if not CALL_SETTINGS.crack and state then
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
  if id == "jdPartner" and SETTINGS.jdPartner == nil then
    return true
  end
  return false
end

---Toggle setting via formatted id
---@param player nil
---@param val nil
---@param id string <"turnOnSettingName"|"turnOffSettingName">
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
  for key in pairs(SETTINGS) do
    if key == idName then
      updateRules(idName, state)
    end
  end
  for key in pairs(CALL_SETTINGS) do
    if key == idName then
      updateCalls(idName, state)
    end
  end
  UI.setAttribute(parentID1, "active", state)
  UI.setAttribute(parentID2, "active", not state)
end

---@param bool boolean
function stateChangeCalls(bool)
  if bool then
    UI.setAttribute("callSettingsBackground", "image", "crackDisabled")
  else
    UI.setAttribute("callSettingsBackground", "image", "callsDisabled")
    for key, value in pairs(CALL_SETTINGS) do
      if value then
        local formatKey = "turnOff" .. key
        toggleSetting(player, val, formatKey)
      end
    end
  end
end

---@param bool boolean
function stateChangeDealerSitsOut(bool)
  if SORTED_SEATED_PLAYERS == nil then
    return
  end
  if bool then
    if #SORTED_SEATED_PLAYERS == 6 then
      PLAYER_COUNT = 5
      print("[21AF21]Dealer will sit out every hand.[-]")
    end
  else
    if #SORTED_SEATED_PLAYERS == 6 then
      PLAYER_COUNT = #SORTED_SEATED_PLAYERS
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
  if bool then
    SETTINGS.jdPartner = nil
    if not SETTINGS.calls then
      Wait.time(function() toggleSetting(player, val, "turnOnCalls") end, 3)
    end
    if not CALL_SETTINGS.leaster then
      Wait.time(function() toggleSetting(player, val, "turnOnLeaster") end, 3)
    end
    UI.setAttribute(jdPartnerID, "tooltip", "Can not change setting, No partner playing 3 handed")
  else
    if SETTINGS.jdPartner == nil then
      local callCount = 0
      for _, bool in pairs(CALL_SETTINGS) do
        if bool then
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
  if bool then
    UI.setAttribute("callSettingsBackground", "image", "callPanel")
  else
    if SETTINGS.calls then
      UI.setAttribute("callSettingsBackground", "image", "crackDisabled")
    end
    for key, value in pairs(CALL_SETTINGS) do
      local lowerKey = string.lower(key)
      if value and string.find(lowerKey, "crack.") then
        local formatKey = "turnOff" .. key
        toggleSetting(player, val, formatKey)
      end
    end
  end
end

---@param bool boolean
---@param call string
function stateChangeCrackSubSet(bool, call)
  if bool then
    for key, value in pairs(CALL_SETTINGS) do
      local lowerKey = string.lower(key)
      if value and string.find(lowerKey, "crack.") and key ~= call then
        local formatKey = "turnOff" .. key
        toggleSetting(player, val, formatKey)
      end
    end
  end
end

--[[End of functions for settings window]]--

---@param player object
---@param window string<"windowID">
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
  if not PICKING_PLAYER then
    return
  end
  local player = player
  Wait.time( --0.13s delay allows button click sound to be played
    function() --Show call partner window for selected parter mode
      if LEAD_OUT_PLAYER then
        broadcastToColor("[DC0000]You can not do this now[-]", player.color)
        return
      end
      if SETTINGS.jdPartner then
        local dealer = getPlayerObject(DEALER_COLOR_VAL, SORTED_SEATED_PLAYERS)
        if player.color == dealer.color and player.color == PICKING_PLAYER.color then
          if doesPlayerPossessCard(player, "Jack of Diamonds") then
            toggleWindowVisibility(player, "playAloneWindow")
          else
            broadcastToColor("[DC0000]Jack of Diamonds will be your partner[-]", player.color)
          end
        else
          broadcastToColor("[DC0000]You can only call up if you are forced to pick and have the Jack[-]", player.color)
        end
      else --Call an Ace
        if player.color == PICKING_PLAYER.color then
          toggleWindowVisibility(player, "selectPartnerWindow")
        else
          broadcastToColor("[DC0000]Only the picker can call their partner[-]", player.color)
        end
      end
      toggleWindowVisibility(player, "callsWindow")
    end, 
    0.13
  )
end

---@param player object<eventTrigger>
---@param val nil
---@param id string<"eventID">
function playerCallsEvent(player, val, id)
  if not safeToContinue() then
    broadcastToColor("[DC0000]It's not time to call[-] ", player.color)
    return
  end
  local player = player
  local id = string.gsub(id, "Button", "")
  id = upperFirstChar(id)
  if id ~= "Leaster" then
    local cardsOnTable = 0
    for _, zone in pairs(TRICK_ZONE) do
      cardsOnTable = cardsOnTable + countCards(zone)
    end
    if not PICKING_PLAYER or cardsOnTable > 2 then
      broadcastToColor("[DC0000]It's not time to call[-] ", player.color)
      return
    end
  end
  Wait.time(function() toggleWindowVisibility(player, "callsWindow") end, 0.13)
  if id == "Leaster" then
    dealer = getPlayerObject(DEALER_COLOR_VAL, SORTED_SEATED_PLAYERS)
    if player.color == dealer.color and checkCardCount(SCRIPT_ZONE.center, 2) then
      broadcastToAll("[21AF21]" .. player.steam_name .. " calls for a " .. id .. "[-]")
      PICKING_PLAYER = player
      startLuaCoroutine(self, 'startLeasterHandCoroutine')
    elseif player.color == dealer.color and countCards(SCRIPT_ZONE.center) ~= 2 then
      broadcastToColor("[DC0000] You can only call leaster before you pick the blinds[-]", player.color)
    else
      broadcastToColor("[DC0000] You can only call leaster if you are forced to pick[-]", player.color)
    end
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

---@param player object<eventTrigger>
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
---@param cards table<"cardNames">
---@param name string<"Jack"|"Queen">
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
    for i = #nextHigh, 1, -1 do
      local suit = nextHigh[i]
      if string.find(cardInHand, suit) then
        table.remove(nextHigh, i)
      end
    end
  end
  callCard = name .. " of " .. nextHigh[1]
  return callCard
end

---if valid holdCards found in player hand will enable corresponding buttons in selectPartnerWindow<br>
---and updates the global HOLD_CARDS | if no valid holdCards will update as nil
---@param player object<player>
function buildPartnerChoices(player)
  --failCards = all suitableFail including ten's
  local failCards = filterPlayerCards(player, "suitableFail", "Diamonds")
  local failSuits, holdCards, partnerChoices = {}, {}, {}
  if tableLength(failCards) > 0 then
    failSuits = uniqueFailSuits(failCards)
    local notPartnerChoices, card = aceOrTenOfNotPartnerChoices(player)

    if card == "Ten" then --player has 3 aces, Hold card must be the ace
      failSuits = {"Hearts", "Spades", "Clubs"}
      holdCards = {"Ace of Hearts", "Ace of Spades", "Ace of Clubs"}
    end
    if tableLength(notPartnerChoices) > 0 then
      failSuits = removeHeldCards(notPartnerChoices, failSuits)
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
  if tableLength(failCards) == 0 or tableLength(failSuits) == 0 then
    HOLD_CARDS = nil --nil = unknown mode
    return
  end
  setActivePartnerButtons(partnerChoices)
  HOLD_CARDS = holdCards
end

---filters a list of card names down to one of each fail suit
---@param failCards table<"cardName">
---@return table<"suitName">
function uniqueFailSuits(failCards)
  local failSuits = {}
  for _, cardName in ipairs(failCards) do
    local cardSuit = getLastWord(cardName)
    if not tableContains(failSuits, cardSuit) then
      table.insert(failSuits, cardSuit)
    end
  end
  return failSuits
end

---returns the fail aces a player holds, if player holds 3 fail aces returns the fail 10's a player holds<br>
---setting unknown will include the King
---@param player object
---@param unknown option_bool
---@return table<"cardNames">
---@return string<"Ace"|"Ten">
function aceOrTenOfNotPartnerChoices(player, unknown)
  local tryOrder = {"Ace", "Ten"}
  if unknown then
    table.insert(tryOrder, "King")
  end
  local notPartnerChoices, card
  for _, tryCard in ipairs(tryOrder) do
    card = tryCard
    notPartnerChoices = filterPlayerCards(player, tryCard, "Diamonds")
    if tableLength(notPartnerChoices) < 3 then
      break
    end
  end
  return notPartnerChoices, card
end

---Removes suits from failSuits if they share the same suit with cards found in notPartnerChoices
---@param notPartnerChoices table<"cardNames">
---@param failSuits table<"suitName">
---@return table<"suitName">
function removeHeldCards(notPartnerChoices, failSuits)
  for _, cardToRemove in ipairs(notPartnerChoices) do
    for i = #failSuits, 1, -1 do
      local suit = failSuits[i]
      if string.find(cardToRemove, suit) then
        table.remove(failSuits, i)
      end
    end
  end
  return failSuits
end

---Finds the valid partnerChoices for when unknown event is triggered and passes them to setActivePartnerButtons
---@param player object
function unknownPartnerChoices(player)
  local failSuits = {"Hearts", "Spades", "Clubs"}
  local notPartnerChoices, card = aceOrTenOfNotPartnerChoices(player, true)
  failSuits = removeHeldCards(notPartnerChoices, failSuits)
  local partnerChoices = {}
  for _, suit in ipairs(failSuits) do
    table.insert(partnerChoices, card .. " of " .. suit)
  end
  setActivePartnerButtons(partnerChoices)
  if DEBUG then
    print("Unknown event triggered")
    print(table.concat(partnerChoices, ", "))
  end
end

---@param list table<"cardNames">
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

---@param player object<eventTrigger>
function selectPartnerEvent(player, val, id)
  FLAG.fnRunning = true
  local formattedID = id:gsub("-", " ")
  local unknownFormat = ""
  if UNKNOWN_TEXT then
    unknownFormat = " - Unknown"
  end
  broadcastToAll("[21AF21]" .. player.steam_name .. " Picks " .. formattedID .. unknownFormat .. " as their parnter")
  toggleWindowVisibility(player, "selectPartnerWindow")
  local validSuit = getLastWord(formattedID)
  Wait.time(
    function()
      if not UNKNOWN_TEXT then --Unknown event off
        local nonValidSuits = {"Hearts", "Spades", "Clubs"}
        for i, suit in ipairs(nonValidSuits) do
          if string.find(suit, validSuit) then
            table.remove(nonValidSuits, i)
            break
          end
        end
        for _, suit in ipairs(nonValidSuits) do --update global HOLD_CARDS
          for i = #HOLD_CARDS, 1, -1 do
            if string.find(HOLD_CARDS[i], suit) then
              table.remove(HOLD_CARDS, i)
            end
          end
        end
        local validCards = copyTable(HOLD_CARDS) --build validCards for string format to player
        local numOfValidCards = #validCards
        if numOfValidCards > 1 then
          table.insert(validCards, #validCards, "or")
        end
        validCards = table.concat(validCards, " ")
        if numOfValidCards > 2 then
          validCards = validCards:gsub(validSuit .. "([^,])", validSuit .. ",%1")
        end
        broadcastToColor("[21AF21]Remember to play the " .. validCards .. " the first time " .. validSuit .. " is played[-]", PICKING_PLAYER.color)
        if DEBUG then
          print("Valid holdCards are: " .. table.concat(HOLD_CARDS, ", "))
        end
      else --Unknown event on
        broadcastToColor("[21AF21]Remember to play your unknown card the first time ".. validSuit .. " is played[-]", PICKING_PLAYER.color)
      end
      FLAG.fnRunning = false
    end,
    2
  )
end
--[[End of functions and buttons for playAloneWindow/selectPartnerWindow window]]--

function startLeasterHandCoroutine()
  group(getLooseCards(SCRIPT_ZONE.center))
  pause(0.6)
  LAST_LEASTER_TRICK = getDeck(SCRIPT_ZONE.table)
  if LAST_LEASTER_TRICK.getQuantity() ~= 2 then
    print("startLeasterHand Err: blinds wrong quanity")
    return 1
  end
  local playerRotation = ROTATION.color[PICKING_PLAYER.color]
  local leasterPos = SPAWN_POS.leasterCards:copy():rotateOver('y', playerRotation)
  LAST_LEASTER_TRICK.setPositionSmooth(leasterPos)
  LAST_LEASTER_TRICK.setRotationSmooth({0, playerRotation + 30, 180})
  LAST_LEASTER_TRICK.interactable = false
  setLeadOutPlayer()
  FLAG.leasterHand = true
  printLeasterRules()
  return 1
end

function printLeasterRules()
  Wait.time(function() broadcastToAll("[21AF21]No teams, everyone for themselves![-]") end, 1)
  Wait.time(function() broadcastToAll("[21AF21]Player with least ammount of points wins +1 from all[-]") end, 3)
  Wait.time(function() broadcastToAll("[21AF21]Player who takes the last trick gets the blinds[-]") end, 5)
end


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
    if SORTED_SEATED_PLAYERS == nil then
      print("[21AF21]Press Set Up Game to initialize variables before changing player count.")
    elseif #SORTED_SEATED_PLAYERS > 0 and #SORTED_SEATED_PLAYERS < 6 then
      table.insert(SORTED_SEATED_PLAYERS, #SORTED_SEATED_PLAYERS + 1,
        ALL_PLAYERS[#SORTED_SEATED_PLAYERS + 1])
      print("Current players: ", table.concat(SORTED_SEATED_PLAYERS, ", "))
    else
      print("Can not add any more players")
      print("Current players: ", table.concat(SORTED_SEATED_PLAYERS, ", "))
    end
  end
end

function playerCountDebugDown()
  if DEBUG then
    if SORTED_SEATED_PLAYERS == nil then
      print("[21AF21]Press Set Up Game to initialize variables before changing player count.")
    elseif #SORTED_SEATED_PLAYERS == 1 then
      print("Can not remove any more players")
      print("Current players: ", table.concat(SORTED_SEATED_PLAYERS, ", "))
    else
      table.remove(SORTED_SEATED_PLAYERS, #SORTED_SEATED_PLAYERS)
      print("Current players: ", table.concat(SORTED_SEATED_PLAYERS, ", "))
    end
  end
end

function test(player)

end
