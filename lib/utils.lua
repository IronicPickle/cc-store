local M = {}

function M.tableHasValue(tab, value)
  for _,v in ipairs(tab) do
      if v == value then return true end
  end
  return false
end

function M.concatTables(tab1, tab2)
  for i=1, #tab2 do
    tab1[#tab1+1] = tab2[i]
  end
  return tab1
end

function M.filterTable(tab, func)
  local newTab = {}
  for i=1, #tab do
    if func(tab[i], newTab) then
      newTab[#newTab+1] = tab[i]
    end
  end
  return newTab
end

function M.findInTable(tab, func)
  for i=1, #tab do
    if func(tab[i]) then
      return tab[i]
    end
  end
  return nil
end


function M.urlEncode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w ])", function(char) return string.format("%%%02X", string.byte(char)) end)
  url = url:gsub(" ", "+")
  return url
end

function M.urlDecode(url)
  if url == nil then
    return
  end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", function(char) return string.char(tonumber(char, 16)) end)
  return url
end

function M.capitalize(text)
  return text:gsub("^%l", string.upper)
end

return M