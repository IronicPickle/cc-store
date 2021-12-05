--$ARGS|Max Y (5)|$ARGS

-- Args
local args = { ... }
local MAX_Y = tonumber(args[1]) or 5

-- Libraries
local stateHandler = require("/lua/lib/stateHandler")
local WrappedTurtle = require("/lua/lib/WrappedTurtle")
local WT = WrappedTurtle:new(turtle)

-- Globals
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

  takeFuel()
  takeSaplings()
  depositInventory()
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
  while true do
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
    y = Y,
    z = Z,
    firstTime = FIRST_TIME,
  }
  stateHandler.updateState("lumberer", state)
end

function loadState()
  local state = stateHandler.getState("lumberer")
  if state then
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
    if Z == 0 then
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
      Z = Z + 1
      saveState()
      WT:forward(1, true)
    end

    for y = Y, MAX_Y - 2 do
      while not WT:canUp(true) do fetchAndDeposit() end
      Y = Y + 1
      saveState()
      WT:up(1, true)
    end

    for y = 0, Y - 1 do
      Y = Y - 1
      saveState()
      WT:down(1, true)
    end

    if Z == 1 then
      Z = Z - 1
      WT:back(1)
      WT:place(15)
    end
  end

end


start()