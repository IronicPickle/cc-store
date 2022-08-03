--$ARGS|Channel (40)|$ARGS

-- Libraries
local setup = require("/lua/lib/setupUtils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox
local fillBackground = monUtils.fillBackground
local createButton = monUtils.createButton
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")
local trainUtils = require("/lua/lib/trains/trainUtils")
local stationUtils = require("/lua/lib/trains/stationUtils")
local scheduleUtils = require("/lua/lib/trains/scheduleUtils")

-- Args
local args = { ... }
local channel = tonumber(args[1]) or 40

-- Peripherals
local wrappedPers = setup.getPers({
  "modem",
  "monitor"
})
local modem = wrappedPers.modem[1]
local monitor = setup.setupMonitor(
    wrappedPers.monitor[1], 0.5
)

-- Windows
local winHeader = setup.setupWindow(
    monitor, 1, 1, monitor.x, 6
)
local winFooter = setup.setupWindow(
    monitor, 1, (monitor.y - 5), monitor.x, 6
)
local winMain = setup.setupWindow(
    monitor, 1, 7, monitor.x, (monitor.y - (6 + 6)) 
)

-- Setup
local STATIONS = {}
local TRAINS = stateHandler.getState("trains") or {}
local MODE = "stations"
local NETWORK_JOINED = false

function start()
  parallel.waitForAny(joinNetwork, await)
end

function joinNetwork()
  network.joinOrCreate(channel, true, nil, function (devices)
    NETWORK_JOINED = true
    STATIONS = devices
    if MODE == "stations" then stationUtils.drawStations(winMain, STATIONS) end
  end)
end

function await()
  parallel.waitForAny(drawAll, awaitNetwork)
end

function awaitNetwork()
  waitForNetwork()
  while true do
    local body = network.await(nil, false)

    if body.type == "/trains/get/train" then
      local trainName = body.trainName
      local train = utils.findInTable(TRAINS, function (train)
        return train.name == trainName
      end)
      os.sleep(0.25)
      modem.transmit(channel, channel, {
        type = "/trains/get/train-res/" .. body.stationName,
        train = train
      })
    elseif body.type == "/trains/get/fallback-station" then
      local station = utils.findInTable(STATIONS, function (train)
        return train.isFallback
      end)
      os.sleep(0.25)
      modem.transmit(channel, channel, {
        type = "/trains/get/fallback-station-res/" .. body.stationName,
        station = station
      })
    elseif body.type == "/trains/get/station-current-train" then
      local train = utils.findInTable(TRAINS, function (train)
        return train.currentStationName == body.stationName
      end)
      os.sleep(0.25)
      modem.transmit(channel, channel, {
        type = "/trains/get/station-current-train-res/" .. body.stationName,
        train = train
      })
    elseif body.type == "/trains/get/station-next-trains" then
      local trains = utils.filterTable(TRAINS, function (train)
        return train.nextStationName == body.stationName
      end)
      os.sleep(0.25)
      modem.transmit(channel, channel, {
        type = "/trains/get/station-next-trains-res/" .. body.stationName,
        trains = trains
      })
    elseif body.type == "/trains/post/train-arrived" then
      trainArrived(body.trainName, body.stationName)
    elseif body.type == "/trains/post/train-departed" then
      trainDeparted(body.trainName, body.stationName)
    end
  end
end

function waitForNetwork()
  while not NETWORK_JOINED do
    os.pullEvent()
  end
end

function getRouteEntry(train, stationName)
  if not train or not train.schedule.route then return false end
  local route = train.schedule.route

  return utils.findInTable(route, function (entry)
    return entry.stationName == stationName
  end)
end

function getNextRouteEntry(train, stationName)
  if not train or not train.schedule.route then return false end
  local route = train.schedule.route

  local _, i = getRouteEntry(train, stationName)
  if not i then return nil end

  if i == utils.tableLength(route) then
    i = 1
  else
    i = i + 1
  end
  return route[i], i
end

function getTrainFromState(trainName)
  local train, i = utils.findInTable(TRAINS, function (train)
    return train.name == trainName
  end)

  return train, i
end

function updateTrainsCurrentStation(trainName, stationName)
  local train, i = getTrainFromState(trainName)
  if not train then
    print("> Could state of " .. trainName .. ". Train not found in state.")
    return
  end
  
  TRAINS[i].currentStationName = stationName
  stateHandler.updateState("trains", TRAINS)
end

function updateTrainsNextStation(trainName, stationName)
  local train, i = getTrainFromState(trainName)
  if not train then
    print("> Could state of " .. trainName .. ". Train not found in state.")
    return
  end
  
  local nextRouteEntry = getNextRouteEntry(train, stationName)

  if not nextRouteEntry then
    print("> Could not update next station of " .. trainName .. ". Next station in route not found.")
    return
  end

  TRAINS[i].nextStationName = nextRouteEntry.stationName
  stateHandler.updateState("trains", TRAINS)

  return nextRouteEntry.stationName
end

function trainArrived(trainName, stationName)
  print("<=> " .. trainName .. " arrived at " .. stationName .. ".")
  
  updateTrainsCurrentStation(trainName, stationName)
  local nextStationName = updateTrainsNextStation(trainName, stationName)

  modem.transmit(channel, channel, {
    type = "/trains/post/trains-state-update"
  })
  print("<#> Next station: " .. nextStationName .. "\n")
end

function trainDeparted(trainName, stationName)
  print("<=> " .. trainName .. " departed from " .. stationName .. ".")
  
  updateTrainsCurrentStation(trainName, nil)
  local nextStationName = updateTrainsNextStation(trainName, stationName)

  modem.transmit(channel, channel, {
    type = "/trains/post/trains-state-update"
  })
  print("<#> Next station: " .. nextStationName .. "\n")
end

function drawAll()
  while true do
    drawHeader()
    parallel.waitForAny(drawFooter, drawMain)
  end
end

function drawHeader()
  winHeader.bg = colors.green
  winHeader.setBackgroundColor(winHeader.bg)
  
  drawBox(winHeader,
      1, 1, winHeader.x, winHeader.y,
      true
  )
  drawBox(winHeader,
      1, winHeader.y, winHeader.x, winHeader.y,
      true, colors.white
  )
  
  write(winHeader, "Train Controller", 0, 2, "center")
  write(winHeader, "Mode: " .. utils.capitalize(MODE), 0, 4, "center")
end

function drawFooter()
  winFooter.bg = colors.green
  winFooter.setBackgroundColor(winFooter.bg)
  
  drawBox(winFooter,
    1, 1, winFooter.x, winFooter.y,
    true
  )
  drawBox(winFooter,
    1, 1, winFooter.x, 1,
    true, colors.white
  )
  
  local createViewStationsButton = function()
    createButton(winFooter, 3, 3, 2, 1, "left", colors.white, colors.green, "Stations", function ()
      MODE = "stations"
      return true
    end)
  end
  
  local createViewTrainsButton = function()
    createButton(winFooter, 0, 3, 2, 1, "center", colors.white, colors.green, "Trains", function ()
      MODE = "trains"
      return true
    end)
  end
  
  local createSchedulesButton = function()
    createButton(winFooter, 3, 3, 2, 1, "right", colors.white, colors.green, "Schedules", function ()
      MODE = "schedules"
      return true
    end)
  end

  parallel.waitForAny(createViewStationsButton, createViewTrainsButton, createSchedulesButton)
end

function drawMain()

  local drawFunctions = {
    stations = function ()
      stationUtils.drawStations(winMain, STATIONS, channel)
    end,
    trains = function ()
      trainUtils.drawTrains(winMain, TRAINS)
    end,
    schedules = function ()
      scheduleUtils.drawSchedules(winMain, TRAINS, STATIONS, modem, channel)
    end,
  }

  drawFunctions[MODE]()


  while true do
    os.pullEvent()
  end

end

function drawSchedules()
  fillBackground(winMain, colors.black)
end

setup.utilsWrapper(start, modem, channel)