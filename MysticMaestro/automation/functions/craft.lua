local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Craft"

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

function automationTable.Stop()
	MM.AutomationUtil.HideAutomationPopup()
	running = false
end

function automationTable.PostProcessing()
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)