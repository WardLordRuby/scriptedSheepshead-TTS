---@alias canBeJSON table<"is_valid_json">|colorList
---@alias hyphenCardNameList table<hyphenCardNameStr>
---@alias camelCardNameList table<camelCardNameStr>
---@alias cardSuitList table<suitEnum>
---@alias colorList table<colorEnum>
---@alias dealOrderList table<colorEnum|string<"Blinds">>

---@alias pipeList colorEnum|string<"Color|Color|Color">
---@alias cardNameStr string<"Card of Suit">
---@alias camelCardNameStr string<"cardName">
---@alias hyphenCardNameStr string<"Card-of-Suit">
---@alias GUID string<"GUID">

---@enum suitEnum
local suits = {
  diamonds = "Diamonds",
  hearts = "Hearts",
  spades = "Spades",
  clubs = "Clubs"
}

---@enum deckSize
local deckSize = {
  big = "Big",
  small = "Small"
}

---@enum searchScheme
local searchSchemes = {
  suitableFail = "SuitableFail",
  king = "King",
  ace = "Ace",
  ten = "Ten",
  jack = "Jack",
  queen = "Queen"
}

---@enum callCard
local callCards = {
  jack = "Jack",
  queen = "Queen"
}

---@alias index integer<"index">
---@alias UID integer<"UID">
---@alias seconds integer<"seconds">

---@class allPlayers
---@field [1] colorEnum
---@field [2] colorEnum
---@field [3] colorEnum
---@field [4] colorEnum
---@field [5] colorEnum
---@field [6] colorEnum

---@class GlobalVars
---@field playerCount integer|nil
---@field sortedSeatedPlayers colorList|nil
---@field dealOrder dealOrderList|nil
---@field blackSevens GUID|nil
---@field dealerColorIdx index|nil
---@field holdCards camelCardNameList|nil # `nil` == unknown mode
---@field currentTrick currentTrick|nil # `self[1]` contains general trickMetadata, followed by metadata for each card in the trick
---@field gameSetupPlayer colorEnum|nil
---@field pickingPlayer colorEnum|nil
---@field partnerCard camelCardNameStr|nil
---@field leadOutPlayer colorEnum|nil
---@field lastLeasterTrick GUID|nil
---@field unknownText GUID|nil # Shares position data with leasterCards
---@field chipScoreText GUID|nil
---@field counterGUIDs table<string<"zoneGUID">, string<"counterGUID">>|nil

---@class GlobalFlags
---@field setupRan boolean
---@field trickInProgress boolean
---@field handInProgress boolean
---@field crackCalled boolean
---@field leasterHand boolean
---@field stopCoroutine boolean
---@field lookForPlayerText boolean
---@field continue boolean|nil # continue defaults to `nil` because it is also used as an interrupt for `pause`
---@field cardsToBeBuried boolean
---@field counterVisible boolean
---@field firstDealOfGame boolean
---@field allowGrouping boolean
---@field selectingPartner boolean
---@field fnRunning boolean

---@class GlobalSettings
---@field jdPartner boolean|nil # `false` == Call an Ace && `nil` == No Partner
---@field dealerSitsOut boolean
---@field calls boolean
---@field threeHanded boolean

---@class counterSets
---@field z zoneObject
---@field c counterObject

---@class currentTrick
---@field [1] trickProperties?
---@field [2] trickCardProperties?
---@field [3] trickCardProperties?
---@field [4] trickCardProperties?
---@field [5] trickCardProperties?
---@field [6] trickCardProperties?
---@field [7] trickCardProperties?

---@class trickProperties
---@field highStrengthIndex index
---@field currentHighStrength integer
---@field trump boolean # Whether `currentHighStrength` refers to fail strength or trump strength
---@field ledSuit suitEnum

---@class trickCardProperties
---@field guid GUID
---@field cardName cardNameStr
---@field playedByColor colorEnum
---@field index index

---@class trumpIdent
---@field [1] suitEnum
---@field [2] callCard
---@field [3] callCard