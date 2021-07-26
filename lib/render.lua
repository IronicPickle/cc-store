local setup = require("/lua/lib/setupUtils")
local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local drawBox = monUtils.drawBox

local M = {}

function renderButtons(output, buttons)
    for i, button in pairs(buttons) do
        drawBox(output,
            2, button.y,
            output.x, button.y,
            true, button.color
        )
        write(output,
            (button.text), 1, button.y, "centre",
            colors.white, button.color
        )
    end
end

M.setupWindows = function(output)
    local windows = {}
    local x = output.x - 36
    local y = output.y
    local xWindows = (x / 42)
    local yWindows = (y / 14) - 1
    
    for i = 0, yWindows, 1 do
        for ii = 0, xWindows, 1 do
            local winX = (ii * 42) + 1
            local winY = (i * 14) + 2
            
            local window = setup.setupWindow(
                output, winX, winY,
                36, 13
            )
            local controlWindow = setup.setupWindow(
                window, (window.x - 13), 1,
                14, window.y
            )
            
            table.insert(windows, {
                window = window,
                controlWindow = controlWindow
            })
        end
    end
    return windows
end

M.ender = function(outputsTable)

    local buttons = {
        { action = "toggle",
            y = 4, color = colors.blue,
            text = "Toggle"
        }, {action = "toggleAuto",
            y = 6, color = colors.blue,
            text = "Toggle Auto"
        }
    }
    
    for i, outputs in pairs(outputsTable) do
        local data = outputs.data
        local output = outputs.output
        local controlOutput = outputs.controlOutput
    
        output.clear()
        write(output,
            "Endergenic Unit: " .. data.num,
            1, 2, "left"
        )
        local msgs = {
            on = "Active",
            off = "Idle"
        }
        write(output,
            "State: " .. msgs[data.state],
            1, 4, "left"
        )
        write(output,
            "Average RF/t: " .. data.avgRFT,
            1, 7, "left"
        )
        
        msgs = {
            on = "Enabled",
            off = "Disabled"
        }
        write(output,
            "Auto: " .. msgs[data.auto],
            1, (output.y - 1), "left"
        )
        
        local bgs = {
            off = colors.purple,
            on = colors.cyan
        }
        
        controlOutput.bg = bgs[data.state]
        controlOutput.setBackgroundColor(controlOutput.bg)
        drawBox(controlOutput,
            1, 1, controlOutput.x, controlOutput.y,
            true
        )
        drawBox(controlOutput,
            1, 1, 1, controlOutput.y,
            true, colors.white
        )
        write(controlOutput,
            "Controls:",
            1, 2, "centre"
        )
    
        renderButtons(controlOutput, buttons)
        
    end
    
    return buttons
    
end

M.power = function(outputsTable)
    
    local buttons = {
        { action = "toggle",
            y = 4, color = colors.orange,
            text = "Toggle"
        }, { action = "toggleAuto",
            y = 6, color = colors.orange,
            text = "Toggle Auto"
        }
    }
    
    for i, outputs in pairs(outputsTable) do
        local data = outputs.data
        local output = outputs.output
        local controlOutput = outputs.controlOutput
        
        output.clear()
        write(output,
            data.energyType .. " Power Unit",
            1, 2, "left"
        )
        local msgs = {
            on = "Active",
            off = "Idle"
        }
        write(output,
            "State: " .. msgs[data.state],
            1, 4, "left"
        )
        
        local bgs = {
            off = colors.orange,
            on = colors.red
        }
        controlOutput.bg = bgs[data.state]
        controlOutput.setBackgroundColor(controlOutput.bg)
        drawBox(controlOutput,
            1, 1, controlOutput.x, controlOutput.y,
            true
        )
        drawBox(controlOutput,
            1, 1, 1, controlOutput.y,
            true, colors.white
        )
        write(controlOutput,
            "Controls:",
            1, 2, "centre"
        )
        
        renderButtons(controlOutput, buttons)
        
        
    end
    
end

return M