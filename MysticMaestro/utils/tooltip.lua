local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:TooltipHandler(tooltip, ...)
  local enchantName = MM:MatchTooltipRE(tooltip)
  if enchantName then
    local enchantStats = self.db.realm.RE_AH_STATISTICS[enchantName]["current"]
    tooltip:AddDoubleLine("Mystic Maestro", enchantName)
    if enchantStats ~= nil then
      local ttMin = (enchantStats.minVal or 0.0) / 10000
      local ttMed = (enchantStats.medVal or 0.0) / 10000
      local ttAvg = (enchantStats.avgVal or 0.0) / 10000
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
