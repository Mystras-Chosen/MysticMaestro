local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

MM.OnUpdateFrame = CreateFrame("Frame")

local GetSpellInfo = GetSpellInfo

function MM:OnInitialize()
  MM:SetupDatabase()
  --MM:RegisterEvent("MYSTIC_ENCHANT_LEARNED")
  MM:RegisterEvent("ADDON_LOADED", MM.collectionSetup)
end

function MM:OnEnable()
  MM:HookScript(GameTooltip, "OnTooltipSetItem", "TooltipHandlerItem")
  MM:HookScript(GameTooltip, "OnTooltipSetSpell", "TooltipHandlerSpell")
  MM:AddressCompatibility()
end

MM.RE_LOOKUP = {}
MM.RE_KNOWN = {}
MM.RE_NAMES = {}
MM.RE_ID = {}

function MM:AddressCompatibility()

  local function transformEnchantQuality(qualityString)
    if qualityString == "RE_QUALITY_LEGENDARY" then
      return 5 --"legendary"
    elseif qualityString == "RE_QUALITY_EPIC" then
      return 4 -- "epic"
    elseif qualityString == "RE_QUALITY_RARE" then
      return 3 --"rare"
    elseif qualityString == "RE_QUALITY_UNCOMMON" then
      return 2 --"uncommon"
    else
      print("trying to transform unknown enchant quality: " .. (qualityString or ""))
    end
  end
  
  local results = C_MysticEnchant.QueryEnchants(10000, 1, "", {})
  
  local enchants = {}
  for _, enchantData in ipairs(results) do
    enchants[enchantData.SpellID] = {
      spellID = enchantData.SpellID,
      flags = enchantData.IsWorldforged and 1 or false,
      quality = transformEnchantQuality(enchantData.Quality),
      spellName = enchantData.SpellName,
      known = enchantData.Known,
      enchantID = enchantData.SpellID,
    }
  end
  
  MYSTIC_ENCHANTS = enchants
  
  function IsReforgeEnchantmentKnown(spellID) -- old API function. was enchantID, but now should be spellID
    return enchants[spellID].known
  end
  
  function GetREInSlot(bagID, containerIndex)
    for _, scrollData in ipairs(C_MysticEnchant.GetMysticScrolls()) do
      if scrollData.Bag == bagID and scrollData.Slot == containerIndex then
        local enchantInfo = C_MysticEnchant.GetEnchantInfoByItem(scrollData.Entry)
        if enchantInfo and enchantInfo.SpellID then
          return enchantInfo.SpellID
        end
      end
    end
  end
  
  function GetREData(spellID)
    local enchantData = MYSTIC_ENCHANTS[spellID]
    return {
      spellName = enchantData.spellName,
      quality = enchantData.quality, -- color
      spellID = enchantData.spellID,
      enchantID = enchantData.spellID
    }
  end
  
  -- spellID, flags, enchantID, quality, spellName, 
  
  EnchantQualitySettingsWithBar = {
    [5] = "|cFFFF8000", -- 255, 128, 0
    [4] = "|cFFA335EE", -- 163, 53, 238
    [3] = "|cFF0070DD", -- 0, 112, 221
    [2] = "|cFF1EFF00", -- 30, 255, 0
  }
  
  
  EnchantQualitySettings = {
    [5] = "\124cFFFF8000", -- 255, 128, 0
    [4] = "\124cFFA335EE", -- 163, 53, 238
    [3] = "\124cFF0070DD", -- 0, 112, 221
    [2] = "\124cFF1EFF00", -- 30, 255, 0
  }

  for k, v in pairs(MYSTIC_ENCHANTS) do
    if v.spellID ~= 0 and v.flags ~= 1 then
      local enchantName = GetSpellInfo(v.spellID)
      MM.RE_LOOKUP[enchantName] = v.enchantID
      MM.RE_NAMES[v.enchantID] = enchantName
      MM.RE_KNOWN[v.enchantID] = IsReforgeEnchantmentKnown(v.enchantID)
      if v.spellID ~= v.enchantID then
        MM.RE_ID[v.spellID] = v.enchantID
      end
    end
  end
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