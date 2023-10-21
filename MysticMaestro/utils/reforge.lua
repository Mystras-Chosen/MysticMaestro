local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local reforgeActive
local buttonTextTimerHandle
local disenchantingItem, purchasingScroll
local strKnown = "|cff00ff00known|r"
local strUnknown = "|cffff0000unknown|r"

function MM:FindEmptySlot(needTwo)
	local count = 0
	for i=1, 4 do
		for j=1, GetContainerNumSlots(i) do
			local item = GetContainerItemID(i, j)
			if not item then
				if needTwo then
					count = count + 1
					if count >= 2 then return true end
				else
					return true
				end
			end
		end
	end
end

function MM:PurchaseScroll()
	if purchasingScroll then return end
	MM:RegisterEvent("UNIT_SPELLCAST_FAILED")
	purchasingScroll = C_MysticEnchant.PurchaseMysticScroll()
	MM:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	MM:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
end

-- We set an entry point for any reforge requests
function MM:ActivateReforge()
	reforgeActive = true
	MM:RegisterEvent("MYSTIC_ENCHANT_REFORGE_RESULT")

	-- Ensure we are not mounted
	if IsMounted() then Dismount() end

	-- Show floating rune count down
	if MM.rollState ~= "Reforging" then
		MM:ToggleScreenReforgeText(true)
		MM:StandaloneReforgeText(true)
	end
	
	-- Stop attempting if player is moving
	if MM:IsMoving() then MM:TerminateReforge("Player Moving") return end

	-- Retry next frame if we have no altar
	if not C_MysticEnchant.HasNearbyMysticAltar() then Timer.NextFrame(MM.ActivateReforge) return end

	-- Return if we are currently extracting
	if MM:FindExtractable() then return end

	-- Stop attempting if out of runes and configured to do so
	if MM:MatchNoRunes() then MM:TerminateReforge("No Runes") return end

	-- Ensure we have an empty slot to craft into
	if not MM:FindEmptySlot() then MM:TerminateReforge("No Inventory Space") return end
	
	-- Make sure we have an item to reforge
	local item = MM:FindReforgableScroll()
	if not item then
		if MM.db.realm.OPTIONS.purchaseScrolls then
			if MM:FindEmptySlot(true) then MM:PurchaseScroll() end
			if purchasingScroll then return end
		end
		MM:TerminateReforge("Out of Scrolls")
		return
	end

	-- Set the button text to indicate reforge began
	MM.rollState = "Reforging"
	local button = MysticMaestro_CollectionsFrame_ReforgeButton
	if button and not buttonTextTimerHandle then 
		button:SetText("Reforging" .. MM:Dots())
		buttonTextTimerHandle = Timer.NewTicker(1, function() button:SetText("Reforging".. MM:Dots()) end)
	end

	-- All validations have passed, so we can safely proceed to reforge
	MM:ReforgeItem(item)
end

function MM:TerminateReforge(reason)
	if not reforgeActive then return end
	reforgeActive = nil
	disenchantingItem = nil
	purchasingScroll = nil

	if buttonTextTimerHandle then
		buttonTextTimerHandle:Cancel()
		buttonTextTimerHandle = nil
		MysticMaestro_CollectionsFrame_ReforgeButton:SetText("Auto Reforge")
	end

	-- Hide screen text count down
	MM:ToggleScreenReforgeText()
	MM:StandaloneReforgeText()
	MM.rollState = "Start Reforge"
	
	if reason then
		MM:Print("Reforge stopped for " .. reason)
	else
		MM:Print("Reforge has been stopped")
	end

	MM:UnregisterEvent("MYSTIC_ENCHANT_REFORGE_RESULT")
end

function MM:ReforgeItem(itemGuid)
	if C_MysticEnchant.CanReforgeItem(itemGuid) then
		MM:RegisterEvent("UNIT_SPELLCAST_FAILED")
		C_MysticEnchant.ReforgeItem(itemGuid)
		MM:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		MM:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	else
		MM:Print("Was unable to reforge item, trying again in one second")
		Timer.After(1,MM.ActivateReforge)
	end
end

-- This is our entry point for reforge loop
-- We use this with our reforge buttons
function MM:ReforgeToggle()
	if not reforgeActive then
		MM:ActivateReforge()
	else
		MM:TerminateReforge("Button Pressed")
	end

end


-- This will require an event function to handle the disenchantingItem reset
function MM:FindExtractable()
	if disenchantingItem then return true end
	-- gathers a list of scrolls in the inventory
	local inventoryList = C_MysticEnchant.GetMysticScrolls()
	for _, scroll in ipairs(inventoryList) do
		-- fetch the enchant information and check for a match
		local enchant = C_MysticEnchant.GetEnchantInfoByItem(scroll.Entry)
		if enchant and MM:MatchExtractable(enchant) then
			if MM:Extract(enchant) then
				disenchantingItem = true
				return true
			end
		end
	end
end


-- Reforge event functions

local function unregisterSpellCast()
	MM:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	MM:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	MM:UnregisterEvent("UNIT_SPELLCAST_FAILED")
end

function MM:UNIT_SPELLCAST_SUCCEEDED(event, arg1, arg2)
	MM:RemoveAltars(arg2)
	if not reforgeActive and not MM.enchantScroll then return end
	if arg1 ~= "player" then return end
	if arg2 ~= "Reforge Mystic Enchant"
	and arg2 ~= "Disenchant Mystic Enchant"
	and arg2 ~= "Purchase Mystic Scroll" then return end
	MM:RegisterEvent("BAG_UPDATE")
	unregisterSpellCast()
	if arg2 == "Disenchant Mystic Enchant" then
		disenchantingItem = nil
	end
	if arg2 == "Purchase Mystic Scroll" then
		purchasingScroll = nil
	end
end

function MM:UNIT_SPELLCAST_FAILED(event, arg1, arg2)
	if not reforgeActive then return end
	if arg1 ~= "player" then return end
	if arg2 ~= "Reforge Mystic Enchant"
	and arg2 ~= "Disenchant Mystic Enchant"
	and arg2 ~= "Purchase Mystic Scroll" then return end

	unregisterSpellCast()

	if arg2 == "Disenchant Mystic Enchant" then
		disenchantingItem = nil
	end
	if arg2 == "Purchase Mystic Scroll" then
		purchasingScroll = nil
	end
	
	if MM:IsMoving() then MM:TerminateReforge("Player Moving") return end
	Timer.After(MM.db.realm.OPTIONS.delayAfterBagUpdate, MM.ActivateReforge)
end

function MM:BAG_UPDATE()
	MM:UnregisterEvent("BAG_UPDATE")
	if MM.enchantScroll then
		Timer.After(MM.db.realm.OPTIONS.delayAfterBagUpdate, MM.CreateScroll)
		MM.enchantScroll = false
		return
	end
	if not reforgeActive then return end
	Timer.After(MM.db.realm.OPTIONS.delayAfterBagUpdate, MM.ActivateReforge)
end

function MM:UNIT_SPELLCAST_INTERRUPTED(event, arg1, arg2)
	if not reforgeActive then return end
	if arg1 ~= "player" then return end
	if arg2 ~= "Reforge Mystic Enchant"
	and arg2 ~= "Disenchant Mystic Enchant"
	and arg2 ~= "Purchase Mystic Scroll" then return end

	if arg2 == "Disenchant Mystic Enchant" then
		disenchantingItem = nil
	end
	if arg2 == "Purchase Mystic Scroll" then
		purchasingScroll = nil
	end

	unregisterSpellCast()

	if MM:IsMoving() then MM:TerminateReforge("Player Moving") return end

	-- The altar has likely expired, so we put a timer to continue next frame
	Timer.After(1, MM.ActivateReforge)
end

function MM:MYSTIC_ENCHANT_REFORGE_RESULT(event, result, SpellID)
	if not reforgeActive
	or result ~= "RE_REFORGE_OK"
	or SpellID == 0 then return end

	-- Fetch the resulting enchant information
	local currentEnchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
	if not currentEnchant then MM:Print("Error in returning the enchant info for " .. SpellID) return end

	local knownState = currentEnchant.Known and strKnown or strUnknown
	local result = MM:MatchConfiguration(currentEnchant)
	if not MM.db.realm.OPTIONS.noChatResult then
		if result then
			MM:Print("Stopped on " .. knownState .. " enchant:" .. MM:ItemLinkRE(SpellID) .. " because of " .. result)
		else
			MM:Print("Skipping " .. knownState .. " enchant:" .. MM:ItemLinkRE(SpellID))
		end
	end
	MM:AltarLevelRequiredRolls()
	MM:UpdateScreenReforgeText()
end
