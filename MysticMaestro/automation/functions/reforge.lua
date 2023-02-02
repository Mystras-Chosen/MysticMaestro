local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local green = "|cff00ff00"
local red = "|cffff0000"
local itemLoaded = false
local options, autoAutoEnabled, autoReforgeEnabled
local shopEnabledList, shopExtractList, shopReserveList, shopUnknownList
local reforgeHandle, dynamicButtonTextHandle
local bagID, slotIndex
local AltarReforgesText, settingsButton

local function StopCraftingAttemptTimer()
	if reforgeHandle then
		reforgeHandle:Cancel()
		reforgeHandle = nil
	end
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

local function RequestReforge()
	-- attempt to roll every .05 seconds
	if autoReforgeEnabled then
		reforgeHandle = Timer.NewTicker(.05, function()
			if GetUnitSpeed("player") ~= 0 then 
				StopCraftingAttemptTimer()
				StopAutoReforge()
				return
			end
			MysticEnchantingFrameControlFrameRollButton:GetScript("OnClick")(MysticEnchantingFrameControlFrameRollButton)
		end)
	elseif autoAutoEnabled then
		reforgeHandle = Timer.NewTicker(.05, function()
			if GetUnitSpeed("player") ~= 0 then
				StopCraftingAttemptTimer()
				StopAutoReforge()
				return
			end
			RequestSlotReforgeEnchantment(bagID, slotIndex)
		end)
	else
			MM:Print("Error starting reforge, values indicate we are not enabled. AR:" .. autoReforgeEnabled .. " AA:" .. autoAutoEnabled)
	end
end

local function configShoppingMatch(currentEnchant)
	return options.stopForShop.enabled and shopEnabledList[currentEnchant.enchantID] 
	and (not shopUnknownList[currentEnchant.enchantID] or (shopUnknownList[currentEnchant.enchantID] and not IsReforgeEnchantmentKnown(currentEnchant.enchantID)))
end

local function isSeasonal(spellID)
	local enchant = GetMysticEnchantInfo(spellID)
	if enchant then
		return not bit.contains(enchant.realms, Enum.RealmMask.Area52)
	end
end

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
						knownStr = red .. "un" .. knownStr .. "|r"
					else
						knownStr = green .. knownStr .. "|r"
					end
					if shopReserveList[re] then
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
					local ID = MM.RE_LOOKUP[standardStr]
					if ID then
						enabledList[ID] = true
						if list.extract then
							extractList[ID] = true
						end
						if list.reserve then
							reserveList[ID] = true
						end
						if list.unknown then
							unknownList[ID] = true
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
	if not IsReforgeEnchantmentKnown(enchantID) 
	and GetItemCount(98463) and (GetItemCount(98463) > 0) then
			MM:Print("Extracting enchant:" .. MM:ItemLinkRE(enchantID))
			RequestSlotReforgeExtraction(bagID, slotIndex)
	end
end

local function configNoRunes(currentEnchant)
	return options.stopIfNoRunes and GetItemCount(98462) <= 0
end

local function configSeasonalMatch(currentEnchant)
    local eval = options.stopSeasonal.enabled and isSeasonal(currentEnchant.enchantID)
    return eval
end

local function configQualityMatch(currentEnchant)
    return options.stopQuality.enabled and options.stopQuality[currentEnchant.quality]
end

local function configUnknownMatch(currentEnchant)
    return options.stopUnknown.enabled and not IsReforgeEnchantmentKnown(currentEnchant.enchantID) and options.stopUnknown[currentEnchant.quality]
end

local function configPriceMatch(currentEnchant)
    local priceObj = Maestro(currentEnchant.enchantID)
    if not priceObj then return options.stopPrice[currentEnchant.quality] end
    return options.stopPrice.enabled and priceObj.Min >= options.stopPrice.value * 10000 and options.stopPrice[currentEnchant.quality]
end

local function configConditionMet(currentEnchant)
	local unknown = configUnknownMatch(currentEnchant)
	local seasonal = configSeasonalMatch(currentEnchant)
	-- Determine if we should extract this enchant
	if autoAutoEnabled
	and ((unknown and options.stopUnknown.extract)
	or (seasonal and options.stopSeasonal.extract)
	or shopExtractList[currentEnchant.enchantID]) then
		extract(currentEnchant.enchantID)
	end
	-- check for spam reforge settings
	if autoReforgeEnabled and options.stopForNothing then
		return configNoRunes(currentEnchant)
	end
	-- Evaluate the enchant against our options
	return configNoRunes(currentEnchant)
	or configQualityMatch(currentEnchant)
	or configShoppingMatch(currentEnchant)
	or unknown
	or seasonal
	or configPriceMatch(currentEnchant)
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
			local knownStr, seasonal = "", ""
			if not IsReforgeEnchantmentKnown(enchantID) then
				knownStr = red .. "unknown" .. "|r"
			else
				knownStr = green .. "known" .. "|r"
			end
			if isSeasonal(enchantID) then
				seasonal = green .. " seasonal" .. "|r"
			end
			if configConditionMet(currentEnchant) then
				MM:Print("Stopped on " .. knownStr .. seasonal .. " enchant:" .. MM:ItemLinkRE(enchantID))
				if not FindNextInsignia() or GetItemCount(98462) <= 0 then
					if GetItemCount(98462) <= 0 then
						MM:Print("Out of runes")
					else
						MM:Print("Out of Insignia")
					end
					StopAutoReforge()
					return
				end
			else
				MM:Print("Skipping " .. knownStr .. seasonal .. " enchant:" .. MM:ItemLinkRE(enchantID))
			end
		end
		if GetUnitSpeed("player") == 0 then
			RequestReforge()
		else
			StopAutoReforge()
		end
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

function MM:ASCENSION_REFORGE_PROGRESS_UPDATE(event, subEvent, xp, level)
	if subEvent ~= "ASCENSION_REFORGE_PROGRESS_UPDATE" then return end
	if not MM.db.realm.AltarXP then MM.db.realm.AltarXP = 0 end
	if xp == 0 or level == 0 then return end
	local gained = xp - MM.db.realm.AltarXP
	local remaining = AltarLevelRequireXP(level) - xp
	local levelUP = math.floor(remaining / gained) + 1
	AltarReforgesText:SetText("Next level in " .. levelUP .. " reforges")
	MM.db.realm.AltarXP = xp
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

local function UNIT_SPELLCAST_INTERRUPTED()
	if (autoAutoEnabled or autoReforgeEnabled)
	and GetUnitSpeed("player") ~= 0 then
		StopAutoReforge()
	end
end
MM:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED",UNIT_SPELLCAST_INTERRUPTED)

if not MysticMaestroEnchantingFrameAutoReforgeButton then
	local button = CreateFrame("Button", "MysticMaestroEnchantingFrameAutoReforgeButton", MysticEnchantingFrame, "UIPanelButtonTemplate")
	button:SetWidth(80)
	button:SetHeight(22)
	button:SetPoint("BOTTOMLEFT", 300, 37)
	button:RegisterForClicks("AnyUp")
	button:SetScript("OnClick", function(self)
		if not options then initOptions() end
		if self:GetText() == "Auto Reforge" then
			StartAutoReforge()
		else
			StopAutoReforge()
		end
	end)
	button:SetText("Auto Reforge")
	MysticEnchantingFrameControlFrameRollButton:HookScript("OnEnable", function() itemLoaded = true end )
	MysticEnchantingFrameControlFrameRollButton:HookScript("OnDisable", function() itemLoaded = false end )
	AltarReforgesText = MysticEnchantingFrameProgressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	AltarReforgesText:SetPoint("TOP", MysticEnchantingFrameProgressBar, "BOTTOM")
	AltarReforgesText:SetText("Start reforging to get estimate")
	settingsButton = CreateFrame("BUTTON", nil, MysticEnchantingFrame)
	settingsButton:SetSize(27, 27)
	settingsButton:SetPoint("LEFT", MysticMaestroEnchantingFrameAutoReforgeButton, "RIGHT")
	settingsButton:SetNormalTexture("Interface\\AddOns\\MysticMaestro\\textures\\settings_icon")
	settingsButton:SetScript("OnClick",
		function()
			MM:OpenConfig("Reforge")
		end
	)
end
