local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local scan = {
  ShowInitPrompt = function() end,
  Start = function() end,
  Stop = function() end
}

scan.Options = {}

MM.AutomationManager:RegisterAutomation("Scan", scan)