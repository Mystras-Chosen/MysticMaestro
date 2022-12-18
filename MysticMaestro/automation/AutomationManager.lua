local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
--[[
automationTable = {
  ShowInitPrompt = function() end,  -- sets up widgets, title, configurations, estimated time, start and cancel buttons
  Cancel = function() end,          -- cleans up automation behavior
  Start = function() end,           -- sets up widgets, progress bar, status, cancel button
  PostProcessing = function() end,  -- optional window if post-processing is required
  Pause = function() end            -- optional if automation is pausable
}
]]

MM.AutomationManager = {}

local automationTables = {}
function MM.AutomationManager:AddAutomation(automationName, automationTable)
  automationTables[automationName] = automationTable
end

local currentAutomation, currentTask -- init, running, postprocessing, paused

local function setMenuLocked(isLocked)
  -- TODO
end

function MM.AutomationManager:InitAutomation(automationName)
  if automationName == currentAutomation and currentTask == "paused" or not currentAutomation then
    currentTask = "init"
    setMenuLocked(true)
    currentAutomation.ShowInitPrompt()
  else
    MM:Print("ERROR: Attempt to initialize automation function while another is running")
  end
end

local function terminateAutomation()
  currentAutomation = nil
  currentTask = nil
  setMenuLocked(false)
end

function MM.AutomationManager:StopAutomation()
  if currentAutomation and currentAutomation.Pause then
    currentTask = "paused"
    currentAutomation.Pause()
    setMenuLocked(false)
    MM:Print("Automation function paused")
  else
    terminateAutomation()
    MM:Print("Automation function canceled")
  end
end

local function logStatusError(status)
  MM:Print("ERROR: Unrecognized automation function status \"" .. tostring(status) .. "\"")
end

local function manageAutomationFunction(status)
  if status == "cancel" then
    currentAutomation.Cancel()
    terminateAutomation()
    return
  end
  if currentTask == "init" then
    if status == "start" then
      currentTask = "running"
      currentAutomation.Start()
    elseif status == "stop" then
      currentTask = "init"
      currentAutomation.ShowInitPrompt()
    else
      logStatusError(status)
    end
  elseif currentTask == "running" then
    if status == "finished" then
      if currentAutomation.PostProcessing then
        currentTask = "postprocessing"
        currentAutomation.PostProcessing()
      else
        terminateAutomation()
      end
    else
      logStatusError(status)
    end
  elseif currentTask == "postprocessing" then
    if status == "finished" then
      terminateAutomation()
    else
      logStatusError(status)
    end
  end
end

-- tell automation manager that it is done executing the current task
function MM.AutomationManager:Inform(automationTable, status)
  if automationTable == currentAutomation then
    manageAutomationFunction(status)
  else
    MM:Print("ERROR: Unmanaged automation function is running")
  end
end