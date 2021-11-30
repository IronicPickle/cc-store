local TrackedTurtle = {}

function TrackedTurtle:new(turtle)
  local o = { turtle = turtle, orientation = 0, x = 0, y = 0, z = 0 }
  setmetatable(o, self)
  self.__index = self
  return o
end

function TrackedTurtle:resetTracker()
  self.orientation = 0
  self.x = 0
  self.y = 0
  self.z = 0
end

function TrackedTurtle:forward(distance, dig)
  if distance == nil then distance = 1 end
  self:updateTrackerCoords(distance)
  for i = 1, distance do
    if dig then self:dig() end
    self.turtle.forward()
  end
end

function TrackedTurtle:back(distance)
  if distance == nil then distance = 1 end
  for i = 1, distance do
    self.turtle.back()
  end
  self:updateTrackerCoords(distance)
end

function TrackedTurtle:right(distance, dig)
  if distance == nil then distance = 1 end
  self:turnRight()
  self:forward(distance, dig)
end

function TrackedTurtle:left(distance, dig)
  if distance == nil then distance = 1 end
  self:turnLeft()
  self:forward(distance, dig)
end

function TrackedTurtle:up(distance, dig)
  if distance == nil then distance = 1 end
  for i = 1, distance do
    if dig then self:digUp() end
    self.turtle.up()
  end
  self:updateTrackerCoords(distance, 4)
end

function TrackedTurtle:down(distance, dig)
  if distance == nil then distance = 1 end
  for i = 1, distance do
    if dig then self:digDown() end
    self.turtle.down()
  end
  self:updateTrackerCoords(distance, 5)
end

function TrackedTurtle:turnRight()
  self.turtle.turnRight()
  local newOrientation = self.orientation + 1
  if newOrientation > 3 then newOrientation = 0 end
  self.orientation = newOrientation
end

function TrackedTurtle:turnLeft()
  self.turtle.turnLeft()
  local newOrientation = self.orientation - 1
  if newOrientation < 0 then newOrientation = 3 end
  self.orientation = newOrientation
end

function TrackedTurtle:turnAround()
  self:turnLeft()
  self:turnLeft()
end

function TrackedTurtle:move(direction)
  actions = {
    forward = function() self:forward() end,
    back = function() self:back() end,
    right = function() self:right() end,
    left = function() self:left() end,
    up = function() self:up() end,
    down = function() self:down() end,
  }
  actions[direction]()
end

function TrackedTurtle:turn(direction)
  actions = {
    right = function() self:turnRight() end,
    left = function() self:turnLeft() end,
    around = function() self:turnAround() end,
  }
  actions[direction]()
end

function TrackedTurtle:dig()
  if self.turtle.detect() then
      self.turtle.dig()
  end
end

function TrackedTurtle:digUp()
  if self.turtle.detectUp() then
      self.turtle.digUp()
  end
end

function TrackedTurtle:digDown()
  if self.turtle.detectDown() then
      self.turtle.digDown()
  end
end

function TrackedTurtle:updateTrackerCoords(distance, orientation)
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
  

return TrackedTurtle