local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local Wrappers = {}
MM.w = Wrappers




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