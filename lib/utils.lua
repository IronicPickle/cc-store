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

return M