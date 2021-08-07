-- Libraries
local utils = require("/lua/lib/utils")
local stateHandler = require("/lua/lib/stateHandler")

-- Exported table
local M = {}


local function getState()
  local state = stateHandler.getState("network")
  return state
end

local function saveState(devices)
  local state = stateHandler.updateState("network", devices)
  return state
end

function M.joinOrCreate(channel, isHost, device, onChange)
  local modem = peripheral.find("modem")
  local devices = getState() or {}
  if not utils.tableHasValue(devices, device) then
    table.insert(devices, device)
  end

  local function handleChange()
    saveState(devices)
    onChange(devices)
  end

  local function startListener()
    while true do
      local event, _, _, _, body = os.pullEvent()

      if event == "modem_message" then
        if isHost then
          if body.type == "/network/join" then
            if not utils.tableHasValue(devices, body.device) then
              table.insert(devices, body.device)
              modem.transmit(channel, channel, {
                type = "/network/update",
                devices = devices
              })
              handleChange()
            end
            modem.transmit(channel, channel, {
              type = "/network/join-res",
              devices = devices
            })
          end
        else
          if body.type == "/network/update" then
            devices = body.devices
            handleChange()
          end
        end
      end
    end
  end
  
  local function attemptJoinNetwork()
    local success = false

    local function join()
      print(" > Polling network on channel: "..channel)

      modem.transmit(channel, channel,
        {
              type = "/network/join",
              device = device
        }
      )

      print(" > Awaiting join response")

      while true do
        local event, _, _, _, body = os.pullEvent()
        if event == "modem_message" then
          if body.type == "/network/join-res" then
            print(" > Network joined")
            devices = body.devices
            handleChange()
            success = true
            break
          end
        end
      end
    end

    while not success do
      parallel.waitForAny(join,
        function()
          os.sleep(5)
        end
      )
    end
  end

  modem.open(channel)

  if isHost then
    handleChange()
  else
    attemptJoinNetwork()
  end

  startListener()

end

return M