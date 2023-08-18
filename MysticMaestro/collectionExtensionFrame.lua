local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local AceGUI = LibStub("AceGUI-3.0")
-- Localized functions
local CreateListFrame, setCurrentSelectedList, createScrollFrame, scrollSliderCreate
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

local function exportString()
    MM.dewdrop:Close()
    local data = {}
    for i,v in ipairs(MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"]) do
        tinsert(data,{v[1]})
    end
    data["Name"] = MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Name"]
    Internal_CopyToClipboard("MMXT:"..MM:Serialize(data))
end

function MM:ListFrameMenuRegister(self)
	MM.dewdrop:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                MM.dewdrop:AddLine(
                    'text', "Send Current List",
                    'func', function() StaticPopup_Show("MysticMaestro_ListFrame_SEND_ENCHANTLIST",MM.shoppingLists[MM.shoppingLists.currentSelectedList].Name) end,
                    'notCheckable', true
                )
                MM.dewdrop:AddLine(
                    'text', "Export List",
                    'func', exportString,
                    'tooltip', "Exports a string to clipboard",
                    'notCheckable', true
                )
                MM.dewdrop:AddLine(
                    'text', "Import List",
                    'func', function() StaticPopup_Show("MysticMaestro_ListFrame_IMPORT_ENCHANTLIST") end,
                    'notCheckable', true
                )
                MM.dewdrop:AddLine(
					'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
					'func', function() MM.dewdrop:Close() end,
					'notCheckable', true
				)
            end
		end,
		'dontHook', true
	)
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
---------------------ScrollFrame----------------------------------
--Check to see if the enchant is allreay on the list
local function GetSavedEnchant(SpellID)
    if MM.shoppingLists[MM.shoppingLists.currentSelectedList]["Enchants"][SpellID] then
        return SpellID
    end
end

local ROW_HEIGHT = 16   -- How tall is each row?
local MAX_ROWS = 26      -- How many rows can be shown at once?
local scrollFrame
createScrollFrame = function()
scrollFrame = CreateFrame("Frame", "MysticMaestro_ListFrame_ScrollFrame", MysticMaestro_ListFrame)
    scrollFrame:EnableMouse(true)
    scrollFrame:SetSize(313, ROW_HEIGHT * MAX_ROWS + 16)
    scrollFrame:SetPoint("LEFT",20,0)
    scrollFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
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
function MM:CollectionSetup(addon)
    if setupLoaded then return end
        for i = 1, 18 do
            local button = _G["EnchantCollection"]["Collection"]["CollectionTab"]["buttonIDToButton"][i]
                button:HookScript("OnMouseDown", function(self, button)
                    if button == "RightButton" then
                        MM:ItemContextMenu(self)
                    end
                end)
        end

    CreateListFrame()
    setupLoaded = true
end

--[[ hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self)
    if MysticMaestro_ListFrame:IsVisible() and IsAltKeyDown() then
        local bagID, slotID = self:GetParent():GetID(), self:GetID()
        local enchant = GetREInSlot(bagID, slotID)
            if enchant and not GetSavedEnchant(enchant) then
                tinsert(MM.shoppingLists[MM.shoppingLists.currentSelectedList],{enchant})
                MysticMaestro_ListFrame_ScrollFrameUpdate()
            else
                local itemLink = MM:CreateItemLink(enchant)
                DEFAULT_CHAT_FRAMM:AddMessage(itemLink .. " Is already on this list.")
            end
    end
end) ]]

--[[ hooksecurefunc("ContainerFrameItemButton_OnClick", function(self, button)
    if _G["EnchantCollection"]["Collection"]["CollectionTab"]:IsVisible() then
        local bagID, slotID = self:GetParent():GetID(), self:GetID()
        MysticMaestro_ListFrame_BAGID = bagID
        MysticMaestro_ListFrame_SLOTID = slotID
        MysticMaestro_ListFrame_ITEMSET = false
        MM:StopAutoRoll()
    end
end) ]]

-- Creates all our frames the first time the enchanting collections window is opened
CreateListFrame = function()
    -- Ascension Enchant Collection Frame Name
local enchantCounts
local collectionOverlay = CreateFrame("FRAME", "MysticMaestro_Collection_Overlay", _G["EnchantCollection"])
    collectionOverlay:SetSize(_G["EnchantCollection"]:GetWidth(), _G["EnchantCollection"]:GetHeight())
    collectionOverlay:SetPoint("CENTER", _G["EnchantCollection"])

--[[     collectionOverlay.ListFrameText = collectionOverlay:CreateFontString()
    collectionOverlay.ListFrameText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    collectionOverlay.ListFrameText:SetFontObject(GameFontNormal)
    collectionOverlay.ListFrameText:SetText("Mystic Extended")
    collectionOverlay.ListFrameText:SetPoint("TOPRIGHT", -70, -11)
    collectionOverlay.ListFrameText:SetShadowOffset(1,-1)
 ]]
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
    listFrame.TitleText:SetText("Enchant Shoping List")
    listFrame.TitleText:SetPoint("TOP", 0, -9)
    listFrame.TitleText:SetShadowOffset(1,-1)
    listFrame.tex = listFrame:CreateTexture(nil, "ARTWORK")
    listFrame.tex:SetPoint("CENTER",0,-35)
    local tex = AtlasUtil:GetAtlasInfo("Enchant-Slot-Frame-Background")
    listFrame.tex:SetTexture(tex.filename)
    listFrame.tex:SetTexCoord(tex.leftTexCoord, tex.rightTexCoord, tex.topTexCoord, tex.bottomTexCoord)
    listFrame.tex:SetSize(345, listFrame:GetHeight()+10)
    listFrame:Hide()
    listFrame:SetScript("OnHide",
    function()
        if _G["EnchantCollection"]:IsVisible() then
            MM.db.ListFrameLastState = false
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

------------------------------------------------------------------
local enableCheck = AceGUI:Create("CheckBox")
    enableCheck.frame:SetParent(MysticMaestro_ListFrame)
    enableCheck:SetPoint("BOTTOMLEFT", MysticMaestro_ListFrame, 35, 60)
    enableCheck:SetHeight(25)
    enableCheck:SetWidth(80)
    enableCheck:SetLabel("Enable")
    enableCheck:SetValue(MM.shoppingLists[MM.shoppingLists.currentSelectedList].enable)
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

local extractCheck = AceGUI:Create("CheckBox")
    extractCheck.frame:SetParent(MysticMaestro_ListFrame)
    extractCheck:SetPoint("LEFT", enableCheck.frame, "RIGHT", 10, 0)
    extractCheck:SetHeight(25)
    extractCheck:SetWidth(80)
    extractCheck:SetLabel("Extract")
    extractCheck:SetValue(MM.shoppingLists[MM.shoppingLists.currentSelectedList].extract)
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

local reforgeCheck = AceGUI:Create("CheckBox")
    reforgeCheck.frame:SetParent(MysticMaestro_ListFrame)
    reforgeCheck:SetPoint("LEFT", extractCheck.frame, "RIGHT", 10, 0)
    reforgeCheck:SetHeight(25)
    reforgeCheck:SetWidth(80)
    reforgeCheck:SetLabel("Reforge")
    reforgeCheck:SetValue(MM.shoppingLists[MM.shoppingLists.currentSelectedList].reforge)
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
    sharebuttonlist:SetScript("OnClick", function(self)
        if MM.dewdrop:IsOpen() then
            MM.dewdrop:Close()
        else
            MM:ListFrameMenuRegister(self)
            MM.dewdrop:Open(self)
        end
    end)
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
    collectionOverlay.reforgebuttonlist.Text:SetPoint("CENTER", 0, 0)
    collectionOverlay.reforgebuttonlist:SetText("Auto Reforge")
    collectionOverlay.reforgebuttonlist:SetScript("OnClick", function(self, btnclick)
        -- if btnclick ~= "LeftButton" then return end
        MM:ReforgeButtonClick()
    end)
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
    local itemID = 1903513
    if MM:HasItem(itemID) then
        collectionOverlay.altarBtn = CreateFrame("Button", nil, collectionOverlay, "SecureActionButtonTemplate")
        collectionOverlay.altarBtn:SetSize(22, 22)
        collectionOverlay.altarBtn:SetPoint("RIGHT", collectionOverlay.reforgebuttonlist, "LEFT", -5, 0)
        collectionOverlay.altarBtn.icon = collectionOverlay.altarBtn:CreateTexture(nil, "ARTWORK")
        collectionOverlay.altarBtn.icon:SetSize(22, 22)
        collectionOverlay.altarBtn.icon:SetPoint("CENTER")
        local _, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
        collectionOverlay.altarBtn.icon:SetTexture(icon)
        collectionOverlay.altarBtn.Highlight = collectionOverlay.altarBtn:CreateTexture(nil, "OVERLAY")
        collectionOverlay.altarBtn.Highlight:SetSize(23,23)
        collectionOverlay.altarBtn.Highlight:SetPoint("CENTER")
        collectionOverlay.altarBtn.Highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected")
        collectionOverlay.altarBtn.Highlight:Hide()
        collectionOverlay.altarBtn:SetAttribute("type", "item")
        collectionOverlay.altarBtn:SetAttribute("item","Mystic Enchanting Altar")
        collectionOverlay.altarBtn:SetScript("OnEnter", function(self)
            collectionOverlay.altarBtn.Highlight:Show()
            local startTime, duration = GetItemCooldown(itemID)
            local cooldown = math.ceil(((duration - (GetTime() - startTime))/60))
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
  MM:ListFrameEnable()
end

-- Right Click context menu in the enchanting frame
function MM:ItemContextMenu(self)

    if MM.dewdrop:IsOpen(self) then MM.dewdrop:Close() return end
    MM.dewdrop:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                MM.dewdrop:AddLine(
                    'text', "Shopping Lists",
                    'notCheckable', true,
                    'isTitle', true,
                    'textHeight', 13,
                    'textWidth', 13
                )
                MM.dewdrop:AddLine(
                    'text', "Add to current list",
                    'func', function() enchantButtonClick(self) end,
                    'textHeight', 12,
                    'textWidth', 12,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                MM:AddDividerLine(35)
                MM.dewdrop:AddLine(
                    'text', "Links",
                    'notCheckable', true,
                    'isTitle', true,
                    'textHeight', 13,
                    'textWidth', 13
                )
                MM.dewdrop:AddLine(
                    'text', ORANGE.."Open In AscensionDB",
                    'func', function() MM:OpenDBURL(self, "spell") end,
                    'textHeight', 12,
                    'textWidth', 12,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                MM.dewdrop:AddLine(
                        "text", GREEN.."Guild",
                        "func", function() MM:Chatlink(self,"GUILD", button) end,
                        'closeWhenClicked', true,
                        'textHeight', 12,
                        'textWidth', 12,
                        "notCheckable", true
                    )
                    MM.dewdrop:AddLine(
                        "text", LIGHTBLUE.."Party",
                        "func", function() MM:Chatlink(self,"PARTY", button) end,
                        'closeWhenClicked', true,
                        'textHeight', 12,
                        'textWidth', 12,
                        "notCheckable", true
                    )
                    MM.dewdrop:AddLine(
                        "text", ORANGE2.."Raid",
                        "func", function() MM:Chatlink(self,"RAID", button) end,
                        'closeWhenClicked', true,
                        'textHeight', 12,
                        'textWidth', 12,
                        "notCheckable", true
                    )
                    --MM:AddDividerLine(35)
            elseif level == 2 then
                if value == "OwnWishlists" then
                end
            end
            --Close button
            MM:CloseDewDrop(true,35)
        end,
        'dontHook', true
    )
    MM.dewdrop:Open(self)
end

