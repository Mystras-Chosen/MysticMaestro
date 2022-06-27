local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local validScanOptions = {
	uncommon = true,
	rare = true,
	epic = true,
	legendary = true,
	all = true
}

local function scanOptionsToString()
	local result = ""
	for option in pairs(validScanOptions) do
		result = result .. " "
	end
	return result
end

local function getAllOperations()
	local all = {}
	for qualityName, active in pairs(validScanOptions) do
		if active and qualityName ~= "all" then
			table.insert(all, qualityName)
		end
	end
	return all
end

local function parseScanQualities(slowScanParams)
	local scanQualityNames = {}
	for t in slowScanParams:gmatch("(%w+)") do
		if not validScanOptions[t:lower()] then
			MM:Print(string.format('Scan option "%s" is invalid. Valid options: %s', t:lower(), scanOptionsToString()))
			return false
		end
		if t:lower() == "all" then
			return getAllOperations()
		else
			table.insert(scanQualityNames, t)
		end
	end
	return scanQualityNames
end

local function validateSlowScanParams(slowScanParams)
	if not slowScanParams or slowScanParams == "" then
		MM:Print(string.format("No scan option specified. Valid options: %s", scanOptionsToString()))
		return false
	end
	return parseScanQualities(slowScanParams)
end

local queue

local function createQueue(scanQualityNames)
	queue = {}
	for _, qualityName in ipairs(scanQualityNames) do
		local enchants = MM:GetAlphabetizedEnchantList(qualityName)
		for _, enchant in ipairs(enchants) do
			table.insert(queue, enchant)
		end
	end
end

local function getStartingIndex(queue, qualityName)
	local lastEnchantScanned = MM.db.realm["LAST_" .. qualityName:upper() .. "_ENCHANT_SCANNED"]
	if lastEnchantScanned then
		for i = 1, #queue do
			if queue[i] == lastEnchantScanned then
				return i % #queue + 1
			end
		end
	else
		return 1
	end
end

local scanQualityNames, currentScanQualityIndex, currentScanQuality
local startingIndex, currentIndex
local slowScanInProgress

local function initializeScan(scanQualityNames)
	createQueue(scanQualityNames)
	currentScanQualityIndex = 1
	currentScanQuality = scanQualityNames[currentScanQualityIndex]
	startingIndex = getStartingIndex(queue, currentScanQuality)
	currentIndex = startingIndex
	slowScanInProgress = true
end

local function performScan(currentIndex)
	QueryAuctionItems(queue[currentIndex], 15, 15, 0, 0, 3, false, true, nil)
end

function MM:HandleSlowScan(slowScanParams)
	if not self:ValidateAHIsOpen() then
		return
	end
	scanQualityNames = validateSlowScanParams(slowScanParams)
	if scanQualityNames and not CanSendAuctionQuery() then
		MM:Print("Scan not ready. Wait a moment and try again.")
	elseif scanQualityNames then
		initializeScan(scanQualityNames)
		performScan(currentIndex)
	end
end

local scanPending, retryTime, retrying

local function clearRetryFlag()
	if retrying then
		retryTime = nil
		retrying = nil
	end
end

local function printScanProgress(scanSuccessful)
	MM:Print(string.format("%s: %d/%d %s",
	queue[currentIndex],
	(currentIndex + #queue - startingIndex) % #queue + 1,
	#queue,
	scanSuccessful and "" or "None Listed"))
end

local function recordLastQualityEnchantScanned()
	MM.db.realm["LAST_" .. currentScanQuality:upper() .. "_ENCHANT_SCANNED"] = queue[currentIndex]
end

local function updateScanDetails()
	if not MM[currentScanQuality:upper() .. "_ENCHANTS"][queue[currentIndex]] then
		currentScanQualityIndex = currentScanQualityIndex % #scanQualityNames + 1
		currentScanQuality = scanQualityNames[currentScanQualityIndex]
	end
end

function MM:Slowscan_AUCTION_ITEM_LIST_UPDATE()
	if slowScanInProgress then
		local scanSuccessful = self:CollectAuctionData(time(), queue[currentIndex])
		if scanSuccessful or retrying then
			clearRetryFlag()
			printScanProgress(scanSuccessful)
			recordLastQualityEnchantScanned()
			currentIndex = currentIndex % #queue + 1

			if currentIndex ~= startingIndex then
				updateScanDetails()
				scanPending = true
			else
				self:Print("Slow scan finished")
				slowScanInProgress = false
			end
		elseif not retryTime then
			retryTime = GetTime()
		end
	end
end

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", "Slowscan_AUCTION_ITEM_LIST_UPDATE")

local function onUpdate()
	if scanPending and CanSendAuctionQuery() then
		scanPending = false
		performScan(currentIndex)
	elseif retryTime and GetTime() - retryTime > .2 then
		retrying = true
		performScan(currentIndex)
	end
end

MM.OnUpdateFrame:HookScript("OnUpdate", onUpdate)
