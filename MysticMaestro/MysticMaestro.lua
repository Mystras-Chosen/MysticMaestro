local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local AceGUI = LibStub("AceGUI-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

MM.OnUpdateFrame = CreateFrame("Frame")

function MM:OnInitialize()
  MM:SetupDatabase()

  MM:RegisterEvent("MYSTIC_ENCHANT_LEARNED")
  MM:RegisterEvent("MYSTIC_ENCHANT_REFORGE_RESULT")
  MM:RegisterEvent("ADDON_LOADED")
  MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
  MM:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
  MM:RegisterEvent("GUILDBANKFRAME_OPENED");

  if MM.sbSettings.Citys then
    MM:RegisterEvent("ZONE_CHANGED");
    MM:RegisterEvent("ZONE_CHANGED_NEW_AREA");
  end

  MM.RE_CACHE = {}
  local enchantList = C_MysticEnchant.QueryEnchants(9999,1,"",{})
  for _, enchant in pairs(enchantList) do
    MM.RE_CACHE[enchant.SpellID] = enchant
  end
end

function MM:OnEnable()
  MM:StandaloneCityReforgeToggle()
  MM:MinimapIconSetup()

  MM:HookScript(GameTooltip, "OnTooltipSetItem", "TooltipHandlerItem")
  MM:HookScript(GameTooltip, "OnTooltipSetSpell", "TooltipHandlerSpell")

end

--[[
Event Handlers
]]
function MM:ZONE_CHANGED(event, arg1, arg2, arg3)
    -- used to auto hide/show floating button while out off citys
  if event == "ZONE_CHANGED" then
    MM:StandaloneCityReforgeToggle()
  end
end

function MM:ZONE_CHANGED_NEW_AREA(event, arg1, arg2, arg3)
  -- used to auto hide/show floating button while out off citys
  if event == "ZONE_CHANGED_NEW_AREA" then
    MM:StandaloneCityReforgeToggle()
  end
end

function MM:ADDON_LOADED(event, arg1, arg2, arg3)
  -- setup for auction house window
  if event == "ADDON_LOADED" and arg1 == "Blizzard_AuctionUI" then
    MM:initAHTab()
  end
  -- setup for collection frame
  if event == "ADDON_LOADED" and arg1 == "Ascension_EnchantCollection" then
    MM:CollectionSetup()
  end
end

function MM:AUCTION_ITEM_LIST_UPDATE(event, arg1, arg2, arg3)
    -- Auction house events
  if event == "AUCTION_ITEM_LIST_UPDATE" then
    MM:GetAllScan_AUCTION_ITEM_LIST_UPDATE()
    MM:SingleScan_AUCTION_ITEM_LIST_UPDATE()
    MM:BuyCancel_AUCTION_ITEM_LIST_UPDATE()
  end
end
function MM:AUCTION_OWNED_LIST_UPDATE(event, arg1, arg2, arg3)
  if event == "AUCTION_OWNED_LIST_UPDATE" then
    MM:MyAuctions_AUCTION_OWNED_LIST_UPDATE()
    MM:List_AUCTION_OWNED_LIST_UPDATE()
  end
end

function MM:GUILDBANKFRAME_OPENED(event, arg1, arg2, arg3)
  if event == "GUILDBANKFRAME_OPENED" then
    MM:guildBankFrameOpened()
  end
end
