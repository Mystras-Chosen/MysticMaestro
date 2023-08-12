local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
-- Localized functions
local CreateListFrame, setCurrentSelectedList, createScrollFrame, scrollSliderCreate, collectionSetup
-- Ascension Enchant Collection Frame Name
local C_Frame = "EnchantCollection"
-- Colours stored for code readability
local WHITE = "|cffFFFFFF";
local GREEN = "|cff1eff00";
local BLUE = "|cff0070dd";
local ORANGE = "|cffFF8400";
local GOLD  = "|cffffcc00";
local LIGHTBLUE = "|cFFADD8E6";
local ORANGE2 = "|cFFFFA500";

local realmName = GetRealmName();
local showtable = {};

setCurrentSelectedList = function()
    local thisID = this:GetID();
    MM.db.currentSelectedList = thisID;
    UIDropDownMenu_SetSelectedID(MysticMaestro_ListFrame_ListDropDown,thisID);
    MysticMaestro_ListFrame_ScrollFrameUpdate();
end

function MM:MenuInitialize()
        local info;
        for k,v in ipairs(MM.EnchantSaveLists) do
                    info = {
                        text = v.Name;
                        func = function() setCurrentSelectedList() end;
                    };
                    UIDropDownMenu_AddButton(info);
        end
end

function MysticMaestro_ListFrame_ListEnable()
    UIDropDownMenu_Initialize(MysticMaestro_ListFrame_ListDropDown, MM.MenuInitialize);
	UIDropDownMenu_SetSelectedID(MysticMaestro_ListFrame_ListDropDown,MM.db.currentSelectedList);
    MysticMaestro_ListFrame_ScrollFrameUpdate();
end

StaticPopupDialogs["MysticMaestro_ListFrame_ADDLIST"] = {
    text = "Add New List?",
    button1 = "Confirm",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function (self, data, data2)
        local text = self.editBox:GetText()
        MM.EnchantSaveLists[#MM.EnchantSaveLists + 1] = {["Name"] = text, [realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false}; }
        UIDropDownMenu_Initialize(MysticMaestro_ListFrame_ListDropDown, MM.MenuInitialize);
        UIDropDownMenu_SetSelectedID(MysticMaestro_ListFrame_ListDropDown,#MM.EnchantSaveLists);
        MM.db.currentSelectedList = #MM.EnchantSaveLists;
    MysticMaestro_ListFrame_ScrollFrameUpdate();
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
		self.editBox:SetText(MM.EnchantSaveLists[MM.db.currentSelectedList].Name)
		self:SetFrameStrata("TOOLTIP");
	end,
    OnAccept = function (self, data, data2)
        local text = self.editBox:GetText()
        if text ~= "" then
            MM.EnchantSaveLists[MM.db.currentSelectedList].Name = text;
            UIDropDownMenu_Initialize(MysticMaestro_ListFrame_ListDropDown, MM.MenuInitialize);
            UIDropDownMenu_SetText(MysticMaestro_ListFrame_ListDropDown, text)
            MysticMaestro_ListFrame_ScrollFrameUpdate();
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
        tremove(MM.EnchantSaveLists, MM.db.currentSelectedList);
        UIDropDownMenu_Initialize(MysticMaestro_ListFrame_ListDropDown, MM.MenuInitialize);
        UIDropDownMenu_SetSelectedID(MysticMaestro_ListFrame_ListDropDown,1);
        MM.db.currentSelectedList = 1;
        MysticMaestro_ListFrame_ScrollFrameUpdate();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    enterClicksFirstButton = true,
}

local function exportString()
    MM.dewdrop:Close();
    local data = {};
    for i,v in ipairs(MM.EnchantSaveLists[MM.db.currentSelectedList]) do
        tinsert(data,{v[1]});
    end
    data["Name"] = MM.EnchantSaveLists[MM.db.currentSelectedList]["Name"];
    Internal_CopyToClipboard("MMXT:"..MM:Serialize(data));
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
                    'func', function() StaticPopup_Show("MysticMaestro_ListFrame_SEND_ENCHANTLIST",MM.EnchantSaveLists[MM.db.currentSelectedList].Name) end,
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
local function GetSavedEnchant(id)
    for i, enchant in ipairs(MM.EnchantSaveLists[MM.db.currentSelectedList]) do
        if enchant[1] == id then
            return i
        end
    end
end

local ROW_HEIGHT = 16;   -- How tall is each row?
local MAX_ROWS = 23;      -- How many rows can be shown at once?
local scrollFrame
createScrollFrame = function()
scrollFrame = CreateFrame("Frame", "MysticMaestro_ListFrame_ScrollFrame", MysticMaestro_ListFrame);
    scrollFrame:EnableMouse(true);
    scrollFrame:SetSize(265, ROW_HEIGHT * MAX_ROWS + 16);
    scrollFrame:SetPoint("LEFT",20,-8);
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    });
end

 
function MysticMaestro_ListFrame_ScrollFrameUpdate()
    if MM.EnchantSaveLists[MM.db.currentSelectedList] then
        showtable = {Name = MM.EnchantSaveLists[MM.db.currentSelectedList].Name, MenuID = MM.EnchantSaveLists[MM.db.currentSelectedList].MenuID};
        for _,v in ipairs(MM.EnchantSaveLists[MM.db.currentSelectedList]) do
            if MYSTIC_ENCHANTS[v[1]] then
                tinsert(showtable,v)
            end
        end

        local maxValue = #showtable
        FauxScrollFrame_Update(scrollFrame.scrollBar, maxValue, MAX_ROWS, ROW_HEIGHT);
        local offset = FauxScrollFrame_GetOffset(scrollFrame.scrollBar);
        for i = 1, MAX_ROWS do
            local value = i + offset
            scrollFrame.rows[i]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD");
            if value <= maxValue and showtable[value] and MYSTIC_ENCHANTS[showtable[value][1]] then
                local row = scrollFrame.rows[i]
                local qualityColor = select(4,GetItemQualityColor(MYSTIC_ENCHANTS[showtable[value][1]].quality))
                row:SetText(qualityColor..GetSpellInfo(MYSTIC_ENCHANTS[showtable[value][1]].spellID))
                row.enchantID = showtable[value][1]
                row.link = MM:CreateItemLink(showtable[value][1])
                row:Show()
            else
                scrollFrame.rows[i]:Hide()
            end
        end
    end
end

scrollSliderCreate = function()
local scrollSlider = CreateFrame("ScrollFrame","MysticMaestro_ListFrameScroll",MysticMaestro_ListFrame_ScrollFrame,"FauxScrollFrameTemplate");
scrollSlider:SetPoint("TOPLEFT", 0, -8)
scrollSlider:SetPoint("BOTTOMRIGHT", -30, 8)
scrollSlider:SetScript("OnVerticalScroll", function(self, offset)
    self.offset = math.floor(offset / ROW_HEIGHT + 0.5)
    MysticMaestro_ListFrame_ScrollFrameUpdate();
end)

scrollSlider:SetScript("OnShow", function()
    MysticMaestro_ListFrame_ScrollFrameUpdate();
end)

scrollFrame.scrollBar = scrollSlider

local rows = setmetatable({}, { __index = function(t, i)
	local row = CreateFrame("Button", "$parentRow"..i, scrollFrame)
	row:SetSize(150, ROW_HEIGHT)
	row:SetNormalFontObject(GameFontHighlightLeft)
    row:RegisterForClicks("LeftButtonDown","RightButtonDown")
    row:SetScript("OnClick", function(self,button)
        local item = tonumber(row.enchantID)
        local itemNum = GetSavedEnchant(item)
        if button == "RightButton" then
            if MM.EnchantSaveLists[MM.db.currentSelectedList][itemNum] then
                tremove(MM.EnchantSaveLists[MM.db.currentSelectedList],itemNum)
            end
            MysticMaestro_ListFrame_ScrollFrameUpdate()    
        elseif button == "LeftButton" then
            if IsShiftKeyDown() then
                ChatEdit_InsertLink(MM:CreateItemLink(row.enchantID))
            else
                Internal_CopyToClipboard(GetSpellInfo(MYSTIC_ENCHANTS[row.enchantID].spellID))
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
function MM:CreateItemLink(id)
    local qualityColor = select(4,GetItemQualityColor(MYSTIC_ENCHANTS[id].quality))
    local link = qualityColor.."|Hspell:"..MYSTIC_ENCHANTS[id].spellID.."|h["..GetSpellInfo(MYSTIC_ENCHANTS[id].spellID).."]|h|r"
    return link
end

local function enchantButtonClick(self)
    local id = self.Enchant
    if not GetSavedEnchant(id) then
        tinsert(MM.EnchantSaveLists[MM.db.currentSelectedList],{id})
        MysticMaestro_ListFrame_ScrollFrameUpdate();
    else
        local itemLink = MM:CreateItemLink(id)
        DEFAULT_CHAT_FRAMM:AddMessage(itemLink .. " Is already on this list.")
    end
end

--Moves Ascensions xp/search/sortmenu




local altarBtnBuilt = false
function MM:CreateAlterButton()
    if MM.db.UnlockEnchantWindow then AT_MYSTIC_ENCHANT_ALTAR = true end
    if MM.db.ListFrameLastState then
        MysticMaestro_ListFrame:Show();
        showFrameBttn:SetText("Hide");
    else
        MysticMaestro_ListFrame:Hide();
        showFrameBttn:SetText("Show");
    end
    local itemID = 1903513
    if not altarBtnBuilt and MM:HasItem(itemID) then
        local altarBtn = CreateFrame("Button", "MysticMaestro_ListFrame_AltarButton", _G[C_Frame], "SecureActionButtonTemplate")
        altarBtn:SetSize(18, 18)
        altarBtn:SetPoint("RIGHT", _G[C_Frame].ControlFrame.ExtractButton, 20, 0)
        altarBtn.icon = altarBtn:CreateTexture(nil, "ARTWORK")
        altarBtn.icon:SetSize(18, 18)
        altarBtn.icon:SetPoint("CENTER", altarBtn, "CENTER", 0, 0)
        local _, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
        altarBtn.icon:SetTexture(icon);
        altarBtn.Highlight = altarBtn:CreateTexture(nil, "OVERLAY");
        altarBtn.Highlight:SetSize(19,19);
        altarBtn.Highlight:SetPoint("CENTER", altarBtn,"CENTER", 0, 0);
        altarBtn.Highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected");
        altarBtn.Highlight:Hide();
        altarBtn:SetAttribute("type", "item");
        altarBtn:SetAttribute("item","Mystic Enchanting Altar");
        altarBtn:SetScript("OnEnter", function(self)
            altarBtn.Highlight:Show();
            local startTime, duration = GetItemCooldown(itemID)
            local cooldown = math.ceil(((duration - (GetTime() - startTime))/60))
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetHyperlink(itemLink)
            if cooldown > 0 then
                GameTooltip:AddLine("Cooldown: |cFF00FFFF("..cooldown.." ".. "mins" .. ")")
              end
            GameTooltip:Show()
        end)
        altarBtn:SetScript("OnLeave", function() GameTooltip:Hide() altarBtn.Highlight:Hide() end)
        altarBtnBuilt = true
    end
end

collectionSetup = function()
    for i = 1, 15 do
        local button = _G["EnchantCollection"]["Collection"]["CollectionTab"]["buttonIDToButton"][i]
            button:HookScript("OnMouseDown", function(self, arg1)
                if arg1 == "RightButton" then
                    MM:ItemContextMenu(self.enchantInfo.SpellID, self.enchantInfo.ItemID, self)
                end
            end)
    end
    --Show list view when Mystic Enchanting frame opens
    _G[C_Frame]:HookScript("OnShow", function()

        -- MM:CreateAlterButton()
    end)

    --Hide it when it closes
    _G[C_Frame]:HookScript("OnHide", function()

    end)
    CreateListFrame()
    return true
end


local collectionFrameSetup
CollectionsPoolFrameCollectionTabTemplate4:HookScript("OnClick", function()
    if not collectionFrameSetup then
        collectionFrameSetup = collectionSetup()
    end
end)

hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self)
    if MysticMaestro_ListFrame:IsVisible() and IsAltKeyDown() then
        local bagID, slotID = self:GetParent():GetID(), self:GetID();
        local enchant = GetREInSlot(bagID, slotID)
            if enchant and not GetSavedEnchant(enchant) then
                tinsert(MM.EnchantSaveLists[MM.db.currentSelectedList],{enchant})
                MysticMaestro_ListFrame_ScrollFrameUpdate();
            else
                local itemLink = MM:CreateItemLink(enchant)
                DEFAULT_CHAT_FRAMM:AddMessage(itemLink .. " Is already on this list.")
            end
    end
end)

hooksecurefunc("ContainerFrameItemButton_OnClick", function(self, button)
    if _G[C_Frame]:IsVisible() then
        local bagID, slotID = self:GetParent():GetID(), self:GetID();
        MysticMaestro_ListFrame_BAGID = bagID
        MysticMaestro_ListFrame_SLOTID = slotID
        MysticMaestro_ListFrame_ITEMSET = false
        MM:StopAutoRoll()
    end
end)

-- Creates all our frames the first time the enchanting collections window is opened
CreateListFrame = function()

local collectionOverlay = CreateFrame("FRAME", "MysticMaestro_Collection_Overlay", _G[C_Frame])
    collectionOverlay:SetSize(_G[C_Frame]:GetWidth(), _G[C_Frame]:GetHeight())
    collectionOverlay:SetPoint("CENTER")
    collectionOverlay:Show()

--[[     collectionOverlay.ListFrameText = collectionOverlay:CreateFontString();
    collectionOverlay.ListFrameText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    collectionOverlay.ListFrameText:SetFontObject(GameFontNormal)
    collectionOverlay.ListFrameText:SetText("Mystic Extended");
    collectionOverlay.ListFrameText:SetPoint("TOPRIGHT", -70, -11);
    collectionOverlay.ListFrameText:SetShadowOffset(1,-1);
 ]]
    collectionOverlay.ListFrameKnownCount = CreateFrame("Button", nil, collectionOverlay)
    collectionOverlay.ListFrameKnownCount:SetPoint("TOPLEFT", 0, 0)
    collectionOverlay.ListFrameKnownCount:SetSize(190,20)
    collectionOverlay.ListFrameKnownCount.Lable = collectionOverlay.ListFrameKnownCount:CreateFontString(nil , "BORDER", "GameFontNormal")
    collectionOverlay.ListFrameKnownCount.Lable:SetJustifyH("LEFT")
    collectionOverlay.ListFrameKnownCount.Lable:SetPoint("LEFT", 0, 0);
    collectionOverlay.ListFrameKnownCount:SetScript("OnShow", function()
        MM:CalculateKnowEnchants()
        collectionOverlay.ListFrameKnownCount.Lable:SetText("Known Enchants: |cffffffff".. MM.db.KnownEnchantNumbers.Total.Known.."/"..MM.db.KnownEnchantNumbers.Total.Total)
    end)
    collectionOverlay.ListFrameKnownCount:SetScript("OnEnter", function(self) MM:EnchantCountTooltip(self) end)
    collectionOverlay.ListFrameKnownCount:SetScript("OnLeave", function() GameTooltip:Hide() end)

local listFrame = CreateFrame("FRAME", "MysticMaestro_ListFrame", collectionOverlay, "UIPanelDialogTemplate")
    listFrame:SetSize(350, collectionOverlay:GetHeight()+7);
    listFrame:SetPoint("LEFT", collectionOverlay,"RIGHT")
    listFrame.TitleText = listFrame:CreateFontString();
    listFrame.TitleText:SetFont("Fonts\\FRIZQT__.TTF", 12)
    listFrame.TitleText:SetFontObject(GameFontNormal)
    listFrame.TitleText:SetText("Enchant Shoping List");
    listFrame.TitleText:SetPoint("TOP", 0, -9);
    listFrame.TitleText:SetShadowOffset(1,-1);
    listFrame:Hide();
    listFrame:SetScript("OnHide",
    function()
        if _G[C_Frame]:IsVisible() then
            MM.db.ListFrameLastState = false;
            MysticMaestro_ListFrame_ShowButton:SetText("Show");
            _G[C_Frame].ListFrameText:Show();
        end
    end)
    listFrame.texture = listFrame:CreateTexture(nil, "BACKGROUND")
    local tex = AtlasUtil:GetAtlasInfo("_UI-Frame-TitleTileBg")
    listFrame.texture:SetTexture(tex.filename)
    listFrame.texture:SetTexCoord(tex.leftTexCoord, tex.rightTexCoord, tex.topTexCoord, tex.bottomTexCoord)
    listFrame.texture:SetSize(listFrame:GetWidth(), listFrame:GetHeight())
    listFrame.texture:SetPoint("CENTER")
    listFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    });

    local listDropdown = CreateFrame("Button", "MysticMaestro_ListFrame_ListDropDown", MysticMaestro_ListFrame, "UIDropDownMenuTemplate");
    listDropdown:SetPoint("TOPLEFT", 4, -40);
    listDropdown:SetScript("OnClick", MysticMaestro_ListFrame_ListOnClick);
    UIDropDownMenu_SetWidth(MysticMaestro_ListFrame_ListDropDown, 155)
    listDropdown.EnchantNumber = listDropdown:CreateFontString("MysticMaestro_ListFrameEnchantCount", "OVERLAY", "GameFontNormal");
    listDropdown.EnchantNumber:SetPoint("TOPLEFT", 26, -8);
    listDropdown.EnchantNumber:SetFont("Fonts\\FRIZQT__.TTF", 11)
    listDropdown:SetScript("OnUpdate", function()
            listDropdown.EnchantNumber:SetText("|cff00ff00"..#showtable);
        end)

local editlistnamebtn = CreateFrame("Button", "MysticMaestro_ListFrame_EditListBtn", MysticMaestro_ListFrame, "OptionsButtonTemplate");
    editlistnamebtn:SetPoint("TOPLEFT", 195, -41);
    editlistnamebtn:SetText("E")
    editlistnamebtn:SetSize(27, 27);
    editlistnamebtn:SetScript("OnClick", function() StaticPopup_Show("MysticMaestro_ListFrame_EDITLISTNAMM") end);
    editlistnamebtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Edit List Name")
		GameTooltip:Show()
	end)
	editlistnamebtn:SetScript("OnLeave", function() GameTooltip:Hide() end)


local addlistbtn = CreateFrame("Button", "MysticMaestro_ListFrame_AddListBtn", MysticMaestro_ListFrame, "OptionsButtonTemplate");
    addlistbtn:SetPoint("TOPLEFT", 225, -41);
    addlistbtn:SetText("+")
    addlistbtn:SetSize(27, 27);
    addlistbtn:SetScript("OnClick", function() StaticPopup_Show("MysticMaestro_ListFrame_ADDLIST") end);
    addlistbtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Create New List")
		GameTooltip:Show()
	end)
	addlistbtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local removelistbtn = CreateFrame("Button", "MysticMaestro_ListFrame_RemoveListBtn", MysticMaestro_ListFrame, "OptionsButtonTemplate");
    removelistbtn:SetPoint("TOPLEFT", 255, -41);
    removelistbtn:SetText("-")
    removelistbtn:SetSize(27, 27);
    removelistbtn:SetScript("OnClick", function() StaticPopup_Show("MysticMaestro_ListFrame_DELETELIST") end);
    removelistbtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("Remove List")
		GameTooltip:Show()
	end)
	removelistbtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

------------------------------------------------------------------


--Shows a menu with options and sharing options
local sharebuttonlist = CreateFrame("Button", "MysticMaestro_ListFrame_ListFrameMenuButton", MysticMaestro_ListFrame, "OptionsButtonTemplate");
    sharebuttonlist:SetSize(133,30);
    sharebuttonlist:SetPoint("BOTTOMRIGHT", MysticMaestro_ListFrame, "BOTTOMRIGHT", -20, 20);
    sharebuttonlist:SetText("Export/Share");
    sharebuttonlist:RegisterForClicks("LeftButtonDown");
    sharebuttonlist:SetScript("OnClick", function(self)
        if MM.dewdrop:IsOpen() then
            MM.dewdrop:Close();
        else
            MM:ListFrameMenuRegister(self);
            MM.dewdrop:Open(self);
        end
    end);
    collectionOverlay.sharebuttonlist = sharebuttonlist

-- opens the settings page
    listFrame.optionsbuttonlist = CreateFrame("Button", nil, MysticMaestro_ListFrame, "SettingsGearButtonTemplate");
    listFrame.optionsbuttonlist:SetSize(30,30);
    listFrame.optionsbuttonlist:SetPoint("BOTTOMLEFT", MysticMaestro_ListFrame, "BOTTOMLEFT", 20, 20);
    listFrame.optionsbuttonlist:SetText("Options");
    listFrame.optionsbuttonlist:RegisterForClicks("LeftButtonDown");
    listFrame.optionsbuttonlist:SetScript("OnClick", function() MM:OptionsToggle() end);

--Show/Hide button in main list view
    collectionOverlay.showFrameBttn  = CreateFrame("Button", nil, collectionOverlay, "FilterDropDownMenuTemplate");
    collectionOverlay.showFrameBttn :SetSize(80,26);
    collectionOverlay.showFrameBttn :SetPoint("BOTTOMRIGHT", MysticMaestro_Collection_Overlay, -5, 4)
    collectionOverlay.showFrameBttn :SetScript("OnClick", function()
        if listFrame:IsVisible() then
            listFrame:Hide();
            MM.db.char.ListFrameLastState = false;
            collectionOverlay.showFrameBttn:SetText("Show");
        else
            collectionOverlay.showFrameBttn:SetText("Hide");
            listFrame:Show();
            MM.db.char.ListFrameLastState = true;
        end
    end)
    if MM.db.char.ListFrameLastState then
        collectionOverlay.showFrameBttn:SetText("Show");
    else
        collectionOverlay.showFrameBttn:SetText("Hide");
    end
--Reforge button in list interface
    collectionOverlay.reforgebuttonlist = CreateFrame("Button", nil, collectionOverlay, "FilterDropDownMenuTemplate");
    collectionOverlay.reforgebuttonlist:SetSize(100,26);
    collectionOverlay.reforgebuttonlist:SetPoint("RIGHT", collectionOverlay.showFrameBttn, "LEFT", 0, 0);
    collectionOverlay.reforgebuttonlist:SetText("Start Reforge");
    collectionOverlay.reforgebuttonlist:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    collectionOverlay.reforgebuttonlist:SetScript("OnClick", function(self, btnclick) MysticMaestro_ListFrame_OnClick(self,btnclick) end);
    collectionOverlay.reforgebuttonlist:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Left Click To Start Reforging");
        GameTooltip:AddLine("Right Click To Show Roll Settings");
        GameTooltip:Show();
    end);
    collectionOverlay.reforgebuttonlist:SetScript("OnLeave", function() GameTooltip:Hide() end);

    createScrollFrame()
    scrollSliderCreate()
end

function MM:ItemContextMenu(spellID, itemID, self)
    if MM.dewdrop:IsOpen(self) then MM.dewdrop:Close() return end
    MM.dewdrop:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                MM.dewdrop:AddLine(
                    'text', "Links",
                    'notCheckable', true,
                    'isTitle', true,
                    'textHeight', 13,
                    'textWidth', 13
                )
                MM.dewdrop:AddLine(
                    'text', ORANGE.."Open In AscensionDB",
                    'func', function() MM:OpenDBURL(spellID ,"spell") end,
                    'textHeight', 12,
                    'textWidth', 12,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                MM.dewdrop:AddLine(
                        "text", GREEN.."Guild",
                        "func", function() MM:Chatlink(spellID,"GUILD","spell") end,
                        'closeWhenClicked', true,
                        'textHeight', 12,
                        'textWidth', 12,
                        "notCheckable", true
                    );
                    MM.dewdrop:AddLine(
                        "text", LIGHTBLUE.."Party",
                        "func", function() MM:Chatlink(spellID,"PARTY","spell") end,
                        'closeWhenClicked', true,
                        'textHeight', 12,
                        'textWidth', 12,
                        "notCheckable", true
                    );
                    MM.dewdrop:AddLine(
                        "text", ORANGE2.."Raid",
                        "func", function() MM:Chatlink(spellID,"RAID","spell") end,
                        'closeWhenClicked', true,
                        'textHeight', 12,
                        'textWidth', 12,
                        "notCheckable", true
                    );
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