
--$ARGS|Channel (40)|Station Name (Unnamed)|$ARGS

-- Libraries
local setup = require("/lua/lib/setupUtils")
local stateHandler = require("/lua/lib/stateHandler")
local network = require("/lua/lib/networkUtils")
local utils = require("/lua/lib/utils")

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

function start()
  parallel.waitForAny(await)
end

function await()
  while true do
    awaitUpdate()
  end
end

function awaitUpdate()
  network.await("/trains/post/trains-state-update", false)

  local currentTrain = getCurrentTrain()
  local nextTrains = getNextTrains()

  print(currentTrain, nextTrains)
end

function getCurrentTrain()
  modem.transmit(channel, channel, {
    type = "/trains/get/station-current-train",
    stationName = stationName
  })

  local body = await("/trains/get/station-current-train-res/" .. stationName)

  return body and body.train or nil
end

function getNextTrains()
  modem.transmit(channel, channel, {
    type = "/trains/get/station-next-trains",
    stationName = stationName
  })

  local body = await("/trains/get/station-next-trains-res/" .. stationName)

  return body and body.trains or {}
end