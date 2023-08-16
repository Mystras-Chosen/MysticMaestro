local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local strKnown = "|cff00ff00known|r"
local strUnknown = "|cffff0000unknown|r"
local itemLoaded = false
local options, autoAutoEnabled, autoReforgeEnabled
local shopEnabledList, shopExtractList, shopReserveList, shopUnknownList
local reforgeHandle, dynamicButtonTextHandle
local bagID, slotIndex, itemGuid
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
	if not autoReforgeEnabled then return end
	autoReforgeEnabled = false
	if slotIndex - 1 >= 0 then
		slotIndex = slotIndex - 1
	elseif bagID - 1 >= 0 then
		bagID = bagID - 1
		slotIndex = GetContainerNumSlots(bagID)
	end
	if dynamicButtonTextHandle then
		dynamicButtonTextHandle:Cancel()
		dynamicButtonTextHandle = nil
	end
	if result then
		MM:Print("Reforge stopped for " .. result)
	else
		MM:Print("Reforge has been stopped")
	end
	if MysticMaestro_CollectionsFrame_ReforgeButton then
		MysticMaestro_CollectionsFrame_ReforgeButton:SetText("Auto Reforge")
	end
	--hide screen text count down
	MM:ToggleScreenReforgeText()
	MM:StandaloneReforgeText()
end


function MM:UNIT_SPELLCAST_SUCCEEDED(event, arg1, arg2, arg3)
    --starts the next roll after last cast
    if arg1 == "player" and arg2 == "Reforge Mystic Enchant" then
        --stops all rolling when enchanting is interrupted
        if event == "UNIT_SPELLCAST_INTERRUPTED" then
            MM:StopAutoRoll();
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            --starts short timer to start next roll item
            MM:ScheduleTimer(MM.RequestReforge, .8);
        end
		MM:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED");
        MM:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    end
end

local function RequestReforge()
	-- attempt to roll every .05 seconds
	if autoReforgeEnabled then
		reforgeHandle = Timer.NewTicker(.1, function()
			if GetUnitSpeed("player") ~= 0 then
				StopCraftingAttemptTimer()
				StopAutoReforge("Player Moving")
				return
			end
			if C_MysticEnchant.CanReforgeItem(itemGuid) then
				C_MysticEnchant.ReforgeItem(itemGuid)
			end
		end)
	else
			MM:Print("Error starting reforge, values indicate we are not enabled. AR:" .. autoReforgeEnabled)
	end
end

function MM:RequestReforge()
	-- attempt to roll every .05 seconds
	if autoReforgeEnabled then
		if GetUnitSpeed("player") ~= 0 then
			StopCraftingAttemptTimer()
			StopAutoReforge("Player Moving")
			return
		end
		MM:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		MM:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
		local itemGuid = MM:FindNextScroll()
		if itemGuid then
			C_MysticEnchant.ReforgeItem(itemGuid)
		end
	else
		MM:Print("Error starting reforge, values indicate we are not enabled. AR:" .. autoReforgeEnabled)
	end
end

local function configShoppingMatch(currentEnchant)
	local enabled = options.stopForShop.enabled and shopEnabledList[currentEnchant.SpellID]
	local unknownMatch = not shopUnknownList[currentEnchant.SpellID] or (shopUnknownList[currentEnchant.SpellID] and not currentEnchant.Known)
	local eval = enabled and unknownMatch 
	return eval and "Shopping Match" or nil
end

--[[ local function FindNextScroll(target)
	local inventoryList = C_MysticEnchant.GetMysticScrolls()
	local enchant
	if target then
		enchant = C_MysticEnchant.GetEnchantInfoBySpell(target)
		if not enchant then return end
	end
	for _, scroll in ipairs(inventoryList) do
		if (target and scroll.Entry == enchant.ItemID)
		or (not target and scroll.Name == "Untarnished Mystic Scroll") then
			bagID = scroll.Bag
			slotIndex = scroll.Slot
			itemGuid = scroll.Guid
			return true
		end
	end
end ]]

function MM:FindNextScroll()
	local inventoryList = C_MysticEnchant.GetMysticScrolls()

	for _, scroll in ipairs(inventoryList) do
	   local itemId = GetContainerItemID(scroll.Bag, scroll.Slot)
	   local enchantInfo = C_MysticEnchant.GetEnchantInfoByItem(itemId)

	   if itemId == 992720 or enchantInfo.Quality == "RE_QUALITY_UNCOMMON" then
		  return scroll.Guid
	   end
	end
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
	local green = configGreenMatch(currentEnchant)
	-- Determine if we should extract this enchant
	if (autoReforgeEnabled)
	and ((unknown and options.stopUnknown.extract)
	or (green and options.green.extract)
	or shopExtractList[currentEnchant.enchantID]) then
		extract(currentEnchant.enchantID)
	end
	-- Evaluate the enchant against our options
	return configQualityMatch(currentEnchant)
	or configShoppingMatch(currentEnchant)
	or unknown
	or green
	or configPriceMatch(currentEnchant)
end

function MM:StartAutoForge(SpellID)
	if not autoReforgeEnabled then return end

	--show rune count down
	MM:ToggleScreenReforgeText(true)
	MM:StandaloneReforgeText(true)

	local currentEnchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
	local knownState = currentEnchant.Known and strKnown or strUnknown
	local result = configConditionMet(currentEnchant)
	if result then
		MM:Print("Stopped on " .. knownState .. " enchant:" .. MM:ItemLinkRE(SpellID) .. " because of " .. result)
	else
		MM:Print("Skipping " .. knownState .. " enchant:" .. MM:ItemLinkRE(SpellID))
	end

	-- dermine if we have runes remaining to continue
	local norunes = configNoRunes()
	if norunes then StopAutoReforge(norunes) return end

	local scrollFound
	-- if we have a match, we want to roll another scroll
	if result then
		local scrollFound = MM:FindNextScroll()
		if not scrollFound then
			-- here we can place logic for possibly creating scrolls
			StopAutoReforge("Out of Scrolls")
			return
		end
	else -- with no match, we find the resulting scroll from the reforge
		scrollFound = MM:FindNextScroll(SpellID)
	end
	if scrollFound then MM:Print("Found reforged scroll") end
	-- Check if the player is moving to stop
	if GetUnitSpeed("player") == 0 then
		MM:RequestReforge()
	else
		StopAutoReforge("Player Moving")
	end
end

function MM:MYSTIC_ENCHANT_REFORGE_RESULT(event, result, SpellID)
	if result ~= "RE_REFORGE_OK"
	or SpellID == 0 then return end

	MM:AltarLevelRequiredRolls() -- not sure why this is here
	MM:StartAutoForge(SpellID)
end

function MM:AltarLevelRequiredRolls()
	if not MM.db.atlarLevel then MM.db.atlarLevel = {} end

	--works out how many rolls on the current item type it will take to get the next altar level
    local progress, level = C_MysticEnchant.GetProgress()

	if MM.db.atlarLevel.lastLevel ~= level or not MM.db.atlarLevel.lastProgress then
		MM.db.atlarLevel.lastLevel = level
		MM.db.atlarLevel.lastProgress = progress
	end

	local progressDif = progress - MM.db.atlarLevel.lastProgress

	if progressDif == 0 then return end

	if progressDif ~= 0 and (not MM.db.atlarLevel.lastProgressDif or MM.db.atlarLevel.lastProgressDif > progressDif) then
		MM.db.atlarLevel.lastProgressDif = progressDif
	end

	if MM.db.atlarLevel.lastProgressDif < progressDif then
		progressDif = MM.db.atlarLevel.lastProgressDif
	end

	MM.db.atlarLevel.lastProgress = progress

	local rollsNeeded = (100 - progress) / progressDif

	MM.db.atlarLevel.rollsNeeded = math.ceil(rollsNeeded)
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
	local remaining = MM:AltarLevelRequiredRolls() - xp
	local levelUP = math.floor(remaining / gained) + 1
	AltarReforgesText:SetText("Next level in " .. levelUP .. " reforges")
	MM.db.realm.AltarXP = xp
	MM.db.realm.AltarLevelUp = levelUP
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
	if MM:FindNextScroll() then
		MM:Print("Scrolls found, lets roll!")
		autoReforgeEnabled = true
	else
		MM:Print("There are no scrolls to roll on!")
		return
	end
	MM:RequestReforge()
	if MysticMaestro_CollectionsFrame_ReforgeButton then 
		local button = MysticMaestro_CollectionsFrame_ReforgeButton
		button:SetText("Reforging"..dots())
		dynamicButtonTextHandle = Timer.NewTicker(1, function() button:SetText("Reforging"..dots()) end)
	end
end

function MM:ReforgeButtonClick()
	if not options then initOptions() end
	if autoReforgeEnabled then
		StopAutoReforge("Button Pressed")
	else
		StartAutoReforge()
	end
end

function MM:UNIT_SPELLCAST_INTERRUPTED()
	if (autoReforgeEnabled)
	and GetUnitSpeed("player") ~= 0 then
		StopAutoReforge("Player Moving")
	end
end