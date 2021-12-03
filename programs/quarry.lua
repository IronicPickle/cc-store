--$ARGS|Max X (10)|Max Z (10)|Max Y (10)|$ARGS

-- Args
local args = { ... }
local MAX_X = tonumber(args[1]) or 3
local MAX_Z = tonumber(args[2]) or 3
local MAX_Y = tonumber(args[3]) or 3

-- Libraries
local stateHandler = require("/lua/lib/stateHandler")
local WrappedTurtle = require("/lua/lib/WrappedTurtle")
local WT = WrappedTurtle:new(turtle)

-- Globals
local X = 0
local Z = 0
local Y = 0
local FIRST_TIME = true
local ORES_FOUND = 0

-- Main
function start()
  print("# Program Started")

  -- Load and resume state if applicable
  loadState()
  WT:resume()

  -- First time refuel attempt
  if FIRST_TIME then takeFuel() end
  FIRST_TIME = false
  saveState()

  WT:reorient()

  -- Main loop
  quarry()
  
  -- Final return and reposit
  WT:returnToTracker(true, { "z", "x", "y" })
  depositInventory()

  local oresFound = ORES_FOUND
  
  -- Reset state
  WT:resetTracker()
  resetState()

  print("# Quarry finished")
  print("# Ores found " .. tostring(oresFound))
  while true do sleep(100) end
end

function fetchAndDeposit()
  print("# Fetching and Despositing")

  WT:returnToTracker(true, { "z", "x", "y" })
  takeFuel()
  depositInventory()
  WT:returnToTracker(true, { "y", "x", "z" })
  WT:setMode("nominal")
end

function takeFuel()
  print("# Taking Fuel")

  WT:turnRight()
  local attempts = 0
  while not WT:takeFuel() do
    attempts = attempts + 1
    if attempts == 1 then print("No fuel in chest, will retry every 10 seconds...") end
    sleep(10)
  end
  WT:reorient()
end

function depositInventory()
  print("# Depositing Inventory")

  WT:turnLeft()
  local attempts = 0
  WT:depositInventory()
  while WT:isInventoryOccupied() do
    attempts = attempts + 1
    if attempts == 1 then print("Can't deposit inventory, will retry every 10 seconds...") end
    sleep(10)
    WT:depositInventory()
  end
  WT:reorient()
end

function inspectSurroundings()
  -- forward
  if checkBlock(WT:inspect()) then WT:dig() end
  -- left
  WT:turnLeft()
  if checkBlock(WT:inspect()) then WT:dig() end
  -- back
  WT:turnLeft()
  if checkBlock(WT:inspect()) then WT:dig() end
  -- right
  WT:turnLeft()
  if checkBlock(WT:inspect()) then WT:dig() end
  -- up and down
  WT:turnLeft()
  if checkBlock(WT:inspectUp()) then WT:digUp() end
  if checkBlock(WT:inspectDown()) then WT:digDown() end
end

function checkBlock(success, block)
  if not success then return false end
  local tags = block["tags"]
  if tags == nil then return false end
  local isOre = tags["forge:ores"] == true
  if isOre then ORES_FOUND = ORES_FOUND + 1 end
  return isOre
end

function saveState()
  local state = {
    x = X,
    y = Y,
    z = Z,
    firstTime = FIRST_TIME,
    oresFound = ORES_FOUND
  }
  stateHandler.updateState("quarry", state)
end

function loadState()
  local state = stateHandler.getState("quarry")
  if state then
    X = state.x
    Z = state.z
    Y = state.y
    FIRST_TIME = state.firstTime
    ORES_FOUND = state.oresFound
    print("# Loaded Quarry State")
    print(textutils.serialize(state))
  end
  return not not state
end

function resetState()
  X = 0
  Z = 0
  Y = 0
  FIRST_TIME = true
  ORES_FOUND = 0
  saveState()
end

function quarry()

  function startY()

    for y = Y, MAX_Y - 1 do
      if math.fmod(Y, 2) == 1 then startX(Y) end
      
      while not WT:canDown(true) do fetchAndDeposit() end
      Y = Y + 1
      saveState()
      WT:down(1, true)
      inspectSurroundings()

      if y == MAX_Y - 1 and math.fmod(Y, 2) == 1 then startX(Y) end
    end

  end

  function startX(Y)
    WT:turnLeft()

    for x = X, MAX_X - 2 do
      local _X = X
      if Y % 4 == 1 then _X = _X + 1 end
      if math.fmod(_X, 2) == 1 then startZ() end

      while not WT:canForward(true) do fetchAndDeposit() end
      X = X + 1
      saveState()
      WT:forward(1, true)
      inspectSurroundings()

      if x == MAX_X - 2 and math.fmod(_X + 1, 2) == 1 then startZ() end
    end

    WT:turnAround()

    for x = 0, X - 1 do
      while not WT:canForward(true) do fetchAndDeposit() end
      X = X - 1
      saveState()
      WT:forward(1, true)
    end

    WT:turnLeft()
  end

  function startZ()
    WT:turnRight()

    for z = Z, MAX_Z - 2 do
      while not WT:canForward(true) or WT:isInventoryOccupied() do fetchAndDeposit() end
      Z = Z + 1
      saveState()
      WT:forward(1, true)
      inspectSurroundings()
    end

    WT:turnAround()

    for z = 0, Z - 1 do
      while not WT:canForward() do fetchAndDeposit() end
      Z = Z - 1
      saveState()
      WT:forward(1, true)
    end

    WT:turnRight()
  end

  startY()
end


start()