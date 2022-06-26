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
				table.insert(enchants, GetSpellInfo(enchantData.spellID))
			end
		end
		table.sort(enchants)
		MM[qualityName:upper() .. "_ENCHANTS"] = enchants
	end
	return enchants
end

local function startSlowScan(scanType)
	local enchantQuality = scanType == "rare" and 3 or (scanType == "epic" and 4 or 5)
	local enchants = getAlphabetizedEnchantList(scanType, enchantQuality)
	-- start scan from where we left off of it is mentioned in the database.  otherwise, start from beginning.
end

function MM:HandleSlowScan(slowScanParams)
	local scanTypes = validateSlowScanParams(slowScanParams)
	if scanTypes then
		for _, scanType in ipairs(scanTypes) do -- this can't be a loop. need to schedule multiple quality scans another way.
			startSlowScan(scanType)
		end
	end

	--[[
	local AuctionFrame = _G["AuctionFrame"]
	if AuctionFrame and AuctionFrame:IsShown() then
		MM:Print("Auction house window is open and we did a slow scan! ;)")
	else
		MM:Print("Auction house window must be open to perform scan")
	end]]
end

-- set up event handler. the same event for fullscan will be used, so we should consider using non-default handler function names.
-- ex. function MM:Slowscan_AUCTION_ITEM_LIST_UPDATE() end
-- MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", "Slowscan_AUCTION_ITEM_LIST_UPDATE")
