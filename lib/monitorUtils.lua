-- Libraries
local setup = require("/lua/lib/setupUtils")

-- Exported table
local M = {}

function M.write(output, text, x, y, align, textColor, bgColor)
    local prevTextColor = output.getTextColor()
    local prevBgColor = output.getBackgroundColor()
    
    if(textColor) then
        output.setTextColor(textColor)
    end
    if(bgColor) then
        output.setBackgroundColor(bgColor)
    end
    
    local len = text:len() - 2
    if(align == "center") then
        x = ( ( output.x - len ) / 2 ) + x
    elseif(align == "right") then
        x = output.x - len - x - 1
    elseif(align == "left") then 
        x = 1 + x
    end
    
    output.setCursorPos(x, y)
    output.write(text)
    
    output.setTextColor(prevTextColor)
    output.setBackgroundColor(prevBgColor)
    
end

function M.drawBox(output, x, y, dx, dy, filled, bgColor)
    local prevBgColor = output.getBackgroundColor()
    bgColor = bgColor or prevBgColor
    
    term.redirect(output)
    if(filled) then
        paintutils.drawFilledBox(
            x, y, dx, dy, bgColor
        )
    else
        paintutils.drawBox(
            x, y, dx, dy, bgColor
        )
    end
    term.redirect(term.native())
    output.setBackgroundColor(prevBgColor)
end

function M.createButton(output, x, y, paddingX, paddingY, align, bgColor, textColor, text, onClick, disabled)
    local len = text:len()
    
    if(align == "center") then
        x = ( ( output.x - (len + paddingX) ) / 2 ) + x
    elseif(align == "right") then
        x = output.x - (len + paddingX) - x
    elseif(align == "left") then
        x = x
    end

    local dx = x + len + (paddingX * 2) - 1
    local dy = y + (paddingY * 2)

    M.drawBox(output, x, y, dx, dy, true, bgColor)
    M.write(output, text, x + paddingX, y + paddingY, nil, textColor, bgColor)

    while true do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        local isTouch = (event == "monitor_touch")

        if isTouch then
            local touchX = p2 - output.posX + 1
            local touchY = p3 - output.posY + 1

            if touchX >= x and touchY >= y and touchX <= dx and touchY <= dy and not disabled then
                if onClick() then break end
            end
        end
    end
end

function M.fillBackground(output, bgColor)
    output.bg = bgColor
    output.setBackgroundColor(output.bg)
  
    M.drawBox(output,
        1, 1, output.x, output.y,
        true
    )
end

function M.createModal(output, title, bgColor, textColor, disabledColor, cancelButtonText, submitButtonText, buttons)
    M.fillBackground(output, bgColor)
    M.write(output, title, 0, 3, "center", textColor)

    local modalInner = setup.setupWindow(
        output, 2, 6, output.x - 2, output.y - 10
    )

    local action = nil

    local awaitButtonInput = buttons

    if not awaitButtonInput then
        awaitButtonInput = function(disabled)
            function createCancelButton()
                M.createButton(output, -6, output.y - 3, 2, 1, "center", bgColor, textColor, cancelButtonText or "Cancel", function ()
                action = "cancel"
                return true
                end)
            end
            function createSubmitButton()
                M.createButton(output, 6, output.y - 3, 2, 1, "center", disabled and disabledColor or textColor, bgColor, submitButtonText or "Create", function ()
                action = "submit"
                return true
                end, disabled)
            end
            
            parallel.waitForAny(createCancelButton, createSubmitButton)

            return action
        end
    end

    return modalInner, awaitButtonInput
end
return M