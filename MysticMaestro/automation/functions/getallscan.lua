local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local GetTime = GetTime

local automationName = "GetAll Scan"

local automationTable = {}

function automationTable.GetName()
	return automationName
end

local listings

function automationTable.ShowInitPrompt()
	MM.AutomationUtil.SetPopupTitle(automationTable, automationName)
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "getAllScanPrompt")
	listings = MM.data.RE_AH_LISTINGS
end

local awaitingResults, scanTime, collectTime

function MM:GetAllScan_AUCTION_ITEM_LIST_UPDATE()
	if awaitingResults then
		awaitingResults = nil
		scanTime = time()
		collectTime = GetTime() + 2
	end
end

local function startGetAllScan()
	QueryAuctionItems("", nil, nil, 0, 0, 0, 0, 0, 0, true)
	awaitingResults = true
end

local scannedEnchantIDs
local function collectScannedEnchantIDs()
	scannedEnchantIDs = {}
	for _, quality in ipairs({"legendary", "epic", "rare", "uncommon"}) do
		local enchants = MM:GetAlphabetizedEnchantList(quality)
		for _, enchant in ipairs(enchants) do
			table.insert(scannedEnchantIDs, enchant)
		end
	end
end

function automationTable.Start()
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "getAllScanRunning")
	startGetAllScan()
	collectScannedEnchantIDs() -- collect enchant IDs in table while we wait
end

local function recordListingData(index)
	local _, enchantData, buyoutPrice = MM:GetAuctionMysticEnchantInfo("list", index)
	if enchantData and buyoutPrice and buyoutPrice > 0 then
		local temp = listings[enchantData.SpellID][scanTime] or ""
		listings[enchantData.SpellID][scanTime] = buyoutPrice .. "," .. temp
	end
end

local function calculateStatistics(index)
	local enchantID = scannedEnchantIDs[index]
	MM:CalculateREStats(enchantID, listings[enchantID])
end

local recordingStartTime, calcStartTime
local secondsPerFrame = 1/20
local currentIndex, numAuctions, numEnchants

local function nilGetAllScanVariables()
	awaitingResults = nil
	scanTime = nil
	collectTime = nil
	scannedEnchantIDs = nil
	recordingStartTime = nil
	calcStartTime = nil
	currentIndex = nil
	numAuctions = nil
	numEnchants = nil
end

local function initRecording()
	collectTime = nil
	recordingStartTime = GetTime()
	currentIndex = 1
	numAuctions = GetNumAuctionItems("list")
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "running")
	MM.AutomationUtil.SetProgressBarDisplayMode(automationTable, "percent")
	MM.AutomationUtil.SetProgressBarMinMax(automationTable, 0, numAuctions)
	MM.AutomationUtil.SetProgressBarValues(automationTable, 0, numAuctions)
	MM.AutomationUtil.AppendProgressBarText(automationTable, "Archiving: ", true)
end

local function throttledRecording()
	while GetTime() - recordingStartTime < secondsPerFrame and currentIndex <= numAuctions do
		recordListingData(currentIndex)
		currentIndex = currentIndex + 1
	end
	if currentIndex > numAuctions then
		calcStartTime = recordingStartTime
		recordingStartTime = nil
		currentIndex = 1
		numEnchants = #scannedEnchantIDs
		MM.AutomationUtil.SetProgressBarMinMax(automationTable, 0, numEnchants)
		MM.AutomationUtil.SetProgressBarValues(automationTable, 0, numEnchants)
		MM.AutomationUtil.AppendProgressBarText(automationTable, "Calculating: ", true)
	else
		recordingStartTime = recordingStartTime + secondsPerFrame
		MM.AutomationUtil.SetProgressBarValues(automationTable, currentIndex, numAuctions)
		MM.AutomationUtil.AppendProgressBarText(automationTable, "Archiving: ", true)
	end
end

local function throttledCalculating()
	while GetTime() - calcStartTime < secondsPerFrame and currentIndex <= numEnchants do
		calculateStatistics(currentIndex)
		currentIndex = currentIndex + 1
	end
	if currentIndex > numEnchants then
		MM.AutomationUtil.SetProgressBarDisplayMode(automationTable, "none")
		MM.AutomationUtil.SetProgressBarValues(automationTable, numEnchants, numEnchants)
		nilGetAllScanVariables()
		MM.AutomationManager:Inform(automationTable, "finished")
	else
		calcStartTime = calcStartTime + secondsPerFrame
		MM.AutomationUtil.SetProgressBarValues(automationTable, currentIndex, numEnchants)
		MM.AutomationUtil.AppendProgressBarText(automationTable, "Calculating: ", true)
	end
end

local function getAllScan_OnUpdate()
	if collectTime and GetTime() >= collectTime then
		initRecording()
	elseif recordingStartTime then
		throttledRecording()
	end
	if calcStartTime then
		throttledCalculating()
	end
end

MM.OnUpdateFrame:HookScript("OnUpdate", getAllScan_OnUpdate)

function automationTable.PostProcessing()
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "noPostProcessing")
end

function automationTable.Stop()
	nilGetAllScanVariables()
	MM.AutomationUtil.HideAutomationPopup(automationTable)
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)

MM.AutomationUtil.RegisterPopupTemplate("getAllScanPrompt",
	{
		Show = function(self)
			MM.AutomationUtil.CreatePromptButtonWidgets(self, automationTable, -122)
			MM.AutomationUtil.CreateLabelWidget(self, "GetAll Scan can be run once every 15 minutes and generally executes quickly.\n\nThe first scan after a patch or server restart can take up to 15 minutes.", 14, "LEFT", 280, 80, 42, -34)
			MM.AutomationUtil.SetPopupSize(self, 400, 180)
			MM.AutomationUtil.SetAlertIndicatorVisible(self, true)
		end,
		Hide = function(self)
			MM.AutomationUtil.SetAlertIndicatorVisible(self, false)
		end
	}
)

MM.AutomationUtil.RegisterPopupTemplate("getAllScanRunning",
	{
		Show = function(self)
			MM.AutomationUtil.CreateButtonWidget(self, automationTable, "Stop", "stopClicked", 0, -106)
			MM.AutomationUtil.CreateLabelWidget(self, "Waiting for payload from server\n\nLEAVING THIS WINDOW WILL\nCANCEL DATA COLLECTION", 14, "CENTER", 220, 80, 0, -34)
			MM.AutomationUtil.SetPopupSize(self, 380, 154)
			MM.AutomationUtil.SetWaitIndicatorVisible(self, true)
			MM.AutomationUtil.SetAlertIndicatorVisible(self, true)
		end,
		Hide = function(self)
			MM.AutomationUtil.SetWaitIndicatorVisible(self, false)
			MM.AutomationUtil.SetAlertIndicatorVisible(self, false)
		end
	}
)