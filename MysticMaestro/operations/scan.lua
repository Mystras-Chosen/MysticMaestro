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

local function parseScanQualities(scanParams)
	local scanQualityNames = {}
	for t in scanParams:gmatch("(%w+)") do
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

local function validateScanParams(scanParams)
	if not scanParams or scanParams == "" then
		MM:Print(string.format("No scan option specified. Valid options: %s", scanOptionsToString()))
		return false
	end
	return parseScanQualities(scanParams)
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
local scanInProgress

local function initializeScan(scanQualityNames)
	createQueue(scanQualityNames)
	currentScanQualityIndex = 1
	currentScanQuality = scanQualityNames[currentScanQualityIndex]
	startingIndex = getStartingIndex(queue, currentScanQuality)
	currentIndex = startingIndex
	scanInProgress = true
end

local function performScan(currentIndex)
	QueryAuctionItems(queue[currentIndex], 15, 15, 0, 0, 3, false, true, nil)
end

function MM:HandleScan(scanParams)
	if not self:ValidateAHIsOpen() then
		return
	end
	scanQualityNames = validateScanParams(scanParams)
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
	local nametxt = MM:cTxt(queue[currentIndex],tostring(MYSTIC_ENCHANTS[MM.RE_LOOKUP[queue[currentIndex]]].quality))
	MM:Print(string.format("%s: %d/%d %s",
	nametxt,
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

local retryScanTime

-- event triggers a lot, potentially on the same frame
function MM:Scan_AUCTION_ITEM_LIST_UPDATE()
	-- if scan is active and not currently waiting for a retry
	if scanInProgress and (not retryTime or retrying) then
		-- trinkets with searched enchants are sometimes not found when they exist
		local scanTime = retrying and retryScanTime or time()
		local scanSuccessful = self:CollectSpecificREData(scanTime, queue[currentIndex])
		if scanSuccessful or retrying then
			clearRetryFlag()
			printScanProgress(scanSuccessful)
			recordLastQualityEnchantScanned()
			currentIndex = currentIndex % #queue + 1

			if currentIndex ~= startingIndex then
				updateScanDetails()
				scanPending = true
			else
				self:Print("Calculations!")
				self:CalculateAllStats()
				self:Print("Scan finished")
				scanInProgress = false
			end
		elseif not retryTime then
			retryScanTime = scanTime
			retryTime = GetTime()
		end
	end
end

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", "Scan_AUCTION_ITEM_LIST_UPDATE")

local function onUpdate()
	if scanPending and CanSendAuctionQuery() then
		scanPending = false
		performScan(currentIndex)
	elseif retryTime and GetTime() - retryTime > .4 then
		retrying = true
		performScan(currentIndex)
	end
end

MM.OnUpdateFrame:HookScript("OnUpdate", onUpdate)
