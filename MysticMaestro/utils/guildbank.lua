local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local AceGUI = LibStub("AceGUI-3.0")
local bagnonGuildbank
local frameLoaded
--adds a move to and from buttons to realm/personal/guild bank for auto moving mystic enchanted trinkets 
function MM:guildBankFrameOpened()
	if frameLoaded then return end
	local gFrame = GuildBankFrame
	local toPointX, toPointY = -55,-40
	if select(4,GetAddOnInfo("Bagnon_GuildBank")) then
		gFrame = BagnonFrameguildbank
		toPointX, toPointY = -90, -5
	elseif select(4,GetAddOnInfo("ElvUI")) then
		toPointX, toPointY = -80, -15
	end

	local moveReItemsTobank = CreateFrame("BUTTON", nil, gFrame)
	moveReItemsTobank:SetSize(26,26)
	moveReItemsTobank:SetPoint("TOPRIGHT", gFrame, toPointX, toPointY)
	moveReItemsTobank:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up");
	moveReItemsTobank:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down");
	moveReItemsTobank:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled");
	moveReItemsTobank:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD");
	moveReItemsTobank:SetScript("OnClick", function()
		for bagID = 0, 4 do
			for slotID = 1, GetContainerNumSlots(bagID) do
				local enchant = MM:GetREInSlot(bagID, slotID)
				if enchant then
					if (MM.db.realm.OPTIONS.enableMatching and MM.db.realm.OPTIONS.matchingToBank and MM:MatchConfiguration(enchant)) or not MM.db.realm.OPTIONS.enableMatching or not MM.db.realm.OPTIONS.matchingToBank then
						UseContainerItem(bagID, slotID)
					end
				end
			end
		end
	end)

	local moveReItemsFrombank = CreateFrame("BUTTON", nil, gFrame)
	moveReItemsFrombank:SetSize(26,26)
	moveReItemsFrombank:SetPoint("LEFT", moveReItemsTobank, "RIGHT", 0, 0)
	moveReItemsFrombank:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
	moveReItemsFrombank:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down");
	moveReItemsFrombank:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled");
	moveReItemsFrombank:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD");
	moveReItemsFrombank:SetScript("OnClick", function()
		for c = 1, 112 do
			if GetGuildBankItemLink(GetCurrentGuildBankTab(), c) then
				local itemID = tonumber(select(3, strfind(GetGuildBankItemLink(GetCurrentGuildBankTab(), c), "^|%x+|Hitem:(%-?%d+).*")))
				local enchant = C_MysticEnchant.GetEnchantInfoByItem(itemID)
				if enchant then
					if (MM.db.realm.OPTIONS.enableMatching and MM.db.realm.OPTIONS.mathcingFromBank and MM:MatchConfiguration(enchant)) or not MM.db.realm.OPTIONS.enableMatching or not MM.db.realm.OPTIONS.mathcingFromBank then
						AutoStoreGuildBankItem(GetCurrentGuildBankTab(), c)
					end
				end
			end
		end
	end)
	moveReItemsFrombank:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Move all Mystic Scrolls out of bank")
		GameTooltip:Show()
	end)
	moveReItemsFrombank:SetScript("OnLeave", function() GameTooltip:Hide() end)
	MM.bankMoverOut = moveReItemsFrombank

	moveReItemsTobank:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Move Mystic Scrolls into bank")
		GameTooltip:Show()
	end)
	moveReItemsTobank:SetScript("OnLeave", function() GameTooltip:Hide() end)
	MM.bankMoverIn = moveReItemsTobank

	local moveOnlyMatched = AceGUI:Create("CheckBox")
	moveOnlyMatched.frame:SetParent(gFrame)
	moveOnlyMatched:SetPoint("RIGHT", moveReItemsTobank, "LEFT", 0, 0)
	moveOnlyMatched:SetHeight(25)
	moveOnlyMatched:SetWidth(25)
	moveOnlyMatched:SetCallback("OnValueChanged", function() MM.db.realm.OPTIONS.enableMatching = not MM.db.realm.OPTIONS.enableMatching end)
	moveOnlyMatched:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(moveOnlyMatched.frame, "ANCHOR_RIGHT")
		GameTooltip:SetText("Only move enchants matching my rolling criteria")
		GameTooltip:Show()
	end)
	moveOnlyMatched.frame:Show()
	moveOnlyMatched:SetCallback("OnLeave", function() GameTooltip:Hide() end)
	MM.bankMoverOnlyMatched = moveOnlyMatched


end