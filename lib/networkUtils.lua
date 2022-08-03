-- Libraries
local stateHandler = require("/lua/lib/stateHandler")

-- Exported table
local M = {}


local function deviceOnNetwork(devices, device)
  for _,v in ipairs(devices) do
      if v.id == device.id then return true end
  end
  return false
end

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
  if device then device.id = os.getComputerID() end
  local devices = {}
  if isHost then
    devices = getState() or {}
  end
  if device and not deviceOnNetwork(devices, device) then
    table.insert(devices, device)
  end

  local function handleChange()
    if isHost then saveState(devices) end
    if onChange then onChange(devices) end
  end

  local function startListener()
    while true do
      local event, key, _, _, body = os.pullEvent()

      if event == "modem_message" then
        if isHost then
          if body.type == "/network/join" then
            if not deviceOnNetwork(devices, body.device) then
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

        if body.type == "/network/reset" then
          print(" > Received network reset request")
          if isHost then saveState({}) end
          os.sleep(2)
          return
        end
      elseif event == "key_up" then
        if key == 261 then -- DEL key
          print(" > Sending network reset request")
          if isHost then saveState({}) end
          modem.transmit(channel, channel, {
            type = "/network/reset"
          })
          os.sleep(2)
          return
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

function M.await(type, timeout)
  local returnBody = nil

  local funcs = {}

  table.insert(funcs, function ()
    while true do
      local event, p1, p2, p3, p4, p5 = os.pullEvent()

      
      local isModemMessage = (event == "modem_message")
      
      if(isModemMessage) then
        local body = p4
        if(not type or body.type == type) then
          returnBody = body
        end
      end
    end
  end)

  

  if timeout ~= false then
    table.insert(funcs, function ()
      os.sleep(timeout or 5)
    end)
  end

  parallel.waitForAny(table.unpack(funcs))

  return returnBody
end

function M.transmit(modem, channel, body, timeout)
  parallel.waitForAny(function ()
    modem.transmit(channel, channel, body)
  end, function ()
    os.sleep(timeout or 5)
  end)
end

return M