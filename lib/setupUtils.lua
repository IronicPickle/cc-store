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
end


return M