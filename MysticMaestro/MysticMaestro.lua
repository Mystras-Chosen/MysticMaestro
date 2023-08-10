local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local AceGUI = LibStub("AceGUI-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

MM.OnUpdateFrame = CreateFrame("Frame")

local GetSpellInfo = GetSpellInfo

function MM:OnInitialize()
  MM:SetupDatabase()
  MM:RegisterEvent("MYSTIC_ENCHANT_LEARNED")
end

function MM:OnEnable()
  MM:HookScript(GameTooltip, "OnTooltipSetItem", "TooltipHandlerItem")
  MM:HookScript(GameTooltip, "OnTooltipSetSpell", "TooltipHandlerSpell")
end

-- MM.RE_NAMES = {}
-- for k, v in pairs(MYSTIC_ENCHANTS) do
--   if v.spellID ~= 0 and v.flags ~= 1 then
--     local enchantName = GetSpellInfo(v.spellID)
--     MM.RE_NAMES[v.enchantID] = enchantName
--   end
-- end

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", function()
  MM:GetAllScan_AUCTION_ITEM_LIST_UPDATE()
  MM:SingleScan_AUCTION_ITEM_LIST_UPDATE()
  MM:BuyCancel_AUCTION_ITEM_LIST_UPDATE()
end)

MM:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", function()
  MM:MyAuctions_AUCTION_OWNED_LIST_UPDATE()
  MM:List_AUCTION_OWNED_LIST_UPDATE()
end)