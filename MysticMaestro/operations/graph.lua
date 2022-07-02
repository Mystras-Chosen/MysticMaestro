local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local Graph = LibStub("LibGraph-2.0")

local MYSTIC_ENCHANTS = MYSTIC_ENCHANTS

local function validateEnchant(enchantName)
  local enchantFound = false
  for _, enchantData in pairs(MYSTIC_ENCHANTS) do
    if enchantData.spellName == enchantName then
      enchantFound = true
      break
    end
  end
  if not enchantFound then
    MM:Print('"' .. enchantName .. '" is not a valid mystic enchant')
    return false
  end
  if not next(MM.db.realm.RE_AH_LISTINGS[enchantName]) then
    MM:Print('No listings found for mystic enchant "' .. enchantName .. '"')
    return false
  end
  return true
end

local g = Graph:CreateGraphLine("MysticEnchantStatsGraph", UIParent, "CENTER", "CENTER", 90, 90, 396, 181)
g:SetYLabels(true)
g:SetGridColor({0.5, 0.5, 0.5, 0.5})
g:SetAxisDrawing(true, true)
g:SetAxisColor({1, 1, 1, 1})
g:Hide()

local function averageBuyout(buyouts)
  local sum = 0
  for _, buyout in ipairs(buyouts) do
    sum = sum + buyout
  end
  return sum / #buyouts
end

local function minimumBuyout(buyouts)
  local minimum
  for _, buyout in ipairs(buyouts) do
    minimum = (not minimum or buyout < minimum) and buyout or minimum
  end
  return minimum
end

local function createMysticEnchantData(enchantListingData)
  local averageData, minimumData = {}, {}
  for timeStamp, buyouts in pairs(enchantListingData) do
    if #buyouts ~= 0 then
      table.insert(averageData, {
        timeStamp,
        averageBuyout(buyouts) / 10000 -- convert copper to gold
      })
      table.insert(minimumData, {
        timeStamp,
        minimumBuyout(buyouts) / 10000 -- convert copper to gold
      })
    end
  end
  return averageData, minimumData
end

local function sortData(data)
  local temp, currentMin, currentMinIndex
  for i = 1, #data do
    for j = i, #data do
      if not currentMin or currentMin[1] > data[j][1] then
        currentMin = data[j]
        currentMinIndex = j
      end
    end
    temp = data[i]
    data[i] = currentMin
    data[currentMinIndex] = temp
    currentMin = nil
  end
end

local daysDisplayedInGraph = 10

local function shiftGraphForGridLineAlignment(averageData, minimumData, leftBound, rightBound)
    local correction = rightBound % 86400
    rightBound = rightBound - correction
    leftBound = leftBound - correction
    g:SetXAxis(leftBound, rightBound)
    for i=1, #averageData do
      averageData[i][1] = averageData[i][1] - correction
      minimumData[i][1] = minimumData[i][1] - correction
    end
    return leftBound, rightBound
end

local function updateXAxisRange(averageData, minimumData)
  local currentTime = time()
  local currentDateTime = date("%H %M %S", currentTime)
  local hours, minutes, seconds = currentDateTime:match("(%d+) (%d+) (%d+)")
  local rightBound = currentTime - hours * 3600 - minutes * 60 - seconds + 86400
  local leftBound = rightBound - daysDisplayedInGraph * 86400
  return shiftGraphForGridLineAlignment(averageData, minimumData, leftBound, rightBound)
end

local function updateYAxisRange(averageData)
  local maxBuyout = -1
  for _, point in ipairs(averageData) do
    maxBuyout = point[2] > maxBuyout and point[2] or maxBuyout
  end
  g:SetYAxis(0, maxBuyout > 100 and maxBuyout or 100)
end

local function drawGraph(enchantListingData)
  g:Show()
  g:ResetData()
  local averageData, minimumData = createMysticEnchantData(enchantListingData)
  sortData(averageData)
  sortData(minimumData)
  updateXAxisRange(averageData, minimumData)
  updateYAxisRange(averageData)
  g:AddDataSeries(averageData, {1.0, 0.0, 0.0, 0.8})
  g:AddDataSeries(minimumData, {0.0, 1.0, 0.0, 0.8})
  g:SetGridSpacing(86400, 20)
end

function MM:HandleGraph(enchantName)
  if enchantName:lower() == "hide" then
    g:Hide()
    return
  end
  if validateEnchant(enchantName) then
    drawGraph(MM.db.realm.RE_AH_LISTINGS[enchantName])
    return g
  end
end
