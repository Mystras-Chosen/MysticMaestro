local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local ahExtensionMenu

local function createContainerFrame()
	ahExtensionMenu = CreateFrame("Frame", "MysticMaestroMenuAHExtension", UIParent)
	ahExtensionMenu:SetSize(212, 378)
end

local buttonHeight = 16
local auctionScrollFrameWidth = 195

local selectedMyAuctionData

function MM:GetSelectedMyAuctionData()
	return selectedMyAuctionData
end

function MM:SetSelectedMyAuctionData(data)
	selectedMyAuctionData = data
	local myAuctionsButton = self:GetMyAuctionsScrollFrame().buttons
	for _, button in ipairs(myAuctionsButton) do
		if data and button.data and button.data.SpellID == data.SpellID then
			button.H:Show()
			button.H:SetDesaturated(false)
		else
			button.H:Hide()
		end
	end
end

function MM:SelectMyAuctionBySpellID(SpellID)
	local myAuctionResults = self:GetSortedMyAuctionResults()
	for _, result in ipairs(myAuctionResults) do
		if result.SpellID == SpellID then
			self:SetSelectedMyAuctionData(result)
			return
		end
	end
	self:SetSelectedMyAuctionData(nil)
end

local selectedSelectedEnchantAuctionData

function MM:GetSelectedSelectedEnchantAuctionData()
	return selectedSelectedEnchantAuctionData
end

function MM:SetSelectedSelectedEnchantAuctionData(selectedButton)
	local selectedEnchantAuctionsButtons = self:GetSelectedEnchantAuctionsScrollFrame().buttons
	for _, button in ipairs(selectedEnchantAuctionsButtons) do
			button.H:Hide()
	end
	if selectedButton then
		selectedSelectedEnchantAuctionData = selectedButton.data
		selectedButton.H:Show()
		selectedButton.H:SetDesaturated(false)
		self:EnableBuyoutCancelButton()
	else
		selectedSelectedEnchantAuctionData = nil
		self:DisableBuyoutCancelButton()
	end
end

local function createMyAuctionsButton(parent, listingName)
	local listingButton = CreateFrame("Button", listingName, parent)
	listingButton:SetSize(parent:GetWidth(), buttonHeight)
	listingButton.H = listingButton:CreateTexture(nil, "OVERLAY")
	listingButton.H:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
	listingButton.H:SetAllPoints()
	listingButton.H:SetBlendMode("ADD")
	listingButton.H:SetTexCoord(0, 1, 0, 0.578125)
	listingButton.H:Hide()

	listingButton.auctionCount = listingButton:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	listingButton.auctionCount:SetPoint("LEFT")

	listingButton.enchantName = listingButton:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	listingButton.enchantName:SetPoint("LEFT", listingButton, "LEFT", 14, 0)
	listingButton.enchantName:SetPoint("RIGHT", listingButton, "RIGHT", 0, 0)

	listingButton:SetScript("OnClick",
		function(self)
			local currentSelectionData = MM:GetSelectedMyAuctionData()
			if not currentSelectionData or self.data.SpellID ~= currentSelectionData.SpellID then
				MM:SetSelectedMyAuctionData(self.data)
				MM:SetSearchBarDefaultText()
				MM:SetResultSet({self.data.SpellID})
				MM:GoToPage(1)
				MM:SetSelectedEnchantButton(1)
			end
		end
	)

	listingButton:SetScript("OnLeave",
		function(self)
			local data = MM:GetSelectedMyAuctionData()
			if not data or self.data.SpellID ~= data.SpellID then
				self.H:Hide()
			end
		end
	)

	listingButton:SetScript("OnEnter",
		function(self)
			local data = MM:GetSelectedMyAuctionData()
			if not data or self.data.SpellID ~= data.SpellID then
				self.H:Show()
				self.H:SetDesaturated(true)
			end
		end
	)

	return listingButton
end

local durationKey = {
	"Short",
	"Medium",
	"Long",
	"Very Long"
}

local function createSelectedAuctionsButton(parent, listingName)
	local listingButton = CreateFrame("Button", listingName, parent)
	listingButton:SetSize(parent:GetWidth(), buttonHeight)
	listingButton.H = listingButton:CreateTexture(nil, "OVERLAY")
	listingButton.H:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
	listingButton.H:SetAllPoints()
	listingButton.H:SetBlendMode("ADD")
	listingButton.H:SetTexCoord(0, 1, 0, 0.578125)
	listingButton.H:Hide()
	
	listingButton.icon = listingButton:CreateTexture(nil, "OVERLAY")
	listingButton.icon:SetSize(buttonHeight, buttonHeight)
	listingButton.icon:SetPoint("LEFT")

	listingButton.price = CreateFrame("Frame", listingName.."Price", listingButton, "SmallMoneyFrameTemplate")
	MoneyFrame_SetType(listingButton.price, "AUCTION")
	listingButton.price:SetPoint("LEFT", listingButton.icon, "RIGHT", 0, 0)
	listingButton.price:SetSize(parent:GetWidth(), buttonHeight)

	listingButton.price.Suffix = listingButton.price:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	listingButton.price.Suffix:SetPoint("RIGHT", listingButton, "RIGHT", 0, 0)

	listingButton:SetScript("OnClick",
		function(self)
			local currentSelectionData = MM:GetSelectedSelectedEnchantAuctionData()
			if self.data == currentSelectionData then
				MM:SetSelectedSelectedEnchantAuctionData(nil)
			else
				MM:SetSelectedSelectedEnchantAuctionData(self)
			end
		end
	)

	listingButton:SetScript("OnLeave",
		function(self)
			if self.data ~= MM:GetSelectedSelectedEnchantAuctionData() then
				self.H:Hide()
			end
			GameTooltip:Hide()
		end
	)

	listingButton:SetScript("OnEnter",
		function(self)
			if self.data ~= MM:GetSelectedSelectedEnchantAuctionData() then
				self.H:Show()
				self.H:SetDesaturated(true)
			end
			GameTooltip:SetOwner(self, "ANCHOR_NONE")
			GameTooltip:SetPoint("TOPLEFT",self,"TOPRIGHT")
			GameTooltip:SetHyperlink(self.data.link)
			GameTooltip:AddDoubleLine("Posted By", MM:cTxt(self.data.seller and self.data.seller or "unknown","white"))
			GameTooltip:AddDoubleLine("Time Left", MM:cTxt(durationKey[self.data.duration],"white"))
			GameTooltip:Show()
		end
	)
	return listingButton
end

local function createAuctionsScrollFrame(name, title, parent, numRows, buttonCreateFunc)
	local scrollFrame = CreateFrame("ScrollFrame", name.."ScrollFrame", parent, "FauxScrollFrameTemplate")
	scrollFrame:SetSize(auctionScrollFrameWidth - 24, buttonHeight * numRows)
	scrollFrame:SetPoint("LEFT")
	scrollFrame.Title = scrollFrame:CreateFontString(name.."Title", "OVERLAY", "GameTooltipText")
	scrollFrame.Title:SetPoint("BOTTOM", scrollFrame, "TOP", 0, 2)
	scrollFrame.Title:SetWidth(auctionScrollFrameWidth)
	scrollFrame.Title:SetText(title)
	scrollFrame.buttons = {}
	
	for i=1, numRows do
		local listingButton = buttonCreateFunc(scrollFrame, name.."Button"..i)
		listingButton:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, (1-i)*buttonHeight)
		table.insert(scrollFrame.buttons, listingButton)
	end

	return scrollFrame
end

local function myAuctionsScrollFrame_Update(self)
	local buttons = self.buttons
	local results = MM:GetSortedMyAuctionResults()
	FauxScrollFrame_Update(self, #results, #buttons, buttonHeight, nil, nil, nil, nil, nil, nil, true)
	local selectedData = MM:GetSelectedMyAuctionData()
	local offset = FauxScrollFrame_GetOffset(self)
	for line = 1, #buttons do
		local lineplusoffset = line + offset
		local button = buttons[line]
		if lineplusoffset > #results then
			button:Hide()
			button.data = nil
		else
			local result = results[lineplusoffset]
			button.data = result
			local textColor = MM:GetLastScanTimeColor(result)
			button.auctionCount:SetText("|cff" .. textColor .. #button.data.auctions .. "|r")
			local enchantData = C_MysticEnchant.GetEnchantInfoBySpell(result.SpellID)
			button.enchantName:SetText(MM:cTxt(enchantData.SpellName, tostring(enchantData.Quality)))
			button:Show()
			if selectedData and button.data.SpellID == selectedData.SpellID then
				button.H:Show()
				button.H:SetDesaturated(false)
			elseif button:IsMouseOver() then
				button.H:Show()
				button.H:SetDesaturated(true)
			else
				button.H:Hide()
				button.H:SetDesaturated(true)
			end
		end
	end
end

local function selectEnchantAuctionsScrollFrame_Update(self)
	local buttons = self.buttons
	local results = MM:GetSelectedEnchantAuctionsResults()
	FauxScrollFrame_Update(self, #results, #buttons, buttonHeight, nil, nil, nil, nil, nil, nil, true)
	local offset = FauxScrollFrame_GetOffset(self)
	local selectedEnchant = MM:GetSelectedSelectedEnchantAuctionData()
	-- go through each button and set visibility and associate with results
	for line = 1, #buttons do
		local lineplusoffset = line + offset
		local button = buttons[line]
		MM:EnableSelectEnchantAuctionButton(button)
		if lineplusoffset > #results then
			button:Hide()
			button.data = nil
		else
			local result = results[lineplusoffset]
			button.price.Suffix:SetText(result.yours and "  (yours)" or nil)
			MoneyFrame_Update(button.price, result.buyoutPrice)
			button.data = result
			button.icon:SetTexture(result.icon)
			button:Show()
			MM:EnableSelectEnchantAuctionButton(button)
			if button.data == selectedEnchant then
				button.H:Show()
				button.H:SetDesaturated(false)
			elseif button:IsMouseOver() then
				button.H:Show()
				button.H:SetDesaturated(true)
			else
				button.H:Hide()
				button.H:SetDesaturated(true)
			end
		end
	end
end

local myAuctionsScrollFrame

function MM:GetMyAuctionsScrollFrame()
	return myAuctionsScrollFrame
end

function MM:SetMyAuctionsScrollFrame(scrollFrame)
	myAuctionsScrollFrame = scrollFrame
end

local myAuctionsButtonCount = 12

local function createMyAuctionsScrollFrame()
	local myAuctionsScrollFrameContainer = MM:CreateMenuContainer(ahExtensionMenu, "TOPRIGHT", auctionScrollFrameWidth, buttonHeight * myAuctionsButtonCount, -11, -20)
	local scrollFrame = createAuctionsScrollFrame(
		"MysticMaestroMyAuctions",
		"My Auctions",
		myAuctionsScrollFrameContainer,
		myAuctionsButtonCount,
		createMyAuctionsButton
	)
	scrollFrame.Title:SetJustifyH("CENTER")
	scrollFrame:SetScript("OnVerticalScroll",
		function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, buttonHeight, myAuctionsScrollFrame_Update)
		end
	)
	MM:SetMyAuctionsScrollFrame(scrollFrame)
	MM_FRAMES_MENU_MYAUCTIONS = myAuctionsScrollFrameContainer
end

function MM:RefreshMyAuctionsScrollFrame()
	myAuctionsScrollFrame_Update(self:GetMyAuctionsScrollFrame())
	local selectedEnchantButton = self:GetSelectedEnchantButton()
	if selectedEnchantButton then
		self:SelectMyAuctionBySpellID(selectedEnchantButton.SpellID)
	end
end

local selectedEnchantAuctionsScrollFrame

function MM:GetSelectedEnchantAuctionsScrollFrame()
	return selectedEnchantAuctionsScrollFrame
end

function MM:SetSelectedEnchantAuctionsScrollFrame(scrollFrame)
	selectedEnchantAuctionsScrollFrame = scrollFrame
end

local selectedEnchantAuctionsButtonCount = 6

local function createSelectedEnchantAuctionsScrollFrame()
	local selectedEnchantAuctionsScrollFrameContainer = MM:CreateMenuContainer(ahExtensionMenu, "BOTTOMRIGHT", auctionScrollFrameWidth, buttonHeight * selectedEnchantAuctionsButtonCount, -11, 40)
	local scrollFrame = createAuctionsScrollFrame(
		"MysticMaestroSelectedEnchantAuctions",
		"Selected Enchant Auctions",
		selectedEnchantAuctionsScrollFrameContainer,
		selectedEnchantAuctionsButtonCount,
		createSelectedAuctionsButton
	)
	scrollFrame.Title:SetJustifyH("RIGHT")
	scrollFrame:SetScript("OnVerticalScroll",
		function(self, offset)
			FauxScrollFrame_OnVerticalScroll(self, offset, buttonHeight, selectEnchantAuctionsScrollFrame_Update)
		end
	)
	MM:SetSelectedEnchantAuctionsScrollFrame(scrollFrame)
	MM_FRAMES_MENU_SELECTEDRESULTS = selectedEnchantAuctionsScrollFrameContainer
end

local refreshButton
local function createRefreshButton()
	refreshButton = CreateFrame("BUTTON", nil, ahExtensionMenu)
	refreshButton:SetSize(18, 18)
	refreshButton:SetPoint("LEFT", ahExtensionMenu, "BOTTOMLEFT", 8, 148)
	refreshButton:SetNormalTexture("Interface\\BUTTONS\\UI-RefreshButton")
	refreshButton:SetPushedTexture("Interface\\AddOns\\MysticMaestro\\textures\\UI-RefreshButton-Down")
	refreshButton:SetDisabledTexture("Interface\\AddOns\\MysticMaestro\\textures\\UI-RefreshButton-Disabled")
	refreshButton:SetScript("OnClick",
	function()
		if MM.AutomationManager:IsRunning() then return end
		if MM:GetSelectedEnchantButton() then
			MM:ClearSelectedEnchantAuctions()
			MM:RefreshSelectedEnchantAuctions(false)
		end
	end)
	MM:DisableAuctionRefreshButton()
	MM_FRAMES_MENU_RESULTREFRESH = refreshButton
end

function MM:DisableAuctionRefreshButton()
	refreshButton:Disable()
end

function MM:EnableAuctionRefreshButton()
	refreshButton:Enable()
end

local function initAHExtension()
	createContainerFrame()
	createMyAuctionsScrollFrame()
	createSelectedEnchantAuctionsScrollFrame()
	createRefreshButton()
end

local function undercut(SpellID, buyoutPrice, yours)
	if yours then
		MM:ListAuction(SpellID, buyoutPrice)
	else
		MM:ListAuction(SpellID, buyoutPrice - 1)
	end
end

local listButton, buyCancelbutton, postButton, scanButton 
local function setUpButtonWidgets()
	postButton = AceGUI:Create("Button")
	postButton.frame:SetParent(ahExtensionMenu)
	postButton:SetPoint("TOPLEFT", ahExtensionMenu, "TOPLEFT", 4, 28)
	postButton:SetWidth(82)
	postButton:SetHeight(22)
	postButton:SetText("Post")
	postButton:SetCallback("OnClick",
		function(self, event)
			MM.AutomationManager:ShowAutomationPrompt("Post")
		end
	)
	postButton.frame:Show()

	scanButton = AceGUI:Create("Button")
	scanButton.frame:SetParent(ahExtensionMenu)
	scanButton:SetPoint("TOPRIGHT", ahExtensionMenu, "TOPRIGHT", -12, 28)
	scanButton:SetWidth(106)
	scanButton:SetHeight(22)
	scanButton:SetCallback("OnClick",
		function(self, event)
			if MM.db.realm.OPTIONS.useGetall and MM:CheckRealmA52() then
				MM.AutomationManager:ShowAutomationPrompt("GetAll Scan")
			else
				MM.AutomationManager:ShowAutomationPrompt("Batch Scan")
			end
		end
	)
	scanButton.frame:Show()

	listButton = AceGUI:Create("Button")
	listButton.frame:SetParent(ahExtensionMenu)
	listButton:SetPoint("BOTTOMLEFT", ahExtensionMenu, "BOTTOMLEFT", 0, 15)
	listButton:SetWidth(82)
	listButton:SetHeight(22)
	listButton:SetText("List")
	listButton:SetCallback("OnClick",
		function(self, event)
			if MM.AutomationManager:IsRunning() then return end
			local auctionData = MM:GetSelectedSelectedEnchantAuctionData()
			if not auctionData then
				local results = MM:GetSelectedEnchantAuctionsResults()
				if #results > 0 then
					local price, yours = MM:PriceCorrection(results[1],results)
					if not price then
						MM:Print("Price is below Minimum, leaving in inventory.")
					else
						undercut(MM:GetSelectedEnchantButton().SpellID, price, yours)
					end
				else
					MM:ListAuction(MM:GetSelectedEnchantButton().SpellID, MM.db.realm.OPTIONS.postDefault * 10000)
				end
			else
				undercut(auctionData.SpellID, auctionData.buyoutPrice, auctionData.yours)
			end
		end
	)
	listButton.frame:Show()
	MM:DisableListButton()
	MM_FRAMES_MENU_LIST = listButton.frame

	buyCancelbutton = AceGUI:Create("Button")
	buyCancelbutton.frame:SetParent(ahExtensionMenu)
	buyCancelbutton:SetPoint("BOTTOMRIGHT", ahExtensionMenu, "BOTTOMRIGHT", -6, 15)
	buyCancelbutton:SetWidth(124)
	buyCancelbutton:SetHeight(22)
	buyCancelbutton:SetText("Buyout/Cancel")
	buyCancelbutton:SetCallback("OnClick",
		function(self, event)
			if MM.AutomationManager:IsRunning() then return end
			local selectedAuctionData = MM:GetSelectedSelectedEnchantAuctionData()
			if not selectedAuctionData then return end
			if selectedAuctionData.yours then
				MM:CancelAuction(selectedAuctionData.SpellID, selectedAuctionData.buyoutPrice)
			else
				MM:BuyoutAuction(selectedAuctionData.id)
			end
		end
	)
	buyCancelbutton.frame:Show()
	MM:DisableBuyoutCancelButton()
	MM_FRAMES_MENU_BUYOUTCANCEL = buyCancelbutton.frame
end


local time, CanSendAuctionQuery = time, CanSendAuctionQuery
MM.OnUpdateFrame:HookScript("OnUpdate",
	function()
		if not scanButton then return end
		if not MM.db.realm.OPTIONS.useGetall or not MM:CheckRealmA52() then
			scanButton:SetText("Scan")
			scanButton:SetDisabled(false)
			return
		end
		
		if select(2, CanSendAuctionQuery()) then
			scanButton:SetText("GetAll Scan")
			scanButton:SetDisabled(false)
		else
			local secondsRemaining = math.floor(900 - (time() - (MM.db.char.lastGetAllScanTime or 0)))
			secondsRemaining = secondsRemaining >= 0 and secondsRemaining or 0
			if secondsRemaining == 0 then
				scanButton:SetText("GetAll Scan")
			else
				scanButton.text:SetFormattedText("%d:%02d", math.floor(secondsRemaining/60), secondsRemaining%60)
			end
			scanButton:SetDisabled(true)
		end
	end
)

local function tearDownButtonWidgets()
	scanButton:Release()
	postButton:Release()
	listButton:Release()
	buyCancelbutton:Release()
	scanButton = nil
	postButton = nil
	listButton = nil
	buyCancelbutton = nil
end

function MM:DisableListButton()
	listButton:SetDisabled(true)
end

function MM:EnableListButton()
	listButton:SetDisabled(false)
end

function MM:DisableBuyoutCancelButton()
	buyCancelbutton:SetDisabled(true)
end

function MM:EnableBuyoutCancelButton()
	buyCancelbutton:SetDisabled(false)
end

function MM:ShowAHExtension()
	if not MysticMaestroMenuAHExtension then
		initAHExtension()
	end
	setUpButtonWidgets()
	myAuctionsScrollFrame_Update(self:GetMyAuctionsScrollFrame())
	selectEnchantAuctionsScrollFrame_Update(self:GetSelectedEnchantAuctionsScrollFrame())
	MysticMaestroMenuAHExtension:Show()
	MysticMaestroMenuAHExtension:ClearAllPoints()
	MysticMaestroMenuAHExtension:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", 0, 0)
	MysticMaestroMenuAHExtension:SetParent(AuctionFrame)
	MM:toggleAHExtensionHelpPlates(true)
	self.AutomationManager:ShowAutomationPromptIfPaused()
end

function MM:HideAHExtension()
	self:ResetAHExtension()
	tearDownButtonWidgets()
	MysticMaestroMenuAHExtension:Hide()
	MM:toggleAHExtensionHelpPlates(false)
end

function MM:ResetAHExtension()
	self:SetSelectedMyAuctionData(nil)
	self:ClearSelectedEnchantAuctions()
	self:CloseAuctionPopups()
	self:DisableListButton()
	self:DisableAuctionRefreshButton()
	self:CancelSingleScan()
end

function MM:PopulateSelectedEnchantAuctions(results)
	self:SetSelectedEnchantAuctionsResults(results)
	selectEnchantAuctionsScrollFrame_Update(self:GetSelectedEnchantAuctionsScrollFrame())
end

local selectedEnchantAuctionsResults
function MM:GetSelectedEnchantAuctionsResults()
	self:SetSelectedEnchantAuctionsResults(selectedEnchantAuctionsResults or {})
	return selectedEnchantAuctionsResults
end

function MM:SetSelectedEnchantAuctionsResults(results)
	selectedEnchantAuctionsResults = results
end

function MM:ClearSelectedEnchantAuctions()
	self:SetSelectedSelectedEnchantAuctionData(nil)
	self:PopulateSelectedEnchantAuctions({})
end

local function setMoneyButtonTransparency(button, alpha)
	local moneyFrameName = button.price:GetName()
	_G[moneyFrameName.."GoldButton"]:GetNormalTexture():SetVertexColor(1, 1, 1, alpha)
	_G[moneyFrameName.."GoldButtonText"]:SetTextColor(1, 1, 1, alpha)
	_G[moneyFrameName.."SilverButton"]:GetNormalTexture():SetVertexColor(1, 1, 1, alpha)
	_G[moneyFrameName.."SilverButtonText"]:SetTextColor(1, 1, 1, alpha)
	_G[moneyFrameName.."CopperButton"]:GetNormalTexture():SetVertexColor(1, 1, 1, alpha)
	_G[moneyFrameName.."CopperButtonText"]:SetTextColor(1, 1, 1, alpha)
	button.price.Suffix:SetTextColor(1, 1, 1, alpha)
end

function MM:DisableSelectEnchantAuctionButton(button)
	setMoneyButtonTransparency(button, .3)
	button:Disable()
end

function MM:EnableSelectEnchantAuctionButton(button)
	setMoneyButtonTransparency(button, 1)
	button:Enable()
end

function MM:MyAuctions_AUCTION_OWNED_LIST_UPDATE()
	self:CacheMyAuctionResults(self.listedAuctionSpellID)
	self.listedAuctionSpellID = nil
	self.listedAuctionBuyoutPrice = nil
	if self:IsEmbeddedMenuOpen() and not self.AutomationManager:IsRunning() then
		self:RefreshMyAuctionsScrollFrame()
	end
end