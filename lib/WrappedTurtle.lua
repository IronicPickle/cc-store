local WrappedTurtle = {}

function WrappedTurtle:new(turtle)
  local o = { turtle = turtle, orientation = 0, x = 0, y = 0, z = 0 }
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
  if distance == nil then distance = 1 end
  self:updateTrackerCoords(distance)
  local travelled = 0
  for i = 1, distance do
    if dig then self:dig() end
    if self.turtle.forward() then
      travelled = travelled + 1
    else break end
  end
  return travelled == distance, travelled
end

function WrappedTurtle:back(distance)
  if distance == nil then distance = 1 end
  local travelled = 0
  for i = 1, distance do
    if self.turtle.back() then
      travelled = travelled + 1
    end
  end
  self:updateTrackerCoords(-travelled)
  return travelled == distance, travelled
end

function WrappedTurtle:right(distance, dig)
  if distance == nil then distance = 1 end
  self:turnRight()
  return self:forward(distance, dig)
end

function WrappedTurtle:left(distance, dig)
  if distance == nil then distance = 1 end
  self:turnLeft()
  return self:forward(distance, dig)
end

function WrappedTurtle:up(distance, dig)
  if distance == nil then distance = 1 end
  local travelled = 0
  for i = 1, distance do
    if dig then self:digUp() end
    if self.turtle.up() then
      travelled = travelled + 1
    else break end
  end
  self:updateTrackerCoords(travelled, 4)
  return travelled == distance, travelled
end

function WrappedTurtle:down(distance, dig)
  if distance == nil then distance = 1 end
  local travelled = 0
  for i = 1, distance do
    if dig then self:digDown() end
    if self.turtle.down() then
      travelled = travelled + 1
    else break end
  end
  self:updateTrackerCoords(travelled, 5)
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
  actions = {
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
  actions = {
    right = function() self:turnRight() end,
    left = function() self:turnLeft() end,
    around = function() self:turnAround() end,
  }
  return actions[direction]()
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

function WrappedTurtle:updateTrackerCoords(distance, orientation)
  if orientation == nil then orientation = self.orientation end
  actions = {
    [0] = function() self.x = self.x + distance end,
    [1] = function() self.z = self.z + distance end,
    [2] = function() self.x = self.x - distance end,
    [3] = function() self.z = self.z - distance end,
    [4] = function() self.y = self.y + distance end,
    [5] = function() self.y = self.y - distance end
  }

  actions[orientation]()
end
  

return WrappedTurtle