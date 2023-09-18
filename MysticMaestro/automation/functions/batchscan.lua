local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Batch Scan"

local isPaused

local automationTable = {}

function automationTable.GetName()
	return automationName
end

local options

local listings
function automationTable.ShowInitPrompt()
	options = options or MM.db.realm.OPTIONS
	MM.AutomationUtil.SetPopupTitle(automationTable, automationName)
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "prompt")
	listings = MM.data.RE_AH_LISTINGS
end

local running

local enchantQueue

local function queryMysticScrollPage(page)
	QueryAuctionItems("Mystic Scroll: ", nil, nil, 0, 0, 0, page)
end

local collectingData, recordingStartTime, listingRecordTime, currentIndex, calcStartTime
local secondsPerFrame = 1/20
local currentPage, totalPages, awaitingResults, pendingQuery, timeoutTime, totalAuctions
local pendingResults, finalResults, preparedFinalResults = {}, {}, {}

local function initRecording()
	collectingData = nil
	recordingStartTime = GetTime()
	listingRecordTime = time()
	currentIndex = 1
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "running")
	MM.AutomationUtil.SetProgressBarDisplayMode(automationTable, "percent")
	MM.AutomationUtil.SetProgressBarMinMax(automationTable, 0, #preparedFinalResults)
	MM.AutomationUtil.SetProgressBarValues(automationTable, 0, #preparedFinalResults)
	MM.AutomationUtil.AppendProgressBarText(automationTable, "Archiving: ", true)
end


local function recordListingData(index)
	local listingData = preparedFinalResults[index]
	listings[listingData.spellID][listingRecordTime] = listingData.buyoutString
end



local function nilBatchScanVariables()
	isPaused = false
	running = false
	lastUpdate = nil
	currentPage = nil
	totalPages = nil
	pendingResults = nil
	finalResults = nil
	collectingData = nil
	recordingStartTime = nil
	listingRecordTime = nil
	preparedFinalResults = nil
	calcStartTime = nil
	totalAuctions = nil
end

local function throttledRecording()
	while GetTime() - recordingStartTime < secondsPerFrame and currentIndex <= #preparedFinalResults do
		recordListingData(currentIndex)
		currentIndex = currentIndex + 1
	end
	if currentIndex > #preparedFinalResults then
		calcStartTime = recordingStartTime
		recordingStartTime = nil
		currentIndex = 1
		MM.AutomationUtil.SetProgressBarMinMax(automationTable, 0, #preparedFinalResults)
		MM.AutomationUtil.SetProgressBarValues(automationTable, 0, #preparedFinalResults)
		MM.AutomationUtil.AppendProgressBarText(automationTable, "Calculating: ", true)
	else
		recordingStartTime = recordingStartTime + secondsPerFrame
		MM.AutomationUtil.SetProgressBarValues(automationTable, currentIndex, #preparedFinalResults)
		MM.AutomationUtil.AppendProgressBarText(automationTable, "Archiving: ", true)
	end
end

local function calculateStatistics(index)
	local spellID = preparedFinalResults[index].spellID
	MM:CalculateREStats(spellID, listings[spellID])
end

local function throttledCalculating()
	while GetTime() - calcStartTime < secondsPerFrame and currentIndex <= #preparedFinalResults do
		calculateStatistics(currentIndex)
		currentIndex = currentIndex + 1
	end
	if currentIndex > #preparedFinalResults then
		MM.AutomationUtil.SetProgressBarDisplayMode(automationTable, "none")
		MM.AutomationUtil.SetProgressBarValues(automationTable, #preparedFinalResults, #preparedFinalResults)
		nilBatchScanVariables()
		MM.AutomationManager:Inform(automationTable, "finished")
	else
		calcStartTime = calcStartTime + secondsPerFrame
		MM.AutomationUtil.SetProgressBarValues(automationTable, currentIndex, #preparedFinalResults)
		MM.AutomationUtil.AppendProgressBarText(automationTable, "Calculating: ", true)
	end
end

local function prepareAuctionData()
	preparedFinalResults = {}
	for spellID, buyoutString in pairs(finalResults) do
		table.insert(preparedFinalResults, {
			spellID = spellID,
			buyoutString = buyoutString
		})
	end
end

local function batchScan_OnUpdate()
	if running and not isPaused then
		if collectingData then
			if (not totalAuctions or currentPage < totalPages) and CanSendAuctionQuery() and not awaitingResults then
				currentPage = currentPage + 1
				pendingQuery = true
				awaitingResults = false
				timeoutTime = nil
				MM.AutomationUtil.SetProgressBarMinMax(automationTable, 0, totalPages or 1)
				MM.AutomationUtil.SetProgressBarValues(automationTable, currentPage, totalPages or 1)
			elseif totalAuctions and totalPages == currentPage and not awaitingResults then
				prepareAuctionData()
				initRecording()
			end
			if pendingQuery and CanSendAuctionQuery() then
				queryMysticScrollPage(currentPage)
				pendingQuery = false
				awaitingResults = true
				timeoutTime = GetTime() + 1
			end
			if timeoutTime and GetTime() >= timeoutTime then
				MM:BatchScan_AUCTION_ITEM_LIST_UPDATE()
			end
		end
		if recordingStartTime then
			throttledRecording()
		end
		if calcStartTime then
			throttledCalculating()
		end
	end
end

local function cacheResults()
	for spellID, buyouts in pairs(pendingResults) do
		finalResults[spellID] = (finalResults[spellID] or "") .. buyouts
	end
end

function MM:BatchScan_AUCTION_ITEM_LIST_UPDATE()
	if awaitingResults then
		local currentTime = GetTime()
		awaitingResults = false
		pendingResults = {}
		for i=1, GetNumAuctionItems("list") do
			local itemLink, enchantData, buyoutPrice, seller, duration, icon = MM:GetAuctionMysticEnchantInfo("list", i)
			if enchantData and buyoutPrice and buyoutPrice > 0 then
				pendingResults[enchantData.SpellID] = (pendingResults[enchantData.SpellID] or "") .. buyoutPrice .. ","
			end
			if itemLink == nil and currentTime < timeoutTime then
				awaitingResults = true
			end
		end
		if awaitingResults then return end
		timeoutTime = (awaitingResults and currentTime < timeoutTime) and timeoutTime or nil
		if timeoutTime == nil then
			cacheResults()
			
			totalAuctions = select(2, GetNumAuctionItems("list"))
			totalPages = math.ceil(totalAuctions / 50)
		end
	end
end

function automationTable.Start()
	if not isPaused then
		currentPage = -1
		pendingResults, finalResults = {}, {}
		collectingData = true
	end
	isPaused = false
	MM.AutomationUtil.SetProgressBarMinMax(automationTable, 0, totalPages or 1)
	MM.AutomationUtil.SetProgressBarDisplayMode(automationTable, "both")
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "running")
	running = true
end

MM.OnUpdateFrame:HookScript("OnUpdate", batchScan_OnUpdate)

function automationTable.PostProcessing()
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "noPostProcessing")
end

local function cancelBatchScan()
	pendingQuery = false
	awaitingResults = false
	timeoutTime = nil
end

function automationTable.Pause()
	if running then
		isPaused = true
		MM.AutomationUtil.HideAutomationPopup(automationTable)
		cancelBatchScan()
		currentPage = currentPage - 1
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
	cancelBatchScan()
	nilBatchScanVariables()
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)