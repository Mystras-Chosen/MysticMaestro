local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Queue Scan"

local isPaused

local automationTable = {}

function automationTable.GetName()
	return automationName
end

local options

function automationTable.ShowInitPrompt()
	options = options or MM.db.realm.OPTIONS
	MM.AutomationUtil.SetPopupTitle(automationTable, automationName)
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "prompt")
end

local currentIndex
local running

local enchantQueue

local scanQualityFilters = {
	{ rarityLegendary = "legendary" },
	{ rarityEpic = "epic" },
	{ rarityRare = "rare" },
	{ rarityMagic = "uncommon" }
}

local function prepareEnchantQueue()
	enchantQueue = {}
	for _, filter in ipairs(scanQualityFilters) do
		local optionKey, quality = next(filter)
		if options[optionKey] then
			local enchants = MM:GetAlphabetizedEnchantList(quality)
			for _, enchant in ipairs(enchants) do
				table.insert(enchantQueue, enchant)
			end
		end
	end
end

local currentIndex

local function queueScan_OnUpdate()
	if running and not isPaused then
		if currentIndex < #enchantQueue and CanSendAuctionQuery() and not MM:AwaitingSingleScanResults() then
			currentIndex = currentIndex + 1
			MM:InitializeSingleScan(enchantQueue[currentIndex])
			MM.AutomationUtil.SetProgressBarValues(automationTable, currentIndex-1, #enchantQueue)
		elseif currentIndex == #enchantQueue and not MM:AwaitingSingleScanResults() then
			MM.AutomationUtil.SetProgressBarValues(automationTable, currentIndex, #enchantQueue)
			MM.AutomationManager:Inform(automationTable, "finished")
			running = false
			isPaused = false
		end
	end
end

function automationTable.Start()
	if not isPaused then
		prepareEnchantQueue()
		currentIndex = 0
	end
	isPaused = false
	MM.AutomationUtil.SetProgressBarDisplayMode(automationTable, "value")
	MM.AutomationUtil.SetProgressBarMinMax(automationTable, 0, #enchantQueue)
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "running")
	running = true
end

MM.OnUpdateFrame:HookScript("OnUpdate", queueScan_OnUpdate)

function automationTable.PostProcessing()
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "noPostProcessing")
end

function automationTable.Pause()
	if running then
		isPaused = true
		MM.AutomationUtil.HideAutomationPopup(automationTable)
		MM:CancelSingleScan()
		currentIndex = currentIndex - 1
	elseif isPaused then -- can be called when already paused and init prompt showing
		MM.AutomationUtil.HideAutomationPopup(automationTable)
	else
		MM:Print("ERROR: " .. automationName .." paused when not running")
	end
end

function automationTable.IsPaused()
	return isPaused
end

function automationTable.Stop()
	MM.AutomationUtil.HideAutomationPopup(automationTable)
	MM:CancelSingleScan()
	isPaused = false
	running = false
	lastUpdate = nil
	currentIndex = nil
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)