local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local FrameBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 }
}

local EdgelessFrameBackdrop = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 }
}

local f
do
  f = CreateFrame("Frame", "MysticMaestroFrameContainer", UIParent)
  f:Hide()
  f:EnableMouse(true)
  f:SetMovable(true)
  f:SetResizable(false)
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:SetBackdrop(FrameBackdrop)
  f:SetBackdropColor(0, 0, 0, 1)
  f:SetToplevel(true)
  f:SetPoint("CENTER")
  f:SetSize(635, 455)
  f:SetClampedToScreen(true)

  local function CreateDecoration(frame, width)
    local deco = CreateFrame("Frame", nil, frame)
    deco:SetSize(width, 40)
  
    local bg1 = deco:CreateTexture(nil, "BACKGROUND")
    bg1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    bg1:SetTexCoord(0.31, 0.67, 0, 0.63)
    bg1:SetAllPoints(deco)
  
    local bg2 = deco:CreateTexture(nil, "BACKGROUND")
    bg2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    bg2:SetTexCoord(0.235, 0.275, 0, 0.63)
    bg2:SetPoint("RIGHT", bg1, "LEFT", 1, 0)
    bg2:SetSize(10, 40)
  
    local bg3 = deco:CreateTexture(nil, "BACKGROUND")
    bg3:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    bg3:SetTexCoord(0.72, 0.76, 0, 0.63)
    bg3:SetPoint("LEFT", bg1, "RIGHT", -1, 0)
    bg3:SetSize(10, 40)
  
    return deco
  end
  
  local title = CreateDecoration(f, 130)
  title:SetPoint("TOP", 0, 24)
  title:EnableMouse(true)
  title:SetScript("OnMouseDown", function(f) f:GetParent():StartMoving() end)
  title:SetScript("OnMouseUp", function(f) f:GetParent():StopMovingOrSizing() end)
  
  local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titletext:SetPoint("CENTER", title)
  titletext:SetText("Mystic Maestro")
  
  
  local close = CreateDecoration(f, 17)
  close:SetPoint("TOPRIGHT", -30, 12)
  
  local closebutton = CreateFrame("BUTTON", nil, close, "UIPanelCloseButton")
  closebutton:SetPoint("CENTER", close, "CENTER", 1, -1)
  closebutton:SetScript("OnClick", function() MM:CloseStandaloneMenu() end)
end

local mmf = CreateFrame("Frame", "MysticMaestroFrame", UIParent)
mmf:Hide()
mmf:SetSize(609, 420)
MM.MysticMaestroFrame = mmf

function MM:OpenStandaloneMenu()
  mmf:ClearAllPoints()
  mmf:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 13, 9)
  f:Show()
  mmf:Show()
end

function MM:CloseStandaloneMenu()
  f:Hide()
  mmf:Hide()
end


local function createContainer(parent, anchorPoint, width, height, xOffset, yOffset)
  local container = CreateFrame("Frame", nil, parent)
  container:SetResizable(false)
  container:SetFrameStrata("FULLSCREEN_DIALOG")
  container:SetBackdrop(EdgelessFrameBackdrop)
  container:SetBackdropColor(0, 0, 0, 1)
  container:SetToplevel(true)
  container:SetPoint(anchorPoint, parent, anchorPoint, xOffset or 0, yOffset or 0)
  container:SetSize(width, height)
  return container
end

local enchantContainer = createContainer(mmf, "BOTTOMLEFT", 200, 396)
local statsContainer = createContainer(mmf, "BOTTOMRIGHT", 412, 192)
local graphContainer = createContainer(mmf, "BOTTOMRIGHT", 412, 198, 0, 198)

-- created just to show the height of the invisible frame that holds everything
local dummyContainer = createContainer(mmf, "TOPRIGHT", 100, 32, 0, 0)