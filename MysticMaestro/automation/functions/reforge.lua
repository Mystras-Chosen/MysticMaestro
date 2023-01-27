local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local green = "|cff00ff00"
local red = "|cffff0000"
local itemLoaded = false
local options, autoAutoEnabled, autoReforgeEnabled, enchantsOfInterest, reforgeHandle, dynamicButtonTextHandle
local bagID, slotIndex, init

local function FindNextInsignia()
	for i=bagID, 4 do
		for j=slotIndex + 1, GetContainerNumSlots(i) do
			local item = select(7, GetContainerItemInfo(i, j))
			if item and (item:find("Insignia of the Alliance") or item:find("Insignia of the Horde") or item:find("Bloodforged Untarnished Mystic Scroll")) then
				local re = GetREInSlot(i, j)
				local reObj = MYSTIC_ENCHANTS[re]
				if reObj ~= nil then
					local knownStr = "known"
					if not IsReforgeEnchantmentKnown(re) then
						knownStr = aura_env.color.red .. "un" .. knownStr .. "|r"
					else
						knownStr = aura_env.color.green .. knownStr .. "|r"
					end
					if options.reserveShoppingList and configShoppingMatch(reObj) then
						print("Reserving " .. knownStr .. " enchant from Shopping List: " .. MM:ItemLinkRE(re))
					else
						bagID = i
						slotIndex = j
						return true
					end
				else
					bagID = i
					slotIndex = j
					return true
				end
			end
		end
		slotIndex = 0
	end
	bagID = 0
	slotIndex = 0
end

local function BuildWorkingShopList()
	local shopList = {}
	for _, list in ipairs(options.shoppingLists) do
		for _, enchantName in pairs(list) do
			if _ ~= "name" and enchantName ~= "" then
				local n = enchantName:lower()
				shopList[select(3, n:find("%[(.-)%]")) or select(3, n:find("(.+)"))] = true
			end
		end
	end
	enchantsOfInterest = shopList
end

local function initOptions()
	options = options or MM.db.realm.OPTIONS
	options.stopIfNoRunes = true
	options.stopForShop = {}
	options.stopForShop.enabled = false
	options.stopForShop.unknown = false
	options.shoppingLists = {}
	options.stopSeasonal = {}
	options.stopSeasonal.enabled = true
	options.stopSeasonal.extract = true
	options.stopQuality = {}
	options.stopQuality.enabled = true
	options.stopQuality["2"] = false
	options.stopQuality["3"] = true
	options.stopQuality["4"] = true
	options.stopQuality["5"] = true
	options.stopUnknown = {}
	options.stopUnknown.enabled = true
	options.stopUnknown.extract = true
	options.stopUnknown["2"] = false
	options.stopUnknown["3"] = true
	options.stopUnknown["4"] = true
	options.stopUnknown["5"] = true
	options.stopPrice = {}
	options.stopPrice.enabled = true
	options.stopPrice.value = 3.5
	options.stopPrice["2"] = false
	options.stopPrice["3"] = true
	options.stopPrice["4"] = true
	options.stopPrice["5"] = true
	options.reserveShoppingList = true
	BuildWorkingShopList()
	init = true
end

local function configNoRunes(currentEnchant)
	return options.stopIfNoRunes and GetItemCount(98462) <= 0
end

local function configShoppingMatch(currentEnchant)
    return options.stopForShop.enabled and enchantsOfInterest[currentEnchant.spellName:lower()] 
    and (not options.stopForShop.unknown or (options.stopForShop.unknown and not IsReforgeEnchantmentKnown(currentEnchant.enchantID)))
end

local function configSeasonalMatch(currentEnchant)
    local eval = options.stopSeasonal.enabled and isSeasonal(currentEnchant.enchantID)
    if eval and options.stopSeasonal.extract then
        -- Code for extraction
        extract(currentEnchant.enchantID)
    end
    return eval
end

local function configQualityMatch(currentEnchant)
    return options.stopQuality.enabled and options.stopQuality[tostring(currentEnchant.quality)]
end

local function configUnknownMatch(currentEnchant)
    local eval = options.stopUnknown.enabled and not IsReforgeEnchantmentKnown(currentEnchant.enchantID) and options.stopUnknown[tostring(currentEnchant.quality)]
    if eval and options.stopUnknown.extract then
        -- Code for extraction
        extract(currentEnchant.enchantID)
    end
    return eval
end

local function configPriceMatch(currentEnchant)
    local priceObj = Maestro(currentEnchant.enchantID)
    if not priceObj then return options.stopPrice[tostring(currentEnchant.quality)] end
    return options.stopPrice.enabled and priceObj.Min >= options.stopPrice.value * 10000 and options.stopPrice[tostring(currentEnchant.quality)]
end

local function configConditionMet(currentEnchant)
    return configNoRunes(currentEnchant)
    or configQualityMatch(currentEnchant)
    or configShoppingMatch(currentEnchant)
    or configUnknownMatch(currentEnchant)
    or configSeasonalMatch(currentEnchant)
    or configPriceMatch(currentEnchant)
end

local function isSeasonal(spellID)
    local enchant = GetMysticEnchantInfo(spellID)
    if enchant then
        return not bit.contains(enchant.realms, Enum.RealmMask.Area52)
    end
end

local function extract(enchantID)
    if not IsReforgeEnchantmentKnown(enchantID) 
    and GetItemCount(98463) and (GetItemCount(98463) > 0) then
        print("Extracting enchant:" .. MM:ItemLinkRE(enchantID))
        RequestSlotReforgeExtraction(bagID, slotIndex)
    end
end

function MM:ASCENSION_REFORGE_ENCHANT_RESULT(event, subEvent, sourceGUID, enchantID)
	if subEvent ~= "ASCENSION_REFORGE_ENCHANT_RESULT" then return end
	
	if tonumber(sourceGUID) == tonumber(UnitGUID("player"), 16) then
		local currentEnchant = MYSTIC_ENCHANTS[enchantID]
		if not autoAutoEnabled and (not autoReforgeEnabled or configConditionMet(currentEnchant)) then
			-- End reforge
			StopAutoReforge()
			return
		end
		
		if autoAutoEnabled then
			local knownStr, seasonal = "known", ""
			if not IsReforgeEnchantmentKnown(enchantID) then
				knownStr = red .. "un" .. knownStr .. "|r"
			else
				knownStr = green .. knownStr .. "|r"
			end
			if isSeasonal(enchantID) then
				seasonal = green .. " seasonal" .. "|r"
			end
			
			if configConditionMet(currentEnchant) then
				print("Stopped on " .. knownStr .. seasonal .. " enchant:" .. MM:ItemLinkRE(enchantID))

				if not FindNextInsignia() or GetItemCount(98462) <= 0 then
					if GetItemCount(98462) <= 0 then
						print("Out of runes")
					else
						print("Out of Insignia")
					end
					StopAutoReforge()
					return
				end
			else
				print("Skipping " .. knownStr .. seasonal .. " enchant:" .. MM:ItemLinkRE(enchantID))
			end
		end
		if GetUnitSpeed("player") == 0 then
			RequestReforge()
		else
			StopAutoReforge()
		end
	end
end

local function StopCraftingAttemptTimer()
	if reforgeHandle then
		reforgeHandle:Cancel()
		reforgeHandle = nil
	end
end

local function UNIT_SPELLCAST_START(event, unitID, spell)
	if event ~= "UNIT_SPELLCAST_START" then print("issue with spell start params") return end
	-- if cast has started, then stop trying to cast
	if unitID == "player" and spell == "Enchanting" then
		StopCraftingAttemptTimer()
	end
end
MM:RegisterEvent("UNIT_SPELLCAST_START",UNIT_SPELLCAST_START)

local function RequestReforge()
	-- attempt to roll every .05 seconds
	if autoReforgeEnabled then
		reforgeHandle = Timer.NewTicker(.05, function()
			MysticEnchantingFrameControlFrameRollButton:GetScript("OnClick")(MysticEnchantingFrameControlFrameRollButton)
		end)
	elseif autoAutoEnabled then
		reforgeHandle = Timer.NewTicker(.05, function()
			RequestSlotReforgeEnchantment(bagID, slotIndex)
		end)
	else
			print("Error starting reforge, values indicate we are not enabled. AR:" .. autoReforgeEnabled .. " AA:" .. autoAutoEnabled)
	end
end


local function dots()
	local floorTime = math.floor(GetTime())
	return floorTime % 3 == 0 and "." or (floorTime % 3 == 1 and ".." or "...")
end

local function StartAutoReforge()
	if itemLoaded then
		MM:Print("Reforging the loaded item!")
		autoReforgeEnabled = true
	else
		if bagID == nil then
			bagID = 0
			slotIndex = 0
		end
		if FindNextInsignia() then
			MM:Print("Trinkets found, lets roll!")
			autoAutoEnabled = true
		else
			MM:Print("There are no trinkets to roll on!")
			return
		end
	end
	RequestReforge()
	local button = MysticMaestroEnchantingFrameAutoReforgeButton
	button:SetText("Reforging"..dots())
	dynamicButtonTextHandle = Timer.NewTicker(1, function() button:SetText("Reforging"..dots()) end)
end

local function StopAutoReforge()
	autoReforgeEnabled = false
	autoAutoEnabled = false
	if dynamicButtonTextHandle then
		dynamicButtonTextHandle:Cancel()
		dynamicButtonTextHandle = nil
	end
	MM:Print("Reforge has been stopped")
	MysticMaestroEnchantingFrameAutoReforgeButton:SetText("Auto Reforge")
end

local function UNIT_SPELLCAST_INTERRUPTED()
	if GetUnitSpeed("player") ~= 0 then
		StopAutoReforge()
	end
end
MM:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED",UNIT_SPELLCAST_INTERRUPTED)

if not MysticMaestroEnchantingFrameAutoReforgeButton then
	local button = CreateFrame("Button", "MysticMaestroEnchantingFrameAutoReforgeButton", MysticEnchantingFrame, "UIPanelButtonTemplate")
	button:SetWidth(80)
	button:SetHeight(22)
	button:SetPoint("BOTTOMLEFT", 300, 36)
	button:RegisterForClicks("AnyUp")
	button:SetScript("OnClick", function(self)
		if not init then initOptions() end
		if self:GetText() == "Auto Reforge" then
			StartAutoReforge()
		else
			StopAutoReforge()
		end
	end)
	button:SetText("Auto Reforge")
	MysticEnchantingFrameControlFrameRollButton:HookScript("OnEnable", function() itemLoaded = true end )
	MysticEnchantingFrameControlFrameRollButton:HookScript("OnDisable", function() itemLoaded = false end )
end
