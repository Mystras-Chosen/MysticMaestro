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
        MM:Print("\"" .. enchantName .. "\" is not a valid mystic enchant")
        return false
    end
    if not next(MM.db.realm.RE_AH_LISTINGS[enchantName]) then
        MM:Print("No listings found for mystic enchant \"" .. enchantName .. "\"")
        return false
    end
    return true
end

local g = Graph:CreateGraphLine("MysticEnchantStatsGraph",UIParent,"CENTER","CENTER",90,90,500,150)
g:SetXAxis(0,1)
g:SetYLabels(true)
g:SetGridColor({0.5,0.5,0.5,0.5})
g:SetAxisDrawing(true,true)
g:SetAxisColor({1, 1, 1, 1})
g:Hide()

local function averageBuyout(buyouts)
    local sum = 0
    for _, buyout in ipairs(buyouts) do
        sum = sum + buyout
    end
    return sum / #buyouts
end

local function createMysticEnchantData(enchantListingData)
    local data = {}
    local firstTime, lastTime
    for k in pairs(enchantListingData) do
        firstTime = (not firstTime or firstTime > k) and k or firstTime
        lastTime = (not lastTime or lastTime < k) and k or lastTime
    end
    local timeRange = lastTime - firstTime
    for timeStamp, buyouts in pairs(enchantListingData) do
        local dataEntry = {
            (timeStamp - firstTime) / timeRange,
            averageBuyout(buyouts) / 10000 -- convert copper to gold
        }
        table.insert(data, dataEntry)
    end
    return data
end

local function sortData(data)
    -- TODO: need to sort the data by it's x value or the graph looks weird
    -- selection sort
    local temp, currentMin, currentMinIndex
    for i=1, #data do
        for j=i, #data do
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

local function updateYAxis(data)
    local maxBuyout = -1
    for _, point in ipairs(data) do
        maxBuyout = point[2] > maxBuyout and point[2] or maxBuyout
    end
    g:SetYAxis(0, maxBuyout > 100 and maxBuyout or 100)
    g:SetGridSpacing(0, 20)
end

local function drawGraph(enchantListingData)
    g:Show()
    g:ResetData()
    local data = createMysticEnchantData(enchantListingData)
    sortData(data)
    for _, v in ipairs(data) do print(v[1], v[2]) end
    g:AddDataSeries(data, {1.0,0.0,0.0,0.8})
    updateYAxis(data)
end

function MM:HandleGraph(enchantName)
    if enchantName:lower() == "hide" then
        g:Hide()
        return
    end
    if validateEnchant(enchantName) then
        drawGraph(MM.db.realm.RE_AH_LISTINGS[enchantName])
    end
end