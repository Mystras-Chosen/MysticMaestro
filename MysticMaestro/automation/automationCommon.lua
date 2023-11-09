local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local automationPopupFrame

local AnimateTexCoords = AnimateTexCoords

MM.AutomationUtil = {}

local function createAutomationPopupFrame()
	-- set up widget container
	automationPopupFrame = CreateFrame("Frame", nil, MysticMaestroMenu)
	automationPopupFrame:SetResizable(false)
	automationPopupFrame:SetFrameStrata("DIALOG")
	automationPopupFrame:SetBackdrop(MM.DarkFrameBackdrop)
	automationPopupFrame:SetBackdropColor(0, 0, 0, 1)
	automationPopupFrame:SetToplevel(true)
	automationPopupFrame:SetPoint("CENTER")
	automationPopupFrame.Title = MM:CreateDecoration(automationPopupFrame, 40)
	automationPopupFrame.Title:SetPoint("TOP", 0, 12)
	automationPopupFrame.Title.Text = automationPopupFrame.Title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	automationPopupFrame.Title.Text:SetPoint("CENTER", automationPopupFrame.Title)
	-- setup progress bar variables
	local statusBarAtlas = "skillbar_fill_flipbook_alchemy"
	-- local statusBarAtlas = "skillbar_fill_flipbook_blacksmithing"
	-- local statusBarAtlas = "skillbar_fill_flipbook_enchanting"
	-- local statusBarAtlas = "skillbar_fill_flipbook_engineering"
	-- local statusBarAtlas = "skillbar_fill_flipbook_inscription"
	-- local statusBarAtlas = "skillbar_fill_flipbook_jewelcrafting"
	-- local statusBarAtlas = "skillbar_fill_flipbook_leatherworking"
	-- local statusBarAtlas = "skillbar_fill_flipbook_tailoring"
	-- local statusBarAtlas = "skillbar_fill_flipbook_herbalism"
	-- local statusBarAtlas = "skillbar_fill_flipbook_mining"
	-- local statusBarAtlas = "skillbar_fill_flipbook_skinning"
	-- local statusBarAtlas = "skillbar_fill_flipbook_cooking"
	-- local statusBarAtlas = "skillbar_fill_flipbook_fishing"
	local atlas = AtlasUtil:GetAtlasInfo(statusBarAtlas)
	local frameWidth, frameHeight = 856, 34
	local frames = (atlas.height / frameHeight) * 2
	local fps = 26
	automationPopupFrame.ProgressBar = CreateFrame("Frame", nil, automationPopupFrame, "BetterStatusBarTemplate")
	automationPopupFrame.ProgressBar:SetPoint("CENTER", automationPopupFrame, "TOP", 0, -53)
	automationPopupFrame.ProgressBar:SetSize(230, 16)
	automationPopupFrame.ProgressBar:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		tile = true,
		tileSize = 12
	})
	automationPopupFrame.ProgressBar:SetBackdropColor(0, 0, 0, .8)
	automationPopupFrame.ProgressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	automationPopupFrame.ProgressBar:SetStatusBarAtlas(statusBarAtlas)
	automationPopupFrame.ProgressBar.Edge = CreateFrame("Frame", nil, automationPopupFrame.ProgressBar)
	automationPopupFrame.ProgressBar.Edge:SetPoint("TOPLEFT", automationPopupFrame.ProgressBar, "TOPLEFT", -5, 5)
	automationPopupFrame.ProgressBar.Edge:SetPoint("BOTTOMRIGHT", automationPopupFrame.ProgressBar, "BOTTOMRIGHT", 5, -5)
	automationPopupFrame.ProgressBar.Edge:SetBackdrop({
		edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
		tile = true,
		tileSize = 12,
		edgeSize = 12,
	})
	automationPopupFrame.ProgressBar:SetStatusBarFlipbookAtlas(statusBarAtlas, frameWidth, frameHeight, frames, fps)
	automationPopupFrame.ProgressBar.flipbook:Play()
	automationPopupFrame.ProgressBar:Hide()

	automationPopupFrame.WaitIndicator = CreateFrame("Frame", nil, automationPopupFrame)
	automationPopupFrame.WaitIndicator:SetPoint("CENTER", automationPopupFrame, "TOPRIGHT", -54, -69)
	automationPopupFrame.WaitIndicator:SetSize(54, 54)
	automationPopupFrame.WaitIndicator.T = automationPopupFrame.WaitIndicator:CreateTexture(nil, "ARTWORK")
	automationPopupFrame.WaitIndicator.T:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\spinning_arrows")
	automationPopupFrame.WaitIndicator.T:SetAllPoints()
	automationPopupFrame.WaitIndicator:SetScript("OnUpdate",
		function(self, elapsed)
			AnimateTexCoords(self.T, 1024, 1024, 128, 128, 50, elapsed, .02)
		end
	)
	automationPopupFrame.WaitIndicator:Hide()

	automationPopupFrame.AlertIndicator = CreateFrame("Frame", nil, automationPopupFrame)
	automationPopupFrame.AlertIndicator:SetPoint("CENTER", automationPopupFrame, "TOPLEFT", 54, -66)
	automationPopupFrame.AlertIndicator:SetSize(48, 48)
	automationPopupFrame.AlertIndicator.T = automationPopupFrame.AlertIndicator:CreateTexture(nil, "ARTWORK")
	automationPopupFrame.AlertIndicator.T:SetTexture(STATICPOPUP_TEXTURE_ALERT)
	automationPopupFrame.AlertIndicator.T:SetAllPoints()
	automationPopupFrame.AlertIndicator:Hide()
end

local function setPopupComponentVisibility(componentKey, isVisible)
	if isVisible then
		automationPopupFrame[componentKey]:Show()
	else
		automationPopupFrame[componentKey]:Hide()
	end
end

function MM.AutomationUtil.SetPopupSize(width, height)
	automationPopupFrame:SetSize(width, height)
end

function MM.AutomationUtil.SetPopupTitle(title)
	automationPopupFrame.Title.Text:SetText(title)
	automationPopupFrame.Title:SetSize(automationPopupFrame.Title.Text:GetWidth() + 8, 40)
end

function MM.AutomationUtil.SetProgressBarVisible(isVisible)
	setPopupComponentVisibility("ProgressBar", isVisible)
end

function MM.AutomationUtil.SetWaitIndicatorVisible(isVisible)
	setPopupComponentVisibility("WaitIndicator", isVisible)
end

function MM.AutomationUtil.SetAlertIndicatorVisible(isVisible)
	setPopupComponentVisibility("AlertIndicator", isVisible)
end

local popupWidgets = {}

local function releasePopupWidgets()
	for _, widget in ipairs(popupWidgets) do
		widget:Release()
	end
	popupWidgets = {}
end

local currentAutomationTable

local popupButtonWidth = 90
function MM.AutomationUtil.CreateButtonWidget(automationTable, text, informStatus, xOffset, yOffset)
	local button = AceGUI:Create("Button")
	button:SetWidth(popupButtonWidth)
	button:SetText(text)
	button:SetPoint("TOP", automationPopupFrame, "TOP", xOffset, yOffset)
	button:SetCallback("OnClick",
		function()
			if informStatus ~= "nextBatchClicked" then
				MM.AutomationUtil.HideAutomationPopup(currentAutomationTable)
			end
			MM.AutomationManager:Inform(automationTable, informStatus)
		end
	)
	button.frame:SetParent(automationPopupFrame)
	button.frame:Show()
	table.insert(popupWidgets, button)
	return button
end

function MM.AutomationUtil.CreateLabelWidget(text, textHeight, alignment, width, height, xOffset, yOffset)
	local label = AceGUI:Create("Label")
	label:SetPoint("TOP", automationPopupFrame, "TOP", xOffset, yOffset)
	label:SetWidth(width)
	label:SetHeight(height)
	label:SetText(text)
	label:SetJustifyH(alignment)
	label:SetFont(GameFontHighlightSmall:GetFont(), textHeight)
	label.frame:SetParent(automationPopupFrame)
	label.frame:Show()
	table.insert(popupWidgets, label)
	return label
end

local function validateInterface(template)
	return type(template.Show) == "function" and type(template.Hide) == "function"
end

local registeredTemplates = {}

local pendingTemplate, currentTemplate

-- schedules the popup to show or hide in the OnUpdate script since Show and Hide can be called on the same frame
function MM.AutomationUtil.ShowAutomationPopup(templateName)
	if registeredTemplates[templateName] then
		pendingTemplate = templateName
	else
		MM:Print("ERROR: Unrecognized template name: " .. pendingTemplate)
	end
end

function MM.AutomationUtil.HideAutomationPopup()
	pendingTemplate = false
end

local displayMode

function MM.AutomationUtil.SetProgressBarDisplayMode(mode)
	displayMode = mode
end

function MM.AutomationUtil.SetProgressBarValues(current, max)
	automationPopupFrame.ProgressBar:SetValue(current)
	if displayMode == "value" then
		automationPopupFrame.ProgressBar:SetFormattedText("%d / %d", current, max)
	elseif displayMode == "percent" then
		automationPopupFrame.ProgressBar:SetFormattedText("%d%%", math.floor(current/max * 100))
	elseif displayMode == "both" then
		automationPopupFrame.ProgressBar:SetFormattedText("%d%%  (%d/%d)", math.floor(current/max * 100), current, max)
	elseif displayMode == "none" then
		automationPopupFrame.ProgressBar:SetText("")
	elseif display ~= nil then
		MM:Print("ERROR: Automation popup progress bar has invalid display mode")
	else
		MM:Print("ERROR: Automation popup progress bar display mode not set")
	end
end

function MM.AutomationUtil.SetProgressBarMinMax(min, max)
	automationPopupFrame.ProgressBar:SetMinMaxValues(min, max)
end

function MM.AutomationUtil.AppendProgressBarText(appendText, appendBefore)
	local existingText = automationPopupFrame.ProgressBar.Text:GetText() or ""
	automationPopupFrame.ProgressBar:SetText(appendBefore and appendText .. existingText or existingText .. appendText)
end

MM.OnUpdateFrame:HookScript("OnUpdate",
	function()
		if pendingTemplate ~= nil then
			releasePopupWidgets()
			if pendingTemplate then
				if currentTemplate then
					registeredTemplates[currentTemplate]:Hide()
				end
				currentTemplate = pendingTemplate
				registeredTemplates[currentTemplate]:Show()
				automationPopupFrame:Show()
			elseif currentTemplate then
				registeredTemplates[currentTemplate]:Hide()
				currentTemplate = nil
				automationPopupFrame:Hide()
			end
			pendingTemplate = nil
		end
	end
)


function MM.AutomationUtil.CreatePromptButtonWidgets(automationTable, verticalPosition)
	if automationTable.Pause and automationTable:IsPaused() then
		MM.AutomationUtil.CreateButtonWidget(automationTable, automationTable, "Continue", "continueClicked", -popupButtonWidth, verticalPosition)
		MM.AutomationUtil.CreateButtonWidget(automationTable, automationTable, "Stop", "stopClicked", 0, verticalPosition)
		MM.AutomationUtil.CreateButtonWidget(automationTable, automationTable, "Cancel", "cancelClicked", popupButtonWidth, verticalPosition)
	else
		MM.AutomationUtil.CreateButtonWidget(automationTable, automationTable, "Start", "startClicked", -.5 * popupButtonWidth, verticalPosition)
		MM.AutomationUtil.CreateButtonWidget(automationTable, automationTable, "Cancel", "cancelClicked", .5 * popupButtonWidth, verticalPosition)
	end
end

local function isRegisteredTemplate(caller)
	for name, template in pairs(registeredTemplates) do
		if template == caller then
			return true
		end
	end
	return false
end

-- prehook util functions with authentication function
local function authenticateCurrentAutomation(caller)
	return caller ~= nil and caller == currentAutomationTable or isRegisteredTemplate(caller)
end

-- All calls to AutomationUtil funcions will check that the caller is the current automation
local newAutomationUtil = {}
for funcName, func in pairs(MM.AutomationUtil) do
	newAutomationUtil[funcName] = function(caller, ...)
		if authenticateCurrentAutomation(caller) then
			return func(...)
		else
			MM:Print("ERROR: Unauthorized requestor attempting to call AutomationUtil." .. funcName)
		end
	end
end

MM.AutomationUtil = newAutomationUtil

-- All AutomationUtil functions after this point don't authenticate

-- Should only be called by AutomationManager
function MM.AutomationUtil.SetCurrentAutomation(automationTable)
	if not automationPopupFrame then
		createAutomationPopupFrame()
	end
	currentAutomationTable = automationTable
end

function MM.AutomationUtil.RegisterPopupTemplate(name, template)
	if validateInterface(template) then
		registeredTemplates[name] = template
	else
		MM:Print("ERROR: Automation popup template \"".. tostring(name) .. "\" has an invalid interface")
	end
end

MM.AutomationUtil.RegisterPopupTemplate("prompt",
	{
		Show = function(self)
			MM.AutomationUtil.CreatePromptButtonWidgets(self, currentAutomationTable, -40)
			MM.AutomationUtil.SetPopupSize(self, currentAutomationTable.Pause and currentAutomationTable:IsPaused() and 320 or 230, 100)
		end,
		Hide = function(self)
			-- no special handling
		end
	}
)

local function createRunningWidgets(self)
	if currentAutomationTable.Pause then
		MM.AutomationUtil.CreateButtonWidget(self, currentAutomationTable, "Pause", "pauseClicked", -45, -70)
	elseif currentAutomationTable.ProcessBatch then
		MM.AutomationUtil.CreateButtonWidget(self, currentAutomationTable, "Next", "nextBatchClicked", -45, -70)
	end
	MM.AutomationUtil.CreateButtonWidget(self, currentAutomationTable, "Stop", "stopClicked", currentAutomationTable.Pause or currentAutomationTable.ProcessBatch and 45 or 0, -70)
end

MM.AutomationUtil.RegisterPopupTemplate("running",
	{
		Show = function(self)
			createRunningWidgets(self)
			MM.AutomationUtil.SetPopupSize(self, 300, 120)
			MM.AutomationUtil.SetProgressBarVisible(self, true)
		end,
		Hide = function(self)
			MM.AutomationUtil.SetProgressBarVisible(self, false)
		end
	}
)

MM.AutomationUtil.RegisterPopupTemplate("noPostProcessing",
	{
		Show = function(self)
			MM.AutomationUtil.CreateButtonWidget(self, currentAutomationTable, "Done", "doneClicked", 0, -70)
			MM.AutomationUtil.SetPopupSize(self, 300, 120)
			MM.AutomationUtil.SetProgressBarVisible(self, true)
		end,
		Hide = function(self)
			MM.AutomationUtil.SetProgressBarVisible(self, false)
		end
	}
)