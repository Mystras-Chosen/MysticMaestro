local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local AceGUI = LibStub("AceGUI-3.0")
local bagnonGuildbank
--adds a move to and from buttons to realm/personal/guild bank for auto moving mystic enchanted trinkets 
function MM:guildBankFrameOpened()
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
                if enchant then --and (MM:SearchLists(enchant.SpellID, "Keep") or (MM:DoRarity(enchant.SpellID,1) and not MM:SearchLists(enchant.SpellID, "Ignore"))) then
                    UseContainerItem(bagID, slotID)
                end
            end
        end
    end)
    moveReItemsTobank:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Move all Mystic Scrolls into bank that are\n on a list of meet your set roll conditions")
		GameTooltip:Show()
    end)
    moveReItemsTobank:SetScript("OnLeave", function() GameTooltip:Hide() end)
    MM.bankMoverIn = moveReItemsTobank


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
                if C_MysticEnchant.GetEnchantInfoByItem(itemID) then
                    AutoStoreGuildBankItem(GetCurrentGuildBankTab(), c)
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
     MM:UnregisterEvent("GUILDBANKFRAME_OPENED")
end