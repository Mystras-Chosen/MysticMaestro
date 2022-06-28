local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:TooltipHandler(tooltip, ...)
  local enchantName = MM:MatchTooltipRE(tooltip)
  if enchantName then
    local enchantStats = self.db.realm.RE_AH_STATISTICS[enchantName]["current"]
    tooltip:AddDoubleLine("Mystic Maestro", enchantName)
    if enchantStats ~= nil then
      local ttMin = tonumber(enchantStats.minVal) / 10000 or 0.0
      local ttMed = tonumber(enchantStats.medVal) / 10000 or 0.0
      local ttAvg = tonumber(enchantStats.avgVal) / 10000 or 0.0
      tooltip:AddDoubleLine("Number Listed", enchantStats.listed or 0.0)
      tooltip:AddDoubleLine("Min/Med/Avg", "("..ttMin.."/"..ttMed.."/"..ttAvg..")")
    else
      tooltip:AddDoubleLine("Number Listed", "none found")
    end
  end
end

GameTooltip:HookScript(
  "OnTooltipSetItem",
  function(...)
    MM:TooltipHandler(...)
  end
)
