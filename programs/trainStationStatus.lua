
--$ARGS|Channel (40)|Station Name (Unnamed)|$ARGS

-- Libraries
local setup = require("/lua/lib/setupUtils")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox
local fillBackground = monUtils.fillBackground

-- Args
local args = { ... }
local channel = tonumber(args[1]) or 40
local stationName = utils.urlDecode(args[2] or "Unnamed")

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
    monitor, 1, 1, monitor.x, 1
)
local winCurr = setup.setupWindow(
    monitor, 1, 2, monitor.x, 3
)
local winNext = setup.setupWindow(
    monitor, 1, 5, monitor.x, (monitor.y - (1 + 3)) 
)

-- Setup
local TRAINS = {}
local PREV_TRAIN = nil
local CURR_TRAIN = nil
local CURR_COUNTDOWN = 0
local NEXT_TRAINS = {}

function start()
  modem.open(channel)
  parallel.waitForAny(await)
end

function await()
  while true do
    parallel.waitForAny(awaitUpdate, drawAll)
  end
end

function awaitUpdate()
  local body = network.await("/trains/post/trains-state-update", false)

  TRAINS = body.trains

  PREV_TRAIN = CURR_TRAIN
  CURR_TRAIN = getCurrentTrain()
  NEXT_TRAINS = getNextTrains()
end

function getCurrentTrain()
  local train = utils.findInTable(TRAINS, function (train)
    return train.currentStationName == stationName
  end)

  return train
end

function getNextTrains()
  local trains = utils.filterTable(TRAINS, function (train)
    return train.nextStationName == stationName
  end)

  return trains
end

function getRouteEntry(train)
  if not train or not train.schedule.route then return false end
  local route = train.schedule.route

  return utils.findInTable(route, function (entry)
    return entry.stationName == stationName
  end)
end

function getCurrentRouteEntry()
  if not CURR_TRAIN or not CURR_TRAIN.schedule.route then return false end
  local route = CURR_TRAIN.schedule.route

  return utils.findInTable(route, function (entry)
    return entry.stationName == stationName
  end)
end

function getNextRouteEntries()
  if not CURR_TRAIN or not CURR_TRAIN.schedule.route then return false end
  local route = CURR_TRAIN.schedule.route

  local _, i = getCurrentRouteEntry()
  if not i then return nil end

  local prevEntries, nextEntries = utils.tableSplit(route, i, true)

  local entries = {}

  for _, entry in ipairs(nextEntries) do
    table.insert(entries, entry)
  end
  for _, entry in ipairs(prevEntries) do
    table.insert(entries, entry)
  end

  return entries
end

function drawAll()
  drawHeader()
  drawNext()
  drawCurrent()
end

function drawHeader()
  winHeader.bg = colors.orange
  winHeader.setBackgroundColor(winHeader.bg)

  fillBackground(winHeader, colors.orange)
  
  write(winHeader, stationName, 0, 1, "center", colors.black)
end

function drawCurrent()
  winCurr.bg = colors.black
  winCurr.setBackgroundColor(winCurr.bg)

  fillBackground(winCurr, colors.black)

  drawCurrentTrain()
end

function drawCurrentTrain()

  function drawLeftText(text)
    write(winCurr, text, 1, 2, "left", colors.orange, colors.black)
  end

  local trainName = CURR_TRAIN and CURR_TRAIN.name or nil
  local prevTrainName = PREV_TRAIN and PREV_TRAIN.name or nil

  if trainName then
    local routeEntry = getRouteEntry(CURR_TRAIN)

    drawLeftText(trainName)
    
    if routeEntry then
      local isNewTrain = prevTrainName ~= trainName

      CURR_COUNTDOWN = isNewTrain and routeEntry.delay or CURR_COUNTDOWN

      for i = CURR_COUNTDOWN, 0, -1 do
        CURR_COUNTDOWN = i
        fillBackground(winCurr, colors.black)

        drawLeftText(trainName)

        write(winCurr, i .. "s", 1, 2, "right", colors.orange, colors.black)
        os.sleep(1)
      end
    else
      while true do
        write(winCurr, "No Schedule", 1, 2, "right", colors.orange, colors.black)
        os.sleep(999)
      end
    end
  else
    
    local i = 1
    while true do
      fillBackground(winCurr, colors.black)
      drawLeftText("Waiting for next train" .. string.rep(".", i))
      os.sleep(1)
      i = i + 1
      if i > 3 then i = 1 end
    end
  end
end

function drawNext()
  winNext.bg = colors.black
  winNext.setBackgroundColor(winNext.bg)

  fillBackground(winNext, colors.black)

  if CURR_TRAIN then drawNextStations() else drawNextTrains() end
  
end

function drawNextStations()
  local nextStations = getNextRouteEntries()

  if not nextStations then
    return
  end

  drawBox(winNext, 1, 1, winNext.x, 1, true, colors.orange)
  write(winNext, "Next Stops", 0, 1, "center", colors.black, colors.orange)

  local noStations = utils.tableLength(nextStations) == 0
  if noStations then
    write(winNext, "No upcoming stops", 1, 3, "left", colors.orange, colors.black)
  else
    for i, entry in ipairs(nextStations) do
      local text = entry.stationName .. " (stops for " .. entry.delay .. "s)"
      write(winNext, text, 1, i + 2, "left", colors.orange, colors.black)
    end
  end
end

function drawNextTrains()
  drawBox(winNext, 1, 1, winNext.x, 1, true, colors.orange)
  write(winNext, "Next Trains", 0, 1, "center", colors.black, colors.orange)

  local noTrains = utils.tableLength(NEXT_TRAINS) == 0
  if noTrains then
    write(winNext, "No upcoming trains", 1, 3, "left", colors.orange, colors.black)
  else
    for i, train in ipairs(NEXT_TRAINS) do
      local text = train.name
      local routeEntry = getRouteEntry(train)
      if routeEntry then
        text = text .. " (stops for " .. routeEntry.delay .. "s)"
      end
      write(winNext, text, 1, i + 2, "left", colors.orange, colors.black)
    end
  end
end

start()