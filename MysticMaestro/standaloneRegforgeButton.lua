local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

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

function MM:RollMenuRegister(button)
	local text = self.db.realm.OPTIONS.purchaseScrolls and "Auto Buy Scrolls |cFF32CD32(On)" or "Auto Buy Scrolls |cffff0000(Off)"
	local menuList = {
		[1] = {
			{altar = true},
			{text = "Enchant Collection", func = function() self:ToggleEnchantCollection() end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = "Mystic Maestro Standalone", func = function() self:HandleMenuSlashCommand() end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = "Options", func = function() self:OpenConfig("Reforge") end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = "Unlock Frame", func = self.UnlockFrame, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = text, func = function() self.db.realm.OPTIONS.purchaseScrolls = not self.db.realm.OPTIONS.purchaseScrolls end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{close = true, divider = 35}
		},
	}
	self:OpenDewdropMenu(button, menuList)
end

function MM:CreateUI()
	if not MysticMaestroCharDB then MysticMaestroCharDB = {} end
	self.charDB = MysticMaestroCharDB
    self.reforgebutton = CreateFrame("Button", "MysticMaestro_ReforgeFrame", UIParent)
    self.reforgebutton:SetSize(70, 70)
    self.reforgebutton:EnableMouse(true)
    self.reforgebutton:SetScript("OnDragStart", function() self.reforgebutton:StartMoving() end)
    self.reforgebutton:SetScript("OnDragStop", function()
        self.reforgebutton:StopMovingOrSizing()
        self.charDB.menuPos = { self.reforgebutton:GetPoint() }
        self.charDB.menuPos[2] = "UIParent"
    end)
    self.reforgebutton:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    self.reforgebutton.icon = self.reforgebutton:CreateTexture(nil, "ARTWORK")
    self.reforgebutton.icon:SetSize(55, 55)
    self.reforgebutton.icon:SetPoint("CENTER", self.reforgebutton, "CENTER", 0, 0)
    self.reforgebutton.icon:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\inv_blacksmithing_khazgoriananvil1")
    self.reforgebutton.Text = self.reforgebutton:CreateFontString()
    self.reforgebutton.Text:SetFont("Fonts\\FRIZQT__.TTF", 13)
    self.reforgebutton.Text:SetFontObject(GameFontNormal)
    self.reforgebutton.Text:SetText("|cffffffffStart\nReforge")
    self.reforgebutton.Text:SetPoint("CENTER", self.reforgebutton.icon, "CENTER", 0, 0)
    self.reforgebutton.Highlight = self.reforgebutton:CreateTexture(nil, "OVERLAY")
    self.reforgebutton.Highlight:SetSize(70, 70)
    self.reforgebutton.Highlight:SetPoint("CENTER", self.reforgebutton, 0, 0)
    self.reforgebutton.Highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected")
    self.reforgebutton.Highlight:Hide()
	self.reforgebutton.AnimatedTex = self.reforgebutton:CreateTexture(nil, "OVERLAY")
	self.reforgebutton.AnimatedTex:SetSize(59,59)
	self.reforgebutton.AnimatedTex:SetPoint("CENTER", self.reforgebutton.icon, 0, 0)
	self.reforgebutton.AnimatedTex:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected")
	self.reforgebutton.AnimatedTex:SetAlpha(0)
	self.reforgebutton.AnimatedTex:Hide()
    self.reforgebutton:SetScale(self.sbSettings.buttonScale or 1)
    self.reforgebutton:SetScript("OnClick", function(button, btnclick)
        if btnclick == "RightButton" then
            if self.reforgebutton.unlocked then
                self:UnlockFrame()
			else
				if IsAltKeyDown() then
					self:ToggleEnchantCollection()
				else
					self:RollMenuRegister(button)
				end
            end
        elseif not self.reforgebutton.unlocked and (btnclick == "LeftButton") then
			self:ReforgeToggle()
        end
    end)
	self.reforgebutton.AnimatedTex.AG = self.reforgebutton.AnimatedTex:CreateAnimationGroup()
	self.reforgebutton.AnimatedTex.AG.Alpha0 = self.reforgebutton.AnimatedTex.AG:CreateAnimation("Alpha")
	self.reforgebutton.AnimatedTex.AG.Alpha0:SetStartDelay(0)
	self.reforgebutton.AnimatedTex.AG.Alpha0:SetDuration(2)
	self.reforgebutton.AnimatedTex.AG.Alpha0:SetOrder(0)
	self.reforgebutton.AnimatedTex.AG.Alpha0:SetEndDelay(0)
	self.reforgebutton.AnimatedTex.AG.Alpha0:SetSmoothing("IN")
	self.reforgebutton.AnimatedTex.AG.Alpha0:SetChange(1)

	self.reforgebutton.AnimatedTex.AG.Alpha1 = self.reforgebutton.AnimatedTex.AG:CreateAnimation("Alpha")
	self.reforgebutton.AnimatedTex.AG.Alpha1:SetStartDelay(0)
	self.reforgebutton.AnimatedTex.AG.Alpha1:SetDuration(2)
	self.reforgebutton.AnimatedTex.AG.Alpha1:SetOrder(0)
	self.reforgebutton.AnimatedTex.AG.Alpha1:SetEndDelay(0)
	self.reforgebutton.AnimatedTex.AG.Alpha1:SetSmoothing("IN_OUT")
	self.reforgebutton.AnimatedTex.AG.Alpha1:SetChange(-1)

	self.reforgebutton.AnimatedTex.AG:SetScript("OnFinished", function()
		self.reforgebutton.AnimatedTex.AG:Play()
	end)

	self.reforgebutton.AnimatedTex.AG:Play()
    self.reforgebutton:SetScript("OnEnter", function(button)
        if self.reforgebutton.unlocked then
            GameTooltip:SetOwner(button, "ANCHOR_TOP")
            GameTooltip:AddLine("Left click to drag")
            GameTooltip:AddLine("Right click to lock frame")
            GameTooltip:Show()
        else
            self.reforgebutton.Highlight:Show()
        end
        if self.sbSettings.EnableAutoHide and not UnitAffectingCombat("player") then
            self.reforgebutton:SetAlpha(10)
        end
    end)
    self.reforgebutton:SetScript("OnLeave", function()
        GameTooltip:Hide()
        if not self.reforgebutton.unlocked then
            self.reforgebutton.Highlight:Hide()
        end
        if self.sbSettings.EnableAutoHide and not self.reforgebutton.unlocked then
            self.reforgebutton:SetAlpha(0)
        end
    end)
    self:SetMenuPos()
    self:SetFrameAlpha()
    if self.sbSettings.Enable then
        self.reforgebutton:Show()
    else
        self.reforgebutton:Hide()
    end
	self:StandaloneCityReforgeToggle()
end

--------------- Frame functions for misc menu standalone button---------------

function MM:SetMenuPos()
    if self.charDB.menuPos then
        local pos = self.charDB.menuPos
        self.reforgebutton:ClearAllPoints()
        self.reforgebutton:SetPoint(pos[1], pos[2], pos[3], pos[4], pos[5])
    else
        self.reforgebutton:ClearAllPoints()
        self.reforgebutton:SetPoint("CENTER", UIParent)
    end
end

function MM:SetFrameAlpha()
    if self.sbSettings.EnableAutoHide then
        self.reforgebutton:SetAlpha(0)
    else
        self.reforgebutton:SetAlpha(10)
    end
end

-- Used to show highlight as a frame mover
function MM:UnlockFrame()
	self = MM
    if self.reforgebutton.unlocked then
        self.reforgebutton:SetMovable(false)
        self.reforgebutton:RegisterForDrag()
        self.reforgebutton.Highlight:Hide()
        if self.sbSettings.enableAutoHide then
            self.reforgebutton:SetAlpha(0)
        end
        self.reforgebutton.unlocked = false
        GameTooltip:Hide()
    else
        self.reforgebutton:SetMovable(true)
        self.reforgebutton:RegisterForDrag("LeftButton")
        self.reforgebutton.Highlight:Show()
        if self.sbSettings.enableAutoHide then
            self.reforgebutton:SetAlpha(10)
        end
        self.reforgebutton.unlocked = true
    end
end

-- toggle the main button frame
function MM:Togglereforgebutton()
	self = MM
    if self.reforgebutton:IsVisible() then
        self.reforgebutton:Hide()
    else
        self.reforgebutton:Show()
    end
end

function MM:ToggleEnchantCollection()
	if Collections:IsShown() then
		HideUIPanel(Collections)
	else
		Collections:GoToTab(Collections.Tabs.MysticEnchants)
	end
end

local countDownFrame = CreateFrame("Frame", "MysticMaestroCountDownFrame", UIParrnt, nil)
	countDownFrame:SetPoint("CENTER",0,200)
	countDownFrame:SetSize(400,50)
	countDownFrame:Hide()
	countDownFrame.cText = countDownFrame:CreateFontString("MysticMaestroCountDownText","OVERLAY","GameFontNormal")
	countDownFrame.cText:Show()
	countDownFrame.cText:SetPoint("CENTER",0,0)
	countDownFrame.nextlvlText = countDownFrame:CreateFontString("MysticMaestroNextLevelText","OVERLAY","GameFontNormal")
	countDownFrame.nextlvlText:Show()
	countDownFrame.nextlvlText:SetPoint("CENTER",0,-20)
	countDownFrame.rollingText = countDownFrame:CreateFontString("MysticMaestroRollingText","OVERLAY","GameFontNormal")
	countDownFrame.rollingText:Show()
	countDownFrame.rollingText:SetPoint("CENTER",0,20)
	countDownFrame.rollingText:SetText("Auto Reforging In Progress")

function MM:ToggleScreenReforgeText(show)
	if not MM.db.realm.ALTARLEVEL or not MM.db.realm.ALTARLEVEL.rollsNeeded then return end
	if show then
		--show rune count down
		MysticMaestroCountDownFrame:Show()
		MysticMaestroNextLevelText:Show()
	else
		MysticMaestroNextLevelText:Hide()
		MysticMaestroCountDownFrame:Hide()
	end
	MysticMaestroCountDownText:SetText("You Have " .. self:GetAscensionRunesCurrency() .. " Runes Left")
	MysticMaestroNextLevelText:SetText("Next Altar Level in "..(MM.db.realm.ALTARLEVEL.rollsNeeded).." Enchants")
end

function MM:UpdateScreenReforgeText()
	if not MM.db.realm.ALTARLEVEL or not MM.db.realm.ALTARLEVEL.rollsNeeded then return end
	MysticMaestroCountDownText:SetText("You Have " .. self:GetAscensionRunesCurrency() .. " Runes Left")
	MysticMaestroNextLevelText:SetText("Next Altar Level in "..(MM.db.realm.ALTARLEVEL.rollsNeeded).." Enchants")
end

function MM:StandaloneCityReforgeToggle(button)
	if button == "city" then
		self.sbSettings.Citys = not self.sbSettings.Citys
		if self.sbSettings.Citys then
			self:RegisterEvent("ZONE_CHANGED");
			self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
		else
			self:UnregisterEvent("ZONE_CHANGED");
			self:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
		end
	elseif button == "enable" then
		self.sbSettings.Enable = not self.sbSettings.Enable
	end

	--auto show/hide in city's
	if self.sbSettings.Enable and self.sbSettings.Citys and (citysList[GetMinimapZoneText()] or citysList[GetRealZoneText()])
	or self.sbSettings.Enable and not self.sbSettings.Citys then
		self.reforgebutton:SetAlpha(10)
	else
		self.reforgebutton:SetAlpha(0)
	end
end

function MM:StandaloneReforgeText(show)
	if show then
		self.reforgebutton.AnimatedTex:Show()
		self.reforgebutton.Text:SetText("|cffffffffAuto\nForging")
	else
		self.reforgebutton.AnimatedTex:Hide()
		self.reforgebutton.Text:SetText("|cffffffffStart\nReforge")
	end
end