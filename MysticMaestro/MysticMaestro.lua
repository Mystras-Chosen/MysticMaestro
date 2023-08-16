local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local AceGUI = LibStub("AceGUI-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

MM.OnUpdateFrame = CreateFrame("Frame")

function MM:OnInitialize()
  MM:SetupDatabase()
  MM:RegisterEvent("MYSTIC_ENCHANT_LEARNED")
  MM:RegisterEvent("MYSTIC_ENCHANT_REFORGE_RESULT")
  --MM:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
  MM:RegisterEvent("ADDON_LOADED")
  MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
  MM:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
  MM:RegisterEvent("GUILDBANKFRAME_OPENED");
  MM:RegisterEvent("ZONE_CHANGED");
  MM:RegisterEvent("ZONE_CHANGED_NEW_AREA", MM.ZONE_CHANGED);
end

function MM:OnEnable()

  MM:HookScript(GameTooltip, "OnTooltipSetItem", "TooltipHandlerItem")
  MM:HookScript(GameTooltip, "OnTooltipSetSpell", "TooltipHandlerSpell")

  MM:StandaloneButtonOnLoad()
  MM:MinimapIconSetup()

end

--[[
Event Handlers
]]
function MM:ZONE_CHANGED(event, arg1, arg2, arg3)
    -- used to auto hide/show floating button in citys
  if event == "ZONE_CHANGED" or event == "ZONE_CHANGED_NEW_AREA" then
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
    MM.CollectionSetup()
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
