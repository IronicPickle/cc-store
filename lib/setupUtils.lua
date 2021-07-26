-- Libraries
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
-- Exported table
local M = {}

function M.getPers(requiredPers)
    term.current().clear()
    term.current().setCursorPos(1, 2)
    print("# Peripheral Setup\n")
    
    print("- Required Peripherals:\n")
    print(unpack(requiredPers))
    
    local activePers = peripheral.getNames()
    local wrappedPers = {}
    local pers = {}
    
    for i, side in pairs(activePers) do
        local per = peripheral.wrap(side)
        local perName = peripheral.getType(side)
        
        if(wrappedPers[perName] == nil) then
            wrappedPers[perName] = {}
        end
        
        local indexTable = {}
        for ii, v in pairs(requiredPers) do
            indexTable[v] = ii
        end
        
        local perIndex = indexTable[perName]
        if(perIndex) then
            table.remove(requiredPers, perIndex)
            table.insert(pers, {
                tostring(i),
                perName,
                side
            })
        end
        
        table.insert(wrappedPers[perName], per)
    end
    
    print("\n- Wrapped Peripherals:\n")
    textutils.tabulate(unpack( pers ))
    print("\n")
    
    if(#requiredPers > 0) then
        error(
            "\nMissing peripherals - " ..
            table.concat(requiredPers, ", ")
        )
    end
    
    return wrappedPers
end

function M.setupMonitor(monitor, scale)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    if(scale) then
        monitor.setTextScale(scale)
    end
    monitor.setCursorPos(2, 2)
    local resX, resY = monitor.getSize()
    monitor.x = resX
    monitor.y = resY
    
    return monitor
    
end

function M.setupWindow(monitor, x, y, width, height)
    local win = window.create(
        monitor, x or 1, y or 1,
        width or monitor.x,
        height or monitor.y
    )
    win.setCursorPos(2, 2)
    local resX, resY = win.getSize()
    win.x = resX
    win.y = resY
    win.posX = x
    win.posY = y
    
    return win
    
end

function M.utilsWrapper(callback, modem, channel)
    parallel.waitForAny(callback, function()
        while(true) do
            local event, p1, p2, p3, p4, p5 = os.pullEvent()
            
            local isDelKey = (event == "key" and p1 == 211)
            
            local isModemMessage = (event == "modem_message")
            
            if(isDelKey) then
                if(modem and channel) then
                    modem.transmit(channel, channel,
                        {
                            type = "globalRestart"
                        }
                    )
                end
                break
            elseif(isModemMessage) then
                local body = p4
                if(body.type == "globalRestart") then
                    break
                end
            end
            
        end
    end)
    return
end

function M.setupNetwork(modem, channel, deviceData, output)
    output = output or M.setupMonitor(term.native())
    write(output,
        "# Network Setup #",
        0, 2, "centre"
    )
    write(output,
        "Channel: " .. channel,
        0, 4, "centre"
    )
    write(output,
        "No network found",
        0, 6, "centre"
    )
    write(output,
        "Press Enter or Right Click",
        0, 8, "centre"
    )
    write(output,
        "to create a network",
        0, 9, "centre"
    )
    
    modem.open(channel)
    modem.transmit(channel, channel,
        {
            type = "networkPoll",
            deviceData = deviceData
        }
    )
    
    while(true) do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        local isEnterKey = (event == "key" and p1 == 28)
        local isRightClick = (event == "mouse_click" and p1 == 2)
        local isTouch = (event == "monitor_touch")
        
        local isModemMessage = (event == "modem_message")
        
        if(isEnterKey or isRightClick or isTouch) then
            return createNetwork(modem, channel, deviceData, output)
        elseif(isModemMessage) then
            local body = p4
            if(body.type == "networkPollRes") then
                return joinNetwork(modem, channel, deviceData, output)
            elseif(body.type == "networkCreate") then
                modem.transmit(channel, channel,
                    {
                        type = "networkPoll",
                        deviceData = deviceData
                    }
                )
            end
        end
    end
end

function createNetwork(modem, channel, deviceData, output)
    local devices = { deviceData }

    printNetwork(devices, output)
    
    modem.transmit(channel, channel,
        {
            type = "networkCreate"
        }
    )
    
    while(true) do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        local isEnterKey = (event == "key" and p1 == 28)
        local isRightClick = (event == "mouse_click" and p1 == 2)
        local isTouch = (event == "monitor_touch")
        
        local isModemMessage = (event == "modem_message")
        
        if(isEnterKey or isRightClick or isTouch) then
            modem.transmit(channel, channel,
                {
                    type = "networkContinue",
                    devices = devices
                }
            )
            return devices
         elseif(isModemMessage) then
            local body = p4
            if(body.type == "networkPoll") then
                table.insert(devices, body.deviceData)
                printNetwork(devices, output)
                modem.transmit(channel, channel,
                    {
                        type = "networkPollRes"
                    }
                )
            end
        end
    end
end

function printNetwork(devices, output)
    output.clear()
    write(output,
        "# Network Setup #",
        0, 2, "centre"
    )
    write(output,
        "Network created",
        0, 4, "centre"
    )
    write(output,
        "Devices on Network: " .. #devices,
        0, 6, "centre"
    )
    write(output,
        "Press Enter or Right Click",
        0, 8, "centre"
    )
    write(output,
        "to continue",
        0, 9, "centre"
    )
end

function joinNetwork(modem, channel, deviceData, output)
    output.clear()
    write(output,
        "# Network Setup #",
        0, 2, "centre"
    )
    write(output,
        "Network joined",
        0, 4, "centre"
    )
    write(output,
        "Awaiting further response...",
        0, 6, "centre"
    )
    
    while(true) do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        local isModemMessage = (event == "modem_message")
        
        if(isModemMessage) then
            local body = p4
            if(body.type == "networkContinue") then
                return body.devices
            end
        end
    end
end

return M