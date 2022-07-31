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

function M.createButton(output, x, y, xPadding, xPadding, bgColor, textColor, text)
    local dx = x + text.len() + (xPadding * 2)
    local dy = y + (xPadding * 2)
    
    M.drawBox(output, x, y, dx, dy, true, bgColor)
    M.write(output, text, x + math.floor(dx / 2), math.floor(dy / 2), nil, textColor, bgColor)
end

return M