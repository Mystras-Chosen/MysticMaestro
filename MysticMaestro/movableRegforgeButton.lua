local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local icon = LibStub('LibDBIcon-1.0');
local addonName = ...
local minimap = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject(addonName, {
    type = 'data source',
    text = "MysticMaestro",
    icon = 'Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\inv_blacksmithing_khazgoriananvil1',
  })

local moveReforgeBtn

local realmName = GetRealmName();
--Set Savedvariables defaults
local reFound = false;


--[[ TableName = Name of the saved setting
CheckBox = Global name of the checkbox if it has one and first numbered table entry is the boolean
Text = Global name of where the text and first numbered table entry is the default text ]]
local function setupSettings(db)
    for _,v in ipairs(DefaultSettings) do
        if db[v.TableName] == nil then
            if #v > 1 then
                db[v.TableName] = {}
                for _, n in ipairs(v) do
                    tinsert(db[v.TableName], n)
                end
            else
                db[v.TableName] = v[1]
            end
        end

        if v.CheckBox then
            _G[v.CheckBox]:SetChecked(db[v.TableName])
        end
        if v.Text then
            _G[v.Text]:SetText(db[v.TableName])
        end
    end
end

MM.QualityList = {
    [1] = {"Uncommon",2},
    [2] = {"Rare",3},
    [3] = {"Epic",4},
    [4] = {"Legendary",5}
}

local citysList = {
    ["Stormwind City"] = true,
    ["Ironforge"] = true,
    ["Darnassus"] = true,
    ["Exodar"] = true,
    ["Orgrimmar"] = true,
    ["Silvermoon City"] = true,
    ["Thunder Bluff"] = true,
    ["Undercity"] = true,
    ["Shattrath City"] = true,
    ["Booty Bay"] = true,
    ["Everlook"] = true,
    ["Ratchet"] = true,
    ["Gadgetzan"] = true,
    ["Dalaran"] = true,
}

--Returns listTableNum, enchTableNum, enableDisenchantboolean, enableRollboolean, ignoreListboolean
function MM:SearchLists(enchantID, type)
    local compair = {
        ["Extract"] = { { "enableRoll", true }, { "enableDisenchant", true }, { "ignoreList", false } },
        ["ExtractOnly"] = { { "enableRollExt", true }, { "enableDisenchant", true }, { "ignoreList", false } },
        ["ExtractAny"] = { { "enableDisenchant", true }, { "ignoreList", false } },
        ["Keep"] = { { "enableRoll", true }, { "ignoreList", false } },
        ["Ignore"] = { { "enableRoll", true }, { "enableDisenchant", false }, { "ignoreList", true } }
    }
    --checks to see if we should keep or roll over this enchant
    local function getStates(table)
        for _, s in ipairs(compair[type]) do
            if not s[2] == table[realmName][s[1]] then
                return false
            end
        end
        return true
    end

    for _, v in ipairs(MM.EnchantSaveLists) do
        for _, b in ipairs(v) do
            if b[1] == enchantID and getStates(v) then
                return true
            end
        end
    end
end

--returns if the item needs to be reforged or not
local function rollCheck(bagID, slotID, extractoff)
    if MM.RollExtracts then return true end
    local enchantID = GetREInSlot(bagID, slotID)
    if not enchantID then return true end
    local extractCount = GetItemCount(98463)
        if (MM.db.UnknownAutoExtract and extractCount and (extractCount > MM.db.minExtractNum) and not IsReforgeEnchantmentKnown(enchantID) and MM:DoRarity(enchantID,2)) or
            MM:SearchLists(enchantID, "Extract") or
            (extractCount and (extractCount > 0) and MM:SearchLists(enchantID, "ExtractOnly")) then
            --extract if we have extracts keep if not
            if not extractoff and extractCount and (extractCount > 0) then
                MM:ExtractEnchant(bagID,slotID,enchantID)
                --updates scroll frame after removing an item from a list
                MysticExtended_ScrollFrameUpdate()
            end
            if MM.db.Debug then print("Extract") end
            return false
        elseif MM:SearchLists(enchantID, "Keep") then
            --keep enchants on these lists
            if MM.db.Debug then print("Keep") end
            return false
        elseif MM:SearchLists(enchantID, "Ignore") then
            --reforge items on these lists
            if MM.db.Debug then print("Ignore") end
            return true
        elseif mysticMastro and MM.db.mysticMastro and MysticMaestroData[realmName].RE_AH_STATISTICS[enchantID] and
            MysticMaestroData[realmName].RE_AH_STATISTICS[enchantID].current and
            MM.db.MinGold >= MysticMaestroData[realmName].RE_AH_STATISTICS[enchantID].current.Min then
            if MM.db.Debug then print("Gold") end
            return true
        elseif auctionator and MM.db.auctionator and AUCTIONATOR_MYSTIC_ENCHANT_PRICE_DATABASE[realmName][enchantID] and
        AUCTIONATOR_MYSTIC_ENCHANT_PRICE_DATABASE[realmName][enchantID].Current and
        MM.db.MinGold >= AUCTIONATOR_MYSTIC_ENCHANT_PRICE_DATABASE[realmName][enchantID].Current then
        if MM.db.Debug then print("Gold") end
        return true
        elseif not MM:DoRarity(enchantID,1) then
            --reforge the raritys that arnt selected
            if MM.db.Debug then print("Rarity") end
            return true
        end
end

--works out how many rolls on the current item type it will take to get the next altar level
local function GetRequiredRollsForLevel(level)
    if level == 0 then
        return 1
    end

    if level >= 250 and not C_Realm:IsRealmMask(Enum.RealmMask.Area52) then
        return 557250 + (level - 250) * 4097
    end

    return floor(354 * level + 7.5 * level * level)
end

function MM:ButtonEnable(button)
    if button == "Main" then
        if MM.db.ButtonEnable then
            MysticMaestro_ReforgeFrame:Hide();
            MysticMaestro_ReforgeFrame_Menu:Hide();
            MM.db.ButtonEnable = false
        else
            MysticMaestro_ReforgeFrame:Show();
            MysticMaestro_ReforgeFrame_Menu:Show();
            MM.db.ButtonEnable = true
        end
    else
        if MM.db.ShowInCity then
            MM:UnregisterEvent("ZONE_CHANGED");
            MM:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
            MM.db.ShowInCity = false
            if MM.db.ButtonEnable then
                MysticMaestro_ReforgeFrame:Show();
                MysticMaestro_ReforgeFrame_Menu:Show();
            else
                MysticMaestro_ReforgeFrame:Hide();
                MysticMaestro_ReforgeFrame_Menu:Hide();
            end
        else
            MM.db.ShowInCity = true
            if MM.db.ButtonEnable and (citysList[GetMinimapZoneText()] or citysList[GetRealZoneText()]) then
                MM:RegisterEvent("ZONE_CHANGED", MM.OnEvent);
                MM:RegisterEvent("ZONE_CHANGED_NEW_AREA", MM.OnEvent);
                MysticMaestro_ReforgeFrame:Show();
                MysticMaestro_ReforgeFrame_Menu:Show();
            elseif MM.db.ButtonEnable then
                MM:RegisterEvent("ZONE_CHANGED", MM.OnEvent);
                MM:RegisterEvent("ZONE_CHANGED_NEW_AREA", MM.OnEvent);
                MysticMaestro_ReforgeFrame:Hide();
                MysticMaestro_ReforgeFrame_Menu:Hide();
            end
        end
    end
end

local function realmCheck(table)
    if table[realmName] then return end
    table[realmName] = {["enableDisenchant"] = false, ["enableRoll"] = false, ["ignoreList"] = false};    
end

local function rollMenuLevel1(value,frame)
    if frame == "MysticMaestro_ReforgeFrame" then
        MM.dewdrop:AddLine(
            'text', "Unlock Frame",
            'func', MM.UnlockFrame,
            'notCheckable', true,
            'closeWhenClicked', true
        )
    end
    MM.dewdrop:AddLine(
        'text', "Close Menu",
        'textR', 0,
        'textG', 1,
        'textB', 1,
        'closeWhenClicked', true,
        'notCheckable', true
    )
end

local function rollMenuLevel2(value)
    if value == "extractUnknown" then
        MM.dewdrop:AddLine(
                'text', "Enable",
                'func', QualityEnable,
                'arg1', "UnknownAutoExtract",
                'checked', MM.db.UnknownAutoExtract
            )
        end
    MM.dewdrop:AddLine(
        'text', "Close Menu",
        'textR', 0,
        'textG', 1,
        'textB', 1,
        'closeWhenClicked', true,
        'notCheckable', true
    )
end

local function rollMenuLevel3(value)
    MM.dewdrop:AddLine(
        'text', "Close Menu",
        'textR', 0,
        'textG', 1,
        'textB', 1,
        'closeWhenClicked', true,
        'notCheckable', true
    )
end


function MM:RollMenuRegister(self)
	MM.dewdrop:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                rollMenuLevel1(value, "MysticMaestro_ReforgeFrame")
            elseif level == 2 then
                rollMenuLevel2(value)
            elseif level == 3 then
                rollMenuLevel3(value)
            end
		end,
		'dontHook', true
	)
end

moveReforgeBtn = function(self, arg1)
    if MM.dewdrop:IsOpen() then
        MM.dewdrop:Close();
    else
        if (arg1 == "LeftButton") then
            startAutoRoll();
        elseif (arg1 == "RightButton") then
            if IsAltKeyDown() then
                MysticEnchantingFrame:Display();
            else
                MM:RollMenuRegister(self);
                MM.dewdrop:Open(self);
            end
        end
    end
end

-- Used to show highlight as a frame mover
local unlocked = false
function MM:UnlockFrame()
    if unlocked then
        MysticMaestro_ReforgeFrame_Menu:Show()
        MysticMaestro_ReforgeFrame.Highlight:Hide()
        unlocked = false
        GameTooltip:Hide()
    else
        MysticMaestro_ReforgeFrame_Menu:Hide()
        MysticMaestro_ReforgeFrame.Highlight:Show()
        unlocked = true
    end
end

--Creates the main floating button
local mainframe = CreateFrame("Button", "MysticMaestro_ReforgeFrame", UIParent, nil);
    mainframe:SetPoint("CENTER",0,0);
    mainframe:SetSize(70,70);
    mainframe:EnableMouse(true);
    mainframe:SetMovable(true);
    mainframe:RegisterForDrag("LeftButton");
    mainframe:RegisterForClicks("RightButtonDown");
    mainframe:SetScript("OnDragStart", function(self) mainframe:StartMoving() end);
    mainframe:SetScript("OnDragStop", function(self) mainframe:StopMovingOrSizing() end);
    mainframe:SetScript("OnClick", function(self, btnclick) if unlocked then MM:UnlockFrame() end end);
    mainframe:Hide();
    mainframe.icon = mainframe:CreateTexture(nil,"ARTWORK");
    mainframe.icon:SetSize(55,55);
    mainframe.icon:SetPoint("CENTER", mainframe,"CENTER",0,0);
    mainframe.icon:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\inv_blacksmithing_khazgoriananvil1");
    mainframe.Highlight = mainframe:CreateTexture(nil, "OVERLAY");
    mainframe.Highlight:SetSize(70,70);
    mainframe.Highlight:SetPoint("CENTER", mainframe,"CENTER", 0, 0);
    mainframe.Highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected");
    mainframe.Highlight:Hide();
    mainframe.Text = mainframe:CreateFontString();
    mainframe.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
    mainframe.Text:SetFontObject(GameFontNormal)
    mainframe.Text:SetText("|cffffffffStart\nReforge");
    mainframe.Text:SetPoint("CENTER", 0, 0);
    mainframe.Text:SetShadowOffset(1,-1);
    mainframe:SetScript("OnEnter", function(self)
        if unlocked then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Left click to drag")
            GameTooltip:AddLine("Right click to lock frame")
            GameTooltip:Show()
        end
    end)
    mainframe:SetScript("OnLeave", function() GameTooltip:Hide() end)


local reforgebutton = CreateFrame("Button", "MysticMaestro_ReforgeFrame_Menu", MysticMaestro_ReforgeFrame);
    reforgebutton:SetSize(55,55);
    reforgebutton:SetPoint("CENTER", mainframe, "CENTER", 0, 0);
    reforgebutton.AnimatedTex = reforgebutton:CreateTexture(nil, "OVERLAY");
    reforgebutton.AnimatedTex:SetSize(59,59);
    reforgebutton.AnimatedTex:SetPoint("CENTER", mainframe.icon, 0, 0);
    reforgebutton.AnimatedTex:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected");
    reforgebutton.AnimatedTex:SetAlpha(0);
    reforgebutton.AnimatedTex:Hide();
    reforgebutton.Highlight = reforgebutton:CreateTexture(nil, "OVERLAY");
    reforgebutton.Highlight:SetSize(59,59);
    reforgebutton.Highlight:SetPoint("CENTER", mainframe.icon, 0, 0);
    reforgebutton.Highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected");
    reforgebutton.Highlight:Hide();
    reforgebutton:RegisterForClicks("LeftButtonDown", "RightButtonDown");
    reforgebutton:SetScript("OnClick", function(self, btnclick) moveReforgeBtn(self,btnclick) end);
    reforgebutton:SetScript("OnEnter", function(self)
        reforgebutton.Highlight:Show();
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Left Click To Start Reforging");
        GameTooltip:AddLine("Right Click For Context Menu");
        GameTooltip:AddLine("Alt Right To Open Enchanting Frame");
        GameTooltip:Show();
	end);
	reforgebutton:SetScript("OnLeave", function()
        reforgebutton.Highlight:Hide();
        GameTooltip:Hide();
    end);
    reforgebutton:Hide();
    
    reforgebutton.AnimatedTex.AG = reforgebutton.AnimatedTex:CreateAnimationGroup();
    reforgebutton.AnimatedTex.AG.Alpha0 = reforgebutton.AnimatedTex.AG:CreateAnimation("Alpha");
    reforgebutton.AnimatedTex.AG.Alpha0:SetStartDelay(0);
    reforgebutton.AnimatedTex.AG.Alpha0:SetDuration(2);
    reforgebutton.AnimatedTex.AG.Alpha0:SetOrder(0);
    reforgebutton.AnimatedTex.AG.Alpha0:SetEndDelay(0);
    reforgebutton.AnimatedTex.AG.Alpha0:SetSmoothing("IN");
    reforgebutton.AnimatedTex.AG.Alpha0:SetChange(1);
    
    reforgebutton.AnimatedTex.AG.Alpha1 = reforgebutton.AnimatedTex.AG:CreateAnimation("Alpha");
    reforgebutton.AnimatedTex.AG.Alpha1:SetStartDelay(0);
    reforgebutton.AnimatedTex.AG.Alpha1:SetDuration(2);
    reforgebutton.AnimatedTex.AG.Alpha1:SetOrder(0);
    reforgebutton.AnimatedTex.AG.Alpha1:SetEndDelay(0);
    reforgebutton.AnimatedTex.AG.Alpha1:SetSmoothing("IN_OUT");
    reforgebutton.AnimatedTex.AG.Alpha1:SetChange(-1);

    reforgebutton.AnimatedTex.AG:SetScript("OnFinished", function()
        reforgebutton.AnimatedTex.AG:Play();
    end)

    reforgebutton.AnimatedTex.AG:Play();

local countDownFrame = CreateFrame("Frame", "MysticExtendedCountDownFrame", UIParrnt, nil);
    countDownFrame:SetPoint("CENTER",0,200);
    countDownFrame:SetSize(400,50);
    countDownFrame:Hide();
    countDownFrame.cText = countDownFrame:CreateFontString("MysticExtendedCountDownText","OVERLAY","GameFontNormal");
    countDownFrame.cText:Show();
    countDownFrame.cText:SetPoint("CENTER",0,0);
    countDownFrame.nextlvlText = countDownFrame:CreateFontString("MysticExtendedNextLevelText","OVERLAY","GameFontNormal");
    countDownFrame.nextlvlText:Show();
    countDownFrame.nextlvlText:SetPoint("CENTER",0,-20);
    countDownFrame.rollingText = countDownFrame:CreateFontString("MysticExtendedRollingText","OVERLAY","GameFontNormal");
    countDownFrame.rollingText:Show();
    countDownFrame.rollingText:SetPoint("CENTER",0,20);
    countDownFrame.rollingText:SetText("Auto Reforging In Progress");

--[[
SlashCommand(msg):
msg - takes the argument for the /mysticextended command so that the appropriate action can be performed
If someone types /mysticextended, bring up the options box
]]
local function SlashCommand(msg)
    if msg == "options" then
        MM:OptionsToggle();
    elseif msg == "extract" then
        MM:ExtractToggle();
    elseif msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF90EE90<MysticExtended>");
        DEFAULT_CHAT_FRAME:AddMessage("options to open options");
        DEFAULT_CHAT_FRAME:AddMessage("extract to open extract interface");
    elseif msg == "debug" then
        MM:Debug()
    else
        if MysticMaestro_ReforgeFrame:IsVisible() then
            MysticMaestro_ReforgeFrame:Hide();
            MysticMaestro_ReforgeFrame_Menu:Hide();
        else
            MysticMaestro_ReforgeFrame:Show();
            MysticMaestro_ReforgeFrame_Menu:Show();
        end
    end
end

function MM:Debug()
    if MM.db.Debug then
        MM.db.Debug = false
        DEFAULT_CHAT_FRAME:AddMessage("Debug Is Now OFF");
    else
        MM.db.Debug = true
        DEFAULT_CHAT_FRAME:AddMessage("Debug Is Now ON");
    end
end

-- All credit for this func goes to Tekkub and his picoGuild!
local function GetTipAnchor(frame)
    local x, y = frame:GetCenter()
    if not x or not y then return 'TOPLEFT', 'BOTTOMLEFT' end
    local hhalf = (x > UIParent:GetWidth() * 2 / 3) and 'RIGHT' or (x < UIParent:GetWidth() / 3) and 'LEFT' or ''
    local vhalf = (y > UIParent:GetHeight() / 2) and 'TOP' or 'BOTTOM'
    return vhalf .. hhalf, frame, (vhalf == 'TOP' and 'BOTTOM' or 'TOP') .. hhalf
end

function minimap.OnClick(self, button)
    GameTooltip:Hide()
    if button == "RightButton" then
        if MM.dewdrop:IsOpen() then
            MM.dewdrop:Close();
        else
            MM:MiniMapMenuRegister(self);
            MM.dewdrop:Open(this);
        end
    elseif not MysticExtendedExtractFrame:IsVisible() and button == 'LeftButton' then
        MysticExtendedExtractFrame:Show();
    else
        MysticExtendedExtractFrame:Hide();
    end
end

function minimap.OnLeave()
    GameTooltip:Hide()
end

function minimap.OnEnter(self)
    GameTooltip:SetOwner(self, 'ANCHOR_NONE')
    GameTooltip:SetPoint(GetTipAnchor(self))
    GameTooltip:ClearLines()
    GameTooltip:AddLine('MysticExtended')
    GameTooltip:Show()
end

function MM:ToggleMinimap()
    local hide = not MM.db.minimap.hide
    MM.db.minimap.hide = hide
    if hide then
      icon:Hide('MysticExtended')
    else
      icon:Show('MysticExtended')
    end
end

local function toggleFloatingbutton()
    if MysticMaestro_ReforgeFrame:IsVisible() then
        MysticMaestro_ReforgeFrame:Hide();
        MysticMaestro_ReforgeFrame_Menu:Hide();
    else
        MysticMaestro_ReforgeFrame:Show();
        MysticMaestro_ReforgeFrame_Menu:Show();
    end
end

function MM:MiniMapMenuRegister(self)
	MM.dewdrop:Register(self,
        'point', function(parent)
            return "TOP", "BOTTOM"
        end,
        'children', function(level, value)
            if level == 1 then
                local text = "Start Reforge"
                if MM.AutoRolling then
                    text = "Reforging"
                end
                MM.dewdrop:AddLine(
                    'text', text,
                    'func', startAutoRoll,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                local itemID = 1903513
                if MM:HasItem(itemID) then
                    local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
                    local startTime, duration = GetItemCooldown(itemID)
                    local cooldown = math.ceil(((duration - (GetTime() - startTime))/60))
                    local text = name
                    if cooldown > 0 then
                      text = name.." |cFF00FFFF("..cooldown.." ".. "mins" .. ")"
                    end
                    local secure = {
                      type1 = 'item',
                      item = name
                    }
                    MM.dewdrop:AddLine(
                      'text', text,
                      'secure', secure,
                      'icon', icon,
                      'closeWhenClicked', true
                    )
                end
                MM.dewdrop:AddLine(
                    'text', "Roll Options",
                    'hasArrow', true,
                    'value', "Roll Options",
                    'notCheckable', true
                )
                MM.dewdrop:AddLine(
                    'text', "Show/Hide Floating Button",
                    'func', toggleFloatingbutton,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                MM.dewdrop:AddLine(
                    'text', "Options",
                    'func', MM.OptionsToggle,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                MM.dewdrop:AddLine(
					'text', "Close Menu",
                    'textR', 0,
                    'textG', 1,
                    'textB', 1,
					'closeWhenClicked', true,
					'notCheckable', true
				)
            elseif level == 2 then
                if value == "Roll Options" then
                    rollMenuLevel1(value)
                end
            elseif level == 3 then
                rollMenuLevel2(value)
            elseif level == 4 then
                rollMenuLevel3(value)
            end
		end,
		'dontHook', true
	)
end




