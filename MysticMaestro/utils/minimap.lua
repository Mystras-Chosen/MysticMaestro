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
                    'func', MM.ReforgeButtonClick,
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
                    'text', "Show/Hide Floating Button",
                    'func', MM.StandaloneReforgeShow,
                    'notCheckable', true,
                    'closeWhenClicked', true
                )
                MM.dewdrop:AddLine(
                    'text', "Options",
                    'func', function() MM:OpenConfig("Reforge") end,
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