local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Undercut"

local isPaused

local automationTable = {}

function automationTable.GetName()
	return automationName
end

local options

function automationTable.ShowInitPrompt()
	options = options or MM.db.realm.OPTIONS
	MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, "prompt")
end

local running

function automationTable.Start()
end

function automationTable.Pause()
	if running then
		isPaused = true
		MM.AutomationUtil.HideAutomationPopup()
	elseif isPaused then -- can be called when already paused and init prompt showing
		MM.AutomationUtil.HideAutomationPopup()
	else
		MM:Print("ERROR: " .. automationName .." paused when not running")
	end
end

function automationTable.IsPaused()
	return isPaused
end

function automationTable.Stop()
	MM.AutomationUtil.HideAutomationPopup()
	isPaused = false
	running = false
end

function automationTable.PostProcessing()
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)