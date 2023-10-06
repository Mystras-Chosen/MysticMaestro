local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local automationName = "Post"

local isPaused

local automationTable = {}

local quality = {
	["RE_QUALITY_UNCOMMON"] = "postUncommon",
	["RE_QUALITY_RARE"] = "postRare",
	["RE_QUALITY_EPIC"] = "postEpic",
	["RE_QUALITY_LEGENDARY"] = "postLegendary",
}

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

local enchantScanList, sellableEnchants

local function collectSellableEnchantItems()
	sellableEnchants = MM:GetSellableREs()
	enchantScanList = {}
	for enchantID in pairs(sellableEnchants) do
		local enchantInfo = C_MysticEnchant.GetEnchantInfoBySpell(enchantID)
		if MM.db.realm.OPTIONS[quality[enchantInfo.Quality]] then
			table.insert(enchantScanList, enchantID)
		end
	end
end

local running, currentIndex, scanResultSet

function automationTable.Start()
	collectSellableEnchantItems()
	if #enchantScanList <= 0 then
		MM:Print("No sellable scrolls in inventory.")
		MM.AutomationManager:Inform(automationTable, "finished")
		return
	end
	MM.AutomationUtil.SetProgressBarDisplayMode(automationTable, "value")
	MM.AutomationUtil.SetProgressBarMinMax(automationTable, 0, #enchantScanList)
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "running")
	running = true
	currentIndex = 0
	scanResultSet = {}
end

local function undercut(enchantID, buyoutPrice, yours)
	if yours then
		MM:ListAuctionQueue(enchantID, buyoutPrice)
	else
		MM:ListAuctionQueue(enchantID, buyoutPrice - 1)
	end
end

local function postScan_OnUpdate()
	if running and not MM:AwaitingSingleScanResults() then
		if currentIndex ~= 0 then
			scanResultSet[enchantScanList[currentIndex]] = MM:GetSingleScanResults()
		end
		if currentIndex < #enchantScanList and CanSendAuctionQuery() then
			currentIndex = currentIndex + 1
			MM:InitializeSingleScan(enchantScanList[currentIndex])
			MM.AutomationUtil.SetProgressBarValues(automationTable, currentIndex-1, #enchantScanList)
		elseif currentIndex == #enchantScanList then
			MM.AutomationUtil.SetProgressBarValues(automationTable, currentIndex, #enchantScanList)
			MM.AutomationManager:Inform(automationTable, "finished")
			running = false
		end
	end
end

MM.OnUpdateFrame:HookScript("OnUpdate", postScan_OnUpdate)

function automationTable.Stop()
	MM.AutomationUtil.HideAutomationPopup(automationTable)
	running = false
end

local function assembleQueFromResults()
	for enchantID, results in pairs(scanResultSet) do
		local enchantInfo = C_MysticEnchant.GetEnchantInfoBySpell(enchantID)
		if MM.db.realm.OPTIONS[quality[enchantInfo.Quality]] then
			if #results > 0 then
				local price, yours = MM:PriceCorrection(results[1],results)
				if not price then
					MM:Print("Price is below Minimum, leaving in inventory.")
				else
					undercut(enchantID, price, yours)
				end
			else
				MM:ListAuctionQueue(enchantID, MM.db.realm.OPTIONS.postDefault * 10000)
			end
		end
	end
	scanResultSet = nil
end

function automationTable.PostProcessing()
	if scanResultSet then
		assembleQueFromResults()
	end
	MM.AutomationUtil.ShowAutomationPopup(automationTable, "noPostProcessing")
end

MM.AutomationManager:RegisterAutomation(automationName, automationTable)