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

local currentIndex
local running

function automationTable.Start()
  print("start called")
  -- collect list of enchants to search if not paused
  -- show progress bar (set automation table, and make buttons visible based on whether or not automation is pausable, set progress current and max)
  -- update progress bar
  MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "running")
  isPaused = false
  currentIndex = currentIndex or 1
  MM.AutomationUtil.SetProgressBarValues(currentIndex-1, 100)
  lastUpdate = GetTime()
  running = true
end

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    if running and not isPaused and lastUpdate < GetTime() - .05 then
      MM.AutomationUtil.SetProgressBarValues(currentIndex, 100)
      currentIndex = currentIndex + 1
      lastUpdate = GetTime()
    end
  end
)

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
  running = false
  lastUpdate = nil
  currentIndex = nil
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)