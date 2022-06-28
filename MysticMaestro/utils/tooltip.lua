local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local function addLinesTooltip(tt, name)
  local stats = MM.db.realm.RE_AH_STATISTICS[name]["current"]
  tt:AddDoubleLine("MM: "..name, (stats and stats.listed or "None" ) .. " Listed")
  if stats ~= nil then
    local ttMin = MM:round((stats.minVal or 0.0) / 10000)
    local ttMed = MM:round((stats.medVal or 0.0) / 10000)
    local ttAvg = MM:round((stats.avgVal or 0.0) / 10000)
    local ttTop = MM:round((stats.topVal or 0.0) / 10000)
    tt:AddDoubleLine("Min (Med/Avg/Top)", ttMin.."g ("..ttMed.."g/"..ttAvg.."g/"..ttTop.."g)")
  end
end

function MM:TooltipHandler(tooltip, event)
  local enchant
  -- Handle Item Tooltips
  if event == "OnTooltipSetItem" then
    enchant = MM:MatchTooltipRE(tooltip)
  -- Handle Spell Tooltips
  elseif event == "OnTooltipSetSpell" then
    enchant = select(3 , tooltip:GetSpell())
    if MYSTIC_ENCHANTS[enchant] == nil then
      return
    end
  end
  if enchant then
    addLinesTooltip(tooltip, enchant)
  end
end

GameTooltip:HookScript(
  "OnTooltipSetItem",
  function(self)
    MM:TooltipHandler(self, "OnTooltipSetItem")
  end
)

GameTooltip:HookScript(
  "OnTooltipSetSpell",
  function(self)
    MM:TooltipHandler(self, "OnTooltipSetSpell")
  end
)
