local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Scan"

local isPaused

local automationTable = {}

function automationTable.GetName()
  return automationName
end

function automationTable.ShowInitPrompt()
  print("showinitprompt called")
  MM.AutomationUtil.ShowAutomationPrompt(automationName, automationTable)
end

function automationTable.Start()
  print("start called")
end

function automationTable.Pause()
  print("pause called")
  isPaused = true
end

function automationTable.IsPaused()
  return isPaused
end

function automationTable.Stop()
  print("stop called")
  MM.AutomationUtil.HideAutomationPrompt()
  isPaused = false
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)