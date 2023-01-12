local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
--[[
automationTable = {

  -- sets up widgets, title, configurations, estimated time, start and cancel buttons
  ShowInitPrompt = function() end,
    current task: init
    inform statuses:
    - startClicked - the Start (or Continue if was paused) buttons was clicked
    - stopClicked - the Stop button was clicked (only shows if automation was paused)
    - cancelClicked - the Cancel button was clicked

  -- sets up widgets, progress bar, status, cancel button
  Start = function() end,
    current task: running
    inform statuses:
    - finished - the automation has finished
    - cancelClicked - the Cancel button was clicked

  -- optional window if post-processing is required
  PostProcessing = function() end,
    current task: postprocessing
    inform statuses:
    - finished - post processing has finished

  -- optional if automation is pausable
  Pause = function() end
    current task: paused
    inform statuses:
    - <none>

  -- cleans up automation behavior
  Cancel = function() end,
    inform statuses:
    - <none>
}
]]

MM.AutomationManager = {}

local automationTables = {}

local function validateInterface(automationTable)
  return automationTable.ShowInitPrompt and type(automationTable.ShowInitPrompt) == "function"
    and automationTable.Start and type(automationTable.Start) == "function"
    and automationTable.Cancel and type(automationTable.Cancel) == "function"
end

function MM.AutomationManager:RegisterAutomation(automationName, automationTable)
  local isValid = validateInterface(automationTable)
  if isValid then
    automationTables[automationName] = automationTable
  else
    MM:Print("ERROR: Automation table \"".. tostring(automationName) .. "\" has an invalid interface")
  end
end

local function setMenuLocked(isLocked)
  MM:SetMenuContainersLocked(isLocked)
  MM:SetMenuWidgetsLocked(isLocked)
end

local currentAutomation, currentTask -- init, running, postprocessing, paused

function MM.AutomationManager:StartAutomation(automationName)
  if not currentAutomation or automationName == currentAutomation and currentTask == "paused" then
    currentAutomation = automationName
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
  elseif currentAutomation then
    currentAutomation.Cancel()
    terminateAutomation()
    MM:Print("Automation function canceled")
  end
end

local function logStatusError(status)
  MM:Print("ERROR: Unrecognized automation function status \"" .. tostring(status) .. "\"")
end

local function handleInitStatus(status)
  if status == "startClicked" then
    currentTask = "running"
    currentAutomation.Start()
  elseif status == "stopClicked" then
    currentTask = "init"
    currentAutomation.Cancel()
    currentAutomation.ShowInitPrompt()
  elseif status == "cancelClicked" then
    currentAutomation.Cancel()
    terminateAutomation()
  else
    logStatusError(status)
  end
end

local function handleRunningStatus(status)
  if status == "finished" then
    if currentAutomation.PostProcessing then
      currentTask = "postprocessing"
      currentAutomation.PostProcessing()
    else
      terminateAutomation()
    end
  elseif status == "cancelClicked" then
    currentAutomation.Cancel()
    terminateAutomation()
  else
    logStatusError(status)
  end
end

local function handlePostprocessingStatus(status)
  if status == "finished" then
    terminateAutomation()
  else
    logStatusError(status)
  end
end

local function manageAutomationFunction(status)
  if currentTask == "init" then
    handleInitStatus(status)
  elseif currentTask == "running" then
    handleRunningStatus(status)
  elseif currentTask == "postprocessing" then
    handlePostprocessingStatus(status)
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