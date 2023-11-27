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

function MM:RollMenuRegister(self)
	local menuList = {
		[1] = {
			{altar = true},
			{text = "Enchant Collection", func = function() MM:ToggleEnchantCollection() end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = "Mystic Maestro Standalone", func = function() MM:HandleMenuSlashCommand() end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = "Options", func = function() MM:OpenConfig("General") end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = "Unlock Frame", func = MM.UnlockFrame, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{close = true, divider = 35}
		},
	}
	MM:OpenDewdropMenu(self, menuList)
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
local mainframe = CreateFrame("Button", "MysticMaestro_ReforgeFrame", UIParent, nil)
	mainframe:SetPoint("CENTER",0,0)
	mainframe:SetSize(70,70)
	mainframe:EnableMouse(true)
	mainframe:SetMovable(true)
	mainframe:RegisterForDrag("LeftButton")
	mainframe:RegisterForClicks("RightButtonDown")
	mainframe:SetScript("OnDragStart", function(self) mainframe:StartMoving() end)
	mainframe:SetScript("OnDragStop", function(self) mainframe:StopMovingOrSizing() end)
	mainframe:SetScript("OnClick", function(self, btnclick) if unlocked then MM:UnlockFrame() end end)
	mainframe:Hide()
	mainframe.icon = mainframe:CreateTexture(nil,"ARTWORK")
	mainframe.icon:SetSize(55,55)
	mainframe.icon:SetPoint("CENTER", mainframe,"CENTER",0,0)
	mainframe.icon:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\inv_blacksmithing_khazgoriananvil1")
	mainframe.Highlight = mainframe:CreateTexture(nil, "OVERLAY")
	mainframe.Highlight:SetSize(70,70)
	mainframe.Highlight:SetPoint("CENTER", mainframe,"CENTER", 0, 0)
	mainframe.Highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected")
	mainframe.Highlight:Hide()
	mainframe.Text = mainframe:CreateFontString()
	mainframe.Text:SetFont("Fonts\\FRIZQT__.TTF", 12)
	mainframe.Text:SetFontObject(GameFontNormal)
	mainframe.Text:SetText("|cffffffffStart\nReforge")
	mainframe.Text:SetPoint("CENTER", 0, 0)
	mainframe.Text:SetShadowOffset(1,-1)
	mainframe:SetScript("OnEnter", function(self)
		if unlocked then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("Left click to drag")
			GameTooltip:AddLine("Right click to lock frame")
			GameTooltip:Show()
		end
	end)
	mainframe:SetScript("OnLeave", function() GameTooltip:Hide() end)

function MM:ToggleEnchantCollection()
	if Collections:IsShown() then
		HideUIPanel(Collections)
	else
		Collections:GoToTab(Collections.Tabs.MysticEnchants)
	end
end

local reforgebutton = CreateFrame("Button", "MysticMaestro_ReforgeFrame_Menu", MysticMaestro_ReforgeFrame)
	reforgebutton:SetSize(55,55)
	reforgebutton:SetPoint("CENTER", mainframe, "CENTER", 0, 0)
	reforgebutton.AnimatedTex = reforgebutton:CreateTexture(nil, "OVERLAY")
	reforgebutton.AnimatedTex:SetSize(59,59)
	reforgebutton.AnimatedTex:SetPoint("CENTER", mainframe.icon, 0, 0)
	reforgebutton.AnimatedTex:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected")
	reforgebutton.AnimatedTex:SetAlpha(0)
	reforgebutton.AnimatedTex:Hide()
	reforgebutton.Highlight = reforgebutton:CreateTexture(nil, "OVERLAY")
	reforgebutton.Highlight:SetSize(59,59)
	reforgebutton.Highlight:SetPoint("CENTER", mainframe.icon, 0, 0)
	reforgebutton.Highlight:SetTexture("Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\Slot2Selected")
	reforgebutton.Highlight:Hide()
	reforgebutton:RegisterForClicks("LeftButtonDown", "RightButtonDown")
	reforgebutton:SetScript("OnClick", function(self, button) 
		if (button == "LeftButton") then
			MM:ReforgeToggle()
		elseif (button == "RightButton") then
			if IsAltKeyDown() then
				MM:ToggleEnchantCollection()
			else
				MM:RollMenuRegister(self)
			end
		end
	end)
	reforgebutton:SetScript("OnEnter", function(self)
		reforgebutton.Highlight:Show()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Left Click To Start Reforging")
		GameTooltip:AddLine("Right Click For Context Menu")
		GameTooltip:AddLine("Alt Right To Open Enchanting Frame")
		GameTooltip:Show()
	end)
	reforgebutton:SetScript("OnLeave", function()
		reforgebutton.Highlight:Hide()
		GameTooltip:Hide()
	end)
	reforgebutton:Hide()

	reforgebutton.AnimatedTex.AG = reforgebutton.AnimatedTex:CreateAnimationGroup()
	reforgebutton.AnimatedTex.AG.Alpha0 = reforgebutton.AnimatedTex.AG:CreateAnimation("Alpha")
	reforgebutton.AnimatedTex.AG.Alpha0:SetStartDelay(0)
	reforgebutton.AnimatedTex.AG.Alpha0:SetDuration(2)
	reforgebutton.AnimatedTex.AG.Alpha0:SetOrder(0)
	reforgebutton.AnimatedTex.AG.Alpha0:SetEndDelay(0)
	reforgebutton.AnimatedTex.AG.Alpha0:SetSmoothing("IN")
	reforgebutton.AnimatedTex.AG.Alpha0:SetChange(1)

	reforgebutton.AnimatedTex.AG.Alpha1 = reforgebutton.AnimatedTex.AG:CreateAnimation("Alpha")
	reforgebutton.AnimatedTex.AG.Alpha1:SetStartDelay(0)
	reforgebutton.AnimatedTex.AG.Alpha1:SetDuration(2)
	reforgebutton.AnimatedTex.AG.Alpha1:SetOrder(0)
	reforgebutton.AnimatedTex.AG.Alpha1:SetEndDelay(0)
	reforgebutton.AnimatedTex.AG.Alpha1:SetSmoothing("IN_OUT")
	reforgebutton.AnimatedTex.AG.Alpha1:SetChange(-1)

	reforgebutton.AnimatedTex.AG:SetScript("OnFinished", function()
		reforgebutton.AnimatedTex.AG:Play()
	end)

	reforgebutton.AnimatedTex.AG:Play()

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
	MysticMaestroCountDownText:SetText("You Have " .. GetItemCount(98462) .. " Runes Left")
	MysticMaestroNextLevelText:SetText("Next Altar Level in "..(MM.db.realm.ALTARLEVEL.rollsNeeded).." Enchants")
end

function MM:UpdateScreenReforgeText()
	if not MM.db.realm.ALTARLEVEL or not MM.db.realm.ALTARLEVEL.rollsNeeded then return end
	MysticMaestroCountDownText:SetText("You Have " .. GetItemCount(98462) .. " Runes Left")
	MysticMaestroNextLevelText:SetText("Next Altar Level in "..(MM.db.realm.ALTARLEVEL.rollsNeeded).." Enchants")
end

function MM:StandaloneReforgeShow()
	if MysticMaestro_ReforgeFrame:IsVisible() then
		MysticMaestro_ReforgeFrame:Hide()
		MysticMaestro_ReforgeFrame_Menu:Hide()
	else
		MysticMaestro_ReforgeFrame:Show()
		MysticMaestro_ReforgeFrame_Menu:Show()
	end
end

function MM:StandaloneCityReforgeToggle(button)
	if button == "city" then
		MM.sbSettings.Citys = not MM.sbSettings.Citys
		if MM.sbSettings.Citys then
			MM:RegisterEvent("ZONE_CHANGED");
			MM:RegisterEvent("ZONE_CHANGED_NEW_AREA");
		else
			MM:UnregisterEvent("ZONE_CHANGED");
			MM:UnregisterEvent("ZONE_CHANGED_NEW_AREA");
		end
	elseif button == "enable" then
		MM.sbSettings.Enable = not MM.sbSettings.Enable
	end

	--auto show/hide in city's
	if MM.sbSettings.Enable and MM.sbSettings.Citys and (citysList[GetMinimapZoneText()] or citysList[GetRealZoneText()])
	or MM.sbSettings.Enable and not MM.sbSettings.Citys then
		MysticMaestro_ReforgeFrame:Show()
		MysticMaestro_ReforgeFrame_Menu:Show()
	else
		MysticMaestro_ReforgeFrame:Hide()
		MysticMaestro_ReforgeFrame_Menu:Hide()
	end
end

function MM:StandaloneReforgeText(show)
	if show then
		MysticMaestro_ReforgeFrame_Menu.AnimatedTex:Show()
		MysticMaestro_ReforgeFrame.Text:SetText("|cffffffffAuto\nForging")
	else
		MysticMaestro_ReforgeFrame_Menu.AnimatedTex:Hide()
		MysticMaestro_ReforgeFrame.Text:SetText("|cffffffffStart\nReforge")
	end
end