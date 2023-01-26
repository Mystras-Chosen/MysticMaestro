local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Reforge"

local isPaused

local automationTable = {}

function automationTable.GetName()
  return automationName
end

local options

function automationTable.ShowInitPrompt()
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
	BuildWorkingShopList()
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "prompt")
end

local running

function automationTable.Start()
end

function automationTable.Pause()
  if running then
    isPaused = true
    MM.AutomationUtil.HideAutomationPopup()
  elseif isPaused then -- can be called when already paused and init prompt showing
    MM.AutomationUtil.HideAutomationPopup()
  else
    MM:Print("ERROR: " .. automationName .." paused when not running")
  end
end

function automationTable.IsPaused()
  return isPaused
end

function automationTable.Stop()
  MM.AutomationUtil.HideAutomationPopup()
  isPaused = false
  running = false
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)

-- Refactored code below

local itemLoaded = false
local bagID, slotIndex, autoAutoEnabled, autoReforgeEnabled
local enchantsOfInterest
local reforgeHandle

-- Options to configure:
-- stopForShop.enabled, stopForShop.unknown, shoppingLists
-- stopSeasonal.enabled, stopSeasonal.extract
-- stopSeasonal.enabled, stopSeasonal.extract
-- stopQuality.enabled, options.stopQuality[tostring(currentEnchant.quality)]
-- stopUnknown.enabled, stopUnknown.extract, stopUnknown[tostring(currentEnchant.quality)]
-- stopIfNoRunes
-- stopPrice.enabled, stopPrice.value, stopPrice[tostring(currentEnchant.quality)]

if not MysticMaestroEnchantingFrameAutoReforgeButton then
	local button = CreateFrame("Button", "MysticMaestroEnchantingFrameAutoReforgeButton", MysticEnchantingFrame, "UIPanelButtonTemplate")
	button:SetWidth(80)
	button:SetHeight(22)
	button:SetPoint("BOTTOMLEFT", 300, 36)
	-- button:Disable()
	button:RegisterForClicks("AnyUp")
	button:SetScript("OnClick", function(self)
		if itemLoaded then
			if self:GetText() == "Auto Reforge" then
				StartAutoReforge()
				RequestReforge()
			else
				StopAutoReforge()
			end
		else
			if self:GetText() == "Auto Reforge" then
				StartAutoAutoReforge()
			else
				StopAutoAutoReforge()
			end
		end
	end)
	button:SetText("Auto Reforge")
	MysticEnchantingFrameControlFrameRollButton:HookScript("OnEnable", function() itemLoaded = true end )
	MysticEnchantingFrameControlFrameRollButton:HookScript("OnDisable", function() itemLoaded = false end )
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

local colorHex = {
    ["green"] = "|cff00ff00",
    ["red"] = "|cffff0000"
}

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

local function configNoRunes(currentEnchant)
    return options.stopIfNoRunes and GetItemCount(98462) <= 0
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

local function getLinkRE(ID)
    local RE = MYSTIC_ENCHANTS[ID]
    local color = AscensionUI.MysticEnchant.EnchantQualitySettings[RE.quality][1]
    return color .. "\124Hspell:" .. RE.spellID .. "\124h[" .. RE.spellName .. "]\124h\124r"
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
        print("Extracting enchant:" .. getLinkRE(enchantID))
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
				knownStr = colorHex.red .. "un" .. knownStr .. "|r"
			else
				knownStr = colorHex.green .. knownStr .. "|r"
			end
			if isSeasonal(enchantID) then
				seasonal = colorHex.green .. " seasonal" .. "|r"
			end
			
			if configConditionMet(currentEnchant) then
				print("Stopped on " .. knownStr .. seasonal .. " enchant:" .. getLinkRE(enchantID))

				if not findNextInsignia() or GetItemCount(98462) <= 0 then
					if GetItemCount(98462) <= 0 then
						print("Out of runes")
					else
						print("Out of Insignia")
					end
					WeakAuras.ScanEvents("POLI_AUTO_AUTO_OFF")
					return
				end
			else
				print("Skipping " .. knownStr .. seasonal .. " enchant:" .. getLinkRE(enchantID))
			end
		end
		RequestReforge()
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

local function StopCraftingAttemptTimer()
	if reforgeHandle then
		reforgeHandle:Cancel()
		reforgeHandle = nil
	end
end

local function ThreeDotsString()
	local floorTime = math.floor(GetTime())
	return floorTime % 3 == 0 and "." or (floorTime % 3 == 1 and ".." or "...")
end

-- Trigger 3 : POLI_AUTO_REFORGE_ON, POLI_AUTO_REFORGE_OFF
local function StartAutoReforge()
	autoReforgeEnabled = true
	MysticMaestroEnchantingFrameAutoReforgeButton:SetText("Reforging" .. ThreeDotsString())
	dynamicButtonTextHandle = Timer.NewTicker(1, function()
		MysticMaestroEnchantingFrameAutoReforgeButton:SetText("Reforging" .. ThreeDotsString())
	end)
end

local function StopAutoReforge()
	autoReforgeEnabled = false
	if dynamicButtonTextHandle then
		dynamicButtonTextHandle:Cancel()
		dynamicButtonTextHandle = nil
	end
	MysticMaestroEnchantingFrameAutoReforgeButton:SetText("Auto Reforge")
end

-- Trigger 4 : POLI_AUTO_AUTO_ON, POLI_AUTO_AUTO_OFF
local function StartAutoAutoReforge()
	if bagID == nil then
		bagID = 0
		slotIndex = 0
	end
	if findNextInsignia() then
		autoAutoEnabled = true
		RequestReforge()
	end
	MysticMaestroEnchantingFrameAutoReforgeButton:SetText("Reforging" .. ThreeDotsString())
	dynamicAutoButtonTextHandle = Timer.NewTicker(1, function()
		MysticMaestroEnchantingFrameAutoReforgeButton:SetText("Reforging" .. ThreeDotsString())
	end)
end

local function StopAutoAutoReforge()
	autoAutoEnabled = false
	if dynamicAutoButtonTextHandle then
		dynamicAutoButtonTextHandle:Cancel()
		dynamicAutoButtonTextHandle = nil
	end
	MysticMaestroEnchantingFrameAutoReforgeButton:SetText("Auto Reforge")
end