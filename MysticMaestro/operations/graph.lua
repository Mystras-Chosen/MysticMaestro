local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local Graph = LibStub("LibGraph-2.0")

local MYSTIC_ENCHANTS = MYSTIC_ENCHANTS

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

local function createMysticEnchantData(enchantListingData, correction)
  local averageData, minimumData = {}, {}
  for timeStamp, buyouts in pairs(enchantListingData) do
    timeStamp = timeStamp - correction
    if #buyouts ~= 0 then
      table.insert(
        averageData,
        {
          timeStamp,
          averageBuyout(buyouts) -- convert copper to gold
        }
      )
      table.insert(
        minimumData,
        {
          timeStamp,
          minimumBuyout(buyouts) -- convert copper to gold
        }
      )
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

local secondsPerDay, secondsPerHour, secondsPerMinute = 86400, 3600, 60

local function getDayStartTime()
  local currentTime = time()
  local currentDateTime = date("%H %M %S", currentTime)
  local hours, minutes, seconds = currentDateTime:match("(%d+) (%d+) (%d+)")
  return currentTime - hours * secondsPerHour - minutes * secondsPerMinute - seconds
end

local function calcGridLineCorrection()
  return getDayStartTime() % secondsPerDay
end

local g

local function updateXAxisRange(correction)
  local rightBound = getDayStartTime() + secondsPerDay - correction
  local leftBound = rightBound - daysDisplayedInGraph * secondsPerDay
  g:SetXAxis(leftBound, rightBound)
end

local function getMaxBuyout(averageData)
  local maxBuyout = -1
  for _, point in ipairs(averageData) do
    maxBuyout = point[2] > maxBuyout and point[2] or maxBuyout
  end
  return maxBuyout
end

local function updateYAxisRange(averageData)
  if not averageData then
    g:SetYAxis(0, 100)
  else
    local maxBuyout = getMaxBuyout(averageData)
    g:SetYAxis(0, maxBuyout > 100 and maxBuyout or 100)
  end
end

local maxYAxisGridLines = 8

local function getYSpacing(averageData)
  local maxBuyout = getMaxBuyout(averageData)
  if maxBuyout < 100 then return 20 end
  local unprocessedYSpacing = maxBuyout / maxYAxisGridLines
  return unprocessedYSpacing % 10 ~= 0 and unprocessedYSpacing + 10 - unprocessedYSpacing % 10 or unprocessedYSpacing
end

function MM:InitializeGraph(name, parent, relative, relativeTo, offsetX, offsetY, width, height)
  if g then
    return
  end
  g = Graph:CreateGraphLine(name, parent, relative, relativeTo, offsetX, offsetY, width, height)
  g:SetYLabels(true)
  g:SetGridColor({0.5, 0.5, 0.5, 0.5})
  g:SetAxisDrawing(true, true)
  g:SetAxisColor({1, 1, 1, 1})
  g:SetGridSpacing(secondsPerDay, 20)
  updateXAxisRange(calcGridLineCorrection())
  g:SetYAxis(0, 100)
end

function MM:PopulateGraph(enchantID)
  g:ResetData()
  local enchantListingData = self.db.realm.RE_AH_LISTINGS[enchantID]
  if not next(enchantListingData) then
    self:Print('No listings found for mystic enchant "' .. MM.RE_NAMES[enchantID] .. '"')
    return
  end
  local correction = calcGridLineCorrection()
  local averageData, minimumData = createMysticEnchantData(enchantListingData, correction)
  sortData(averageData)
  sortData(minimumData)
  updateXAxisRange(correction)
  updateYAxisRange(averageData)
  g:AddDataSeries(averageData, {1.0, 0.0, 0.0, 0.8})
  g:AddDataSeries(minimumData, {0.0, 1.0, 0.0, 0.8})
  g:SetGridSpacing(secondsPerDay, getYSpacing(averageData))
end

function MM:ClearGraph()
  g:ResetData()
  g:SetGridSpacing(secondsPerDay, 20)
  updateYAxisRange()
end
