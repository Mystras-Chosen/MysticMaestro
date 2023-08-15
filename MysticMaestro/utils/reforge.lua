local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local green = "|cff00ff00"
local red = "|cffff0000"
local itemLoaded = false
local options, autoAutoEnabled, autoReforgeEnabled
local shopEnabledList, shopExtractList, shopReserveList, shopUnknownList
local reforgeHandle, dynamicButtonTextHandle
local bagID, slotIndex
local AltarReforgesText, settingsButton
local otherGreens = {
	Speedy = true,
	Improved = true,
	Defensive = true,
	Energizing = true,
	Camouflage = true,
	Debbie = true,
	Meating = true,
	Dispersing = true,
}

local function StopCraftingAttemptTimer()
	if reforgeHandle then
		reforgeHandle:Cancel()
		reforgeHandle = nil
	end
end

local function StopAutoReforge(result)
	local enabled = false
	if autoReforgeEnabled or autoAutoEnabled then
		enabled = true
	end
	if autoAutoEnabled then
		if slotIndex - 1 >= 0 then
			slotIndex = slotIndex - 1
		elseif bagID - 1 >= 0 then
			bagID = bagID - 1
			slotIndex = GetContainerNumSlots(bagID)
		end
	end
	autoReforgeEnabled = false
	autoAutoEnabled = false
	if dynamicButtonTextHandle then
		dynamicButtonTextHandle:Cancel()
		dynamicButtonTextHandle = nil
	end
	if result then
		MM:Print("Reforge stopped for " .. result)
	elseif enabled then
		MM:Print("Reforge has been stopped")
	end
	-- MysticMaestroEnchantingFrameAutoReforgeButton:SetText("Auto Reforge")
end

local function RequestReforge()
	-- attempt to roll every .05 seconds
	if autoReforgeEnabled then
		reforgeHandle = Timer.NewTicker(.05, function()
			if GetUnitSpeed("player") ~= 0 then 
				StopCraftingAttemptTimer()
				StopAutoReforge("Player Moving")
				return
			end
		end)
	elseif autoAutoEnabled then
		reforgeHandle = Timer.NewTicker(.05, function()
			if GetUnitSpeed("player") ~= 0 then
				StopCraftingAttemptTimer()
				StopAutoReforge("Player Moving")
				return
			end
			RequestSlotReforgeEnchantment(bagID, slotIndex)
		end)
	else
			MM:Print("Error starting reforge, values indicate we are not enabled. AR:" .. autoReforgeEnabled .. " AA:" .. autoAutoEnabled)
	end
end

local function configShoppingMatch(currentEnchant)
	local enabled = options.stopForShop.enabled and shopEnabledList[currentEnchant.SpellID]
	local unknownMatch = not shopUnknownList[currentEnchant.SpellID] or (shopUnknownList[currentEnchant.SpellID] and not currentEnchant.Known)
	local eval = enabled and unknownMatch 
	return eval and "Shopping Match" or nil
end

local function isSeasonal(enchant)
	return false
	-- if enchant then
	-- 	return not bit.contains(enchant.realms, Enum.RealmMask.Area52)
	-- end
end

local function FindNextScroll()
	for i=bagID, 4 do
		for j=slotIndex + 1, GetContainerNumSlots(i) do
			local item = select(7, GetContainerItemInfo(i, j))
			if item then
				local name = GetItemInfo(item)
				if MM:IsUntarnished(name) then 
					bagID = i
					slotIndex = j
					return true
				end
				local re = MM:GetREInSlot(i, j)
				local reObj = C_MysticEnchant.GetEnchantInfoBySpell(re)
				if reObj ~= nil then
					local knownStr
					if not reObj.Known then
						knownStr = red .. "unknown" .. "|r"
					else
						knownStr = green .. "known" .. "|r"
					end
					if shopReserveList[re] then
						print("Reserving " .. knownStr .. " enchant from Shopping List: " .. MM:ItemLinkRE(re))
					else
						bagID = i
						slotIndex = j
						return true
					end
				end
			end
		end
		slotIndex = 0
	end
	bagID = 0
	slotIndex = 0
end

local function initOptions()
	options = MM.db.realm.OPTIONS
	MM:BuildWorkingShopList()
end

function MM:BuildWorkingShopList()
	if not options then initOptions() end
	local enabledList = {}
	local extractList = {}
	local reserveList = {}
	local unknownList = {}
	for _, list in ipairs(options.shoppingLists) do
		if list.enabled then
			for _, enchantName in ipairs(list) do
				if enchantName ~= "" then
					local n = enchantName:lower()
					local standardStr = select(3, n:find("%[(.-)%]")) or select(3, n:find("(.+)"))
					local enchantList = C_MysticEnchant.QueryEnchants(99,1,standardStr,{})
					local enchant, SpellID
					if enchantList then
						for _, enchant in ipairs(enchantList) do
							if enchant.SpellName == standardStr then
								SpellID = enchant.SpellID
								do break end
							end
						end
					end
					if SpellID then
						enabledList[SpellID] = true
						if list.extract then
							extractList[SpellID] = true
						end
						if list.reserve then
							reserveList[SpellID] = true
						end
						if list.unknown then
							unknownList[SpellID] = true
						end
					end
				end
			end
		end
	end
	shopEnabledList = enabledList
	shopExtractList = extractList
	shopReserveList = reserveList
	shopUnknownList = unknownList
end

local function extract(enchantID)
	if not MM:IsREKnown(enchantID) 
	and GetItemCount(98463) and (GetItemCount(98463) > 0) then
			MM:Print("Extracting enchant:" .. MM:ItemLinkRE(enchantID))
			RequestSlotReforgeExtraction(bagID, slotIndex)
	end
end

local function configNoRunes()
	local eval = options.stopIfNoRunes and GetItemCount(98462) <= 0
	return eval and "No Runes" or nil
end

local function configSeasonalMatch(currentEnchant)
	local eval = options.stopSeasonal.enabled and isSeasonal(currentEnchant)
	return eval and "Seasonal Enchant" or nil
end

local function configQualityMatch(currentEnchant)
	local quality = Enum.EnchantQualityEnum[currentEnchant.Quality]
	local eval = options.stopQuality.enabled and options.stopQuality[quality]
	return eval and "Quality Match" or nil
end

local function configUnknownMatch(currentEnchant)
	local quality = Enum.EnchantQualityEnum[currentEnchant.Quality]
	local eval = options.stopUnknown.enabled and not currentEnchant.Known and options.stopUnknown[quality]
	return eval and "Unknown Match" or nil
end

local function configPriceMatch(currentEnchant)
    local priceObj = Maestro(currentEnchant.SpellID)
		local quality = Enum.EnchantQualityEnum[currentEnchant.Quality]
    if not priceObj then return options.stopPrice.enabled and options.stopPrice[quality] and "Unknown Priced" end
		local eval = options.stopPrice.enabled and priceObj.Min >= options.stopPrice.value * 10000 and options.stopPrice[quality]
    return eval and "Price Match" or nil
end

local function configGreenMatch(currentEnchant)
	local matchGreen, rxMatch, unknownLogic
	local quality = Enum.EnchantQualityEnum[currentEnchant.Quality]
	if options.green.enabled and quality == 2 then
		rxMatch = string.match(currentEnchant.SpellName,"^[a-zA-Z]+")
		unknownLogic = not options.green.unknown or (options.green.unknown and not currentEnchant.Known)
		matchGreen = options.green[rxMatch] or options.green.Other and otherGreens[rxMatch]
	end
	local eval = unknownLogic and matchGreen
	return eval and "Green Match" or nil
end

local function configConditionMet(currentEnchant)
	if not options then initOptions() end
	local unknown = configUnknownMatch(currentEnchant)
	local seasonal = configSeasonalMatch(currentEnchant)
	local green = configGreenMatch(currentEnchant)
	-- Determine if we should extract this enchant
	if (autoAutoEnabled)
	and ((unknown and options.stopUnknown.extract)
	or (seasonal and options.stopSeasonal.extract)
	or (green and options.green.extract)
	or shopExtractList[currentEnchant.enchantID]) then
		extract(currentEnchant.enchantID)
	end
	-- check for spam reforge settings
	if autoReforgeEnabled and options.stopForNothing then
		return configNoRunes()
	end
	-- Evaluate the enchant against our options
	return configQualityMatch(currentEnchant)
	or configShoppingMatch(currentEnchant)
	or unknown
	or seasonal
	or green
	or configPriceMatch(currentEnchant)
end

function MM:MYSTIC_ENCHANT_REFORGE_RESULT(result, SpellID)
	local currentEnchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
	local result = configConditionMet(currentEnchant)
	local norunes = configNoRunes()
	if not autoAutoEnabled and (not autoReforgeEnabled or result or norunes) then
		-- End reforge
		StopAutoReforge(result or norunes)
		return
	end
	if autoAutoEnabled then
		local knownStr, seasonal = "", ""
		if not currentEnchant.Known then
			knownStr = red .. "unknown" .. "|r"
		else
			knownStr = green .. "known" .. "|r"
		end
		if isSeasonal(SpellID) then
			seasonal = green .. " seasonal" .. "|r"
		end
		if result then
			MM:Print("Stopped on " .. knownStr .. seasonal .. " enchant:" .. MM:ItemLinkRE(SpellID) .. " because of " .. result)
		else
			MM:Print("Skipping " .. knownStr .. seasonal .. " enchant:" .. MM:ItemLinkRE(SpellID))
		end
	end
	if result or norunes then
		local cantFind = not FindNextScroll()
		if cantFind or norunes then
			if cantFind then
				MM:Print("Out of Insignia, inventory position reset to first bag")
			end
			StopAutoReforge(norunes)
			return
		end
	end
	if GetUnitSpeed("player") == 0 then
		RequestReforge()
	else
		StopAutoReforge("Player Moving")
	end
end

local function AltarLevelRequireXP(level)
	if level == 0 then
			return 1
	end
	if level >= 250 and not C_Realm:IsRealmMask(Enum.RealmMask.Area52) then
			return 557250 + (level - 250) * 4097
	end
	return floor(354 * level + 7.5 * level * level)
end

function MM:SetAltarLevelUPText(xp, level)
	if not MM.db then return end
	if xp == 0 or xp == nil or level == 0 or level == nil then
		if MM.db.realm.AltarLevelUp then
			AltarReforgesText:SetText("Next level in " .. MM.db.realm.AltarLevelUp .. " reforges")
		end
		return 
	end
	local gained = xp - (MM.db.realm.AltarXP or 0)
	if gained == 0 then
		if MM.db.realm.prevAltarGained then
			gained = MM.db.realm.prevAltarGained
		else
			return
		end
	else
		MM.db.realm.prevAltarGained = gained
	end
	local remaining = AltarLevelRequireXP(level) - xp
	local levelUP = math.floor(remaining / gained) + 1
	AltarReforgesText:SetText("Next level in " .. levelUP .. " reforges")
	MM.db.realm.AltarXP = xp
	MM.db.realm.AltarLevelUp = levelUP
end

function MM:ASCENSION_REFORGE_PROGRESS_UPDATE(xp, level)
	MM:SetAltarLevelUPText(xp, level)
end

local function UNIT_SPELLCAST_START(event, unitID, spell)
	-- if cast has started, then stop trying to cast
	if unitID == "player" and spell == "Enchanting" then
		StopCraftingAttemptTimer()
	end
end
MM:RegisterEvent("UNIT_SPELLCAST_START",UNIT_SPELLCAST_START)

local function dots()
	local floorTime = math.floor(GetTime())
	return floorTime % 3 == 0 and "." or (floorTime % 3 == 1 and ".." or "...")
end

local function StartAutoReforge()
	if bagID == nil then
		bagID = 0
		slotIndex = 0
	end
	if FindNextScroll() then
		MM:Print("Scrolls found, lets roll!")
		autoAutoEnabled = true
	else
		MM:Print("There are no scrolls to roll on!")
		return
	end
	RequestReforge()
	-- local button = MysticMaestroEnchantingFrameAutoReforgeButton
	-- button:SetText("Reforging"..dots())
	-- dynamicButtonTextHandle = Timer.NewTicker(1, function() button:SetText("Reforging"..dots()) end)
end

local function UNIT_SPELLCAST_INTERRUPTED()
	if (autoAutoEnabled or autoReforgeEnabled)
	and GetUnitSpeed("player") ~= 0 then
		StopAutoReforge("Player Moving")
	end
end
MM:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED",UNIT_SPELLCAST_INTERRUPTED)