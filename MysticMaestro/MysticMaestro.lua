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

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", function()
  MM:GetAllScan_AUCTION_ITEM_LIST_UPDATE()
  MM:SingleScan_AUCTION_ITEM_LIST_UPDATE()
  MM:BuyCancel_AUCTION_ITEM_LIST_UPDATE()
end)

MM:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", function()
  MM:MyAuctions_AUCTION_OWNED_LIST_UPDATE()
  MM:List_AUCTION_OWNED_LIST_UPDATE()
end)



-- Action Functions:
-- C_MysticEnchant.CollectionReforgeSlot(<number>slotID, <number>enchantSpellID)
-- C_MysticEnchant.PurchaseMysticScroll() -> <bool>packetSent
-- C_MysticEnchant.Inspect(<string>unitToken, <bool>forceUpdate) -> <bool>packetSent, <table, nil>inspectInfo
-- C_MysticEnchant.ApplySlot(<number>slotID, <number>itemGUID) -> <bool>packetSent
-- C_MysticEnchant.ApplyItem(<number>slotID, <number>itemGUID) -> <bool>packetSent
-- C_MysticEnchant.SaveCollectionReforge() -> <bool>packetSent
-- C_MysticEnchant.SaveApply() -> <bool>packetSent
-- C_MysticEnchant.DisenchantItem(<nubmer>itemGUID) -> <bool>packetSent
-- C_MysticEnchant.CollectionReforgeItem(<number>itemGUID) -> <bool>packetSent
-- C_MysticEnchant.DisenchantSlot(<number>slotID) -> <bool>packetSent
-- C_MysticEnchant.ReforgeItem(<number>itemGUID) -> <bool>packetSent
-- C_MysticEnchant.ReforgeSlot(<number>slotID) -> <bool>packetSent

-- Get Functions:
-- C_MysticEnchant.GetMysticScrollCost() -> <number>goldCost
-- C_MysticEnchant.GetProgress() -> <number>percentForLevel, <number>level
-- C_MysticEnchant.GetAppliedEnchant(<number>slotID) -> <number>spellID
-- C_MysticEnchant.GetEnchantInfoBySpell(<number>spellID) -> <table>enchantInfo
-- C_MysticEnchant.GetEnchantInfoByItem(<number>itemID) -> <table, nil>mysticEnchantInfo
-- C_MysticEnchant.GetCollectionReforgeChanges() -> <table>pendingCollectionReforges
-- C_MysticEnchant.GetMysticScrolls() -> <table>items
-- C_MysticEnchant.GetReforgeCost() -> <number>tokenCost, <number>goldCost
-- C_MysticEnchant.QueryEnchants(<number>entriesPerPage, <number>page, <string>search, <table<string>> additionalFilters) -> <table<enchants>> enchants, <number>totalPages
-- C_MysticEnchant.GetApplyChanges() -> <table>pendingEnchants
-- C_MysticEnchant.GetDisenchantCost() -> <number>tokenCost

-- Check Functions:
-- C_MysticEnchant.HasAnyScroll() -> <bool>hasAnyScrolls
-- C_MysticEnchant.CanCollectionReforgeSlot() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.CanCollectionReforgeAnySlot() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.CanApplySlot() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.HasAnySlotEnchanted() -> <bool>anyEnchanted
-- C_MysticEnchant.CanSaveApply() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.CanInspect(<string>unitToken) -> <bool>canInspect, <table>failReason
-- C_MysticEnchant.CanDisenchantItem() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.CanCollectionReforgeItem() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.CanDisenchantSlot() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.CanReforgeSlot() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.HasAnyCollected() -> <bool>anyEnchantsCollected
-- C_MysticEnchant.CanSaveCollectionReforge() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.CanReforgeItem() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.CanApplyItem() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.HasNearbyMysticAltar() -> <bool>hasNearbyAltar
-- C_MysticEnchant.CanPurchaseMysticScroll() -> <bool>allowed, <table>failReason
-- C_MysticEnchant.CanApplyAnySlot(<number>itemGUID) -> <bool>canApply
-- C_MysticEnchant.GetCollectionReforgeSlotCost(<number>spellID) -> <number>tokenCost, <number>goldCost
-- C_MysticEnchant.GetCollectionReforgeItemCost(<number>spellID) -> <number>tokenCost, <number>goldCost
-- C_MysticEnchant.GetSaveCollectionReforgeSlotCost() -> <number>tokenCost, <number>goldCost
-- C_MysticEnchant.GetApplyItemCost(<number>slot) -> <number>tokenCost, <number>goldCost

-- Undo Functions:
-- C_MysticEnchant.UndoApply(<number>slotID)
-- C_MysticEnchant.UndoCollectionReforge(<number>slotID)
-- C_MysticEnchant.UndoLastCollectionReforge()
-- C_MysticEnchant.UndoLastApply()
 
-- Presets
-- C_MysticEnchantPreset.CanActivate(<number>presetID) -> <bool>canActivate, <table>result
-- C_MysticEnchantPreset.CanSave(<number>presetID) -> <bool>canSave, <table,nil>errorStrings
-- C_MysticEnchantPreset.CanUnlock() -> <bool>canUnlock, <table,nil>errorStrings
-- C_MysticEnchantPreset.GetNumPresets() -> <number>numPresets
-- C_MysticEnchantPreset.GetPresetData(<number>presetID) -> <table>enchantSpells, <bool>isActive
-- C_MysticEnchantPreset.Unlock() -> <bool>packetSent
-- C_MysticEnchantPreset.Save(<number>presetID) -> <bool>packetSent
-- C_MysticEnchantPreset.Activate(<number>presetID) -> <bool>packetSent

-- Lua Utilities
-- MysticEnchantUtil.GetEnchantLink(spellID) -> <string>spellLink
-- MysticEnchantUtil.IsSpellMysticEnchant(spellID) -> <bool>isMysticEnchant
-- MysticEnchantUtil.GetLegendaryEnchantID() -> <number>spellID
-- MysticEnchantUtil.GetAppliedEnchantCountByQuality() -> <qualityTable<spellTable>>enchants (enchants[quality][spellID] = count)
 
-- Events
-- MYSTIC_ENCHANT_LEARNED: <number>spellID
-- MYSTIC_ENCHANT_UNLEARNED: <number>spellID
-- MYSTIC_ENCHANT_SLOT_UPDATE: <number>slotID
-- MYSTIC_ENCHANT_REFORGE_RESULT: <string>result, <number>spellID
-- MYSTIC_ENCHANT_COLLECTION_REFORGE_RESULT: <string>result
-- MYSTIC_ENCHANT_DISENCHANT_RESULT: <string>result
-- MYSTIC_ENCHANT_APPLY_RESULT: <string>result
-- MYSTIC_ENCHANT_PURCHASE_RESULT: <string>result
-- MYSTIC_ENCHANT_INSPECT_RESULT: <string>result
-- MYSTIC_ENCHANT_PATCHED: <number>spellID -- hot patching, probably no use to addons
-- MYSTIC_ENCHANT_PRESET_SAVE_RESULT: <string>result
-- MYSTIC_ENCHANT_PRESET_SET_ACTIVE_RESULT: <string>result
-- MYSTIC_ENCHANT_PRESET_UNLOCK_RESULT: <string>result
-- MYSTIC_SCROLL_USED: <number>itemID
-- MYSTIC_ALTAR_USED
-- MYSTIC_ALTAR_CLOSED