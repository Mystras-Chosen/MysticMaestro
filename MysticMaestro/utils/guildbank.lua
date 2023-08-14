local MM = MysticMaestro
local bagnonGuildbank
--adds a move to and from buttons to realm/personal/guild bank for auto moving mystic enchanted trinkets 
function MM:guildBankFrameOpened()
    local gFrame = GuildBankFrame
    local toPointX, toPointY = -255,-39
    local fromPointX, fromPointY = 255,-39
    if bagnonGuildbank then
        gFrame = BagnonFrameguildbank
        toPointX, toPointY = -80, 25
        fromPointX, fromPointY = 80, 25
    end
    local moveReItemsTobank = CreateFrame("Button", nil, gFrame, "OptionsButtonTemplate");
    moveReItemsTobank:SetSize(135, 26);
    moveReItemsTobank:SetPoint("TOP", gFrame, "TOP", toPointX, toPointY);
    moveReItemsTobank:SetText("Move To Bank");
    moveReItemsTobank:SetScript("OnClick", function()
        for bagID = 0, 4 do
            for slotID = 1, GetContainerNumSlots(bagID) do
                local enchantID = GetREInSlot(bagID, slotID)
                if enchantID and getItemID(bagID, slotID) and
                (MM:SearchLists(enchantID, "Keep") or (MM:DoRarity(enchantID,1) and not MM:SearchLists(enchantID, "Ignore"))) then
                    UseContainerItem(bagID, slotID)
                end
            end
        end
    end)
    local moveReItemsFrombank = CreateFrame("Button", nil, gFrame, "OptionsButtonTemplate");
    moveReItemsFrombank:SetSize(135, 26);
    moveReItemsFrombank:SetPoint("TOP", gFrame, "TOP", fromPointX, fromPointY);
    moveReItemsFrombank:SetText("Move To Inventory");
    moveReItemsFrombank:SetScript("OnClick", function()
        for c = 1, 112 do
            if GetGuildBankItemLink(GetCurrentGuildBankTab(), c) then
                local id = tonumber(select(3,
                    strfind(GetGuildBankItemLink(GetCurrentGuildBankTab(), c), "^|%x+|Hitem:(%-?%d+).*")))
                if getItemID(nil, nil, id) then
                    AutoStoreGuildBankItem(GetCurrentGuildBankTab(), c)
                end
            end
        end
    end)
     MM:UnregisterEvent("GUILDBANKFRAME_OPENED");
end