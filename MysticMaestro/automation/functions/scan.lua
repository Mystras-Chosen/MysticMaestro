local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Scan"

local isPaused

local automationTable = {}

function automationTable.GetName()
  return automationName
end

function automationTable.ShowInitPrompt()
  print("showinitprompt called")
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "prompt")
end



function automationTable.Start()
  print("start called")
  -- collect list of enchants to search if not paused
  -- show progress bar (set automation table, and make buttons visible based on whether or not automation is pausable, set progress current and max)
  -- update progress bar
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "running")
  isPaused = false
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
  MM.AutomationUtil.HideAutomationPopup()
  isPaused = false
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)