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

function M.createButton(output, x, y, paddingX, paddingY, align, bgColor, textColor, text, onClick)
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

            if touchX >= x and touchY >= y and touchX <= dx and touchY <= dy then
                if onClick() then break end
            end
        end
    end
end

return M