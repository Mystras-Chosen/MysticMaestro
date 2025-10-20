local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local icon = LibStub('LibDBIcon-1.0')
local addonName = ...

MYSTICMAESTRO_MINIMAP = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject(addonName, {
	type = 'data source',
	text = "MysticMaestro",
	icon = 'Interface\\AddOns\\AwAddons\\Textures\\EnchOverhaul\\inv_blacksmithing_khazgoriananvil1',
  })

local minimap = MYSTICMAESTRO_MINIMAP

function minimap.OnClick(self, button)
	GameTooltip:Hide()
	if button == "RightButton" then
		if MM.dewdrop:IsOpen() then
			MM.dewdrop:Close()
		else
			MM:MiniMapMenuRegister(self)
			MM.dewdrop:Open(this)
		end
	elseif button == 'LeftButton' then

	end
end

function minimap.OnLeave()
	GameTooltip:Hide()
end

-- handle minimap tooltip
local function GetTipAnchor(frame)
	local x, y = frame:GetCenter()
	if not x or not y then return 'TOPLEFT', 'BOTTOMLEFT' end
	local hhalf = (x > UIParent:GetWidth() * 2 / 3) and 'RIGHT' or (x < UIParent:GetWidth() / 3) and 'LEFT' or ''
	local vhalf = (y > UIParent:GetHeight() / 2) and 'TOP' or 'BOTTOM'
	return vhalf .. hhalf, frame, (vhalf == 'TOP' and 'BOTTOM' or 'TOP') .. hhalf
end

function minimap.OnEnter(self)
	GameTooltip:SetOwner(self, 'ANCHOR_NONE')
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()
	GameTooltip:AddLine("MysticMaestro")
	GameTooltip:Show()
end

function MM:MiniMapMenuRegister(button)
	local text = self.db.realm.OPTIONS.purchaseScrolls and "Auto Buy Scrolls |cFF32CD32(On)" or "Auto Buy Scrolls |cffff0000(Off)"
	local menuList = {
		[1] = {
			{text = self.rollState, func = self.ReforgeToggle, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{altar = true},
			{text = "Enchant Collection", func = function() self:ToggleEnchantCollection() end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = "Show/Hide Floating Button", func = self.ToggleStandaloneButton, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = "Options", func = function() self:OpenConfig("General") end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = "Unlock Frame", func = self.UnlockFrame, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{text = text, func = function() self.db.realm.OPTIONS.purchaseScrolls = not self.db.realm.OPTIONS.purchaseScrolls end, notCheckable = true, closeWhenClicked = true, textHeight = 12, textWidth = 12},
			{close = true, divider = 35}
		},
	}
	self:OpenDewdropMenu(button, menuList)
end

function MM:MinimapIconSetup()
	if not MM.db.realm.OPTIONS.minimap then
		MM.db.realm.OPTIONS.minimap = {hide = false}
	end

	if icon then
		icon:Register('MysticMaestro', minimap, MM.db.realm.OPTIONS.minimap)
	end
end

-- show/hide minimap icon
function MM:ToggleMinimap()
	local hide = not MM.db.realm.OPTIONS.minimap.hide
	MM.db.realm.OPTIONS.minimap.hide = hide
	if hide then
	  icon:Hide("MysticMaestro")
	else
	  icon:Show("MysticMaestro")
	end
end