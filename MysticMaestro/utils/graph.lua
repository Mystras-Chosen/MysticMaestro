local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local Graph = LibStub("LibGraph-2.0")

local function createMysticEnchantData(enchantListingData, correction)
	local averageData, minimumData, maxData = {}, {}, {}
	for timeStamp, auctionList in pairs(enchantListingData) do
		timeStamp = timeStamp - correction
		local r
		if auctionList.Min then
			r = auctionList
		else
			r = MM:CalculateMarketValues(auctionList)
		end
		if #auctionList ~= 0 or auctionList.Min then
			table.insert(
				averageData,
				{
					timeStamp,
					r.Mean / 10000
				}
			)
			table.insert(
				minimumData,
				{
					timeStamp,
					r.Min / 10000
				}
			)
			table.insert(
				maxData,
				{
					timeStamp,
					r.Max / 10000
				}
			)
		end
	end
	return averageData, minimumData, maxData
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

MM.daysDisplayedInGraph = 10

local secondsPerDay, secondsPerHour, secondsPerMinute = 86400, 3600, 60

local function calcGridLineCorrection()
	return MM:DaysAgo(0) % secondsPerDay
end

local g

local function updateXAxisRange(correction)
	local rightBound = MM:DaysAgo(0) - correction
	local leftBound = rightBound - MM.daysDisplayedInGraph * secondsPerDay
	g:SetXAxis(leftBound, rightBound)
end

local function getMaxBuyout(averageData)
	local maxBuyout = -1
	for _, point in ipairs(averageData) do
		maxBuyout = point[2] > maxBuyout and point[2] or maxBuyout
	end
	return maxBuyout
end

local yBuffer = 1.1
local defaultYRange = 100

local function updateYAxisRange(maxData)
	if not maxData then
		g:SetYAxis(0, defaultYRange)
	else
		local maxBuyout = getMaxBuyout(maxData)
		g:SetYAxis(0, maxBuyout > defaultYRange / yBuffer and yBuffer * maxBuyout or defaultYRange)
	end
end

local maxYAxisGridLines = 8

local function getYSpacing(maxData)
	local maxBuyout = getMaxBuyout(maxData)
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

local function getOldListing(listingData, leftBoundMidnightTime)
	for timeKey, auctionList in pairs(listingData) do
		if timeKey < leftBoundMidnightTime and #auctionList > 0 then
			return timeKey, auctionList
		end
	end
end

local function getOldestListingTimeAndIndex(data)
	local oldestTimeIndex, oldestTime
	for i, point in ipairs(data) do
		if not oldestTimeIndex or point[1] < oldestTime then
			oldestTimeIndex = i
			oldestTime = point[1]
		end
	end
	return oldestTime, oldestTimeIndex
end

local function interpolatePoints(x0, y2, y1, x2, x1)
	local m = (y2 - y1) / (x2 - x1)
	return m * (x0 - x1) + y1
end

local function collectAndTransformData(enchantListingData, correction)
	local leftBoundMidnightTime = MM:DaysAgo(MM.daysDisplayedInGraph)
	local oldListingTime, oldListingBuyouts = getOldListing(enchantListingData, leftBoundMidnightTime)
	if oldListingTime then
		enchantListingData[oldListingTime] = nil
	else
		return createMysticEnchantData(enchantListingData, correction)
	end
	local averageData, minimumData, maxData = createMysticEnchantData(enchantListingData, correction)
	local oldListingAverageData, oldListingMinimumData, oldListingMaxData = createMysticEnchantData({[oldListingTime] = oldListingBuyouts}, correction)
	local leftBoundMidnightTimeCorrected = leftBoundMidnightTime - correction
	local x2 = oldListingTime - correction
	local x1, x1Index = getOldestListingTimeAndIndex(averageData)
	table.insert(averageData, {leftBoundMidnightTimeCorrected, interpolatePoints(leftBoundMidnightTimeCorrected, oldListingAverageData[1][2], averageData[x1Index][2], x2, x1)})
	table.insert(minimumData, {leftBoundMidnightTimeCorrected, interpolatePoints(leftBoundMidnightTimeCorrected, oldListingMinimumData[1][2], minimumData[x1Index][2], x2, x1)})
	table.insert(maxData, {leftBoundMidnightTimeCorrected, interpolatePoints(leftBoundMidnightTimeCorrected, oldListingMaxData[1][2], maxData[x1Index][2], x2, x1)})
	return averageData, minimumData, maxData
end

local function auctionDataExists(enchantListingData)
	local leftBoundMidnightTime = MM:DaysAgo(MM.daysDisplayedInGraph)
	for timeKey, auctionList in pairs(enchantListingData) do
		if timeKey >= leftBoundMidnightTime and (#auctionList > 0 or auctionList.Min) then
			return true
		end
	end
	return false
end

function MM:PopulateGraph(enchantID)
	g:ResetData()
	local cutoff = MM:DaysAgo(MM.daysDisplayedInGraph)
	local enchantListingData = {}
	for scanTime, auctionListString in pairs(self.data.RE_AH_LISTINGS[enchantID]) do
		enchantListingData[scanTime] = self:AuctionListStringToList(auctionListString)
	end
	for scanDate, auctionAvgString in pairs(self.data.RE_AH_STATISTICS[enchantID]["daily"] or {}) do
		if scanDate >= cutoff then
			enchantListingData[scanDate] = self:DeserializeScanAvg(auctionAvgString)
		end
	end

	if not auctionDataExists(enchantListingData) then
		return
	end
	local correction = calcGridLineCorrection()
	local averageData, minimumData, maxData = collectAndTransformData(enchantListingData, correction)
	sortData(averageData)
	sortData(minimumData)
	sortData(maxData)
	updateXAxisRange(correction)
	updateYAxisRange(maxData)
	g:AddDataSeries(maxData, {1.0, 0.0, 0.0, 0.8})
	g:AddDataSeries(averageData, {1.0, 1.0, 0.0, 0.8})
	g:AddDataSeries(minimumData, {0.0, 1.0, 0.0, 0.8})
	g:SetGridSpacing(secondsPerDay, getYSpacing(maxData))
end

function MM:ClearGraph()
	g:ResetData()
	g:SetGridSpacing(secondsPerDay, 20)
	updateYAxisRange()
end
