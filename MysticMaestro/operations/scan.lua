local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local validScanOptions = {
  [1] = "legendary",
  [2] = "epic",
  [3] = "rare",
  [4] = "uncommon",
	uncommon = true,
	rare = true,
	epic = true,
	legendary = true,
	all = true
}

local function scanOptionsToString()
	local result = ""
	for k, option in ipairs(validScanOptions) do
		result = result .. " " .. option
	end
	return result
end

local function getAllOperations()
	local all = {}
	for _, qualityName in ipairs(validScanOptions) do
		if validScanOptions[qualityName] then
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
			table.insert(scanQualityNames, t:lower())
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

local scanQualityNames, currentScanQualityIndex, currentScanQuality
local startingIndex, currentIndex
local scanInProgress

local function initializeScan(scanQualityNames)
	createQueue(scanQualityNames)
	currentScanQualityIndex = 1
	currentScanQuality = scanQualityNames[currentScanQualityIndex]
	startingIndex = 1
	currentIndex = startingIndex
	scanInProgress = true
end

local function performScan(currentIndex)
	-- "name", minLevel, maxLevel, invTypeIndex, classIndex, subClassIndex, page, isUsable, minQuality, getAll
	QueryAuctionItems(MM.RE_NAMES[queue[currentIndex]], nil, nil, 0, 0, 3, false, true, nil)
end

function MM:HandleScan(scanParams)
	if not self:ValidateAHIsOpen() then return end
	scanQualityNames = validateScanParams(scanParams)
	if scanQualityNames and not CanSendAuctionQuery() then
		MM:Print("Scan not ready. Wait a moment and try again.")
	elseif scanQualityNames then
		MM:Print("Initiating Scan")
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

	local nametxt = MM:cTxt(MM.RE_NAMES[queue[currentIndex]], tostring(MYSTIC_ENCHANTS[queue[currentIndex]].quality))
	MM:Print(string.format("%s: %d/%d %s",
	nametxt,
	(currentIndex + #queue - startingIndex) % #queue + 1,
	#queue,
	scanSuccessful and "" or "None Listed"))
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
