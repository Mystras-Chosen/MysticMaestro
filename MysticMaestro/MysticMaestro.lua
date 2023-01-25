local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local AceGUI = LibStub("AceGUI-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

MM.OnUpdateFrame = CreateFrame("Frame")

local GetSpellInfo = GetSpellInfo

function MM:OnInitialize()
  MM:SetupDatabase()
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

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", function()
  MM:Scan_AUCTION_ITEM_LIST_UPDATE()
  MM:GetAllScan_AUCTION_ITEM_LIST_UPDATE()
  MM:SingleScan_AUCTION_ITEM_LIST_UPDATE()
  MM:BuyCancel_AUCTION_ITEM_LIST_UPDATE()
end)

MM:RegisterEvent("AUCTION_OWNED_LIST_UPDATE", function()
  MM:MyAuctions_AUCTION_OWNED_LIST_UPDATE()
  MM:List_AUCTION_OWNED_LIST_UPDATE()
end)