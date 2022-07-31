
--$ARGS|Channel (40)|Station Name (Unnamed)|Status Redstone Input (right)|Train Transponder Item (minecraft:paper)|$ARGS

-- Libraries
local setup = require("/lua/lib/setupUtils")
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")

-- Args
local args = { ... }
local channel = tonumber(args[1]) or 40
local stationName = utils.urlDecode(args[2] or "Unnamed")
local statusRedstoneInput = args[3] or "right"
local transponderItem = args[4] or "minecraft:paper"

-- Peripherals
local wrappedPers = setup.getPers({
  "modem",

  "create:track_station",
  "minecraft:chest",

  "create:portable_storage_interface"
})
local modem = wrappedPers.modem[1]

local trackStation = wrappedPers["create:track_station"][1]
local chest = wrappedPers["minecraft:chest"][1]

local storageInterface = wrappedPers["create:portable_storage_interface"][1]

-- Setup
local DESTINATIONS = {}
local CURR_TRAIN = nil

function start()
  parallel.waitForAny(joinNetwork, await)

end

function joinNetwork()
  local deviceData = {
    stationName = stationName
  }

  network.joinOrCreate(channel, false, deviceData)
end

function await()
  while true do
    awaitTrain()

    print("> " .. CURR_TRAIN .. " has arrived" .. "\n")

    goToDesination(selectDestination())
  end
end

function checkIsTrainAtStation()
  return redstone.getInput(statusRedstoneInput)
end

function readTransponder()
  print("> Reading train's transponder\n")
  local items = storageInterface.list()

  for slot, item in pairs(items) do
    if item.name == transponderItem and item.nbt then
      local displayName = storageInterface.getItemDetail(slot).displayName
      if displayName then return displayName end
    end
  end

  return nil;
end

function awaitTrain()
  print("> Awaiting next train...\n")

  CURR_TRAIN = nil

  while true do
    if checkIsTrainAtStation() then
      print("> Detected train at station")
      CURR_TRAIN = readTransponder()
      if CURR_TRAIN == nil then
        print("> Cannot identity train\n")
        CURR_TRAIN = "Unknown Train"
      end
      break
    end
    
    os.pullEvent()
  end
end

function getDestinations()
  DESTINATIONS = {}

  for slot, item in pairs(chest.list()) do

    if item.name == "create:schedule" then
      local displayName = chest.getItemDetail(slot).displayName
      if displayName then
        table.insert(DESTINATIONS, {
          name = displayName,
          slot = slot
        })
      end
    end
  end
  
  return DESTINATIONS
end

function selectDestination()
  print("# Destinations:")

  getDestinations()

  for k, destination in ipairs(DESTINATIONS) do
    print(destination.slot .. " - " .. destination.name)
  end

  print("\n# Select a destination")

  local slot = tonumber(read())

  return utils.findInTable(DESTINATIONS, function(destination) return destination.slot == slot end)
end

function goToDesination(destination)
  print("> Sending train to " .. destination.name .. "\n")

  chest.pushItems(peripheral.getName(trackStation), destination.slot, 1, 1)
  os.sleep(1)

  if checkIsTrainAtStation() then
    print("> Train stalled, waiting...\n")
    while checkIsTrainAtStation() do os.pullEvent() end
  end

  print("> Train departed\n")
end

setup.utilsWrapper(start, modem, channel)