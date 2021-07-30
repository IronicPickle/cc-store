-- Exported table
local M = {}


function M.joinOrCreate(channel, isHost, device, onChange)
  local modem = peripheral.find("modem")
  local devices = { device }

  local function startListener()
    while true do
      local event, _, _, _, body = os.pullEvent()

      if event == "modem_message" then
        if isHost then
          if body.type == "/network/join" then
            table.insert(devices, body.device)
            modem.transmit(channel, channel, {
              type = "/network/join-res",
              devices = devices
            })
            modem.transmit(channel, channel, {
              type = "/network/update",
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
            onChange(devices)
            break
          end
        end
      end
    end

    while true do
      parallel.waitForAny(join,
        function()
          os.sleep(5)
        end
      )
    end
  end

  modem.open(channel)


  if isHost then
    onChange(devices)
  else
    attemptJoinNetwork()
  end

  startListener()

end

return M