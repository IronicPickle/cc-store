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

function WrappedTurtle:resume()
  self:loadState()
  local mode = self.mode or "nominal"

  if mode == "returning" then self:returnToTracker()
  elseif mode == "depositing inventory" then self:depositInventory()
  elseif mode == "taking fuel" then self:takeFuel() end
end

function WrappedTurtle:resetTracker()
  self.orientation = 0
  self.x = 0
  self.y = 0
  self.z = 0
  self:saveState()
end

function WrappedTurtle:forward(distance, dig, bypassFuel)
  distance = distance or 1
  for i = 1, distance do
    if self:canForward(dig, bypassFuel) then
      if dig then
        while self:detect() do self:dig() end
      end
      self:updateTrackerCoords(1)
      self.turtle.forward()
    end
  end
end

function WrappedTurtle:back(distance, bypassFuel)
  distance = distance or 1
  for i = 1, distance do
    if (self:refuel() or bypassFuel) and self.turtle.back() then
      self:updateTrackerCoords(-1)
    end
  end
end

function WrappedTurtle:right(distance, dig, bypassFuel)
  distance = distance or 1
  self:turnRight()
  return self:forward(distance, dig, bypassFuel)
end

function WrappedTurtle:left(distance, dig, bypassFuel)
  distance = distance or 1
  self:turnLeft()
  return self:forward(distance, dig, bypassFuel)
end

function WrappedTurtle:up(distance, dig, bypassFuel)
  distance = distance or 1
  for i = 1, distance do
    if self:canUp(dig, bypassFuel) then
      if dig then 
        while self:detectUp() do self:digUp() end
      end
      self:updateTrackerCoords(1, 4)
      self.turtle.up()
    end
  end
end

function WrappedTurtle:down(distance, dig, bypassFuel)
  distance = distance or 1
  for i = 1, distance do
    if self:canDown(dig, bypassFuel) then
      if dig then
        while self:detectDown() do self:digDown() end
      end
      self:updateTrackerCoords(1, 5)
      self.turtle.down()
    end
  end
end

function WrappedTurtle:canForward(dig, bypassFuel)
  if dig and bypassFuel then return true
  elseif dig then return self:refuel()
  else return self:refuel() and not self:detect() end
end

function WrappedTurtle:canDown(dig, bypassFuel)
  if dig and bypassFuel then return true
  elseif dig then return self:refuel()
  else return self:refuel() and not self:detectDown() end
end

function WrappedTurtle:canUp(dig, bypassFuel)
  if dig and bypassFuel then return true
  elseif dig then return self:refuel()
  else return self:refuel() and not self:detectUp() end
end

function WrappedTurtle:turnRight()
  local newOrientation = self.orientation + 1
  if newOrientation > 3 then newOrientation = 0 end
  self:updateTrackerOrientation(newOrientation)
  self.turtle.turnRight()
end

function WrappedTurtle:turnLeft()
  local newOrientation = self.orientation - 1
  if newOrientation < 0 then newOrientation = 3 end
  self:updateTrackerOrientation(newOrientation)
  self.turtle.turnLeft()
end

function WrappedTurtle:turnAround()
  self:turnLeft()
  self:turnLeft()
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

function WrappedTurtle:detect()
  return self.turtle.detect()
end

function WrappedTurtle:detectUp()
  return self.turtle.detectUp()
end

function WrappedTurtle:detectDown()
  return self.turtle.detectDown()
end

function WrappedTurtle:inspect()
  return self.turtle.inspect()
end

function WrappedTurtle:inspectUp()
  return self.turtle.inspectUp()
end

function WrappedTurtle:inspectDown()
  return self.turtle.inspectDown()
end

function WrappedTurtle:getFuelLevel()
  local level = self.turtle.getFuelLevel()
  if level == "unlimited" then level = math.huge end
  return level, level <= 0
end

function WrappedTurtle:needsFuel(offset)
  offset = offset or 0
  local blocksToTracker = math.abs(self.x) + math.abs(self.y) + math.abs(self.z)
  return self:getFuelLevel() < ((blocksToTracker * 2) + 100 + offset)
end

function WrappedTurtle:refuel()
  local prevSlot = self:getSelectedSlot()
  local attempts = 0
  while self:needsFuel(-1) do
    attempts = attempts + 1
    self:select(16)
    if not self.turtle.refuel(1) then return false end
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
  local x, y, z, orientation = self.x, self.y, self.z, self.orientation

  if self.mode == "returning" then
    x, y, z = (self.targetX or 0) + x, (self.targetY or 0) + y, (self.targetZ or 0) + z
    orientation = (self.targetOrientation or 0) or orientation
    order = self.targetOrder or order
  end

  self.targetX = x
  self.targetY = y
  self.targetZ = z
  self.targetOrientation = orientation
  self.targetOrder = order
  self:setMode("returning")

  function calcOrientation()
    local o = self.orientation + orientation
    local r = o % 3
    if r > 0 then o = r end
    return o
  end

  self:resetTracker()

  local actions = {
    x = function()
      self:reorient(calcOrientation())
      if x > 0 then
        self:left(math.abs(x), dig, true)
      else
        self:right(math.abs(x), dig, true)
      end
      self:reorient(calcOrientation())
    end,
    y = function()
      if y > 0 then
        self:down(math.abs(y), dig, true)
      else
        self:up(math.abs(y), dig, true)
      end
    end,
    z = function()
      self:reorient(calcOrientation())
      if z > 0 then
        self:turnAround()
        self:forward(math.abs(z), dig, true)
      else
        self:forward(math.abs(z), dig, true)
      end
      self:reorient(calcOrientation())
    end
  }

  for i = 1, #order do
    actions[order[i]]()
  end

  self.targetX = nil
  self.targetY = nil
  self.targetZ = nil

  self:reorient(calcOrientation())
  self:saveState()
  self:setMode("nominal")
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
  self:interact("forward", slot, "drop", amount)
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
  self:interact("forward", slot, "suck", amount)
end

function WrappedTurtle:suckUp(slot, amount)
  amount = amount or 1
  self:interact("up", slot, "suck", amount)
end

function WrappedTurtle:suckDown(slot, amount)
  amount = amount or 1
  self:interact("down", slot, "suck", amount)
end

function WrappedTurtle:place(slot)
  local prevSlot = self:getSelectedSlot()
  self:select(slot)
  local success = self.turtle.place(slot)
  self:select(prevSlot)
  return success
end

function WrappedTurtle:placeUp(slot)
  local prevSlot = self:getSelectedSlot()
  self:select(slot)
  local success = self.turtle.palceUp(slot)
  self:select(prevSlot)
  return success
end

function WrappedTurtle:placeDown(slot)
  local prevSlot = self:getSelectedSlot()
  self:select(slot)
  local success = self.turtle.placeDown(slot)
  self:select(prevSlot)
  return success
end

function WrappedTurtle:compare(slot)
  local prevSlot = self:getSelectedSlot()
  self:select(slot)
  local success = self.turtle.compare()
  self:select(prevSlot)
  return success
end

function WrappedTurtle:compareUp(slot)
  local prevSlot = self:getSelectedSlot()
  self:select(slot)
  local success = self.turtle.compareUp()
  self:select(prevSlot)
  return success
end

function WrappedTurtle:compareDown(slot)
  local prevSlot = self:getSelectedSlot()
  self:select(slot)
  local success = self.turtle.compareDown()
  self:select(prevSlot)
  return success
end

function WrappedTurtle:compareSlots(slot1, slot2)
  local prevSlot = self:getSelectedSlot()
  self:select(slot1)
  local success = self.turtle.compareTo(slot2)
  self:select(prevSlot)
  return success
end

function WrappedTurtle:updateTrackerOrientation(orientation)
  self.orientation = orientation
  self:saveState()
end

function WrappedTurtle:updateTrackerCoords(distance, orientation)
  if orientation == nil then orientation = self.orientation end
  local actions = {
    [0] = function() self.z = self.z + distance end,
    [1] = function() self.x = self.x + distance end,
    [2] = function() self.z = self.z - distance end,
    [3] = function() self.x = self.x - distance end,
    [4] = function() self.y = self.y + distance end,
    [5] = function() self.y = self.y - distance end
  }

  actions[orientation]()
  self:saveState()
end

function WrappedTurtle:saveState()
  local state = {
    x = self.x,
    y = self.y,
    z = self.z,
    targetX = self.targetX,
    targetY = self.targetY,
    targetZ = self.targetZ,
    targetOrientation = self.targetOrientation,
    targetOrder = self.targetOrder,
    orientation = self.orientation,
    mode = self.mode,
  }
  updateState("turtle", state)
end

function WrappedTurtle:loadState()
  local state = getState("turtle")
  if state == nil then return end
  self.x = state.x
  self.y = state.y
  self.z = state.z
  self.targetX = state.targetX
  self.targetY = state.targetY
  self.targetZ = state.targetZ
  self.targetOrientation = state.targetOrientation
  self.targetOrder = state.targetOrder
  self.orientation = state.orientation
  self.mode = state.mode

end

function WrappedTurtle:setMode(mode)
  self.mode = mode
  self:saveState()
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
  self:setMode("depositing inventory")
  slot1 = slot1 or 1
  slot2 = slot2 or 15
  for i = slot1, slot2 do
    self:drop(i, 64)
  end
  self:setMode("nominal")
end

function WrappedTurtle:takeFuel(slot)
  self:setMode("taking fuel")
  slot = slot or 16
  local amount = 64 - self:getItemCount(slot)
  self:suck(slot, amount)
  self:setMode("nominal")
  return self:getItemCount(slot) > 0
end

function WrappedTurtle:isInventoryOccupied(slot1, slot2)
  slot1 = slot1 or 1
  slot2 = slot2 or 15
  
  for i = slot1, slot2 do
    if self:getItemCount(i) == 0 then
      return false
    end
  end
  return true
end

function WrappedTurtle:isInventoryFull(slot1, slot2)
  slot1 = slot1 or 1
  slot2 = slot2 or 15

  for i = slot1, slot2 do
    if self:getItemCount(i) ~= 64 then
      return false
    end
  end
  return true
end

return WrappedTurtle