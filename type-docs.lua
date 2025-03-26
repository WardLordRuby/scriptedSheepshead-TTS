---@alias hyphenCardNameList table<hyphenCardNameStr>
---@alias camelCardNameList table<camelCardNameStr>
---@alias cardSuitList table<suitStr>
---@alias colorList table<colorStr>
---@alias dealOrderList table<colorStr|string<"Blinds">>

---@alias pipeList string<"Color|Color|Color">
---@alias colorStr string<"Color">
---@alias typeStr string<"Type">
---@alias suitStr string<"Suit">
---@alias cardNameStr string<"Card of Suit">
---@alias camelCardNameStr string<"cardName">
---@alias hyphenCardNameStr string<"Card-of-Suit">
---@alias GUID string<"GUID">

---@alias index integer<"index">
---@alias UID integer<"UID">
---@alias seconds integer<"seconds">

---@class GlobalVars
---@field playerCount integer?
---@field sortedSeatedPlayers colorList?
---@field dealOrder dealOrderList?
---@field blackSevens GUID?
---@field dealerColorIdx integer<index>?
---@field holdCards camelCardNameList? # `nil` == unknown mode
---@field currentTrick currentTrick? # `self[1]` contains general trickMetadata, followed by metadata for each card in the trick
---@field gameSetupPlayer colorStr?
---@field pickingPlayer colorStr?
---@field partnerCard camelCardNameStr?
---@field leadOutPlayer colorStr?
---@field lastLeasterTrick GUID?
---@field unknownText GUID? # Shares position data with leasterCards
---@field chipScoreText GUID?
---@field counterGUIDs table<string<"zoneGUID">, string<"counterGUID">>?

---@class GlobalFlags
---@field setupRan boolean
---@field trickInProgress boolean
---@field handInProgress boolean
---@field crackCalled boolean
---@field leasterHand boolean
---@field stopCoroutine boolean
---@field lookForPlayerText boolean
---@field continue boolean? # continue's default is nul because it is also used as an interrupt for `pause`
---@field cardsToBeBuried boolean
---@field counterVisible boolean
---@field firstDealOfGame boolean
---@field allowGrouping boolean
---@field selectingPartner boolean
---@field fnRunning boolean

---@class GlobalSettings
---@field jdPartner boolean? # `false` == Call an Ace && `nil` == No Partner
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
---@field ledSuit suitStr

---@class trickCardProperties
---@field guid GUID
---@field cardName cardNameStr
---@field playedByColor colorStr
---@field index index