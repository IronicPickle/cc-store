local stateHandler = require("/lua/lib/stateHandler")
local updateState = stateHandler.updateState
local getState = stateHandler.getState

local WrappedTurtle = {}

local SIDES = {
  front = 0,
  right = 1,
  back = 2,
  left = 3,
  up = 4,
  down = 5
}

function WrappedTurtle:new(turtle)
  local o = { turtle = turtle, orientation = 0, x = 0, y = 0, z = 0, mode = "nominal" }
  setmetatable(o, self)
  self.__index = self
  return o
end

function WrappedTurtle:resetTracker()
  self.orientation = 0
  self.x = 0
  self.y = 0
  self.z = 0
end

function WrappedTurtle:forward(distance, dig)
  distance = distance or 1
  local travelled = 0
  for i = 1, distance do
    if dig then self:dig() end
    if self:refuel() and self.turtle.forward() then
      self:updateTrackerCoords(1)
      travelled = travelled + 1
    else break end
  end
  return travelled == distance, travelled
end

function WrappedTurtle:back(distance)
  distance = distance or 1
  local travelled = 0
  for i = 1, distance do
    if self:refuel() and self.turtle.back() then
      self:updateTrackerCoords(-1)
      travelled = travelled + 1
    end
  end
  return travelled == distance, travelled
end

function WrappedTurtle:right(distance, dig)
  distance = distance or 1
  self:turnRight()
  return self:forward(distance, dig)
end

function WrappedTurtle:left(distance, dig)
  distance = distance or 1
  self:turnLeft()
  return self:forward(distance, dig)
end

function WrappedTurtle:up(distance, dig)
  distance = distance or 1
  local travelled = 0
  for i = 1, distance do
    if dig then self:digUp() end
    if self:refuel() and self.turtle.up() then
      self:updateTrackerCoords(1, 4)
      travelled = travelled + 1
    else break end
  end
  return travelled == distance, travelled
end

function WrappedTurtle:down(distance, dig)
  distance = distance or 1
  local travelled = 0
  for i = 1, distance do
    if dig then self:digDown() end
    if self:refuel() and self.turtle.down() then
      self:updateTrackerCoords(1, 5)
      travelled = travelled + 1
    else break end
  end
  return travelled == distance, travelled
end

function WrappedTurtle:turnRight()
  local success = self.turtle.turnRight()
  if not success then return false end
  local newOrientation = self.orientation + 1
  if newOrientation > 3 then newOrientation = 0 end
  self.orientation = newOrientation
  return true
end

function WrappedTurtle:turnLeft()
  local success = self.turtle.turnLeft()
  if not success then return false end
  local newOrientation = self.orientation - 1
  if newOrientation < 0 then newOrientation = 3 end
  self.orientation = newOrientation
  return true
end

function WrappedTurtle:turnAround()
  return self:turnLeft() and self:turnLeft()
end

function WrappedTurtle:move(direction)
  local actions = {
    forward = function() self:forward() end,
    back = function() self:back() end,
    right = function() self:right() end,
    left = function() self:left() end,
    up = function() self:up() end,
    down = function() self:down() end,
  }
  return actions[direction]()
end

function WrappedTurtle:turn(direction)
  local actions = {
    right = function() self:turnRight() end,
    left = function() self:turnLeft() end,
    back = function() self:turnAround() end,
    forward = function() end,
  }
  return actions[direction]()
end

function WrappedTurtle:face(direction)
  self:reorient(SIDES[direction])
end

function WrappedTurtle:dig()
  if self.turtle.detect() then
      self.turtle.dig()
  end
end

function WrappedTurtle:digUp()
  if self.turtle.detectUp() then
      self.turtle.digUp()
  end
end

function WrappedTurtle:digDown()
  if self.turtle.detectDown() then
      self.turtle.digDown()
  end
end

function WrappedTurtle:getFuelLevel()
  local level = self.turtle.getFuelLevel()
  if level == "unlimited" then level = math.huge end
  return level, level <= 0
end

function WrappedTurtle:refuel()
  local prevSlot = self:getSelectedSlot()
  local blocksToTracker = math.abs(self.x) + math.abs(self.y) + math.abs(self.z)
  self:select(16)
  print("blocks to tracker: " .. blocksToTracker)
  print("fuel level: " .. self:getFuelLevel())
  local attempts = 0
  while self:getFuelLevel() < (blocksToTracker + 100) do
    attempts = attempts + 1
    if not self.turtle.refuel(1) then
      if attempts == 1 then print("refuel failed... waiting...") end
      sleep(5)
    else print("refueled") end
  end
  self:select(prevSlot)
  return true
end

function WrappedTurtle:reorient(orientation)
  orientation = orientation or self.orientation
  if orientation == 1 then
    self:turnLeft()
  elseif orientation == 3 then
    self:turnRight()
  elseif orientation == 2 then
    self:turnAround()
  end
end

function WrappedTurtle:returnToTracker(dig, order)
  order = order or {"z", "x", "y"}
  self.mode = "returning"
  local x, y, z = self.x, self.y, self.z
  self:reorient()
  self:resetTracker()

  local actions = {
    x = function()
      self:reorient()
      if x > 0 then
        self:turnAround()
        self:forward(math.abs(x), dig)
      else
        self:forward(math.abs(x), dig)
      end
      self:reorient()
    end,
    z = function()
      self:reorient()
      if z > 0 then
        self:left(math.abs(z), dig)
      else
        self:right(math.abs(z), dig)
      end
      self:reorient()
    end,
    y = function()
      if y > 0 then
        self:down(math.abs(y), dig)
      else
        self:up(math.abs(y), dig)
      end
    end
  }

  for i = 1, #order do
    actions[order[i]]()
  end

  self:reorient()
  self.mode = "nominal"
end

function WrappedTurtle:select(slot)
  return self.turtle.select(slot)
end

function WrappedTurtle:getSelectedSlot()
  return self.turtle.getSelectedSlot()
end

function WrappedTurtle:interact(side, slot, mode, amount)
  amount = amount or 1
  local prevSlot = self:getSelectedSlot()
  self:select(slot)
  if side == "up" then
    if mode == "drop" then
      self.turtle.dropUp(amount)
    else
      self.turtle.suckUp(amount)
    end
  elseif side == "down" then
    if mode == "drop" then
      self.turtle.dropDown(amount)
    else
      self.turtle.suckDown(amount)
    end
  else
    if mode == "drop" then
      self.turtle.drop(amount)
    else
      self.turtle.suck(amount)
    end
  end
  self:select(prevSlot)
end

function WrappedTurtle:drop(slot, amount)
  amount = amount or 1
  self:interact("foward", slot, "drop", amount)
end

function WrappedTurtle:dropUp(slot, amount)
  amount = amount or 1
  self:interact("up", slot, "drop", amount)
end

function WrappedTurtle:dropDown(slot, amount)
  amount = amount or 1
  self:interact("down", slot, "drop", amount)
end

function WrappedTurtle:suck(slot, amount)
  amount = amount or 1
  self:interact("foward", slot, "suck", amount)
end

function WrappedTurtle:suckUp(slot, amount)
  amount = amount or 1
  self:interact("up", slot, "suck", amount)
end

function WrappedTurtle:suckDown(slot, amount)
  amount = amount or 1
  self:interact("down", slot, "suck", amount)
end

function WrappedTurtle:updateTrackerCoords(distance, orientation)
  if orientation == nil then orientation = self.orientation end
  local actions = {
    [0] = function() self.x = self.x + distance end,
    [1] = function() self.z = self.z + distance end,
    [2] = function() self.x = self.x - distance end,
    [3] = function() self.z = self.z - distance end,
    [4] = function() self.y = self.y + distance end,
    [5] = function() self.y = self.y - distance end
  }

  actions[orientation]()
end

function WrappedTurtle:saveState()
  local state = {
    x = self.x,
    y = self.y,
    z = self.z,
    orientation = self.orientation,
    mode = self.mode,
  }
  updateState("turtle", state)
end

function WrappedTurtle:loadState()
  local state = getState("turtle")
  self.x = state.x
  self.y = state.y
  self.z = state.z
  self.orientation = state.orientation
  self.mode = state.mode
  print("# Loaded state")
  print(textutils.serialize(state))
end

function WrappedTurtle:getOrientationSide(orientation)
  orientation = orientation or self.orientation
  local sides = {
    [0] = "forward",
    [1] = "right",
    [2] = "back",
    [3] = "left",
  }
  return sides[self.orientation]
end  

function WrappedTurtle:getItemCount(slot)
  return self.turtle.getItemCount(slot)
end

function WrappedTurtle:depositInventory(slot1, slot2)
  slot1 = slot1 or 1
  slot2 = slot2 or 15
  for i = slot1, slot2 do
    self:drop(i, 64)
  end
end


function WrappedTurtle:takeFuel(slot)
  slot = slot or 16
  local amount = 64 - self:getItemCount(16)
  self:suck(slot, amount)
end

return WrappedTurtle