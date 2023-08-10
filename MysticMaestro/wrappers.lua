local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local Wrappers = {}
MM.w = Wrappers

local function transformEnchantQuality(qualityString)
  if qualityString == "RE_QUALITY_LEGENDARY" then
    return 5 --"legendary"
  elseif qualityString == "RE_QUALITY_EPIC" then
    return 4 -- "epic"
  elseif qualityString == "RE_QUALITY_RARE" then
    return 3 --"rare"
  elseif qualityString == "RE_QUALITY_UNCOMMON" then
    print("uncommon quality")
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

-- spellID, flags, enchantID, quality, spellName, 



EnchantQualitySettings = {
  [5] = "\124cFFFF8000", -- 255, 128, 0
  [4] = "\124cFFA335EE", -- 163, 53, 238
  [3] = "\124cFF0070DD", -- 0, 112, 221
  [2] = "\124cFF1EFF00", -- 30, 255, 0
}


-- [30]={
--   Known=true,
--   IsAvailableForCurrentClass=true,
--   Quality="RE_QUALITY_LEGENDARY",
--   ItemID=1178447,
--   IsWorldforged=false,
--   RequiredLevel=0,
--   MaxStacks=32767,
--   SpellName="Dragon Warrior",
--   SpellID=954252
-- },

-- [1]="Dragon Warrior",
-- [2]="Rank 5",
-- [3]="Interface\\Icons\\ability_warrior_dragonroar",
-- [4]=0,
-- [5]=false,
-- [6]=0,
-- [7]=0,
-- [8]=0,
-- [9]=0


-- [1]={
--   Bag=3,
--   Name="Mystic Scroll: Powerful Chain Lightning",
--   Guid=264048666,
--   Entry=1176364,
--   Slot=22
-- },
-- [2]={
--   Bag=3,
--   Name="Mystic Scroll: Concentrated Hand of Salvation",
--   Guid=264036493,
--   Entry=1176551,
--   Slot=23
-- }

-- Dump: value=C_MysticEnchant.GetMysticScrolls()
-- [1]={
--   [1]={
--     Bag=0,
--     Name="Mystic Scroll: Powerful Chain Lightning",
--     Guid=264048666,
--     Entry=1176364,
--     Slot=1
--   },
--   [2]={
--     Bag=0,
--     Name="Mystic Scroll: Concentrated Hand of Salvation",
--     Guid=264036493,
--     Entry=1176551,
--     Slot=2
--   },
--   [3]={
--     Bag=0,
--     Name="Untarnished Mystic Scroll",
--     Guid=753344230,
--     Entry=992720,
--     Slot=3
--   },
--   [4]={
--     Bag=0,
--     Name="Untarnished Mystic Scroll",
--     Guid=753344232,
--     Entry=992720,
--     Slot=4
--   },
--   [5]={
--     Bag=0,
--     Name="Untarnished Mystic Scroll",
--     Guid=753344304,
--     Entry=992720,
--     Slot=5
--   }

--C_MysticEnchant.CollectionReforgeItem(753344232)

--753344230, 954252


-- MYSTIC_ALTAR_USED
-- GetBorderStyleForSlot
-- IsItemDataPosAndEntryEqual
-- GetFakeSlotID
-- GetSlotMapForEnchants
-- GetTempSlotData
-- CalculateReforgeCost
-- ApplyScrollEnchant
-- HandleCostDialogue
-- GetCollectionReforgeSlotCostWithAppliedChanges
-- FormatCostIconOnly
-- GetQualityFromQualityName
-- CalculateExtractCost
-- GetAltar
-- ShowApplyDialogue
-- IsItemGUIDLowEqual
-- GetBorderStyleAnimated
-- GetSlotData
-- MYSTIC_ALTAR_CLOSED
-- ShowDisenchantSlotDialogue
-- CheckSlotMap
-- CalculateCollectionReforgeCost
-- RefreshTempData
-- GetCollectionReforgeItemCost
-- GetCollectionReforgeSlotCost
-- Apply
-- ClearStagedChanges
-- AttemptOperation
-- IsCollectionReforge
-- GetFakePositionMap
-- HasStagedChanges
-- GetSlotSettings
-- MYSTIC_ENCHANT_UNLOCK_PRESET_USED
-- RefundEnchant
-- ShowDisenchantItemDialogue
-- CanApplyQualityToSlot
-- MYSTIC_SCROLL_USED
-- ShowDestroySlotDialogue
-- GetRealSlotID
-- SetTexRotationWithCoord
-- ShowCollectionReforgeItemDialogue
-- Init
-- ApplyCollectionEnchant
-- GetQuestionMarkStyle