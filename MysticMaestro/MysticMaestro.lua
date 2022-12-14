local addonName, addonTable = ...

local AceAddon = LibStub("AceAddon-3.0")
local MM = AceAddon:NewAddon("MysticMaestro", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceBucket-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

MM.OnUpdateFrame = CreateFrame("Frame")

local GetSpellInfo = GetSpellInfo

local enchantMT = {
  __index = function(t, k)
    local newListing = {}
    t[k] = newListing
    return newListing
  end
}
local defaultDB = {
  realm = {
    OPTIONS = {
      confirmList = true,
      confirmBuyout = true,
      confirmCancel = true,

      allowEpic = false,
      limitIlvl = 71,
      limitGold = 2,

      myTimeout = 20,
      mySortAlpha = false,

      useGetall = true,
      rarityMagic = true,
      rarityRare = true,
      rarityEpic = true,
      rarityLegendary = true,

      ttKnownIndicator = true,
      ttEnable = true,
      
      ttMin = true,
      ttGPO = true,
      ttMed = false,
      ttMean = false,
      ttMax = false,

      ttTENMin = true,
      ttTENGPO = false,
      ttTENMed = false,
      ttTENMean = false,
      ttTENMax = false,
    },
    VIEWS = {
      sort = 1,
      filter = {
        allQualities = true,
        uncommon = false,
        rare = false,
        epic = false,
        legendary = false,
        allKnown = true,
        known = false,
        unknown = false,
        favorites = false,
        bags = false
      }
    }
  }
}

function MM:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("MysticMaestroDB",defaultDB,true)
  self.db.realm.RE_AH_LISTINGS = setmetatable(self.db.realm.RE_AH_LISTINGS or {}, enchantMT)
  self.db.realm.RE_AH_STATISTICS = setmetatable(self.db.realm.RE_AH_STATISTICS or {}, enchantMT)
  self.db.realm.FAVORITE_ENCHANTS = self.db.realm.FAVORITE_ENCHANTS or {}
  self.db.realm.VIEWS = self.db.realm.VIEWS or {}
  self.db.realm.OPTIONS = self.db.realm.OPTIONS or {}
  MM:RegisterEvent("COMMENTATOR_SKIRMISH_QUEUE_REQUEST")
end

function MM:OnEnable()
  MM:HookScript(GameTooltip, "OnTooltipSetItem", "TooltipHandlerItem")
  MM:HookScript(GameTooltip, "OnTooltipSetSpell", "TooltipHandlerSpell")
end

function MM:ProcessSlashCommand(input)
  local lowerInput = input:lower()
  if lowerInput:match("^fullscan$") or lowerInput:match("^getall$") then
    MM:HandleGetAllScan()
  elseif lowerInput:match("^scan") then
    MM:HandleScan(input:match("^%w+%s+(.+)"))
  elseif lowerInput:match("^calc") then
    MM:CalculateAllStats()
  elseif input == "" then
    MM:HandleMenuSlashCommand()
  else
    MM:Print("Command not recognized")
    MM:Print("Valid input is scan, getall, calc")
    MM:Print("Scan Rarity includes all, uncommon, rare, epic, legendary")
  end
end

MM:RegisterChatCommand("mm", "ProcessSlashCommand")

MM.RE_LOOKUP = {}
MM.RE_KNOWN = {}
MM.RE_NAMES = {}
MM.RE_ID = {}
for k, v in pairs(MYSTIC_ENCHANTS) do
  if v.spellID ~= 0 then
    local enchantName = GetSpellInfo(v.spellID)
    MM.RE_LOOKUP[enchantName] = v.enchantID
    MM.RE_NAMES[v.enchantID] = enchantName
    MM.RE_KNOWN[v.enchantID] = IsReforgeEnchantmentKnown(v.enchantID)
    if v.spellID ~= v.enchantID then
      MM.RE_ID[v.spellID] = v.enchantID
    end
  end
end

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", function()
  MM:Scan_AUCTION_ITEM_LIST_UPDATE()
  MM:GetAllScan_AUCTION_ITEM_LIST_UPDATE()
  MM:SelectScan_AUCTION_ITEM_LIST_UPDATE()
  MM:BuyCancel_AUCTION_ITEM_LIST_UPDATE()
end)

MM:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", function()
  MM:MyAuctions_AUCTION_OWNED_LIST_UPDATE()
  MM:List_AUCTION_OWNED_LIST_UPDATE()
end)