local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
--[[
automationTable = {

  -- sets up widgets, title, configurations, estimated time, start and cancel buttons
  ShowInitPrompt = function() end,
    current task: init
    inform statuses:
    - startClicked - the Start button was clicked (only shows if automation was not paused)
    - continueClicked - the Continue button was clicked (only shows if automation was paused)
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
    inform statuses:
    - <none>

  -- cleans up automation behavior
  Stop = function() end,
    inform statuses:
    - <none>
}
]]

MM.AutomationManager = {}

local automationTables = {}

local function validateInterface(automationTable)
  return automationTable.ShowInitPrompt and type(automationTable.ShowInitPrompt) == "function"
    and automationTable.Start and type(automationTable.Start) == "function"
    and automationTable.Stop and type(automationTable.Stop) == "function"
end

function MM.AutomationManager:RegisterAutomation(automationName, automationTable)
  local isValid = validateInterface(automationTable)
  if isValid then
    automationTables[automationName] = automationTable
  else
    MM:Print("ERROR: Automation table \"".. tostring(automationName) .. "\" has an invalid interface")
  end
end

local currentAutomationName, currentAutomationTable, currentTask -- init, running, postprocessing, paused

local paused

-- called when menu is opened
function MM.AutomationManager:ShowAutomationPromptIfPaused()
  if paused then
    self:ShowAutomationPrompt(currentAutomationName)
  end
end

local function setCurrentAutomation(automationName)
  currentAutomationName = automationName
  currentAutomationTable = automationTables[currentAutomationName]
end

local function setMenuLocked(isLocked)
  MM:SetMenuContainersLocked(isLocked)
  MM:SetMenuWidgetsLocked(isLocked)
  if not isLocked then
    currentTask = nil
  end
end

  -- called by Scan button or automation function dropdown
function MM.AutomationManager:ShowAutomationPrompt(automationName)
  if not self:IsRunning() then
    setCurrentAutomation(automationName)
    currentTask = "init"
    setMenuLocked(true)
    currentAutomationTable.ShowInitPrompt()
  else
    MM:Print("ERROR: Attempt to initialize automation function while another is running")
  end
end

local function terminateAutomation()
  currentAutomationTable.Stop()
  currentAutomationName = nil
  currentAutomationTable = nil
  currentTask = nil
  setMenuLocked(false)
end

-- called when menu is closed
function MM.AutomationManager:StopAutomation()
  if currentAutomationName then
    if currentTask == "running" and currentAutomationTable.Pause then
      paused = true
      currentAutomationTable.Pause()
      MM:Print("Automation function paused")
      setMenuLocked(false)
    elseif not paused then
      terminateAutomation()
    end
  end
end

function MM.AutomationManager:IsRunning()
  return currentAutomationName and currentTask
end

local function logStatusError(status)
  MM:Print("ERROR: Unrecognized automation function status \"" .. tostring(status) .. "\"")
end

local function handleInitStatus(status)
  if status == "startClicked" or status == "continueClicked" then
    paused = false
    currentTask = "running"
    currentAutomationTable.Start()
  elseif status == "stopClicked" then
    paused = false
    currentTask = "init"
    currentAutomationTable.Stop()
    currentAutomationTable.ShowInitPrompt()
  elseif status == "cancelClicked" then
    if not paused then
      terminateAutomation()
    else
      setMenuLocked(false)
    end
  else
    logStatusError(status)
  end
end

local function handleRunningStatus(status)
  if status == "finished" then
    if currentAutomationTable.PostProcessing then
      currentTask = "postprocessing"
      currentAutomationTable.PostProcessing()
    else
      terminateAutomation()
    end
  elseif status == "cancelClicked" then
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
  if automationTable == currentAutomationTable then
    manageAutomationFunction(status)
  else
    MM:Print("ERROR: Unmanaged automation function is running: " .. automationTable.GetName() .. " " .. status)
  end
end