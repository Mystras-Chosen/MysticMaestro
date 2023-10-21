local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local AceGUI = LibStub("AceGUI-3.0")
-- Localized functions
local CreateListFrame, setCurrentSelectedList, createScrollFrame, scrollSliderCreate, reforgeCheck, extractCheck, enableCheck
-- Colours stored for code readability
local WHITE = "|cffFFFFFF"
local GREEN = "|cff1eff00"
local BLUE = "|cff0070dd"
local ORANGE = "|cffFF8400"
local GOLD  = "|cffffcc00"
local LIGHTBLUE = "|cFFADD8E6"
local ORANGE2 = "|cFFFFA500"

local qualityColors = {
["RE_QUALITY_UNCOMMON"] = 2,
["RE_QUALITY_RARE"] = 3,
["RE_QUALITY_EPIC"] = 4,
["RE_QUALITY_LEGENDARY"] = 5,
}

local realmName = GetRealmName()
local showtable = {}

setCurrentSelectedList = function()
	local thisID = this:GetID()
	MM.shoppingLists.currentSelectedList = thisID
	UIDropDownMenu_SetSelectedID(MysticMaestro_ListFrame_ListDropDown,thisID)
	MysticMaestro_ListFrame_ScrollFrameUpdate()
end

function MM:MenuInitialize()
	local info
	for k,v in ipairs(MM.shoppingLists) do
		info = {
			text = v.Name,
			func = function() setCurrentSelectedList() end
		}
		UIDropDownMenu_AddButton(info)
	end
end

function MM:ListFrameEnable()
	UIDropDownMenu_Initialize(MysticMaestro_ListFrame_ListDropDown, MM.MenuInitialize)
	UIDropDownMenu_SetSelectedID(MysticMaestro_ListFrame_ListDropDown,MM.shoppingLists.currentSelectedList)
	MysticMaestro_ListFrame_ScrollFrameUpdate()
end

StaticPopupDialogs["MysticMaestro_ListFrame_ADDLIST"] = {
	text = "Add New List?",
	button1 = "Confirm",
	button2 = "Cancel",
	hasEditBox = true,
	OnAccept = function (self, data, data2)
		local text = self.editBox:GetText()
		MM.shoppingLists[#MM.shoppingLists + 1] = {Name = text, extract = false, enable = false, reforge = false }
		UIDropDownMenu_Initialize(MysticMaestro_ListFrame_ListDropDown, MM.MenuInitialize)
		UIDropDownMenu_SetSelectedID(MysticMaestro_ListFrame_ListDropDown,#MM.shoppingLists)
		MM.shoppingLists.currentSelectedList = #MM.shoppingLists
	MysticMaestro_ListFrame_ScrollFrameUpdate()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	enterClicksFirstButton = true,
}

StaticPopupDialogs["MysticMaestro_ListFrame_EDITLISTNAMM"] = {
	text = "Edit Current List Name?",
	button1 = "Confirm",
	button2 = "Cancel",
	hasEditBox = true,
	OnShow = function(self)
		self.editBox:SetText(MM.shoppingLists[MM.shoppingLists.currentSelectedList].Name)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnAccept = function (self, data, data2)
		local text = self.editBox:GetText()
		if text ~= "" then
			MM.shoppingLists[MM.shoppingLists.currentSelectedList].Name = text
			UIDropDownMenu_Initialize(MysticMaestro_ListFrame_ListDropDown, MM.MenuInitialize)
			UIDropDownMenu_SetText(MysticMaestro_ListFrame_ListDropDown, text)
			MysticMaestro_ListFrame_ScrollFrameUpdate()
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	enterClicksFirstButton = true,
}

StaticPopupDialogs["MysticMaestro_ListFrame_DELETELIST"] = {
	text = "Delete List?",
	button1 = "Confirm",
	button2 = "Cancel",
	OnAccept = function ()
		tremove(MM.shoppingLists, MM.shoppingLists.currentSelectedList)
		UIDropDownMenu_Initialize(MysticMaestro_ListFrame_ListDropDown, MM.MenuInitialize)
		UIDropDownMenu_SetSelectedID(MysticMaestro_ListFrame_ListDropDown,1)
		MM.shoppingLists.currentSelectedList = 1
		MysticMaestro_ListFrame_ScrollFrameUpdate()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
	enterClicksFirstButton = true,
}

local menuSetup
function MM:ListFrameMenuRegister(self)
	local menuList = {
		[1] = {
		{text = "Send Current List", func = function() StaticPopup_Show("MYSTICMAESTRO_SEND_SHOPPINGLIST", MM.shoppingLists[MM.shoppingLists.currentSelectedList].Name) end, closeWhenClicked = true, notCheckable = true, textHeight = 12, textWidth = 12},
		{text = "Export List", func = MM.exportString, closeWhenClicked = true, tooltip = "Exports a string to clipboard", notCheckable = true, textHeight = 12, textWidth = 12},
		{text = "Import List", func = function() StaticPopup_Show("MYSTICMAESTRO_IMPORT_SHOPPINGLIST") end, closeWhenClicked = true, notCheckable = true, textHeight = 12, textWidth = 12},
		{close = true, divider = 35}
		},
	}
	menuSetup = MM:OpenDewdropMenu(self, menuList, menuSetup)
end

------------------ScrollFrameTooltips---------------------------
local function ItemTemplate_OnEnter(self)
	if self.link == nil then return end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -13, -50)
	GameTooltip:SetHyperlink(self.link)
	GameTooltip:Show()
end

local function ItemTemplate_OnLeave()
	GameTooltip:Hide()
end

-- Sorts tables alphabetically
local function pairsByKeys(t)
	local a = {}
	for n in pairs(t) do
	  table.insert(a, n)
	end
	table.sort(a)
  
	local i = 0
	local iter = function()
	  i = i + 1
	  if a[i] == nil then
		return nil
	  else
		return a[i], t[a[i]]
	  end
	end
	return iter
end

--Check to see if the enchant is allreay on the list
local function GetSavedEnchant(SpellID)
	if MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"][SpellID] then
		return true
	end
end

---------------------ScrollFrame----------------------------------
local ROW_HEIGHT = 16   -- How tall is each row?
local MAX_ROWS = 26      -- How many rows can be shown at once?
local scrollFrame
createScrollFrame = function()
scrollFrame = CreateFrame("Frame", "MysticMaestro_ListFrame_ScrollFrame", MysticMaestro_ListFrame)
	scrollFrame:EnableMouse(true)
	scrollFrame:SetSize(MysticMaestro_ListFrame:GetWidth() - 30, ROW_HEIGHT * MAX_ROWS + 16)
	scrollFrame:SetPoint("CENTER",.5,0)
	scrollFrame:SetBackdrop({
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
end

function MysticMaestro_ListFrame_ScrollFrameUpdate()
	local methods = {}
	if MM.shoppingLists[MM.shoppingLists.currentSelectedList] and MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"] then
		for _, enchants in pairs(MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"]) do
			local enchantInfo = C_MysticEnchant.GetEnchantInfoBySpell(enchants.SpellID)
			methods[enchantInfo.SpellName] = { SpellID = enchants.SpellID, Quality = enchantInfo.Quality, Name = enchantInfo.SpellName }
		end
		showtable = {Name = MM.shoppingLists[MM.shoppingLists.currentSelectedList].Name, MenuID = MM.shoppingLists[MM.shoppingLists.currentSelectedList].MenuID}

		for _, table in pairsByKeys(methods) do
			tinsert(showtable, table)
		end

		local maxValue = #showtable
		FauxScrollFrame_Update(scrollFrame.scrollBar, maxValue, MAX_ROWS, ROW_HEIGHT)
		local offset = FauxScrollFrame_GetOffset(scrollFrame.scrollBar)
		for i = 1, MAX_ROWS do
			local value = i + offset
			scrollFrame.rows[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
			if value <= maxValue and showtable[value] then
				local row = scrollFrame.rows[i]
				local qualityColor = select(4,GetItemQualityColor(qualityColors[showtable[value].Quality]))
				row:SetText(qualityColor..showtable[value].Name)
				row.SpellID = showtable[value].SpellID
				row.Quality = showtable[value].Quality
				row.Name = showtable[value].Name
				row.link = MM:CreateItemLink(showtable[value].SpellID, showtable[value].Quality)
				row:Show()
			else
				scrollFrame.rows[i]:Hide()
			end
		end
	else
		for i = 1, MAX_ROWS do
			scrollFrame.rows[i]:Hide()
		end
	end
end

scrollSliderCreate = function()
local scrollSlider = CreateFrame("ScrollFrame","MysticMaestro_ListFrameScroll",MysticMaestro_ListFrame_ScrollFrame,"FauxScrollFrameTemplate")
scrollSlider:SetPoint("TOPLEFT", 0, -8)
scrollSlider:SetPoint("BOTTOMRIGHT", -30, 8)
scrollSlider:SetScript("OnVerticalScroll", function(self, offset)
	self.offset = math.floor(offset / ROW_HEIGHT + 0.5)
	MysticMaestro_ListFrame_ScrollFrameUpdate()
end)

scrollSlider:SetScript("OnShow", function()
	MysticMaestro_ListFrame_ScrollFrameUpdate()
end)

scrollFrame.scrollBar = scrollSlider

local rows = setmetatable({}, { __index = function(t, i)
	local row = CreateFrame("Button", "$parentRow"..i, scrollFrame)
	row:SetSize(150, ROW_HEIGHT)
	row:SetNormalFontObject(GameFontHighlightLeft)
	row:RegisterForClicks("LeftButtonDown","RightButtonDown")
	row:SetScript("OnClick", function(self,button)
		if button == "RightButton" then
			if MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"][row.SpellID] then
				MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"][row.SpellID] = nil
			end
			MysticMaestro_ListFrame_ScrollFrameUpdate()
		elseif button == "LeftButton" then
			if IsShiftKeyDown() then
				ChatEdit_InsertLink(MM:CreateItemLink(row.SpellID, row.Quality))
			else
				Internal_CopyToClipboard(row.Name)
			end
		end
	end)
	row:SetScript("OnEnter", function(self)
		ItemTemplate_OnEnter(self)
	end)
	row:SetScript("OnLeave", ItemTemplate_OnLeave)
	if i == 1 then
		row:SetPoint("TOPLEFT", scrollFrame, 8, -8)
	else
		row:SetPoint("TOPLEFT", scrollFrame.rows[i-1], "BOTTOMLEFT")
	end

	rawset(t, i, row)
	return row
end })

scrollFrame.rows = rows
end
function MM:CreateItemLink(SpellID, Quality)
	local qualityColor = select(4,GetItemQualityColor(qualityColors[Quality]))
	local link = qualityColor.."|Hspell:"..SpellID.."|h["..GetSpellInfo(SpellID).."]|h|r"
	return link
end

local function enchantButtonClick(self)
	local SpellID = self.enchantInfo.SpellID
	local Quality = self.enchantInfo.Quality
	if not MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"] then MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"] = {} end
	if not GetSavedEnchant(SpellID) then
		MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"][SpellID] = {SpellID = SpellID, Quality = self.enchantInfo.Quality}
		MysticMaestro_ListFrame_ScrollFrameUpdate()
	else
		local itemLink = MM:CreateItemLink(SpellID, Quality)
		DEFAULT_CHAT_FRAME:AddMessage(itemLink .. " Is already on this list.")
	end
end

local setupLoaded
local buttonsLoaded = {}
function MM:CollectionSetup(addon)
	if setupLoaded then return end
	EnchantCollection.Collection.CollectionTab:HookScript("OnUpdate", function()
		if buttonsLoaded[18] then return end
		for i = 1, 18 do
			local button = _G["EnchantCollection"]["Collection"]["CollectionTab"]["buttonIDToButton"][i]
			if button and not buttonsLoaded[i] then
				button:HookScript("OnMouseDown", function(self, button)
					if button == "RightButton" then
						MM:ItemContextMenu(self)
					elseif button == "LeftButton" and IsAltKeyDown() then
						enchantButtonClick(self)
					end
				end)
			buttonsLoaded[i] = true
			end
		end
	end)

	CreateListFrame()
	setupLoaded = true
end

-- Creates all our frames the first time the enchanting collections window is opened
CreateListFrame = function()
	-- Ascension Enchant Collection Frame Name
local enchantCounts
local collectionOverlay = CreateFrame("FRAME", "MysticMaestro_Collection_Overlay", _G["EnchantCollection"])
	collectionOverlay:SetSize(_G["EnchantCollection"]:GetWidth(), _G["EnchantCollection"]:GetHeight())
	collectionOverlay:SetPoint("CENTER", _G["EnchantCollection"])

	-- moves enchant page buttons to better fit our known count
	EnchantCollection.Collection.CollectionTab.PageText:SetPoint("BOTTOM",0,50)
	EnchantCollection.Collection.CollectionTab:EnableMouse()
	EnchantCollection.Collection.CollectionTab:HookScript("OnMouseDown", function() MM.dewdrop:Close() end)

	collectionOverlay.KnownCount = CreateFrame("Button", nil, EnchantCollection.Collection.CollectionTab)
	collectionOverlay.KnownCount:SetPoint("BOTTOM", collectionOverlay , 185, 44)
	collectionOverlay.KnownCount:SetSize(190,20)
	collectionOverlay.KnownCount.Lable = collectionOverlay.KnownCount:CreateFontString(nil , "BORDER", "GameFontNormal")
	collectionOverlay.KnownCount.Lable:SetJustifyH("LEFT")
	collectionOverlay.KnownCount.Lable:SetPoint("LEFT", 0, 0)
	collectionOverlay.KnownCount:SetScript("OnShow", function()
		enchantCounts = MM:CalculateKnowEnchants()
		collectionOverlay.KnownCount.Lable:SetText("Known Enchants: |cffffffff"..enchantCounts.knownEnchants.."/"..enchantCounts.totalEnchants)
	end)
	collectionOverlay.KnownCount:SetScript("OnEnter", function(self)
		enchantCounts = MM:CalculateKnowEnchants()
		MM:EnchantCountTooltip(self, enchantCounts) end)
	collectionOverlay.KnownCount:SetScript("OnLeave", function() GameTooltip:Hide() end)

local listFrame = CreateFrame("FRAME", "MysticMaestro_ListFrame", collectionOverlay, "UIPanelDialogTemplate")
	listFrame:SetSize(350, collectionOverlay:GetHeight()+7)
	listFrame:SetPoint("LEFT", collectionOverlay,"RIGHT")
	listFrame.TitleText = listFrame:CreateFontString()
	listFrame.TitleText:SetFont("Fonts\\FRIZQT__.TTF", 12)
	listFrame.TitleText:SetFontObject(GameFontNormal)
	listFrame.TitleText:SetText("Enchant Shopping List")
	listFrame.TitleText:SetPoint("TOP", 0, -9)
	listFrame.TitleText:SetShadowOffset(1,-1)
	listFrame.tex = listFrame:CreateTexture(nil, "ARTWORK")
	listFrame.tex:SetPoint("CENTER",0,-35)
	local tex = AtlasUtil:GetAtlasInfo("Enchant-Slot-Frame-Background")
	listFrame.tex:SetTexture(tex.filename)
	listFrame.tex:SetTexCoord(tex.leftTexCoord, tex.rightTexCoord, tex.topTexCoord, tex.bottomTexCoord)
	listFrame.tex:SetSize(345, listFrame:GetHeight()+10)
	listFrame:Hide()
	listFrame:SetScript("OnHide", function()
		if _G["EnchantCollection"]:IsVisible() then
			MM.db.char.ListFrameLastState = false
		end
	end)

	hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self)
		if MysticMaestro_ListFrame:IsVisible() and IsAltKeyDown() then
			local bagID, slotID = self:GetParent():GetID(), self:GetID()
			self.enchantInfo = C_MysticEnchant.GetEnchantInfoByItem(GetContainerItemID(bagID, slotID))
			if not self.enchantInfo then return end
			enchantButtonClick(self)
		end
	end)

	local listDropdown = CreateFrame("Button", "MysticMaestro_ListFrame_ListDropDown", MysticMaestro_ListFrame, "UIDropDownMenuTemplate")
	listDropdown:SetPoint("TOPLEFT", 4, -40)
	listDropdown:SetScript("OnClick", MysticMaestro_ListFrame_ListOnClick)
	UIDropDownMenu_SetWidth(MysticMaestro_ListFrame_ListDropDown, 155)
	listDropdown.EnchantNumber = listDropdown:CreateFontString("MysticMaestro_ListFrameEnchantCount", "OVERLAY", "GameFontNormal")
	listDropdown.EnchantNumber:SetPoint("TOPLEFT", 26, -8)
	listDropdown.EnchantNumber:SetFont("Fonts\\FRIZQT__.TTF", 11)
	listDropdown:SetScript("OnUpdate", function()
			listDropdown.EnchantNumber:SetText("|cff00ff00"..#showtable)
			if not MM.shoppingLists.currentSelectedList then return end 
			reforgeCheck:SetValue(MM.shoppingLists[MM.shoppingLists.currentSelectedList].reforge)
			extractCheck:SetValue(MM.shoppingLists[MM.shoppingLists.currentSelectedList].extract)
			enableCheck:SetValue(MM.shoppingLists[MM.shoppingLists.currentSelectedList].enable)
		end)

local editlistnamebtn = CreateFrame("Button", "MysticMaestro_ListFrame_EditListBtn", MysticMaestro_ListFrame, "OptionsButtonTemplate")
	editlistnamebtn:SetPoint("TOPLEFT", 195, -41)
	editlistnamebtn:SetText("E")
	editlistnamebtn:SetSize(27, 27)
	editlistnamebtn:SetScript("OnClick", function() StaticPopup_Show("MysticMaestro_ListFrame_EDITLISTNAMM") end)
	editlistnamebtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Edit List Name")
		GameTooltip:Show()
	end)
	editlistnamebtn:SetScript("OnLeave", function() GameTooltip:Hide() end)


local addlistbtn = CreateFrame("Button", "MysticMaestro_ListFrame_AddListBtn", MysticMaestro_ListFrame, "OptionsButtonTemplate")
	addlistbtn:SetPoint("TOPLEFT", 225, -41)
	addlistbtn:SetText("+")
	addlistbtn:SetSize(27, 27)
	addlistbtn:SetScript("OnClick", function() StaticPopup_Show("MysticMaestro_ListFrame_ADDLIST") end)
	addlistbtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Create New List")
		GameTooltip:Show()
	end)
	addlistbtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local removelistbtn = CreateFrame("Button", "MysticMaestro_ListFrame_RemoveListBtn", MysticMaestro_ListFrame, "OptionsButtonTemplate")
	removelistbtn:SetPoint("TOPLEFT", 255, -41)
	removelistbtn:SetText("-")
	removelistbtn:SetSize(27, 27)
	removelistbtn:SetScript("OnClick", function() StaticPopup_Show("MysticMaestro_ListFrame_DELETELIST") end)
	removelistbtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Remove List")
		GameTooltip:Show()
	end)
	removelistbtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

------------------Checkbox------------------------------------
	enableCheck = AceGUI:Create("CheckBox")
	enableCheck.frame:SetParent(MysticMaestro_ListFrame)
	enableCheck:SetPoint("BOTTOMLEFT", MysticMaestro_ListFrame, 35, 60)
	enableCheck:SetHeight(25)
	enableCheck:SetWidth(80)
	enableCheck:SetLabel("Enable")
	enableCheck:SetValue( function()
		if not MM.shoppingLists.currentSelectedList then return end
		return MM.shoppingLists[MM.shoppingLists.currentSelectedList].enable
	end)
	enableCheck:SetCallback("OnValueChanged",
	function(self, event, key)
		MM.shoppingLists[MM.shoppingLists.currentSelectedList].enable = not MM.shoppingLists[MM.shoppingLists.currentSelectedList].enable
	end
	)
	enableCheck:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(enableCheck.frame, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Enable this list for auto reforging")
		GameTooltip:Show()
	end)
	enableCheck:SetCallback("OnLeave", function() GameTooltip:Hide() end)
	enableCheck.frame:Show()
	MM.enableCheck = enableCheck

	extractCheck = AceGUI:Create("CheckBox")
	extractCheck.frame:SetParent(MysticMaestro_ListFrame)
	extractCheck:SetPoint("LEFT", enableCheck.frame, "RIGHT", 10, 0)
	extractCheck:SetHeight(25)
	extractCheck:SetWidth(80)
	extractCheck:SetLabel("Extract")
	extractCheck:SetValue( function() 
		if not MM.shoppingLists.currentSelectedList then return end
		return MM.shoppingLists[MM.shoppingLists.currentSelectedList].extract
	end)
	extractCheck:SetCallback("OnValueChanged",
	function(self, event, key)
		MM.shoppingLists[MM.shoppingLists.currentSelectedList].extract = not MM.shoppingLists[MM.shoppingLists.currentSelectedList].extract
	end
	)
	extractCheck:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(extractCheck.frame, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Auto extract enchants on this list if unknown")
		GameTooltip:Show()
	end)
	extractCheck:SetCallback("OnLeave", function() GameTooltip:Hide() end)
	extractCheck.frame:Show()

	reforgeCheck = AceGUI:Create("CheckBox")
	reforgeCheck.frame:SetParent(MysticMaestro_ListFrame)
	reforgeCheck:SetPoint("LEFT", extractCheck.frame, "RIGHT", 10, 0)
	reforgeCheck:SetHeight(25)
	reforgeCheck:SetWidth(80)
	reforgeCheck:SetLabel("Reforge")
	reforgeCheck:SetValue( function() 
		if not MM.shoppingLists.currentSelectedList then return end
		return MM.shoppingLists[MM.shoppingLists.currentSelectedList].reforge
	end)
	reforgeCheck:SetCallback("OnValueChanged",
	function(self, event, key)
		MM.shoppingLists[MM.shoppingLists.currentSelectedList].reforge = not MM.shoppingLists[MM.shoppingLists.currentSelectedList].reforge
	end
	)
	reforgeCheck:SetCallback("OnEnter", function(self)
		GameTooltip:SetOwner(reforgeCheck.frame, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Set list to reforge any item found on this list")
		GameTooltip:Show()
	end)
	reforgeCheck:SetCallback("OnLeave", function() GameTooltip:Hide() end)
	reforgeCheck.frame:Show()

--Shows a menu with options and sharing options
local sharebuttonlist = CreateFrame("Button", "MysticMaestro_ListFrame_MenuButton", MysticMaestro_ListFrame, "OptionsButtonTemplate")
	sharebuttonlist:SetSize(133,30)
	sharebuttonlist:SetPoint("BOTTOMRIGHT", MysticMaestro_ListFrame, "BOTTOMRIGHT", -20, 20)
	sharebuttonlist:SetText("Export/Share")
	sharebuttonlist:RegisterForClicks("LeftButtonDown")
	sharebuttonlist:SetScript("OnClick", function(self) MM:ListFrameMenuRegister(self) end)
	collectionOverlay.sharebuttonlist = sharebuttonlist



--Show/Hide button in main list view
	collectionOverlay.showFrameBttn  = CreateFrame("Button", nil, collectionOverlay, "FilterDropDownMenuTemplate")
	collectionOverlay.showFrameBttn :SetSize(80,24)
	collectionOverlay.showFrameBttn :SetPoint("BOTTOMRIGHT", collectionOverlay, -5, 3)
	collectionOverlay.showFrameBttn :SetScript("OnClick", function()
		if listFrame:IsVisible() then
			listFrame:Hide()
			MM.db.char.ListFrameLastState = false
			collectionOverlay.showFrameBttn:SetText("Show")
		else
			collectionOverlay.showFrameBttn:SetText("Hide")
			listFrame:Show()
			MM.db.char.ListFrameLastState = true
		end
	end)
	collectionOverlay.showFrameBttn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(WHITE.."Shopping List")
		GameTooltip:AddLine("Open Shopping List Frame")
		GameTooltip:Show()
	end)
	collectionOverlay.showFrameBttn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	if MM.db.char.ListFrameLastState then
		collectionOverlay.showFrameBttn:SetText("Show")
	else
		collectionOverlay.showFrameBttn:SetText("Hide")
	end

	-- Reforge button in list interface
	collectionOverlay.reforgebuttonlist = CreateFrame("Button", "MysticMaestro_CollectionsFrame_ReforgeButton", collectionOverlay, "FilterDropDownMenuTemplate")
	collectionOverlay.reforgebuttonlist:SetSize(100,24)
	collectionOverlay.reforgebuttonlist:SetPoint("RIGHT", collectionOverlay.showFrameBttn, "LEFT", 0, 0)
	collectionOverlay.reforgebuttonlist.Icon:Hide()
	collectionOverlay.reforgebuttonlist.Text:ClearAllPoints()
	collectionOverlay.reforgebuttonlist.Text:SetPoint("CENTER", 0, 0)
	collectionOverlay.reforgebuttonlist:SetText("Auto Reforge")
	collectionOverlay.reforgebuttonlist:SetScript("OnClick", function(self, btnclick) MM:ReforgeToggle() end)
	collectionOverlay.reforgebuttonlist:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(WHITE.."Bulk Reforging")
		GameTooltip:AddLine("Left Click To Start Reforging")
		GameTooltip:AddLine("Stops when out of runes or bag space")
		GameTooltip:AddLine("Stops when moving your character")
		GameTooltip:AddLine("Reforges each scroll until a match")
		GameTooltip:AddLine("Configure match options in settings")
		GameTooltip:Show()
	end)
	collectionOverlay.reforgebuttonlist:SetScript("OnLeave", function() GameTooltip:Hide() end)


	-- Altar summon button on the enchant collection frame
	local altar = MM:ReturnAltar()
	if altar then
		collectionOverlay.altarBtn = CreateFrame("Button", nil, collectionOverlay, "SecureActionButtonTemplate")
		collectionOverlay.altarBtn:SetSize(22, 22)
		collectionOverlay.altarBtn:SetPoint("RIGHT", collectionOverlay.reforgebuttonlist, "LEFT", -5, 0)
		collectionOverlay.altarBtn.icon = collectionOverlay.altarBtn:CreateTexture(nil, "ARTWORK")
		collectionOverlay.altarBtn.icon:SetSize(22, 22)
		collectionOverlay.altarBtn.icon:SetPoint("CENTER")
		collectionOverlay.altarBtn.icon:SetTexture(altar[3])
		collectionOverlay.altarBtn.Highlight = collectionOverlay.altarBtn:CreateTexture(nil, "OVERLAY")
		collectionOverlay.altarBtn.Highlight:SetSize(23,23)
		collectionOverlay.altarBtn.Highlight:SetPoint("CENTER")
		collectionOverlay.altarBtn.Highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected")
		collectionOverlay.altarBtn.Highlight:Hide()
		collectionOverlay.altarBtn:SetAttribute("type", "item")
		collectionOverlay.altarBtn:SetAttribute("item",altar[1])
		collectionOverlay.altarBtn:SetScript("OnMouseDown", function(self)
			local altar = MM:ReturnAltar()
			local _, _, _, _, itemID = unpack(altar)
			if not MM:HasItem(itemID) then
				RequestDeliverVanityCollectionItem(itemID)
			else
				if MM.db.realm.OPTIONS.deleteAltar then
					MM:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
				end
				MM.dewdrop:Close()
			end
		end)
		collectionOverlay.altarBtn:SetScript("OnEnter", function(self)
			collectionOverlay.altarBtn.Highlight:Show()
			local altar = MM:ReturnAltar()
			local name, cooldown, icon, itemLink = unpack(altar)
			collectionOverlay.altarBtn.icon:SetTexture(icon)
			collectionOverlay.altarBtn:SetAttribute("item",name)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetHyperlink(itemLink)
			if cooldown > 0 then
				GameTooltip:AddLine("Cooldown: |cFF00FFFF("..cooldown.." ".. "mins" .. ")")
			  end
			GameTooltip:Show()
		end)
		collectionOverlay.altarBtn:SetScript("OnLeave", function() GameTooltip:Hide() collectionOverlay.altarBtn.Highlight:Hide() end)
	end

	-- opens the settings page
	collectionOverlay.optionsbutton = CreateFrame("Button", nil, collectionOverlay, "SettingsGearButtonTemplate")
	collectionOverlay.optionsbutton:SetSize(24,24)
	collectionOverlay.optionsbutton:SetPoint("RIGHT", collectionOverlay.altarBtn, "LEFT", -5, 1.2)
	collectionOverlay.optionsbutton:RegisterForClicks("LeftButtonDown")
	collectionOverlay.optionsbutton:SetScript("OnClick", function() MM:OpenConfig("Reforge") end)
	collectionOverlay.optionsbutton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Auto Reforge Settings")
		GameTooltip:Show()
	end)
	collectionOverlay.optionsbutton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	createScrollFrame()
	scrollSliderCreate()

	local function NextPage(self)
		PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA)

		if self.page >= self.maxPage then
			self.page = self.maxPage
		else
			self.page = self.page + 1
		end

		self:OnPageChanged()
	end

	function PreviousPage(self)
		PlaySound(SOUNDKIT.ABILITIES_TURN_PAGEA)

		if self.page <= 1 then
			self.page = 1
		else
			self.page = self.page - 1
		end

		self:OnPageChanged()
	end

	EnchantCollection.Collection.CollectionTab:SetScript("OnMouseWheel", function(self, delta)
		if (delta == -1) then
		   NextPage(self)
		elseif (delta == 1) then
		   PreviousPage(self)
		end
	end)

	_G["EnchantCollection"].Collection:HookScript("OnShow", function()
		Collections:SetScale(MM.db.realm.OPTIONS.enchantWindowScale)
		if MM.db.char.ListFrameLastState then
			listFrame:Show();
			collectionOverlay.showFrameBttn:SetText("Hide");
		else
			listFrame:Hide();
			collectionOverlay.showFrameBttn:SetText("Show");
		end
	end)

	_G["EnchantCollection"].Collection:HookScript("OnHide", function()
		Collections:SetScale(1)
	end)

	MM:ListFrameEnable()
end

-- Right Click context menu in the enchanting frame
function MM:ItemContextMenu(self)
	local itemType = "spell"
	local menulist = {
		[1] = {
		{text = GOLD.."Shopping Lists", notCheckable = true, isTitle = true, textHeight = 13, textWidth = 13},
		{text = "Add to current list", func = function() enchantButtonClick(self) end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
		{divider = 35},
		{text = GOLD.."Links", notCheckable = true, isTitle = true, textHeight = 13, textWidth = 13},
		{text = ORANGE.."Open In AscensionDB", func = function() if IsShiftKeyDown() then itemType = "item" end MM:OpenDBURL(self, itemType) end, closeWhenClicked = true, textHeight = 12, textWidth = 12, notCheckable = true},
		{text = GREEN.."Guild", func = function() if IsShiftKeyDown() then itemType = "item" end MM:Chatlink(self, "GUILD", itemType) end, closeWhenClicked = true, textHeight = 12, textWidth = 12, notCheckable = true},
		{text = LIGHTBLUE.."Party", func = function() if IsShiftKeyDown() then itemType = "item" end MM:Chatlink(self, "PARTY", itemType) end, closeWhenClicked = true, textHeight = 12, textWidth = 12, notCheckable = true},
		{text = ORANGE2.."Raid", func = function() if IsShiftKeyDown() then itemType = "item" end MM:Chatlink(self, "RAID", itemType) end, closeWhenClicked = true, textHeight = 12, textWidth = 12, notCheckable = true},
		{divider = 35},
		{text = GOLD.."Enchanting", notCheckable = true, isTitle = true, textHeight = 13, textWidth = 13},
		{text = "Create Mystic Scroll", func = function() MM:CreateScroll(self.enchantInfo.SpellID) end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
		{divider = 35, close = true}
		}
	}
	MM:OpenDewdropMenu(self, menulist)
end
local spellID
function MM:CreateScroll(SpellID)
	if SpellID then spellID = SpellID end
	local scroll = MM:FindUntarnishedScroll()
	if not scroll then return end
	local canCraft, craftingItem, orbCost =  MM:canReforge(spellID)
	if canCraft then
		if MM.db.realm.OPTIONS.confirmCraft then
			StaticPopupDialogs["MM_CRAFT_RE"].reData = {craftingItem, spellID}
			StaticPopup_Show("MM_CRAFT_RE", MM:ItemLinkRE(spellID), orbCost)
		else
			MM:AttemptCraftingRE({craftingItem, spellID})
		end
	end
end