--$ARGS|Channel (40)|$ARGS

local WrappedTurtle = require("/lua/lib/WrappedTurtle")

local WT = WrappedTurtle:new(turtle)

-- Args

-- Main
function start()
  print("# Program Started")

  takeFuel()
  WT:down(7, true)
  WT:left(5, true)
  WT:right(5, true)
  WT:returnToTracker(true, { "x", "z", "y" })
  depositInventory()

  while true do sleep(10) end

end

function takeFuel()
  print("# Taking Fuel")

  WT:turnRight()
  WT:refuel(true)
  WT:reorient()
end

function depositInventory()
  print("# Depositing Inventory")

  WT:turnLeft()
  WT:depositInventory()
  WT:reorient()
end

function printInfo()
  print("orientation", WT.orientation, "x", WT.x, "y", WT.y, "z", WT.z)
end

start()