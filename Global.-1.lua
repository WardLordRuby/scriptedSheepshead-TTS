--[[ Scripted version of Sheepshead built inside of Tabletop Simulator By: WardLordRuby
     Scoring currently uses a modified version of the blackjack counting script by: MrStump
     I liked how EpicWolverine handled rebuilding the deck so I modified his code ]]--

DEBUG = true

--[[CONST values]]--

ALL_PLAYERS = {"White", "Red", "Yellow", "Green", "Blue", "Pink"}

BLACK_SEVENS = {"Seven of Clubs", "Seven of Spades"}

BLINDS_STR = "Blinds"

CHAT_COMMANDS = {
  "[b415ff]Sheepshead Console Help[-]\n",
  "[21AF21].rules[-] [Spawns a Rule and Gameplay Tip Booklet]\n",
  "[21AF21].hiderules[-] [Hides all Rule and Gameplay Tip Booklet(s)]\n",
  "[21AF21].respawndeck[-] [Removes all Cards and Spawns a Fresh Deck]\n",
  "[21AF21].spawnchips[-] [Gives all seated players 15 additional chips]\n",
  "[21AF21].settings[-] [Open/Close a UI Window to Change Game Settings]"
}

COIN_PRAM = {
  mesh = "https://steamusercontent-a.akamaihd.net/ugc/2205135744307283952/DEF0BF91642CF5636724CA3A37083385C810BA06/",
  diffuse = "https://steamusercontent-a.akamaihd.net/ugc/2288456143464578824/E739670FE62B8267C90E54D4B786C1C83BA7CC22/",
  type = 5,
  material = 2,
  specular_sharpness = 5
}

FAIL_STRENGTHS = {"Seven", "Eight", "Nine", "King", "Ten", "Ace"}

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

JD_PARTNER_CARD = "Jack of Diamonds"

POS = {
  center = Vector(0, 1.5, 0),
  objectRespawn = Vector(0, 3, 0),
  defaultDeckRotation = Vector(0, 0, 180),
  centerBlockOffset = Vector(3.5, 0, 0)
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

RULE_BOOK_JSON = [[{
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

TRUMP_IDENTIFIER = {"Diamonds", "Jack", "Queen"}

TRUMP_STRENGTHS = {
  "Seven of Diamonds", "Eight of Diamonds", "Nine of Diamonds", "King of Diamonds", "Ten of Diamonds",
  "Ace of Diamonds", "Jack of Diamonds", "Jack of Hearts", "Jack of Spades", "Jack of Clubs",
  "Queen of Diamonds", "Queen of Hearts", "Queen of Spades", "Queen of Clubs"
}

--[[GLOBAL values]]--

---Timer that loops the `displayWonOrLossText` function passing calculated values back into itself<br>
---Responsible for displaying the number of chips won or loss in a hand<br>
---@type integer<UID>|nil
CHIP_SCORE_TEXT_TIMER = nil

---Note: `object` table contains: `z = object<zone>, c = object<counter>`<br>
---Picker `object` group is always in index `1`<br>Can not be stringified
---@type table<table<objects>>
COUNTER_OBJ_SETS = {}

---Note: Can not be stringified
---@type object<"3DText">|nil
SCORE_TEXT_OBJ = nil

---Timer that loops the responsible functions for displaying the score of a hand<br>
---this value is instantiated by `startTrickCount`
---@type integer<UID>|nil
TRICK_COUNTER_TIMER = nil

---@param script_state JSON<table>
function onLoad(script_state)
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

  ---@type {
  ---   playerCount: integer|nil,
  ---   sortedSeatedPlayers: table<"Colors">|nil,
  ---   dealOrder: table<"Colors"|BLINDS_STR>|nil,
  ---   blackSevens: string<"GUID">|nil,
  ---   dealerColorIdx: integer<index>|nil,
  ---   holdCards: table<"cardName">|nil,
  ---   currentTrick: table<metaData>|nil,
  ---   gameSetupPlayer: string<"Color">|nil,
  ---   pickingPlayer: string<"Color">|nil,
  ---   partnerCard: string<"cardName">|nil,
  ---   leadOutPlayer: string<"Color">|nil,
  ---   lastLeasterTrick: string<"GUID">|nil,
  ---   unknownText: string<"GUID">|nil,
  ---   chipScoreText: string<"GUID">|nil,
  ---   counterGUIDs: table<string<"zoneGUID">, string<"counterGUID">>|nil
  --- }
  GLOBAL = {
    playerCount = nil,
    sortedSeatedPlayers = nil,
    dealOrder = nil,
    blackSevens = nil,
    dealerColorIdx = nil,
    holdCards = nil, --Note: `nil` == unknown mode
    currentTrick = nil, --Note: `self[1]` contains general trickMetadata, followed by metadata for each card in the trick
    gameSetupPlayer = nil,
    pickingPlayer = nil,
    partnerCard = nil,
    leadOutPlayer = nil,
    lastLeasterTrick = nil,
    unknownText = nil, --Note: Shares position data with leasterCards
    chipScoreText = nil,
    counterGUIDs = nil --Note: Linked by Key, Value pairs
  }

  FLAG = {
    setupRan = false,
    trickInProgress = false,
    handInProgress = false,
    crackCalled = false,
    leasterHand = false,
    stopCoroutine = false,
    lookForPlayerText = false,
    continue = nil, --Note: continue's default is nul because it is also used as an interrupt for `pause`
    cardsToBeBuried = false,
    counterVisible = false,
    firstDealOfGame = false,
    allowGrouping = true,
    selectingPartner = false,
    fnRunning = false
  }

  ---Note: the ordering of these values matters for correctly setting state `onLoad`
  ---@type {
  ---   jdPartner: boolean|nil,
  ---   dealerSitsOut: boolean,
  ---   calls: boolean,
  ---   threeHanded: boolean,
  --- }
  SETTINGS = {
    jdPartner = true, --Note: `false` == Call an Ace && `nil` == No Partner
    dealerSitsOut = false,
    calls = false,
    threeHanded = false
  }

  CALL_SETTINGS = {
    sheepshead = false,
    blitz = false,
    leaster = false,
    crack = false,
    crackBack = false,
    crackAroundTheCorner = false
  }

  local state = JSON.decode(script_state)

  if not isEmpty(state) then
    for rule, saved in pairs(state.settings) do
      if SETTINGS[rule] ~= saved then
        updateRules(rule, saved)
        toggleUISettingsButtonState(rule, saved)
      end
    end

    for call, saved in pairs(state.callSettings) do
      if CALL_SETTINGS[call] ~= saved then
        updateCalls(call, saved)
        toggleUISettingsButtonState(call, saved)
      end
    end

    for flag, saved in pairs(state.flags) do
      FLAG[flag] = saved
    end

    for global, saved in pairs(state.globals) do
      GLOBAL[global] = saved
    end

    if FLAG.counterVisible then
      local tableBlock = getObjectFromGUID(GUID.TABLE_BLOCK)
      tableBlock.setInvisibleTo(ALL_PLAYERS)
      tableBlock.setLock(true)
      startTrickCount()
      if not FLAG.leasterHand then
        SCORE_TEXT_OBJ = getObjectFromGUID(GLOBAL.chipScoreText)
        SCORE_TEXT_OBJ.interactable = false
        displayWonOrLossText()
      end
    end

    if FLAG.cardsToBeBuried and GLOBAL.pickingPlayer then
      showSetBuriedButton()
    end
  end

  if DEBUG then
    UI.show("playerUp")
    UI.show("playerDown")
  end

  displayRules()
end

---@return JSON<table>
function onSave()
  local state = {
    settings = SETTINGS,
    callSettings = CALL_SETTINGS,
    flags = FLAG,
    globals = GLOBAL
  }
  return JSON.encode(state)
end

--[[Utility functions]]--

---Returns `true` if there are 6 seated players and `SETTINGS.dealerSitsOut` is active
---@return boolean
function dealerSitsOutActive()
  return GLOBAL.playerCount ~= #GLOBAL.sortedSeatedPlayers
end

---Sets the FLAG.fnRunning to true when safe this must be ran within a coroutine
function startFnRunFlag()
  while FLAG.fnRunning do
    coroutine.yield(0)
  end
  FLAG.fnRunning = true
end

---Pauses script, must be called from within a coroutine
---@param time integer<seconds>
function pause(time)
  local start = Time.time
  repeat coroutine.yield(0) until Time.time > start + time or FLAG.continue ~= nil
end

--[[String manipulation]]--

---@param str string
---@return string
function getLastWord(str)
  return str:match("%S+$") --%S+ = one or more non-space characters, $ = match end of string
end

---@param str string
---@return string
function upperFirstChar(str)
  return str:sub(1, 1):upper() .. str:sub(2)
end

---@param str string
---@return string
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

---Copies input table and removes the first matching value, if value not found returns original table<br>
---Table must have numerical indexes
---@param remove any
---@param from table<any>
---@return table<any>
function removeFromClonedList(remove, from)
  local foundIdx
  for i, v in ipairs(from) do
    if v == remove then
      foundIdx = i
      break
    end
  end
  if foundIdx then
    local modifiedList = copyTable(from)
    table.remove(modifiedList, foundIdx)
    return modifiedList
  end
  return from
end

---@param color string<"Color">
---@param pipeList string
---@return pipeList string
function addColorToPipeList(color, pipeList)
  if not pipeList or pipeList == "" then
    pipeList = color
  else
    pipeList = pipeList .. "|" .. color
  end
  return pipeList
end

---@param color string<"Color">
---@param pipeList string
---@return pipeList string
function removeColorFromPipeList(color, pipeList)
  pipeList = string.gsub(pipeList, color .. '|', "")
  pipeList = string.gsub(pipeList, '|' .. color, "")
  pipeList = string.gsub(pipeList, color, "")
  return pipeList
end

--[[Data retrieval]]--

---@param object object
---@param zone object<zone>
---@return boolean
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
---@param table table<any>|nil
---@return integer
function len(table)
  if isEmpty(table) then
    return 0
  end
  local count = 0
  for _ in pairs(table) do
    count = count + 1
  end
  return count
end

---Used to ensure `true` is returned if table empty or nil
---@param table table<any>|nil
---@return boolean
function isEmpty(table)
  return table == nil or next(table) == nil
end

---Does not check table keys
---@param table table<any>
---@param value any
---@return boolean
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
    if obj.type == "Deck" then
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

---getLooseCards also provides a safe way to return a deck Object from outside of a coroutine<br>
---@param zone object<zone>
---@param returnFirstDeck option_boolean
---@return table<card_Objects_and_deck_Objects>|nil
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

---Searches table for given input and return the index value if found, otherwise returns `nil`
---@param find any
---@param list table<any>|nil
function getIndex(find, list)
  for i, v in ipairs(list) do
    if v == find then
      return i
    end
  end
  return nil
end

---Returns the index of the player seated clockwise from given index, will never return `BLINDS_STR` index<br>
---Can also return the counter-clockwise index position if the `reverse` flag is set
---@param index integer
---@param list table<"Colors">
---@param reverse option_boolean
---@return integer<index>|nil
function cycleColorIndex(index, list, reverse)
  if isEmpty(list) then
    return nil
  end
  local listLength = #list
  if index > listLength or index < 1 then
    return nil
  end

  local step
  if reverse then
    step = function(curr)
      return ((curr - 2) % listLength) + 1
    end
  else
    step = function(curr)
      return (curr % listLength) + 1
    end
  end

  local i = step(index)
  while list[i] == BLINDS_STR do
    i = step(i)
  end
  return i
end

---Returns the rotationValue.z associated for cards if more cards are face up or face down in a given zone
---@param zone object<zone>
---@return integer<0|180>
function moreFaceUpOrDown(zone)
  local total, faceDownCount = countCards(zone)
  local halfOfTotal = math.floor(total / 2)
  if halfOfTotal >= faceDownCount then
    return 0
  end
  return 180
end

---Returns the number of cards in a given zone, also returns faceDownCount
---@param zone object<zone>
---@return integer<numCards>, integer<numCardsFaceDown>
function countCards(zone)
  local objects = zone.getObjects()
  local cardCount, faceDownCount = 0, 0
  for _, obj in ipairs(objects) do
    if obj.type == "Deck" then
      cardCount = cardCount + obj.getQuantity()
      if obj.is_face_down then
        faceDownCount = faceDownCount + obj.getQuantity()
      end
    elseif obj.type == "Card" then
      cardCount = cardCount + 1
      if obj.is_face_down then
        faceDownCount = faceDownCount + 1
      end
    end
  end
  return cardCount, faceDownCount
end

---@param player string<"Color">
---@param cardName string
---@return boolean
function doesPlayerPossessCard(player, cardName)
  local playerCards = getPlayerCards(player)
  for _, name in ipairs(playerCards) do
    if name == cardName then
      return true
    end
  end
  return false
end

---Searches `player`'s `HAND_ZONE` and `TRICK_ZONE`
---@param player string<"Color">
---@return table<"cardNames">
function getPlayerCards(player)
  local cardNames = {}
  for _, card in ipairs(getLooseCards(HAND_ZONE[player])) do
    --Must be card since objects do not group in the hand zone
    table.insert(cardNames, card.getName())
  end
  for _, object in ipairs(getLooseCards(TRICK_ZONE[player])) do
    if object.type == "Card" then
      table.insert(cardNames, object.getName())
    else --Must be deck since `getLooseCards` filters by type "Card" & "Deck" only
      for _, containedCard in ipairs(object.getObjects()) do
        table.insert(cardNames, containedCard.nickname)
      end
    end
  end
  return cardNames
end

---Filters cards relevant to determining Call an Ace conditions or finding next highest card to call
---@param player string<"Color">
---@param scheme string<"suitableFail"|"King"|"Ace"|"Ten"|"Jack"|"Queen">
---@param doNotInclude option_string
---@return table<"cardNames">
function filterPlayerCards(player, scheme, doNotInclude)
  local playerCards = getPlayerCards(player)
  local filteredCards, filterList = {}, {}
  local validCard
  if scheme == "suitableFail" then
    for i = 1, 5 do
      filterList[i] = FAIL_STRENGTHS[i]
    end
  else
    filterList[1] = scheme
  end
  if doNotInclude then
    validCard = function(name, findName)
      return string.find(name, findName) and not string.find(name, doNotInclude)
    end
  else
    validCard = function(name, findName)
      return string.find(name, findName)
    end
  end
  for _, name in ipairs(playerCards) do
    for _, findName in ipairs(filterList) do
      if validCard(name, findName) then
        table.insert(filteredCards, name)
      end
    end
  end
  return filteredCards
end

---@param player string<"Color">
---@return integer<rotationAngle>, vector<playerPosition>
function getItemMoveData(player)
  return ROTATION.color[player], Player[player].getHandTransform().position
end

---Prints `CURRENT_RULES` to the screen
function displayRules()
  setNotes(table.concat(CURRENT_RULES, ""))
end

--[[Object manipulation]]--

---Checks if a deck in the given zone is face up, if so it flips the deck<br>
---Recommended to be ran from within a coroutine
---@param zone object<zone>
function flipDeck(zone)
  local deck = getDeck(zone)
  if not deck then
    return
  end
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

---Called to remove items from a zone. Must be called from within a coroutine if `not skipAnimation`
---@param zone object<zone>
---@param items table<"Types">|string<"Type">
---@param skipAnimation option_boolean
function removeItem(zone, items, skipAnimation)
  if type(items) == "string" then
    items = {items}
  end
  local zoneObjects = zone.getObjects()
  for i = #zoneObjects, 1 , -1 do
    local object = zoneObjects[i]
    if tableContains(items, object.type) then
      object.destruct()
      if not skipAnimation then
        pause(0.06)
      end
    end
  end
end

---Moves deck and dealer chip in front of the next clockwise seated player<br>
---Needs to be ran from within a coroutine
function moveDeckAndDealerChip()
  local rotationAngle, playerPos = getItemMoveData(GLOBAL.sortedSeatedPlayers[GLOBAL.dealerColorIdx])
  local rotatedChipOffset = SPAWN_POS.dealerChip:copy():rotateOver('y', rotationAngle)
  local rotatedDeckOffset = SPAWN_POS.deck:copy():rotateOver('y', rotationAngle)
  local chipRotation = STATIC_OBJECT.dealerChip.getRotation()
  local deck = getDeck(SCRIPT_ZONE.table)
  while not deck do
    coroutine.yield(0)
    deck = getDeck(SCRIPT_ZONE.table)
  end
  STATIC_OBJECT.dealerChip.setRotationSmooth({ chipRotation.x, rotationAngle - 90, chipRotation.z })
  STATIC_OBJECT.dealerChip.setPositionSmooth(playerPos + rotatedChipOffset)
  deck.setRotationSmooth({ deck.getRotation().x, rotationAngle, POS.defaultDeckRotation.z })
  deck.setPositionSmooth(playerPos + rotatedDeckOffset)
end

---prepCards will group and center all cards and respawn the deck if any error is encountered<br>
---Needs to be ran from within a coroutine. Note: this fn assumes it is being called from within a
---coroutine that has already set `FLAG.fnRunning`
function prepCards()
  local looseCards = getLooseCards(SCRIPT_ZONE.table)
  if not looseCards then
    respawnDeckCoroutine(true)
    return
  end

  if #looseCards > 1 then
    group(looseCards)
    pause(0.5)
    local deck = getDeck(SCRIPT_ZONE.table)
    if not deck then
      respawnDeckCoroutine(true)
      return
    end
    deck.setPosition(POS.center)
    deck.setRotation(POS.defaultDeckRotation)
    pause(1)
  end
end

---Just checks to make sure cards are all there<br>
---Note: this fn assumes it is being called from within a coroutine that has already set `FLAG.fnRunning`
function verifyCardCount()
  local cardCount = countCards(SCRIPT_ZONE.table)
  local modifyDeck, deckModifiable, correctCount
  if GLOBAL.playerCount == 4 then
    correctCount = 30
    modifyDeck = removeBlackSevens
    deckModifiable = function(deck)
      return deck and deck.getQuantity() == 32 and cardCount == 32
    end
  else
    correctCount = 32
    modifyDeck = returnDeckToPiquet
    deckModifiable = function(deck)
      return deck and deck.getQuantity() == 30 and cardCount == 30 and GLOBAL.blackSevens
    end
  end

  if cardCount ~= correctCount then
    local deck = getDeck(SCRIPT_ZONE.table)
    if deckModifiable(deck) then
      modifyDeck(deck)
    else
      respawnDeckCoroutine(true)
    end
  end
end

---Spreads cards out over the center of the table, makes sure they are face down, and groups cards
function rebuildDeck()
  FLAG.allowGrouping = false
  local faceRotation = moreFaceUpOrDown(SCRIPT_ZONE.table)
  for _, object in ipairs(getLooseCards(SCRIPT_ZONE.table)) do
    if object.type == "Deck" then
      for _, containedCard in ipairs(object.getObjects()) do
        object.takeObject({
          rotation = { 0, math.random(0, 360), faceRotation },
          position = { math.random(-5.75, 5.75), 1.4, math.random(-5.75, 5.75) },
          guid = containedCard.guid
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

---Runs every time a chat occurs.
---<br>Return: true, hides player msg | false, shows player msg
---@param message string<playerInput>
---@param player object<player>
---@return boolean
function onChat(message, player)
  --Sets flags for determining if to reset game board
  if FLAG.lookForPlayerText and player.color == GLOBAL.gameSetupPlayer then
    local lowerMessage = string.lower(message)
    if lowerMessage == 'y' then
      print("[21AF21]" .. player.steam_name .. " selected new game.[-]")
      print("[21AF21]New game is being set up.[-]")
      FLAG.continue = true
      return false
    elseif lowerMessage == 'n' then
      FLAG.continue = false
      return false
    end
  end

  --Handles chat event for game commands
  if string.sub(message, 1, 1) == '.' then
    local command = string.lower(string.sub(message, 2))
    if command == "help" then
      print(table.concat(CHAT_COMMANDS, ""))
    elseif command == "rules" then
      getRuleBook(player.color)
    elseif command == "hiderules" then
      removeItem(SCRIPT_ZONE.table, "Tile", true)
    elseif command == "respawndeck" then
      respawnDeck(player)
    elseif command == "settings" then
      if adminCheck(player) then
        toggleWindowVisibility(player.color, "settingsWindow")
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
---@return boolean
function adminCheck(player)
  if not player.admin then
    broadcastToColor("[DC0000]You do not have permission to access this feature.[-]", player.color)
    return false
  end
  return true
end

---Spawns a rule book in front of player color
---@param player string<"Color">
function getRuleBook(player)
  local playerRotation = ROTATION.color[player]
  local ruleBookPos = SPAWN_POS.ruleBook:copy():rotateOver('y', playerRotation)
  spawnObjectJSON({
    json = RULE_BOOK_JSON,
    position = { ruleBookPos.x, 1.5, ruleBookPos.z },
    rotation = { 0, playerRotation - 180, 0 }
  })
end

---Removes any cards on the table and respawns the deck
---@param player object<commandTrigger>
function respawnDeck(player)
  if not adminCheck(player) then
    return
  end
  if FLAG.fnRunning then
    broadcastToColor(
      "[fc8803]Action in progress, deck will be re-spawned after current action is complete.[-]",
      player.color
    )
  end
  startLuaCoroutine(self, "respawnDeckCoroutine")
end

---Set `fnRunning` if this function should be ran as a continuation of a currently set `FLAG.fnRunning`
---otherwise will wait for any current `FLAG.fnRunning` to complete and starts a new fnRunning instance
---@param fnRunning option_boolean
function respawnDeckCoroutine(fnRunning)
  if not fnRunning then
    startFnRunFlag()
  end

  local remainingTableCards = getLooseCards(SCRIPT_ZONE.table)
  if not isEmpty(remainingTableCards) then
    removeItem(SCRIPT_ZONE.table, {"Card", "Deck"})
  end
  STATIC_OBJECT.hiddenBag.takeObject({
    guid = GUID.DECK_COPY,
    position = { 3, 2, 0 },
    rotation = POS.defaultDeckRotation,
    smooth = false
  })
  local deckCopy = getObjectFromGUID(GUID.DECK_COPY)
  deckCopy.setInvisibleTo(ALL_PLAYERS)
  local newDeckPos = Vector(0, -3, 0)
  if FLAG.counterVisible then
    newDeckPos = newDeckPos + POS.centerBlockOffset
  end
  local newDeck = deckCopy.clone({
    position = newDeckPos
  })
  STATIC_OBJECT.hiddenBag.putObject(deckCopy)
  if GLOBAL.blackSevens then
    STATIC_OBJECT.hiddenBag.takeObject({
      guid = GLOBAL.blackSevens,
      position = { 5, 2, 0 },
      rotation = POS.defaultDeckRotation,
      smooth = false
    })
    getObjectFromGUID(GLOBAL.blackSevens).destruct()
    GLOBAL.blackSevens = nil
  end
  if GLOBAL.playerCount and GLOBAL.playerCount == 4 then
    pause(0.2)
    removeBlackSevens(newDeck)
  end
  if FLAG.setupRan and FLAG.firstDealOfGame then
    pause(0.4)
    moveDeckAndDealerChip()
  end
  pause(0.75)

  if not fnRunning then
    FLAG.fnRunning = false
  end
  return 1
end

---Builds the `GLOBAL.sortedSeatedPlayers` table of all seated players
function populatePlayers()
  GLOBAL.sortedSeatedPlayers = {}
  for _, color in ipairs(ALL_PLAYERS) do
    if Player[color].seated then
      table.insert(GLOBAL.sortedSeatedPlayers, color)
    end
  end
end

---Prints the current game settings<br>
---Gets the correct deck for the number of seated players<br>
---Will stop `setupGameCoroutine` if there is less than 3 seated players<br>
---Note: this fn assumes it is being called from within a coroutine that has already set `FLAG.fnRunning`
function printGameSettings()
  if #GLOBAL.sortedSeatedPlayers < 3 then
    broadcastToAll("[DC0000]Sheepshead requires 3 to 6 players.[-]")
    FLAG.stopCoroutine = true
    return
  end

  GLOBAL.playerCount = #GLOBAL.sortedSeatedPlayers
  GLOBAL.dealerColorIdx = getIndex(GLOBAL.gameSetupPlayer, GLOBAL.sortedSeatedPlayers)

  if SETTINGS.dealerSitsOut and GLOBAL.playerCount == 6 then
    stateChangeDealerSitsOut(SETTINGS.dealerSitsOut)
  end

  if GLOBAL.playerCount == 3 then
    updateRules("threeHanded", true)
    broadcastToAll("[21AF21]Picker plays Alone, Leasters enabled by default")
  end

  if SETTINGS.threeHanded and GLOBAL.playerCount ~= 3 then
    updateRules("threeHanded", false)
  end

  prepCards()
  verifyCardCount()

  moveDeckAndDealerChip()
  print("[21AF21]Sheepshead set up for [-]", #GLOBAL.sortedSeatedPlayers, " players!")
end

---Called to add the `GLOBAL.blackSevens` to a given deck<br>
---Function uses global string GLOBAL.blackSevens provided by `removeBlackSevens()` to locate<br>
---`GLOBAL.blackSevens` within `STATIC_OBJECT.hiddenBag`, then moves them to the current deck position
---@param deck object<deck>
function returnDeckToPiquet(deck)
  STATIC_OBJECT.hiddenBag.takeObject({
    guid = GLOBAL.blackSevens,
    position = deck.getPosition(),
    rotation = deck.getRotation(),
    smooth = false
  })
  pause(0.3)
  print("[21AF21]The two black sevens have been added to the deck.[-]")
  GLOBAL.blackSevens = nil
end

---Called to remove the `GLOBAL.blackSevens` from a given deck<br>
---Finds the `GLOBAL.blackSevens` inside the given deck and moves them into `STATIC_OBJECT.hiddenBag`<br>
---Sets `GLOBAL.blackSevens` deck guid inside `STATIC_OBJECT.hiddenBag`<br>
---Must be ran from within a coroutine
---@param deck object<deck>
function removeBlackSevens(deck)
  local deckPos, offsetPos = POS.center, POS.center + Vector(2.75, 1, 0)
  if FLAG.counterVisible then
    deckPos = deckPos + POS.centerBlockOffset
    offsetPos = offsetPos + POS.centerBlockOffset
  end
  deck.setPosition(deckPos)
  deck.setRotation(POS.defaultDeckRotation)
  for _, containedCard in ipairs(deck.getObjects()) do
    for _, cardName in ipairs(BLACK_SEVENS) do
      if containedCard.nickname == cardName then
        deck.takeObject({
          guid = containedCard.guid,
          position = offsetPos,
          smooth = false
        })
      end
    end
  end
  print("[21AF21]The two black sevens have been removed from the deck.[-]")
  pause(0.3)
  local smallDeck = getDeck(SCRIPT_ZONE.table, "small")
  smallDeck.setInvisibleTo(ALL_PLAYERS)
  GLOBAL.blackSevens = smallDeck.guid
  STATIC_OBJECT.hiddenBag.putObject(smallDeck)
  pause(0.25)
end

---Helper function for spawning chips from outside a coroutine
---@param player object<commandTrigger>
function startChipSpawn(player)
  if not adminCheck(player) then
    return
  end
  if not FLAG.setupRan then
    broadcastToColor("[DC0000]Setup game before spawning extra chips.[-]", player.color)
    return
  end
  if FLAG.fnRunning then
    broadcastToColor(
      "[fc8803]Action in progress, chips will be spawned after current action is complete.[-]",
      player.color
    )
  end
  startLuaCoroutine(self, "spawnChips")
end

---Deals 15 chips to all seated players<br>Set `fnRunning` if this function should be ran as a continuation
---of a currently set `FLAG.fnRunning` otherwise will wait for any current `FLAG.fnRunning` to complete and
---starts a new fnRunning instance<br>Requires that `FLAG.setupRan` and is ran from within a coroutine
---@param fnRunning option_boolean
function spawnChips(fnRunning)
  if not fnRunning then
    startFnRunFlag()
  end

  for _, color in ipairs(GLOBAL.sortedSeatedPlayers) do
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
        rotation = { 0, rotationAngle + 180, 0 },
        scale = { 0.6, 0.6, 0.6 },
        sound = false
      })
      customCoin.setCustomObject(COIN_PRAM)
      customCoin.reload()
      pause(0.02)
    end
  end

  if not fnRunning then
    FLAG.fnRunning = false
  end
  return 1
end

---Start of game setup event
---@param player object<eventTrigger>
function setupGameEvent(player)
  if not adminCheck(player) or FLAG.fnRunning then
    return
  end
  if FLAG.setupRan and #GLOBAL.sortedSeatedPlayers < 3 then
    broadcastToAll("[DC0000]Sheepshead requires 3 to 6 players.[-]")
    return
  end
  GLOBAL.gameSetupPlayer = player.color
  FLAG.trickInProgress, FLAG.handInProgress, FLAG.leasterHand = false, false, false
  startLuaCoroutine(self, "setupGameCoroutine")
end

---Start of order of operations for game setup<br>Waits for any current `FLAG.fnRunning` to complete and
---starts a new fnRunning instance
function setupGameCoroutine()
  startFnRunFlag()
  if FLAG.setupRan then
    local gameSetupPlayer = Player[GLOBAL.gameSetupPlayer]
    gameSetupPlayer.broadcast("[b415ff]You are trying to set up a new game for [-]"
      .. #GLOBAL.sortedSeatedPlayers .. " players.")
    pause(1.5)
    gameSetupPlayer.broadcast("[b415ff]Are you sure you want to continue?[-] (y/n)")
    FLAG.lookForPlayerText = true
    pause(6)
    if FLAG.continue then
      FLAG.lookForPlayerText, FLAG.continue = false, nil
      removeItem(SCRIPT_ZONE.table, "Chip")
    else
      FLAG.lookForPlayerText, FLAG.fnRunning, FLAG.continue = false, false, nil
      print("[21AF21]New game was not selected.[-]")
      return 1
    end
  end

  if FLAG.counterVisible then
    toggleCounterVisibility()
  end

  if FLAG.cardsToBeBuried then
    hideSetBuriedButton()
  end

  --start of debug code
  --This is how Number of players is managed in debug mode
  --Happens in place of populatePlayers
  if DEBUG then
    if not GLOBAL.sortedSeatedPlayers then
      GLOBAL.sortedSeatedPlayers = copyTable(ALL_PLAYERS)
      FLAG.fnRunning = false
      return 1
    end
  else
    populatePlayers()
  end
  --end of debug code

  printGameSettings()

  if FLAG.stopCoroutine then
    FLAG.stopCoroutine, FLAG.fnRunning = false, false
    return 1
  end

  spawnChips(true)

  FLAG.fnRunning = false
  FLAG.setupRan, FLAG.firstDealOfGame = true, true
  return 1
end

--[[End of order of operations for game setup]]--
--[[End of functions used by Set Up Game event]]--


--[[Start of functions used by New Hand event]]--

---Called to build `GLOBAL.dealOrder` correctly<br>
---Adds "Blinds" to the `GLOBAL.dealOrder` table in the position directly after the current dealer<br>
---If dealer sits out replaces dealer with blinds
function calculateDealOrder()
  GLOBAL.dealOrder = copyTable(GLOBAL.sortedSeatedPlayers)
  if GLOBAL.playerCount == #GLOBAL.sortedSeatedPlayers then
    local blindVal = GLOBAL.dealerColorIdx + 1
    if blindVal > #GLOBAL.dealOrder + 1 then
      blindVal = 1
    end
    table.insert(GLOBAL.dealOrder, blindVal, BLINDS_STR)
  else
    table.remove(GLOBAL.dealOrder, GLOBAL.dealerColorIdx)
    table.insert(GLOBAL.dealOrder, GLOBAL.dealerColorIdx, BLINDS_STR)
  end
end

---Start of New Hand event
function setupHandEvent()
  if FLAG.fnRunning then
    return
  end
  if not FLAG.setupRan then
    print("[21AF21]Press Set Up Game First.[-]")
    return
  end

  if FLAG.cardsToBeBuried then
    hideSetBuriedButton()
  end

  GLOBAL.pickingPlayer, GLOBAL.leadOutPlayer, GLOBAL.holdCards, GLOBAL.partnerCard = nil, nil, nil, nil
  FLAG.trickInProgress, FLAG.handInProgress, FLAG.leasterHand, FLAG.crackCalled = false, false, false, false

  if SETTINGS.jdPartner then
    GLOBAL.partnerCard = JD_PARTNER_CARD
  end

  if GLOBAL.unknownText then
    getObjectFromGUID(GLOBAL.unknownText).destruct()
    GLOBAL.unknownText = nil
  end

  GLOBAL.currentTrick = {}

  local selectPartnerWindowOpen = UI.getAttribute("selectPartnerWindow", "visibility")
  local playAloneWindowOpen = UI.getAttribute("playAloneWindow", "visibility")

  if selectPartnerWindowOpen ~= "" then
    hideUIElement("selectPartnerWindow")
  end
  if playAloneWindowOpen ~= "" then
    hideUIElement("playAloneWindow")
  end

  startLuaCoroutine(self, "dealCardsCoroutine")
end

---Order of operations for dealing<br>
---Waits for any current `FLAG.fnRunning` to complete and starts a new fnRunning instance
function dealCardsCoroutine()
  startFnRunFlag()
  if FLAG.counterVisible then
    toggleCounterVisibility()
  end

  verifyCardCount()
  if not FLAG.firstDealOfGame then
    GLOBAL.dealerColorIdx = cycleColorIndex(GLOBAL.dealerColorIdx, GLOBAL.sortedSeatedPlayers)
    if len(getLooseCards(SCRIPT_ZONE.table)) > 1 then
      rebuildDeck()
    end
    pause(0.3)

    moveDeckAndDealerChip()
    pause(0.4)
  else
    FLAG.firstDealOfGame = false
  end

  calculateDealOrder()

  flipDeck(SCRIPT_ZONE.table)
  pause(0.35)

  local orderIdx = cycleColorIndex(GLOBAL.dealerColorIdx, GLOBAL.dealOrder)
  local counter = 0

  local deck = getDeck(SCRIPT_ZONE.table)
  local rotationVal = deck.getRotation()
  local dealPositions = #GLOBAL.dealOrder

  flipDeck(SCRIPT_ZONE.table)
  pause(0.15)
  deck.randomize()
  pause(0.35)

  while deck ~= nil do
    dealLogic(
      GLOBAL.dealOrder[((orderIdx - 1) % dealPositions) + 1],
      math.floor(counter / dealPositions) + 1,
      deck,
      rotationVal
    )
    counter = counter + 1; orderIdx = orderIdx + 1
    pause(0.25)
  end

  FLAG.fnRunning = false
  return 1
end

---Contains the logic to deal correctly based on the number of
---players seated and the number of times players have received cards
---@param target string<"Color">
---@param round integer
---@param deck object<deck>
---@param rotationVal vector
function dealLogic(target, round, deck, rotationVal)
  if GLOBAL.playerCount == 3 then
    if target ~= BLINDS_STR and (round == 2 or round == 3) then
      deck.deal(3, target)
    elseif target ~= BLINDS_STR then
      deck.deal(2, target)
    elseif target == BLINDS_STR and round == 2 then
      dealToBlinds(deck, rotationVal)
    end
  elseif GLOBAL.playerCount == 4 then
    if target ~= BLINDS_STR and round == 2 then
      deck.deal(3, target)
    elseif target ~= BLINDS_STR then
      deck.deal(2, target)
    elseif target == BLINDS_STR and round == 1 then
      dealToBlinds(deck, rotationVal)
    end
  elseif GLOBAL.playerCount == 5 then
    if target ~= BLINDS_STR then
      deck.deal(2, target)
    elseif target == BLINDS_STR and round == 1 then
      dealToBlinds(deck, rotationVal)
    end
  elseif GLOBAL.playerCount == 6 then
    if target ~= BLINDS_STR and round == 2 then
      deck.deal(3, target)
    elseif target == BLINDS_STR and round == 1 then
      dealToBlinds(deck, rotationVal)
    elseif target ~= BLINDS_STR then
      deck.deal(2, target)
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
      rotation = { rotationVal.x, rotationVal.y, POS.defaultDeckRotation.z }
    })
    pause(0.15)
  end
end

--[[End of functions used by New Hand event]]--

---Prints a message if player passes or is forced to pick
---@param player object<eventTrigger>
function passEvent(player)
  if not GLOBAL.dealerColorIdx or FLAG.fnRunning or countCards(SCRIPT_ZONE.center) ~= 2 then
    return
  end

  local dealerColor = GLOBAL.sortedSeatedPlayers[GLOBAL.dealerColorIdx]
  if dealerSitsOutActive() and player.color == dealerColor then
    broadcastToColor("[DC0000]You can not pass while sitting out.[-]", player.color)
    return
  end

  if player.color == dealerColor then
    if not DEBUG then
      if CALL_SETTINGS.leaster then
        broadcastToColor("[DC0000]Dealer can not pass. Pick your own or Call a Leaster.[-]", player.color)
      else
        broadcastToColor("[DC0000]Dealer can not pass. Pick your own![-]", player.color)
      end
    else
      print("[DC0000]Dealer can not pass. " .. dealerColor .. " pick your own![-]")
    end
  else
    broadcastToAll(player.steam_name .. " passed")
    if CALL_SETTINGS.leaster then
      local rightOfDealerColor = GLOBAL.sortedSeatedPlayers[
        cycleColorIndex(GLOBAL.dealerColorIdx, GLOBAL.sortedSeatedPlayers, true)
      ]
      if player.color == rightOfDealerColor then
        broadcastToColor("[21AF21]You have the option to call a leaster.[-]", dealerColor)
        toggleWindowVisibility(dealerColor, "callsWindow", true)
      end
    end
  end
end

---Moves the blinds into the pickers hand, sets player to `GLOBAL.pickingPlayer`
---Sets `FLAG.cardsToBeBuried` to trigger buryCards logic
---@param player object<eventTrigger>
function pickBlindsEvent(player)
  if FLAG.fnRunning or countCards(SCRIPT_ZONE.center) ~= 2 then
    return
  end
  if dealerSitsOutActive() and player.color == GLOBAL.sortedSeatedPlayers[GLOBAL.dealerColorIdx] then
    broadcastToColor("[DC0000]You can not pick while sitting out.[-]", player.color)
    return
  end
  GLOBAL.pickingPlayer = player.color
  startLuaCoroutine(self, "pickBlindsCoroutine")
end

---Waits for any current `FLAG.fnRunning` to complete and starts a new fnRunning instance
function pickBlindsCoroutine()
  startFnRunFlag()
  local pickingPlayer = Player[GLOBAL.pickingPlayer]
  broadcastToAll("[21AF21]" .. pickingPlayer.steam_name .. " picks![-]")
  local playerPosition = pickingPlayer.getHandTransform().position
  local playerRotation = pickingPlayer.getHandTransform().rotation
  local blinds = getLooseCards(SCRIPT_ZONE.center, true)
  if blinds then
    blinds.takeObject({
      position = playerPosition,
      rotation = playerRotation
    })
    pause(0.2)
  end
  for _, card in ipairs(getLooseCards(SCRIPT_ZONE.center)) do
    card.setPositionSmooth(playerPosition)
    card.setRotationSmooth(playerRotation)
  end
  pause(0.35)
  for _, card in ipairs(getLooseCards(HAND_ZONE[GLOBAL.pickingPlayer])) do
    if card.is_face_down then
      card.flip()
    end
  end
  FLAG.cardsToBeBuried = true
  showSetBuriedButton()

  if SETTINGS.jdPartner then
    if pickingPlayer.color == GLOBAL.sortedSeatedPlayers[GLOBAL.dealerColorIdx] then
      pause(1.5)
      if doesPlayerPossessCard(pickingPlayer.color, JD_PARTNER_CARD) then
        toggleWindowVisibility(pickingPlayer.color, "playAloneWindow", true)
      end
    end
  elseif SETTINGS.jdPartner == false then --Call an Ace
    pause(0.5)
    buildPartnerChoices(pickingPlayer.color)
    pause(0.25)
    if GLOBAL.holdCards then
      toggleWindowVisibility(pickingPlayer.color, "selectPartnerWindow")
    else --Unknown event
      unknownPartnerChoices(pickingPlayer.color)
      pause(0.25)
      local unknownTextPos = SPAWN_POS.leasterCards:copy():rotateOver('y', pickerRotation)
      local unknownText = spawnObject({
        type = "3DText",
        position = unknownTextPos,
        rotation = { 90, pickerRotation - 60, 0 }
      })
      unknownText.interactable = false
      unknownText.TextTool.setFontSize(10)
      unknownText.TextTool.setFontColor("Green")
      unknownText.setValue("Place Unknown Card\nFacedown Here")
      GLOBAL.unknownText = unknownText.guid
      toggleWindowVisibility(pickingPlayer.color, "selectPartnerWindow")
    end
  end
  FLAG.fnRunning = false
  return 1
end

---Does not check either valid condition `FLAG.cardsToBeBuried` and `GLOBAL.pickingPlayer`<br>
---also does not set `FLAG.cardsToBeBuried`
function showSetBuriedButton()
  local pickerRotation = ROTATION.color[GLOBAL.pickingPlayer]
  local setBuriedButtonPos = SPAWN_POS.setBuriedButton:copy():rotateOver('y', pickerRotation)
  STATIC_OBJECT.setBuriedButton.setPosition(setBuriedButtonPos)
  STATIC_OBJECT.setBuriedButton.setRotation({ 0, pickerRotation, 0 })
  STATIC_OBJECT.setBuriedButton.UI.setAttribute("setBuriedButton", "visibility", GLOBAL.pickingPlayer)
  STATIC_OBJECT.setBuriedButton.UI.setAttribute("setBuriedButton", "active", "true")
end

---Also sets `FLAG.cardsToBeBuried` to `false` and ensures no cards are hidden
function hideSetBuriedButton()
  STATIC_OBJECT.setBuriedButton.UI.setAttribute("setBuriedButton", "visibility", "")
  STATIC_OBJECT.setBuriedButton.UI.setAttribute("setBuriedButton", "active", "false")
  FLAG.cardsToBeBuried = false
  Wait.time(
    function()
      for _, card in ipairs(getLooseCards(SCRIPT_ZONE.table)) do
        card.setHiddenFrom({})
      end
    end,
    1.6
  )
end

---Toggles the spawning and deletion of counters.<br> On counter spawn will spawn a counter in front of
---`GLOBAL.pickingPlayer` and the player across from the pickingPlayer. Flips over pickers tricks to see
---score of hand<br>Must be ran from within a coroutine.
function toggleCounterVisibility()
  if not FLAG.counterVisible then
    local pickerColor = GLOBAL.pickingPlayer
    local pickerRotation = ROTATION.color[pickerColor]
    local blockRotation = ROTATION.block[pickerColor]
    local tCounter, pCounter
    local tCounterPos = SPAWN_POS.tableCounter:copy():rotateOver('y', pickerRotation)
    local pCounterPos = SPAWN_POS.pickerCounter:copy():rotateOver('y', pickerRotation)
    local blockPos = SPAWN_POS.tableBlock:copy():rotateOver('y', blockRotation)
    local block = STATIC_OBJECT.hiddenBag.takeObject({
      position = blockPos,
      rotation = { 0, blockRotation, 0 },
      smooth = false,
      guid = GUID.TABLE_BLOCK
    })
    block.setLock(true)
    block.setInvisibleTo(ALL_PLAYERS)
    pause(0.05)
    tCounter = spawnObject({
      type = "Counter",
      position = tCounterPos,
      rotation = { 295, pickerRotation - 180, 0 },
    })
    pCounter = spawnObject({
      type = "Counter",
      position = pCounterPos,
      rotation = { 295, pickerRotation, 0 },
    })
    FLAG.counterVisible = true
    local pickerZone = TRICK_ZONE[pickerColor]
    local pickerCards = getLooseCards(pickerZone)
    if pickerCards then
      group(pickerCards)
      pause(0.6)
      local pickerTricks = getLooseCards(pickerZone, true)
      pickerTricks.setPositionSmooth({ pickerZone.getPosition().x, 1.25, pickerZone.getPosition().z })
      pickerTricks.setRotationSmooth({ 0, pickerTricks.getRotation().y, 0 })
    end
    --Card counter Loop starts here with `startTrickCount()`
    pause(0.2)
    startTrickCount(tCounter.guid, pCounter.guid)
    if not FLAG.leasterHand then
      pause(1.35)
      displayWonOrLossText()
    end
  else
    removeItem(SCRIPT_ZONE.table, "Counter", true)
    STATIC_OBJECT.hiddenBag.putObject(getObjectFromGUID(GUID.TABLE_BLOCK))
    FLAG.counterVisible = false
    trickCountStop()
  end
end

---Makes sure buried cards are face down and ensures blinds and `GLOBAL.pickingPlayers`<br>
---hand objects are not hidden. Calculates global `GLOBAL.leadOutPlayer`, hides Set Buried button
---@param player object<eventTrigger>
function setBuriedEvent(player)
  if player.color ~= GLOBAL.pickingPlayer then
    return
  end
  if countCards(TRICK_ZONE[GLOBAL.pickingPlayer]) ~= 2 then
    broadcastToColor("[DC0000]You must bury 2 cards[-]", player.color)
    return
  end
  if SETTINGS.jdPartner == false then
    local partnerWindowOpen = UI.getAttribute("selectPartnerWindow", "visibility")
    if partnerWindowOpen ~= "" then
      broadcastToColor("[DC0000]Select Partner before burying cards[-]", player.color)
      return
    end
  end
  local buriedCards = getLooseCards(TRICK_ZONE[GLOBAL.pickingPlayer])
  if GLOBAL.holdCards then --callAnAce active, make sure holdCard(s) not in buried cards
    local holdCardsLen = #GLOBAL.holdCards
    if holdCardsLen < 3 then
      local count = 0
      for _, card in ipairs(buriedCards) do
        if tableContains(GLOBAL.holdCards, card.getName()) then
          count = count + 1
        end
      end
      if holdCardsLen == 2 and count == 2 then
        broadcastToColor("[DC0000]You can not bury both of your hold cards[-]", player.color)
        return
      end
      if holdCardsLen == 1 and count == 1 then
        broadcastToColor("[DC0000]You can not bury your hold card[-]", player.color)
        return
      end
    end
  end
  if GLOBAL.unknownText then
    getObjectFromGUID(GLOBAL.unknownText).destruct()
    GLOBAL.unknownText = nil
  end
  for _, card in ipairs(buriedCards) do
    if not card.is_face_down then
      card.flip()
    end
  end
  Wait.time(function() group(buriedCards) end, 0.8)
  setLeadOutPlayer()
  hideSetBuriedButton()
end

function setLeadOutPlayer()
  local leadOutPlayer = Player[GLOBAL.sortedSeatedPlayers[
    cycleColorIndex(GLOBAL.dealerColorIdx, GLOBAL.sortedSeatedPlayers)
  ]]
  GLOBAL.leadOutPlayer = leadOutPlayer.color
  if not DEBUG then
    broadcastToAll("[21AF21]" .. leadOutPlayer.steam_name .. " leads out.[-]")
  else
    print("[21AF21]" .. leadOutPlayer.color .. " leads out.[-]")
  end
end

---Runs when an object tries to enter a container<br>
---Doesn't allow card grouping during `FLAG.trickInProgress` or `FLAG.cardsToBeBuried`<br>
---Return: `true` allows object to enter | `false` does not allow object to enter
---@param container object<container>
---@param object object
---@return boolean
function tryObjectEnterContainer(container, object)
  if object.type ~= "Card" then
    return true
  end
  if not FLAG.allowGrouping then
    return false
  end
  if FLAG.cardsToBeBuried then
    if isInZone(object, TRICK_ZONE[GLOBAL.pickingPlayer]) then
      return false
    end
  end
  if FLAG.trickInProgress then
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
    object.setPosition(POS.objectRespawn)
  end
  --Makes sure other players can not see what cards the picker is burying
  if FLAG.cardsToBeBuried then
    if zone == TRICK_ZONE[GLOBAL.pickingPlayer] and object.type == "Card" then
      object.setHiddenFrom(removeFromClonedList(GLOBAL.pickingPlayer, GLOBAL.sortedSeatedPlayers))
    end
  end
end

---Runs when an object leaves a zone
---@param zone object<zone>
---@param object object
function onObjectLeaveZone(zone, object)
  --Starts trick
  if not FLAG.fnRunning
    and not FLAG.selectingPartner
    and not FLAG.cardsToBeBuried
    and GLOBAL.leadOutPlayer
    and zone == HAND_ZONE[GLOBAL.leadOutPlayer] then
      FLAG.trickInProgress, FLAG.handInProgress = true, true
  end
end

---Runs when a player picks up an object<br>
---If someone plays the wrong card, Ex. Player didn't see they have to follow suit
---and needs to remove a card from the `GLOBAL.currentTrick`
---@param playerColor string
---@param object object
function onObjectPickUp(playerColor, object)
  if FLAG.trickInProgress
    and object.type == "Card"
    and isInZone(object, SCRIPT_ZONE.center)
    and len(GLOBAL.currentTrick) > 1 then
      local objectName = object.getName()
      for i = 2, #GLOBAL.currentTrick do
        if objectName == GLOBAL.currentTrick[i].cardName and playerColor == GLOBAL.currentTrick[i].playedByColor then
          reCalculateCurrentTrick(GLOBAL.currentTrick[i].index)
          break
        end
      end
  end
end

---Runs when a player drops an object<br>Builds the table `GLOBAL.currentTrick`
---to keep track of cardNames and player color who laid them in the `SCRIPT_ZONE.center`
---@param playerColor string
---@param object object
function onObjectDrop(playerColor, object)
  --Guard clauses don't work in onEvents()
  if FLAG.trickInProgress and object.type == "Card" then
    --Wait function allows script to continue in the case of a player throwing a card into `SCRIPT_ZONE.center`
    Wait.time(
      function()
        if isInZone(object, SCRIPT_ZONE.center) then
          addCardDataToCurrentTrick(playerColor, object)
          if #GLOBAL.currentTrick == GLOBAL.playerCount + 1 then
            calculateTrickWinner()
          end
        end
      end,
      0.5
    )
  end
end

---@param indexToRemove integer
---@param indexToUpdate option_integer
function removeCardFromTrick(indexToRemove, indexToUpdate)
  local highCardName
  if indexToUpdate then
    highCardName = GLOBAL.currentTrick[indexToUpdate].cardName
  end

  if DEBUG then print("[21AF21]" .. GLOBAL.currentTrick[indexToRemove].cardName .. " removed from trick[-]") end

  table.remove(GLOBAL.currentTrick, indexToRemove)
  for i = 2, #GLOBAL.currentTrick do
    if indexToUpdate and highCardName == GLOBAL.currentTrick[i].cardName then
      GLOBAL.currentTrick[1].highStrengthIndex = i
    end
    GLOBAL.currentTrick[i].index = i
  end
end

---@param indexToRemove integer
function reCalculateCurrentTrick(indexToRemove)
  --Remove card from trick and update location of current high card
  if indexToRemove ~= GLOBAL.currentTrick[1].highStrengthIndex then
    removeCardFromTrick(indexToRemove, GLOBAL.currentTrick[1].highStrengthIndex)
    return
  end
  --Remove card from trick and find the high card in remaining cards
  removeCardFromTrick(indexToRemove)
  local currentTrickLen = #GLOBAL.currentTrick
  if currentTrickLen > 1 then
    GLOBAL.currentTrick[1].currentHighStrength = 1
    setLeadOutCardProperties(GLOBAL.currentTrick[2].cardName, isTrump(GLOBAL.currentTrick[2].cardName))
    if currentTrickLen > 2 then
      for i = 3, currentTrickLen do
        calculateCardData(i, isTrump(GLOBAL.currentTrick[i].cardName))
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
  if len(GLOBAL.currentTrick) < 2 then
    --Creates GLOBAL.currentTrick properties stored at index 1
    initializeCurrentTrick(objectName, objectIsTrump)
  end
  local cardData = {
    playedByColor = playerColor,
    cardName = objectName,
    index = #GLOBAL.currentTrick + 1,
    guid = object.guid
  }
  table.insert(GLOBAL.currentTrick, cardData)
  if DEBUG then
    if #GLOBAL.currentTrick == 2 then
      print(
        "[21AF21]Card led out is: " .. GLOBAL.currentTrick[GLOBAL.currentTrick[1].highStrengthIndex].cardName .. "[-]"
      )
    else
      print("[21AF21]" .. GLOBAL.currentTrick[#GLOBAL.currentTrick].cardName .. " added to trick[-]")
    end
  end
  calculateCardData(#GLOBAL.currentTrick, objectIsTrump, object.is_face_down)
end

---Function will return early if card does not need to be compared to currentHighStrength
---@param cardIndex integer
---@param objectIsTrump boolean
---@param isFaceDown boolean
function calculateCardData(cardIndex, objectIsTrump, isFaceDown)
  if not GLOBAL.currentTrick[1].trump then --No trump in GLOBAL.currentTrick
    if not objectIsTrump then       --Not trump and not suit led out
      if getLastWord(GLOBAL.currentTrick[cardIndex].cardName) ~= GLOBAL.currentTrick[1].ledSuit then
        return
      end
    else --No trump in GLOBAL.currentTrick but objectIsTrump make sure trumpStrength is greater
      GLOBAL.currentTrick[1].currentHighStrength = 0
    end
  else --Trump is in the GLOBAL.currentTrick
    if not objectIsTrump then
      return
    end
  end
  local strengthVal
  if isFaceDown then
    strengthVal = 0
  else
    strengthVal = quickSearch(GLOBAL.currentTrick[cardIndex].cardName, objectIsTrump)
  end
  if strengthVal > GLOBAL.currentTrick[1].currentHighStrength then
    updateCurrentTrickProperties(objectIsTrump, strengthVal, cardIndex)
  end
end

---@param objectName string
---@param isTrump boolean
function initializeCurrentTrick(objectName, isTrump)
  GLOBAL.currentTrick = {}
  setLeadOutCardProperties(objectName, isTrump)
end

---Trick properties stored in GLOBAL.currentTrick[1]
---@param objectName string
---@param isTrump boolean
function setLeadOutCardProperties(objectName, isTrump)
  local trickProperties = {
    ledSuit = getLastWord(objectName),
    trump = isTrump,
    currentHighStrength = quickSearch(objectName, isTrump),
    highStrengthIndex = 2
  }
  if isEmpty(GLOBAL.currentTrick) then
    table.insert(GLOBAL.currentTrick, trickProperties)
    return
  end
  GLOBAL.currentTrick[1].ledSuit = trickProperties.ledSuit
  GLOBAL.currentTrick[1].trump = isTrump
  GLOBAL.currentTrick[1].currentHighStrength = trickProperties.currentHighStrength
  GLOBAL.currentTrick[1].highStrengthIndex = 2
end

---Trick properties stored in GLOBAL.currentTrick[1]
---@param isTrump boolean
---@param strengthVal integer
---@param index integer
function updateCurrentTrickProperties(isTrump, strengthVal, index)
  if isTrump then
    GLOBAL.currentTrick[1].trump = true
  end
  GLOBAL.currentTrick[1].currentHighStrength = strengthVal
  GLOBAL.currentTrick[1].highStrengthIndex = index

  if DEBUG then print("[21AF21]Current high Card is: " ..
    GLOBAL.currentTrick[GLOBAL.currentTrick[1].highStrengthIndex].cardName .. "[-]")
  end
end

---@param objectName string
---@return boolean
function isTrump(objectName)
  for _, word in ipairs(TRUMP_IDENTIFIER) do
    if string.find(objectName, word) then
      return true
    end
  end
  return false
end

---Only search for strengths higher than currentHighStrength
---@param objectName string
---@param isTrump boolean
---@return integer
function quickSearch(objectName, isTrump)
  local strengthList, startIndex, isStronger
  if isTrump then
    strengthList = TRUMP_STRENGTHS
    isStronger = function(cardName)
      return objectName == cardName
    end
  else
    strengthList = FAIL_STRENGTHS
    isStronger = function(cardName)
      return string.find(objectName, cardName)
    end
  end

  if not GLOBAL.currentTrick[1] or GLOBAL.currentTrick[1].currentHighStrength == 0 then
    startIndex = 1
  else
    startIndex = GLOBAL.currentTrick[1].currentHighStrength
  end

  for i = startIndex, #strengthList do
    if isStronger(strengthList[i]) then
      return i
    end
  end
  return 0
end

---Calculates player to give trick to. Sets global GLOBAL.leadOutPlayer
function calculateTrickWinner()
  FLAG.trickInProgress, FLAG.handInProgress, FLAG.crackCalled, FLAG.allowGrouping = false, false, false, false
  local trickWinner = Player[GLOBAL.currentTrick[GLOBAL.currentTrick[1].highStrengthIndex].playedByColor]
  GLOBAL.leadOutPlayer = trickWinner.color
  broadcastToAll(
    "[21AF21]" .. trickWinner.steam_name .. " takes the trick with " ..
    GLOBAL.currentTrick[GLOBAL.currentTrick[1].highStrengthIndex].cardName .. "[-]"
  )
  startLuaCoroutine(self, "giveTrickToWinnerCoroutine")
end

---Resets trick FLAG and data then moves Trick to TRICK_ZONE of trickWinner. Shows card counters if hand is
---over<br>Waits for any current `FLAG.fnRunning` to complete and starts a new fnRunning instance
function giveTrickToWinnerCoroutine()
  startFnRunFlag()
  local lastTrick = countCards(HAND_ZONE[GLOBAL.leadOutPlayer]) == 0
  pause(1.75)
  FLAG.allowGrouping = true
  local trick = {}
  for i = 2, #GLOBAL.currentTrick do
    table.insert(trick, getObjectFromGUID(GLOBAL.currentTrick[i].guid))
  end
  GLOBAL.currentTrick = {}
  local playerTrickZone = TRICK_ZONE[GLOBAL.leadOutPlayer]
  trick = group(trick)[1]
  pause(0.6)
  trick.flip()
  pause(0.9)
  local oldTricks = getDeck(playerTrickZone, "big")
  if oldTricks then
    local oldTricksPos = oldTricks.getPosition()
    local oldTricksRot = oldTricks.getRotation()
    trick.setPositionSmooth({ oldTricksPos.x, oldTricksPos.y + 0.5, oldTricksPos.z })
    trick.setRotationSmooth({ oldTricksRot.x, oldTricksRot.y, POS.defaultDeckRotation.z })
  else
    local zoneRotation = playerTrickZone.getRotation()
    local zonePos = playerTrickZone.getPosition()
    trick.setPositionSmooth({ zonePos.x, zonePos.y - 2.7, zonePos.z })
    trick.setRotationSmooth({ zoneRotation.x, zoneRotation.y + 180, POS.defaultDeckRotation.z })
  end
  pause(0.5)
  group(getLooseCards(playerTrickZone))
  if lastTrick then
    local delay = 0
    if FLAG.leasterHand then
      local lastLeasterTrick = getObjectFromGUID(GLOBAL.lastLeasterTrick)
      delay = delay + 1.5
      lastLeasterTrick.interactable = true
      pause(0.5)
      local playerTrickPos
      local playerTrickRot
      local playerTrickDeck = getDeck(playerTrickZone)
      if playerTrickDeck then
        playerTrickPos = playerTrickDeck.getPosition()
        playerTrickRot = playerTrickDeck.getRotation()
      else
        playerTrickPos = playerTrickZone.getPosition()
        playerTrickRot = playerTrickZone.getRotation()
      end
      lastLeasterTrick.setPositionSmooth(playerTrickPos)
      lastLeasterTrick.setRotationSmooth(playerTrickRot)
      GLOBAL.lastLeasterTrick = nil
    end
    pause(delay)
    GLOBAL.leadOutPlayer, GLOBAL.partnerCard = nil, nil
    toggleCounterVisibility()
  end
  FLAG.fnRunning = false
  return 1
end

--[[New functions to adapt Blackjack Card Counter]]--

---Returns the color of the `handPosition` located across the table from given color<br>
---Color must be directly across for the counter because `TABLE_BLOCK` is an invisible triangle
---@param player string<"Color">
---@return string<"Color">|nil
function findColorAcrossTable(player)
  for i, colors in ipairs(ALL_PLAYERS) do
    if colors == player then
      local acrossVal
      if i > 3 then
        acrossVal = i - 3
      else
        acrossVal = i + 3
      end
      return ALL_PLAYERS[acrossVal]
    end
  end
  return nil
end

---Creates a global table GLOBAL.counterGUIDs and COUNTER_OBJ_SETS.<br> Table contains each zoneObject
---and its associated counterObject, then starts the `countTricks` loop<br>
---if new GUIDs are not provided will start the counter loop using guids stored in GLOBAL.counterGUIDs
---@param tCounterGUID string
---@param pCounterGUID string
function startTrickCount(tCounterGUID, pCounterGUID)
  if tCounterGUID and pCounterGUID then
    GLOBAL.counterGUIDs = {
      [TRICK_ZONE[GLOBAL.pickingPlayer].guid] = pCounterGUID,
      [TRICK_ZONE[findColorAcrossTable(GLOBAL.pickingPlayer)].guid] = tCounterGUID
    }
  end

  COUNTER_OBJ_SETS = {}
  for zoneGUID, counterGUID in pairs(GLOBAL.counterGUIDs) do
    table.insert(COUNTER_OBJ_SETS, {z = getObjectFromGUID(zoneGUID), c = getObjectFromGUID(counterGUID)})
  end
  startCounterLoop()
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
  for i, set in ipairs(COUNTER_OBJ_SETS) do
    values[i] = {}
    local objectsInZone = set.z.getObjects()
    for _, object in ipairs(objectsInZone) do
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
  for _, containedCard in ipairs(deck.getObjects()) do
    for name, val in pairs(cardNameTable) do
      if string.find(containedCard.nickname, name) then
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
  for i, set in ipairs(COUNTER_OBJ_SETS) do
    set.c.setValue(totals[i])
    local total = totals[i]
    if i == 1 and (total < 61 and total > 30) then
      set.c.setColorTint({ 1, 250 / 255, 160 / 255 })
    elseif i == 2 and (total < 60 and total > 29) then
      set.c.setColorTint({ 1, 250 / 255, 160 / 255 })
    elseif i == 2 and total == 60 then
      set.c.setColorTint({ 0, 1, 0 })
    elseif total > 60 then
      set.c.setColorTint({ 0, 1, 0 })
    else
      set.c.setColorTint({ 0, 0, 0 })
    end
  end
  startCounterLoop()
end

---Internal use only, use `startTrickCount` to properly init counter variables
function startCounterLoop()
  TRICK_COUNTER_TIMER = Wait.time(countTricks, 1)
end

---Stops the trickCount Loop
function trickCountStop()
  if TRICK_COUNTER_TIMER then
    Wait.stop(TRICK_COUNTER_TIMER); TRICK_COUNTER_TIMER = nil
  end
end

---If no params function runs a setup to create params and feeds them back into itself<br>
---runs while `TRICK_COUNTER_TIMER` loop is running
---@param score integer
---@param cardCount integer
---@param numCardInDeck integer
function displayWonOrLossText(score, cardCount, numCardInDeck)
  if not SCORE_TEXT_OBJ then
    local pickerRotation = ROTATION.color[GLOBAL.pickingPlayer] --Shares the same positionData as setBuriedButton
    local textPosition = SPAWN_POS.setBuriedButton:copy():rotateOver('y', pickerRotation)
    SCORE_TEXT_OBJ = spawnObject({
      type = "3DText",
      position = textPosition,
      rotation = { 90, pickerRotation, 0 }
    })
    GLOBAL.chipScoreText = SCORE_TEXT_OBJ.guid
    SCORE_TEXT_OBJ.interactable = false
    SCORE_TEXT_OBJ.setValue("")
    if GLOBAL.playerCount == 4 then
      numCardInDeck = 30
    else
      numCardInDeck = 32
    end
  end

  if TRICK_COUNTER_TIMER then
    local pickerScore = COUNTER_OBJ_SETS[1].c.getValue()
    local pickerTrickCardCount = countCards(COUNTER_OBJ_SETS[1].z)
    local cardStateChange = false
    if cardCount and cardCount ~= pickerTrickCardCount then
      if cardCount == numCardInDeck or (cardCount ~= numCardInDeck and pickerScore == 120) or
      (cardCount > 2 and pickerTrickCardCount < 3) or (cardCount < 3 and pickerTrickCardCount > 2) then
        cardStateChange = true
      end
    end
    if not score or score ~= pickerScore or cardStateChange then
      local text
      if pickerScore == 120 and pickerTrickCardCount == numCardInDeck then
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
      if text ~= SCORE_TEXT_OBJ.getValue() then
        SCORE_TEXT_OBJ.setValue(text)
      end
    end
    if CHIP_SCORE_TEXT_TIMER then
      Wait.stop(CHIP_SCORE_TEXT_TIMER); CHIP_SCORE_TEXT_TIMER = nil
    end
    CHIP_SCORE_TEXT_TIMER = Wait.frames(
      function() displayWonOrLossText(pickerScore, pickerTrickCardCount, numCardInDeck) end,
      15
    )
  else
    SCORE_TEXT_OBJ.destruct(); SCORE_TEXT_OBJ = nil; GLOBAL.chipScoreText = nil
    Wait.stop(CHIP_SCORE_TEXT_TIMER); CHIP_SCORE_TEXT_TIMER = nil
  end
end

--[[END OF CARD SCORING]]--

--[[Start of functions used by settings window]]--

---Updates position of buttons for all enabled calls and<br>
---updates height of panel to fit all buttons
function buildCallPanel()
  local numOfCallsEnabled = 0
  local currentOffsetY = -5
  local buttonOffsetY = -53
  for key, value in pairs(CALL_SETTINGS) do
    local attributeID = key .. "Button"
    if value then
      numOfCallsEnabled = numOfCallsEnabled + 1
      currentOffsetY = currentOffsetY + buttonOffsetY
      local currentOffsetXY = "00 " .. currentOffsetY
      UI.setAttribute(attributeID, "active", "true")
      UI.setAttribute(attributeID, "offsetXY", currentOffsetXY)
    else
      UI.setAttribute(attributeID, "active", "false")
    end
  end
  local initialFrameSizeY = 58
  currentOffsetY = initialFrameSizeY + (numOfCallsEnabled * math.abs(buttonOffsetY))
  UI.setAttribute("callsWindow", "height", currentOffsetY)
  UI.setAttribute("callsWindowBackground", "height", currentOffsetY)
end

---@param rule string<"ruleName">
---@param bool boolean
function updateRules(rule, bool)
  SETTINGS[rule] = bool
  if RULE_TABLE[rule].execute then
    RULE_TABLE[rule].execute(bool)
  end
  if RULE_TABLE[rule][bool] then
    for desc, ruleIdx in pairs(RULE_TABLE[rule][bool]) do
      CURRENT_RULES[ruleIdx] = desc
    end
    displayRules()
  end
end

---@param call string<"callName">
---@param bool boolean
function updateCalls(call, bool)
  CALL_SETTINGS[call] = bool
  if CALL_TABLE[call] then
    CALL_TABLE[call].execute(bool, call)
  end
  buildCallPanel()
end

---Abstracted guard clause for determining if settings window toggle is not valid
---@param player object<eventTrigger>|nil
---@param id string
---@param state boolean
---@return boolean
function toggleNotValid(player, id, state)
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
    if FLAG.fnRunning then
      if player and player.color then
        broadcastToColor("[DC0000]Please wait and try again[-]", player.color)
      else
        print("[DC0000]Please wait and try again[-]")
      end
      return true
    end
  end
  if id == "jdPartner" and SETTINGS.jdPartner == nil then
    return true
  end
  return false
end

---Toggle setting via formatted id
---@param player object<eventTrigger>|nil
---@param val string<"number">|nil
---@param id string<"turnOnSettingName"|"turnOffSettingName">
function toggleSetting(player, val, id)
  local idName, state
  if string.find(id, "turnOn") then
    idName = string.gsub(id, "turnOn", "")
    state = true
  elseif string.find(id, "turnOff") then
    idName = string.gsub(id, "turnOff", "")
    state = false
  else
    return
  end
  if toggleNotValid(player, idName, state) then
    return
  end
  idName = lowerFirstChar(idName)
  for key, _ in pairs(SETTINGS) do
    if key == idName then
      updateRules(idName, state)
    end
  end
  for key, _ in pairs(CALL_SETTINGS) do
    if key == idName then
      updateCalls(idName, state)
    end
  end
  toggleUISettingsButtonState(idName, state)
end

---Toggles the displayed state of a UI button
---@param setting string<"settingName">
---@param state boolean
function toggleUISettingsButtonState(setting, state)
  local id = upperFirstChar(setting)
  local buttonOnID = "settingsButton" .. id .. "On"
  local buttonOffID = "settingsButton" .. id .. "Off"
  UI.setAttribute(buttonOnID, "active", state)
  UI.setAttribute(buttonOffID, "active", not state)
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
  if not GLOBAL.sortedSeatedPlayers then
    return
  end
  if bool then
    if #GLOBAL.sortedSeatedPlayers == 6 then
      GLOBAL.playerCount = 5
      broadcastToAll("[21AF21]Dealer will sit out every hand.[-]")
    end
  else
    if #GLOBAL.sortedSeatedPlayers == 6 then
      GLOBAL.playerCount = 6
      broadcastToAll("[21AF21]Dealer will no longer sit out.[-]")
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
    local callCount = 0
    for _, callEnabled in pairs(CALL_SETTINGS) do
      if callEnabled then
        callCount = callCount + 1
        if callCount > 1 then
          break
        end
      end
    end
    if callCount == 1 then
      Wait.time(function() toggleSetting(player, val, "turnOffCalls") end, 3)
    end
    UI.setAttribute(jdPartnerID, "tooltip", "")
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

---Hides a UI window by ID from all players<br>Use `toggleWindowVisibility` to make UI elements visible to
---specific players
---@param window string<"windowID">
function hideUIElement(window)
  UI.setAttribute(window, "visibility", "")
  UI.hide(window)
end

---@param player string<"Color">
---@param window string<"windowID">
---@param force option_boolean
function toggleWindowVisibility(player, window, force)
  local visibility = UI.getAttribute(window, "visibility")
  if string.find(visibility, player) then
    if force then
      return
    end
    if visibility == player then
      hideUIElement(window)
    else
      visibility = removeColorFromPipeList(player, visibility)
      UI.setAttribute(window, "visibility", visibility)
    end
  else
    if force == false then
      return
    end
    visibility = addColorToPipeList(player, visibility)
    UI.setAttribute(window, "visibility", visibility)
    UI.show(window)
  end
end

--[[Start of functions and buttons for calls window]]--

function showCallsEvent(player)
  toggleWindowVisibility(player.color, "callsWindow")
end

---@param player object<eventTrigger>
function callPartnerEvent(player)
  if not GLOBAL.pickingPlayer then
    return
  end
  Wait.time( --0.13s delay allows button click sound to be played
    function() --Show call partner window for selected partner mode
      if GLOBAL.leadOutPlayer then
        broadcastToColor("[DC0000]You can not do this now[-]", player.color)
        return
      end
      if GLOBAL.partnerCard then
        broadcastToAll("[21AF21]" .. player.steam_name .. " calls " .. GLOBAL.partnerCard .. " as their partner[-]")
      elseif SETTINGS.jdPartner then
        local dealerColor = GLOBAL.sortedSeatedPlayers[GLOBAL.dealerColorIdx]
        if player.color == dealerColor and player.color == GLOBAL.pickingPlayer then
          if doesPlayerPossessCard(player.color, JD_PARTNER_CARD) then
            toggleWindowVisibility(player.color, "playAloneWindow", true)
          else
            broadcastToColor("[DC0000]Jack of Diamonds will be your partner[-]", player.color)
          end
        else
          broadcastToColor("[DC0000]You can only call up if you are forced to pick and have the Jack[-]", player.color)
        end
      elseif SETTINGS.jdPartner == false then --Call an Ace
        if player.color == GLOBAL.pickingPlayer then
          toggleWindowVisibility(player.color, "selectPartnerWindow", true)
        else
          broadcastToColor("[DC0000]Only the picker can call their partner[-]", player.color)
        end
      end
      toggleWindowVisibility(player.color, "callsWindow")
    end,
    0.13
  )
end

---@param player object<eventTrigger>
---@param val nil
---@param id string<"eventID">
function playerCallsEvent(player, val, id)
  local id = string.gsub(id, "Button", "")
  id = upperFirstChar(id)
  Wait.time(function() toggleWindowVisibility(player.color, "callsWindow") end, 0.13)

  if FLAG.handInProgress then
    broadcastToColor("[DC0000]You can only make calls before the hand starts[-]", player.color)
    return
  end

  if id == "Blitz" then
    broadcastToAll("[21AF21]" .. player.steam_name .. " calls " .. id .. "![-]")
    return
  end

  if id == "Sheepshead" then
    if player.color == GLOBAL.pickingPlayer then
      broadcastToAll("[21AF21]" .. player.steam_name .. " calls " .. id .. "![-]")
    else
      broadcastToColor("[DC0000]You can only call Sheepshead if you picked[-]", player.color)
    end
    return
  end

  if id == "Leaster" then
    if player.color == GLOBAL.sortedSeatedPlayers[GLOBAL.dealerColorIdx] then
      if countCards(SCRIPT_ZONE.center) == 2 then
        broadcastToAll("[21AF21]" .. player.steam_name .. " calls for a " .. id .. "[-]")
        GLOBAL.pickingPlayer = player.color
        startLuaCoroutine(self, "startLeasterHandCoroutine")
      else
        broadcastToColor("[DC0000]You can only call 'Leaster' before you pick the blinds[-]", player.color)
      end
    else
      broadcastToColor("[DC0000]You can only call 'Leaster' if you are forced to pick[-]", player.color)
    end
    return
  end

  if not GLOBAL.pickingPlayer then
    id = insertSpaces(id)
    broadcastToColor("[DC0000]You can only call '" .. id .. "' after someone picks the blinds[-]", player.color)
    return
  end

  if id == "Crack" then
    local i = getIndex(GLOBAL.pickingPlayer, GLOBAL.sortedSeatedPlayers)
    local hadChance, noChance = copyTable(GLOBAL.sortedSeatedPlayers), {}

    if i ~= GLOBAL.dealerColorIdx then
      repeat
        i = cycleColorIndex(i, GLOBAL.sortedSeatedPlayers)
        table.insert(noChance, table.remove(hadChance, i))
      until i == GLOBAL.dealerColorIdx
    end

    if tableContains(noChance, player.color) then
      FLAG.crackCalled = true
      broadcastToAll("[21AF21]" .. player.steam_name .. id .. "s![-]")
    else
      broadcastToColor("[DC0000]You can only call 'Crack' if you did not get the chance to pick[-]", player.color)
    end
    return
  end

  if id:sub(1, 5) ~= "Crack" then
    print("Error: player tried to use unknown call " .. id)
    return
  end

  if not FLAG.crackCalled then
    id = insertSpaces(id)
    broadcastToColor("[DC0000]You can only call '" .. id .. "' if 'Crack' has already been called[-]", player.color)
    return
  end

  if id == "CrackBack" and player.color ~= GLOBAL.pickingPlayer then
    broadcastToColor(
      "[DC0000]Only the picker can call 'Crack Back'. The picker's partner can call 'Crack Around the Corner'[-]",
      player.color
    )
    return
  end

  if id == "CrackAroundTheCorner" and player.color ~= GLOBAL.pickingPlayer then
    if SETTINGS.jdPartner == nil
      or not GLOBAL.partnerCard
      or not doesPlayerPossessCard(player.color, GLOBAL.partnerCard) then
        broadcastToColor(
          "[DC0000]Can not call 'Crack Around the Corner' when you are not on the picker's team[-]",
          player.color
        )
        return
    end
  end

  id = string.gsub(insertSpaces(id), "Crack", "Cracks")
  broadcastToAll("[21AF21]" .. player.steam_name .. id .. "![-]")
end

--[[End of functions and buttons for calls window]]--

--[[Start of functions and buttons for playAloneWindow/selectPartnerWindow window]]--

---@param player object<eventTrigger>
function callUpEvent(player)
  toggleWindowVisibility(player.color, "playAloneWindow")
  local callCard
  for i = 2, 3 do
    local tryCard = TRUMP_IDENTIFIER[i]
    callCard = findCardToCall(filterPlayerCards(player.color, tryCard), tryCard)
    if callCard then
      break
    end
  end
  if not callCard then
    broadcastToColor("[DC0000]No suitable card to Call. Try your luck playing alone![-]", player.color)
    return
  end
  GLOBAL.partnerCard = callCard
  broadcastToAll("[21AF21]" .. player.steam_name .. " calls " .. callCard .. " to be their partner![-]")
end

---Finds next highest card that is not in passed in table
---@param cards table<"cardNames">
---@param name string<"Jack"|"Queen">
---@return string<"cardName">|nil
function findCardToCall(cards, name)
  local callCard
  if isEmpty(cards) then
    callCard = name .. " of Diamonds"
    return callCard
  end
  if #cards > 3 then
    return nil
  end
  local nextHigh = {"Diamonds", "Hearts", "Spades", "Clubs"}
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
---and updates the global GLOBAL.holdCards | if no valid holdCards will update as nil
---@param player string<"Color">
function buildPartnerChoices(player)
  --failCards = all suitableFail including ten's
  local failCards = filterPlayerCards(player, "suitableFail", "Diamonds")
  local failSuits, holdCards, partnerChoices = {}, {}, {}
  if not isEmpty(failCards) then
    failSuits = uniqueFailSuits(failCards)
    local notPartnerChoices, card = aceOrTenOfNotPartnerChoices(player)

    if card == "Ten" then --player has 3 aces, Hold card must be the ace
      failSuits = {"Hearts", "Spades", "Clubs"}
      holdCards = {"Ace of Hearts", "Ace of Spades", "Ace of Clubs"}
    end
    if not isEmpty(notPartnerChoices) then
      failSuits = removeHeldCards(notPartnerChoices, failSuits)
    end
    --compile list of valid partnerChoices and valid holdCards
    if not isEmpty(failSuits) then
      for _, suit in ipairs(failSuits) do
        table.insert(partnerChoices, card .. "-of-" .. suit)
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
  if isEmpty(failCards) or isEmpty(failSuits) then
    GLOBAL.holdCards = nil
    return
  end
  setActivePartnerButtons(partnerChoices)
  GLOBAL.holdCards = holdCards
end

---filters a list of card names down to one of each fail suit
---@param failCards table<"cardName">
---@return table<"Suit">
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
---@param player string<"Color">
---@param unknown option_boolean
---@return table<"cardNames">, string<"Ace"|"Ten">
function aceOrTenOfNotPartnerChoices(player, unknown)
  local tryOrder = {"Ace", "Ten"}
  if unknown then
    table.insert(tryOrder, "King")
  end
  local notPartnerChoices, card
  for _, tryCard in ipairs(tryOrder) do
    card = tryCard
    notPartnerChoices = filterPlayerCards(player, tryCard, "Diamonds")
    if len(notPartnerChoices) < 3 then
      break
    end
  end
  return notPartnerChoices, card
end

---Removes suits from failSuits if they share the same suit with cards found in notPartnerChoices
---@param notPartnerChoices table<"cardNames">
---@param failSuits table<"Suit">
---@return table<"Suit">
function removeHeldCards(notPartnerChoices, failSuits)
  for _, cardToRemove in ipairs(notPartnerChoices) do
    for i = #failSuits, 1, -1 do
      if string.find(cardToRemove, failSuits[i]) then
        table.remove(failSuits, i)
      end
    end
  end
  return failSuits
end

---Finds the valid partnerChoices for when unknown event is triggered and passes them to `setActivePartnerButtons`
---@param player string<"Color">
function unknownPartnerChoices(player)
  local notPartnerChoices, card = aceOrTenOfNotPartnerChoices(player, true)
  local failSuits = removeHeldCards(notPartnerChoices, {"Hearts", "Spades", "Clubs"})
  local partnerChoices = {}
  for _, suit in ipairs(failSuits) do
    table.insert(partnerChoices, card .. "-of-" .. suit)
  end
  setActivePartnerButtons(partnerChoices)
  if DEBUG then
    print("Unknown event triggered")
    print(table.concat(partnerChoices, ", "))
  end
end

---Input `list` must be formatted as "Card-of-Suit"
---@param list table<"Card-of-Suit">
function setActivePartnerButtons(list)
  local xmlTable = UI.getXmlTable()
  local selectPartnerWindow = findPanelElement("selectPartnerWindow", xmlTable)
  resetActiveChildren(selectPartnerWindow)
  for _, button in pairs(selectPartnerWindow.children[1].children) do
    if tableContains(list, button.attributes.id) then
      UI.setAttribute(button.attributes.id, "active", "true")
    end
  end
end

---@param id string
---@param table xmlTable
---@return xmlTableElement
function findPanelElement(id, table)
  for i, element in ipairs(table) do
    if element.tag == "Panel" and element.attributes.id == id then
      return table[i]
    end
  end
end

---Sets the `"active"` attribute to `"false"` for all children of the input `panel`
---@param panel xmlTableElement
function resetActiveChildren (panel)
  for _, childrenButtons in pairs(panel.children[1].children) do
    if childrenButtons.attributes.active == "true" then
      UI.setAttribute(childrenButtons.attributes.id, "active", "false")
    end
  end
end

---@param player object<eventTrigger>
function selectPartnerEvent(player, val, id)
  FLAG.selectingPartner = true
  local callCard = id:gsub('-', ' ')
  local unknownFormat = ""
  if GLOBAL.unknownText then
    unknownFormat = " - Unknown"
  end
  GLOBAL.partnerCard = callCard
  broadcastToAll("[21AF21]" .. player.steam_name .. " picks " .. callCard .. unknownFormat .. " as their partner")
  toggleWindowVisibility(player.color, "selectPartnerWindow")
  local validSuit = getLastWord(callCard)
  Wait.time(
    function()
      if not GLOBAL.unknownText then --Unknown event off
        local invalidSuits = {"Hearts", "Spades", "Clubs"}
        for i, suit in ipairs(invalidSuits) do
          if string.find(suit, validSuit) then
            table.remove(invalidSuits, i)
            break
          end
        end
        for _, suit in ipairs(invalidSuits) do --update global GLOBAL.holdCards
          for i = #GLOBAL.holdCards, 1, -1 do
            if string.find(GLOBAL.holdCards[i], suit) then
              table.remove(GLOBAL.holdCards, i)
            end
          end
        end
        local validCards = copyTable(GLOBAL.holdCards) --build validCards for string format to player
        local numOfValidCards = #validCards
        if numOfValidCards > 1 then
          table.insert(validCards, #validCards, "or")
        end
        validCards = table.concat(validCards, ' ')
        if numOfValidCards > 2 then
          validCards = validCards:gsub(validSuit .. "([^,])", validSuit .. ",%1")
        end
        broadcastToColor(
          "[21AF21]Remember to play the " .. validCards .. " the first time " .. validSuit .. " is played[-]",
          GLOBAL.pickingPlayer
        )
        if DEBUG then
          print("Valid holdCards are: " .. table.concat(GLOBAL.holdCards, ", "))
        end
      else --Unknown event on
        broadcastToColor(
          "[21AF21]Remember to play your unknown card the first time ".. validSuit .. " is played[-]",
          GLOBAL.pickingPlayer
        )
      end
      FLAG.selectingPartner = false
    end,
    2
  )
end
--[[End of functions and buttons for playAloneWindow/selectPartnerWindow window]]--

---Waits for any current `FLAG.fnRunning` to complete and starts a new fnRunning instance
function startLeasterHandCoroutine()
  startFnRunFlag()
  group(getLooseCards(SCRIPT_ZONE.center))
  pause(0.6)
  local lastLeasterTrick = getDeck(SCRIPT_ZONE.table)
  GLOBAL.lastLeasterTrick = lastLeasterTrick.guid
  if not lastLeasterTrick or lastLeasterTrick.getQuantity() ~= 2 then
    print("startLeasterHand Err: blinds wrong quantity")
    FLAG.fnRunning = false
    return 1
  end
  local playerRotation = ROTATION.color[GLOBAL.pickingPlayer]
  local leasterPos = SPAWN_POS.leasterCards:copy():rotateOver('y', playerRotation)
  lastLeasterTrick.setPositionSmooth(leasterPos)
  lastLeasterTrick.setRotationSmooth({ 0, playerRotation + 30, POS.defaultDeckRotation.z })
  lastLeasterTrick.interactable = false
  setLeadOutPlayer()
  printLeasterRules()
  FLAG.leasterHand = true
  FLAG.fnRunning = false
  return 1
end

function printLeasterRules()
  broadcastToAll("[21AF21]No teams, everyone for themselves![-]")
  Wait.time(function() broadcastToAll("[21AF21]Player with least amount of points wins +1 from all[-]") end, 2.5)
  Wait.time(function() broadcastToAll("[21AF21]Player who takes the last trick gets the blinds[-]") end, 5)
end

--[[Start of graphic animations]]--

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

  UI.setAttribute(id1, "image", "closeButton")
  toggleWindowVisibility(player.color, id2)
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

--[[End of graphic animations]]--

---GLOBAL table used for displaying the current settings as notes
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
  "Dealer Pick your Own       \nCan Call if Forced to Pick    \n",
  "6 Handed - Normal        \n",
  "Extra Calls Disabled       "
}

--[[CONST tables]]--

--Note: Global tables that contain function pointers must be defined after the function is defined in Lua

RULE_TABLE = {
  dealerSitsOut = {
    [true] = {["6 Handed - Dealer Sits Out   \n"] = 16},
    [false] = {["6 Handed - Normal        \n"] = 16},
    execute = stateChangeDealerSitsOut
  },
  calls = {
    [true] = {["Extra Calls Enabled        "] = 17},
    [false] = {["Extra Calls Disabled       "] = 17},
    execute = stateChangeCalls
  },
  threeHanded = {
    [true] = {
      ["Picker Plays Alone         \n"] = 14,
      ["Dealer Pick your Own       \n"] = 15
    },
    [false] = {["Dealer Pick your Own       \nCan Call if Forced to Pick    \n"] = 15},
    execute = stateChangeThreeHanded
  },
  jdPartner = {
    [true] = {
      ["Jack of Diamonds Partner    \n"] = 14,
      ["Dealer Pick your Own       \nCan Call if Forced to Pick    \n"] = 15
    },
    [false] = {
      ["Call an Ace                \n"] = 14,
      ["Dealer Pick your Own       \n"] = 15
    }
  },
}

CALL_TABLE = {
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

--Debug tools
function playerCountDebugUp()
  if DEBUG then
    if not GLOBAL.sortedSeatedPlayers then
      print("[21AF21]Press Set Up Game to initialize variables before changing player count.")
    elseif #GLOBAL.sortedSeatedPlayers > 0 and #GLOBAL.sortedSeatedPlayers < 6 then
      table.insert(GLOBAL.sortedSeatedPlayers, #GLOBAL.sortedSeatedPlayers + 1,
        ALL_PLAYERS[#GLOBAL.sortedSeatedPlayers + 1])
      print("Current players: ", table.concat(GLOBAL.sortedSeatedPlayers, ", "))
    else
      print("Can not add any more players")
      print("Current players: ", table.concat(GLOBAL.sortedSeatedPlayers, ", "))
    end
  end
end

function playerCountDebugDown()
  if DEBUG then
    if not GLOBAL.sortedSeatedPlayers then
      print("[21AF21]Press Set Up Game to initialize variables before changing player count.")
    elseif #GLOBAL.sortedSeatedPlayers == 1 then
      print("Can not remove any more players")
      print("Current players: ", table.concat(GLOBAL.sortedSeatedPlayers, ", "))
    else
      table.remove(GLOBAL.sortedSeatedPlayers, #GLOBAL.sortedSeatedPlayers)
      print("Current players: ", table.concat(GLOBAL.sortedSeatedPlayers, ", "))
    end
  end
end