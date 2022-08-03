
--$ARGS|Channel (40)|Station Name (Unnamed)|$ARGS

-- Libraries
local setup = require("/lua/lib/setupUtils")
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox
local fillBackground = monUtils.fillBackground
local createButton = monUtils.createButton

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
local monitor = wrappedPers.monitor[1]

-- Windows
local winHeader = setup.setupWindow(
    monitor, 1, 1, monitor.x, 2
)
local winMain = setup.setupWindow(
    monitor, 1, 2, monitor.x, (monitor.y - 2) 
)

-- Setup
local CURR_TRAIN = nil
local NEXT_TRAINS = {}

function start()
  modem.open(channel)
  parallel.waitForAny(await)
end

function await()
  while true do
    awaitUpdate()
  end
end

function awaitUpdate()
  network.await("/trains/post/trains-state-update", false)

  CURR_TRAIN = getCurrentTrain()
  NEXT_TRAINS = getNextTrains()

  drawAll()
end

function getCurrentTrain()
  modem.transmit(channel, channel, {
    type = "/trains/get/station-current-train",
    stationName = stationName
  })

  local body = network.await("/trains/get/station-current-train-res/" .. stationName)

  return body and body.train or nil
end

function getNextTrains()
  modem.transmit(channel, channel, {
    type = "/trains/get/station-next-trains",
    stationName = stationName
  })

  local body = network.await("/trains/get/station-next-trains-res/" .. stationName)

  return body and body.trains or {}
end

function drawAll()
  drawHeader()
  drawMain()
end

function drawHeader()
  winHeader.bg = colors.green
  winHeader.setBackgroundColor(winHeader.bg)
  
  drawBox(winHeader,
      1, 1, winHeader.x, 1,
      true
  )
  
  write(winHeader, stationName, 0, 2, "center")
end

function drawMain()
  winMain.bg = colors.green
  winMain.setBackgroundColor(winMain.bg)
  
  drawBox(winMain,
      1, 1, winMain.x, 1,
      true
  )
end

start()