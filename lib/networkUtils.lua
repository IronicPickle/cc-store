-- Exported table
local M = {}


function M.joinOrCreate(channel, device, onChange)
  local modem = peripheral.find("modem")
  local devices = {}
  local isHost = false

  local function startListener()
    while true do
      local event, _, _, _, body = os.pullEvent()

      if event == "modem_message" then
        if isHost then
          if body.type == "/network/join" then
            table.insert(devices, body.device)
            modem.transmit(channel, channel, {
              type = "network/update",
              devices = devices
            })
            onChange(devices)
          end
        else
          if body.type == "/network/update" then
            devices = body.devices
            onChange(devices)
          end
        end
      end

    end
  end
  
  local function attemptJoinNetwork()
    local function join()
      print(" > Attempting to join network on "..channel)
      modem.transmit(channel, channel,
        {
              type = "/network/join",
              device = device
        }
      )

      while true do
        local event, _, _, _, body = os.pullEvent()
        if event == "modem_message" then
          if body.type == "network/join-res" then
            devices = body.devices
            onChange(devices)
          end
        end
      end
    end

    parallel.waitForAny(join,
      function()
        os.sleep(5)
        print(" > No network fonund, assuming host... ")
        isHost = true
      end
    )
  end

  modem.open(channel)

  attemptJoinNetwork()
  if isHost then
    devices = { device }
    onChange(devices)
  end
  startListener()

  return isHost

end

return M