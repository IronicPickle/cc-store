
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
  parallel.waitForAny(joinNetwork, awaitNetwork, await)
end

function joinNetwork()
  local deviceData = {
    name = stationName
  }

  network.joinOrCreate(channel, false, deviceData)
end

function awaitNetwork()
  while true do
    local body = network.await()
  
    if(body.type == "/trains/get/station-destinations/" .. stationName) then
      local destinations = getDestinations()
      os.sleep(0.25)
      modem.transmit(channel, channel, {
        type = "/trains/get/station-destinations-res/" .. stationName,
        destinations = destinations
      })
    end
  end
end

function await()
  while true do
    awaitTrain()

    local nextRouteEntry = getNextRouteEntry()

    if not CURR_TRAIN then
      print("> Unknown Train arrived!")
    elseif nextRouteEntry == false then
      print("> " .. CURR_TRAIN.name .. " has no schedule, sending to train yard!")
      while true do
        os.pullEvent()
        if not checkIsTrainAtStation() then break end
      end
    elseif nextRouteEntry == nil then
      print("> " .. CURR_TRAIN.name .. " should not be at this station, sending to first station in schedule!")
      local nextDestination = getNextDestination(CURR_TRAIN.schedule.route[1].stationName)
      goToDesination(nextDestination)
    else
      print("> " .. CURR_TRAIN.name .. " has arrived" .. "\n")

      local nextDestination = getNextDestination(nextRouteEntry.stationName)

      print("> Waiting " .. tostring(nextRouteEntry.delay) .. " seconds")
      print("> Next Station: " .. nextRouteEntry.stationName .. "\n")

      os.sleep(nextRouteEntry.delay)
  
      goToDesination(nextDestination)
    end
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
      local trainName = readTransponder()
      CURR_TRAIN = getTrainInfo(trainName)
      break
    end

    os.pullEvent()
  end
end

function getTrainInfo(trainName)
  modem.transmit(channel, channel, {
    type = "/trains/get/train",
    trainName = trainName
  })

  local body = network.await("/trains/get/train-res")
  return body.train
end

function getCurrentRouteEntry()
  if not CURR_TRAIN or not CURR_TRAIN.schedule.route then return false end
  local route = CURR_TRAIN.schedule.route

  return utils.findInTable(route, function (entry)
    return entry.stationName == stationName
  end)
end

function getNextRouteEntry()
  if not CURR_TRAIN or not CURR_TRAIN.schedule.route then return false end
  local route = CURR_TRAIN.schedule.route

  local _, i = getCurrentRouteEntry()
  if not i then return nil end

  if i == utils.tableLength(route) then
    i = 1
  else
    i = i + 1
  end
  return route[i], i
end

function getNextDestination(trainName)
  local destinations = getDestinations()
  return utils.findInTable(destinations, function (destination)
    return destination.name == trainName
  end)
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