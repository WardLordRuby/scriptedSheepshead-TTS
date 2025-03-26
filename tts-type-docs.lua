---@type object<"type.Global">
Global = nil

---@alias XML table<"XML">
---@alias jsonString string<"json_string">

---@type JSON
JSON = nil

---@class JSON
---@field decode fun(data: jsonString): any
---@field encode fun(data: any): jsonString

---@class xmlElement
---@field children xmlElement

---@class object
---@field is_face_down boolean
---@field guid GUID
---@field UI UI
---@field type typeEnum
---@field interactable boolean
---@field flip fun(): boolean
---@field getZones fun(): table<zoneObject>
---@field getObjects fun(): table<object>
---@field getRotation fun(): vector
---@field getPosition fun(): vector
---@field getName fun(): name
---@field TextTool TextTool # only available on type.3DText
---@field getValue fun(): any # return value depends on `self.type`
---@field getQuantity fun(): integer # Returns the number of objects contained within (if the Object is a bag, deck or stack), otherwise -1
---@field setRotationSmooth fun(vector: vector|vector2, collide: boolean?, fast: boolean?): boolean
---@field setPositionSmooth fun(vector: vector|vector2, collide: boolean?, fast: boolean?): boolean
---@field setRotation fun(vector: vector|vector2): boolean
---@field setPosition fun(vector: vector|vector2): boolean
---@field setInvisibleTo fun(players: colorList): boolean
---@field setHiddenFrom fun(players: colorList): boolean
---@field setCustomObject fun(parameters: table<"customObjectParam">): boolean
---@field setValue fun(value: any): boolean
---@field takeObject fun(parameters: takeParameters): object
---@field putObject fun(object: object): object # Places an `object` into a container (chip stacks/bags/decks). If neither Object is a container, but they are able to be combined (like with 2 cards), then they form a deck/stack. The container is returned as the Object reference. Either this is the container/deck/stack the other Object was placed into, or the deck/stack that was formed by the putObject action
---@field clone fun(parameters: cloneParameters): object
---@field setLock fun(lock: boolean): boolean # Sets if an object is locked in place
---@field randomize fun(color: colorEnum?): boolean # Shuffles deck/bag, rolls dice/coin, lifts other objects into the air. Same as pressing R by default. If the optional parameter color is used, this function will trigger `onObjectRandomized()`, passing that player color
---@field deal fun(number: integer, player_color: colorEnum?, index: index?)
---@field destruct fun(): boolean
---@field reload fun(): object

---@class TextTool
---@field getFontColor fun(): color # Returns Table of font Color
---@field getFontSize fun(): integer # Returns Int of the font size
---@field getValue fun(): string # Returns the current text. Behaves the same as Object's getValue()
---@field setFontColor fun(font_color: color|colorEnum): boolean # Sets font Color
---@field setFontSize fun(font_size: integer): boolean # Sets font size
---@field setValue fun(text: string): boolean # Sets the current text. Behaves the same as Object's setValue(...)

---@alias zoneObject object<"type.Zone">
---@alias counterObject object<"type.Counter">
---@alias deckObject object<"type.Deck">
---@alias bagObject object<"type.Bag">
---@alias cardObject object<"type.Card">
---@alias textObject object<"type.3DText">
---@alias containerObject bagObject|deckObject

---@alias name string<"Nickname">

---@type table<colorEnum, player>
Player = nil

---@class player
---@field admin boolean
---@field blindfolded boolean
---@field color colorEnum
---@field host boolean
---@field lift_height number
---@field promoted boolean
---@field seated boolean
---@field steam_id string
---@field steam_name string
---@field team teamEnum
---@field getHandTransform fun(hand_index: index?): transformTable
---@field broadcast fun(message: string, message_color: color|colorEnum?) # Message color optional, defaults to {r=1, g=1, b=1}

---@class transformTable
---@field position vector
---@field rotation vector
---@field scale vector
---@field forward vector
---@field right vector
---@field up vector

---@type UI
UI = nil

---@class UI
---@field show fun(id: string): boolean
---@field hide fun(id: string): boolean
---@field setAttribute fun(id: string, attribute: string, value: any): boolean
---@field getAttribute fun(id: string, attribute: string): any
---@field getXmlTable fun(): XML

---@type Time
Time = nil

---@class Time
---@field time number # The current time
---@field delta_time number #	The amount of time since the last frame
---@field fixed_delta_time number # interval (in seconds) between physics updates

---@type Wait
Wait = nil

---@class Wait
---@field time fun(toRunFunc: function, seconds: number, repetitions: integer?): UID
---@field frames fun(toRunFunc: function, frames: number, repetitions: integer?): UID
---@field stop fun(id: UID): boolean

---@alias eventTriggerPlayer player<"triggeredCommand">

---@class takeParameters
---@field position vector|vector2? # Optional, defaults to container's position + 2 on the x axis
---@field rotation vector|vector2? # Optional, defaults to the container's rotation
---@field flip boolean? # Optional, defaults to false. Only used with decks, not bags/stacks
---@field guid GUID? # GUID of the Object to take. Optional, no default. Only use index or guid, never both
---@field index index? # Index of the Object to take. Optional, no default. Only use index or guid, never both
---@field top boolean? # If an object is taken from the top (vs bottom). Optional, defaults to true
---@field smooth boolean? # If the taken Object moves smoothly or instantly. Optional, defaults to true
---@field callback_function fun(taken: object)? # Callback which will be called when the taken object has finished spawning. Optional, no default

---@class cloneParameters
---@field  position vector|vector2? # Where the Object is placed. Optional, defaults to {x=0, y=3, z=0}
---@field snap_to_grid boolean? # If the Object snaps to grid. Optional, defaults to false

---@class spawnObjectParameters
---@field type string
---@field position vector|vector2? # Position where the object will be spawned. Optional, defaults to {0, 0, 0}
---@field rotation vector|vector2? # Rotation of the spawned object. Optional, defaults to {0, 0, 0}
---@field scale vector|vector2? # Scale of the spawned object. Optional, defaults to {1, 1, 1}
---@field sound boolean? # Whether a sound will be played as the object spawns. Optional, defaults to true
---@field snap_to_grid boolean? # Whether upon spawning, the object will snap to nearby grid lines (or snap points). Optional, defaults to false
---@field callback_function fun(spawned: object)? # Called when the object has finished spawning. Optional, no default

---@class spawnObjectJsonParameters
---@field json jsonString
---@field position vector|vector2? # Position where the object will be spawned. When specified, overrides the Transform position in json
---@field rotation vector|vector2? # Rotation of the spawned object. When specified, overrides the Transform rotation in json
---@field callback_function fun(spawned: object)? # Called when the object has finished spawning. Optional, no default

---@class vector
---@field x number
---@field y number
---@field z number
---@field copy fun(): vector
---@field rotateOver fun(self: self, axis: AxisEnum, angle: number): vector

---@class vector2
---@field [1] number
---@field [2] number
---@field [3] number

---@class color
---@field r number
---@field g number
---@field b number

---@enum AxisEnum
local axis = {
  x = 'x',
  y = 'y',
  z = 'z'
}

---@enum colorEnum
local color = {
  white = "White",
  brown = "Brown",
  red = "Red",
  orange = "Orange",
  yellow = "Yellow",
  green = "Green",
  teal = "Teal",
  blue = "Blue",
  purple = "Purple",
  pink = "Pink",
  grey = "Grey",
  black = "Black"
}

---@enum teamEnum
local team = {
  none = "None",
  clubs = "Clubs",
  diamonds = "Diamonds",
  hearts = "Hearts",
  spades = "Spades",
  jokers = "Jokers"
}

--[[
  Moved to global for better type checking inside iterators
  ---@enum typeEnum
  local type = {
    card = "Card",
    deck = "Deck",
    chip = "Chip",
    counter = "Counter",
    pdf = "Tile"
  }
--]]

---@param objects table<object>
---@return table<object>
---@diagnostic disable-next-line
function group(objects) 
  return {}
end

---@param x number
---@param y number
---@param z number
---@return vector
function Vector(x, y, z)
  return { x = x, y = y, z = z }
end

---@param guid GUID
---@return object
---@diagnostic disable-next-line
function getObjectFromGUID(guid)
  local x
  return x
end

---@param notes string
---@return boolean
---@diagnostic disable-next-line
function setNotes(notes)
  return true
end

---@param message string
---@param player_color colorEnum
---@param message_tint color|colorEnum?
---@return boolean
---@diagnostic disable-next-line
function broadcastToColor(message, player_color, message_tint)
  return true  
end

---@param message string
---@param message_tint color|colorEnum?
---@return boolean
---@diagnostic disable-next-line
function broadcastToAll(message, message_tint)
  return true
end

---@param parameters spawnObjectParameters
---@return object
---@diagnostic disable-next-line
function spawnObject(parameters)
  local x
  return x
end

---@param parameters spawnObjectJsonParameters
---@return object
---@diagnostic disable-next-line
function spawnObjectJSON(parameters)
  local x
  return x
end

---You **must** return a 1 at the end of any coroutine or it will throw an error
---@param function_owner object
---@param function_name string
---@return boolean
---@diagnostic disable-next-line
function startLuaCoroutine(function_owner, function_name)
  return true
end
