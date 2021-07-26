-- Exported table
local M = {}

function M.write(output, text, x, y, centre, textColor, bgColor)
    local prevTextColor = output.getTextColor()
    local prevBgColor = output.getBackgroundColor()
    
    if(textColor) then
        output.setTextColor(textColor)
    end
    if(bgColor) then
        output.setBackgroundColor(bgColor)
    end
    
    local len = text:len() - 2
    if(centre == "centre") then
        x = ( ( output.x - len ) / 2 ) + x
    elseif(centre == "right") then
        x = output.x - len - x - 1
    elseif(centre == "left") then 
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

return M