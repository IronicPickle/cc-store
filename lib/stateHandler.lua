local M = {}

function constructPath(fileName)
    return "/lua/state/" .. fileName .. ".state"
end

M.updateState = function(fileName, data)
    local filePath = constructPath(fileName)
    if(not fs.isDir("/lua/state")) then
        fs.makeDir("/lua/state")
    end
    
    local file = fs.open(filePath, "w")
    file.write(textutils.serialize(data))
    file.close()
    
end

M.getState = function(fileName)
    local filePath = constructPath(fileName)
    local data = nil
    if(fs.exists(filePath)) then
        local file = fs.open(filePath, "r")
        data = textutils.unserialise(file.readAll())
        file.close()
    end
    return data
end

return M