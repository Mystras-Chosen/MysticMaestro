local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

-- report percent complete while scan is going (estimated time remaining as well)
-- remember last scanned enchant and quality

local function validateSlowScanParams(slowScanParams)
	if not slowScanParams or slowScanParams == "" then
		MM:Print("No scan type specified. Valid scan types: rare, epic, legendary")
		return false
	end
	local validScanTypes = {
		rare = true,
		epic = true,
		legendary = true
	}
	local scanTypes = {}
	for t in slowScanParams:gmatch("(%w+)") do
		if not validScanTypes[t:lower()] then
			MM:Print('Scan type "' .. t:lower() .. '" is invalid. Valid scan types: rare, epic, legendary')
			return false
		end
		table.insert(scanTypes, t)
	end
	return scanTypes
end

local function getAlphabetizedEnchantList(qualityName, enchantQuality)
	local enchants = MM[qualityName:upper() .. "_ENCHANTS"]
	if not enchants then
		enchants = {}
		for _, enchantData in pairs(MYSTIC_ENCHANTS) do
			if enchantData.quality == enchantQuality then
				local enchantName = GetSpellInfo(enchantData.spellID)
				table.insert(enchants, enchantName)
				enchants[enchantName] = true
			end
		end
		table.sort(enchants)
		MM[qualityName:upper() .. "_ENCHANTS"] = enchants
	end
	return enchants
end

local queue

local function addToQueue(scanTypes)
	queue = {}
	for _, scanType in ipairs(scanTypes) do
		local enchantQuality = scanType == "rare" and 3 or (scanType == "epic" and 4 or 5)
		local enchants = getAlphabetizedEnchantList(scanType, enchantQuality)
		for _, enchant in ipairs(enchants) do
			table.insert(queue, enchant)
		end
	end
end

local function getStartingIndex(queue, scanType)
	local lastEnchantScanned = MM.db.realm["LAST_" .. scanType:upper() .. "_ENCHANT_SCANNED"]
	if lastEnchantScanned then
		-- considered binary search, but the list is only partially sorted if more than one scan type involved
		for i = 1, #queue do
			if queue[i] == lastEnchantScanned then
				return i + 1
			end
		end
	else
		return 1
	end
end

local startingIndex, currentIndex, slowScanInProgress

local function performScan(currentIndex)
	QueryAuctionItems(queue[currentIndex], 15, 15, 0, 0, 3, false, true, nil)
end

local scanTypes, currentScanTypeIndex, currentScanType

function MM:HandleSlowScan(slowScanParams)
	if not self:ValidateAHIsOpen() then
		return
	end
	scanTypes = validateSlowScanParams(slowScanParams)
	if scanTypes and not CanSendAuctionQuery() then
		MM:Print("Scan not ready. Wait a moment and try again.")
	elseif scanTypes then
		addToQueue(scanTypes)
		currentScanTypeIndex = 1
		currentScanType = scanTypes[currentScanTypeIndex]
		startingIndex = getStartingIndex(queue, currentScanType)
		currentIndex = startingIndex
		slowScanInProgress = true
		performScan(currentIndex)
	end
end

local scanPending
function MM:Slowscan_AUCTION_ITEM_LIST_UPDATE()
	if slowScanInProgress then
		self:CollectAuctionData(time(), queue[currentIndex])
		self.db.realm["LAST_" .. currentScanType:upper() .. "_ENCHANT_SCANNED"] = queue[currentIndex]
		currentIndex = currentIndex % #queue + 1
		if not self[currentScanType:upper() .. "_ENCHANTS"][queue[currentIndex]] then
			currentScanTypeIndex = currentScanTypeIndex + 1
			currentScanType = scanTypes[currentScanTypeIndex]
		end
		if currentScanType and currentIndex ~= startingIndex then
			scanPending = true
		else
			MM:Print("Slow scan finished")
			slowScanInProgress = false
		end
	end
end

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", "Slowscan_AUCTION_ITEM_LIST_UPDATE")

local function onUpdate()
	if scanPending and CanSendAuctionQuery() then
		scanPending = false
		performScan(currentIndex)
	end
end

MM.OnUpdateFrame:HookScript("OnUpdate", onUpdate)
