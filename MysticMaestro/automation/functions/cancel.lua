local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Cancel Auctions"

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

local running
local currentCancel, totalCanceled, cancelList

local function initCanceling()
	currentCancel = 1
	totalCanceled = 0
	cancelList = {}
	for i=1, GetNumAuctionItems("owner") do
		local data={GetAuctionItemInfo("owner",i)}
		local scrollName=data[1]:match("^Mystic Scroll: ([%w%s'-]+)")
		local bid=data[10]
		local timeIndex=GetAuctionItemTimeLeft("owner",i)
		if (timeIndex<4 and bid==0 and scrollName) then
			 table.insert(cancelList,i)
		end
		table.sort(cancelList, function(a,b) return a > b end)
	end
end

local function nilCancelScanVariables()
	running = false
	currentCancel = nil
	totalCanceled = nil
	cancelList = nil
end

function automationTable.ProcessBatch()
	if running then
		if totalCanceled < #cancelList then
			local tally = 0
			for i = currentCancel, #cancelList do
				tally = tally + 1
				totalCanceled = totalCanceled + 1
				currentCancel = currentCancel + 1
				CancelAuction(cancelList[i])
				if tally >= 100 then break end
			end
			MM.AutomationUtil.SetProgressBarValues(automationTable, currentCancel, #cancelList)
			if totalCanceled >= #cancelList then
				nilCancelScanVariables()
				MM.AutomationManager:Inform(automationTable, "finished")
			end
		else
				nilCancelScanVariables()
				MM.AutomationManager:Inform(automationTable, "finished")
		end
	end
end

function automationTable.Start()
	initCanceling()
	MM.AutomationUtil.SetProgressBarDisplayMode(automationTable, "both")
	MM.AutomationUtil.SetProgressBarMinMax(automationTable, 0, cancelList and #cancelList or 1)
	MM.AutomationUtil.SetProgressBarValues(automationTable, currentCancel, #cancelList)
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "running")
	running = true
	if #cancelList <= 0 then
		MM:Print("Nothing within cancel duration")
	end
	automationTable.ProcessBatch()
end

function automationTable.Stop()
	MM.AutomationUtil.HideAutomationPopup(automationTable)
	nilCancelScanVariables()
end

function automationTable.PostProcessing()
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "noPostProcessing")
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)