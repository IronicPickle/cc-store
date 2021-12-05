--$ARGS|Max Y (5)|$ARGS

-- Args
local args = { ... }
local MAX_Y = tonumber(args[1]) or 5

-- Libraries
local stateHandler = require("/lua/lib/stateHandler")
local WrappedTurtle = require("/lua/lib/WrappedTurtle")
local WT = WrappedTurtle:new(turtle)

-- Globals
local X = 0
local Z = 0
local Y = 0
local FIRST_TIME = true

-- Main
function start()
  print("# Program Started")

  -- Load and resume state if applicable
  loadState()
  WT:resume()

  -- First time refuel attempt
  if FIRST_TIME then takeFuel() takeSaplings() end
  FIRST_TIME = false
  saveState()

  WT:reorient()

  -- Main loop
  lumber()

  while true do sleep(100) end
end

function fetchAndDeposit()
  print("# Fetching and Despositing")

  WT:returnToTracker(true, { "x", "z", "y" })
  takeFuel()
  takeSaplings()
  depositInventory()
  WT:returnToTracker(true, { "y", "z", "x" })
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

function takeSaplings()
  print("# Taking Saplings")

  WT:turnAround()
  local attempts = 0
  while needsSaplings() do
    WT:suck(15, 64)
    if not needsSaplings() then break end
    attempts = attempts + 1
    if attempts == 1 then print("No saplings in chest, will retry every 10 seconds...") end
    sleep(10)
  end
  WT:reorient()
end

function depositInventory()
  print("# Depositing Inventory")

  WT:turnLeft()
  local attempts = 0
  WT:depositInventory(1, 14)
  while WT:isInventoryOccupied() do
    attempts = attempts + 1
    if attempts == 1 then print("Can't deposit inventory, will retry every 10 seconds...") end
    sleep(10)
    WT:depositInventory(1, 14)
  end
  WT:reorient()
end

function needsSaplings()
  return WT:getItemCount(15) <= 1
end

function saveState()
  local state = {
    x = X,
    y = Y,
    z = Z,
    firstTime = FIRST_TIME,
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
    print("# Loaded Lumberer State")
    print(textutils.serialize(state))
  end
  return not not state
end

function awaitGrowth()
  print("# Awaiting Growth")
  while WT:compare(15) do
    sleep(5)
  end
end

function lumber()
  
  while true do
    if WT.x == 0 then
      fetchAndDeposit()
    
      if not WT:inspect() then
        local attempts = 0
        while not WT:place(15) do
          attempts = attempts + 1
          if attempts == 1 then print("Can't place sapling, will retry every 10 seconds...") end
          sleep(10)
        end
      end

      awaitGrowth()
      
      while not WT:canForward(true) do fetchAndDeposit() end
      X = X + 1
      saveState()
      WT:forward(1, true)
    end

    for y = Y, MAX_Y do
      while not WT:canUp(true) do fetchAndDeposit() end
      Y = Y + 1
      saveState()
      WT:up(1, true)
    end

    for y = 0, Y do
      Y = Y - 1
      saveState()
      WT:down(1, true)
    end

    if X == 1 then
      X = X - 1
      WT:back(1)
      WT:place(15)
    end
  end

end


start()