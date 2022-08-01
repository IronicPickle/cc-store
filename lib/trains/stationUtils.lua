local monUtils = require("/lua/lib/monitorUtils")
local write = monUtils.write
local fillBackground = monUtils.fillBackground

local M = {}

function M.drawStations(output, stations)
  fillBackground(output, colors.black)

  for i, station in pairs(stations) do
    write(output, "<#> " .. station.name, 3, i * 2 + 1, "left", colors.white)
  end
end

return M