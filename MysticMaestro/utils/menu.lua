local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local EdgelessFrameBackdrop = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  tile = true,
  tileSize = 32,
  edgeSize = 32,
  insets = {left = 0, right = 0, top = 0, bottom = 0}
}

function MM:CreateContainer(parent, anchorPoint, width, height, xOffset, yOffset)
  local container = CreateFrame("Frame", nil, parent)
  container:SetResizable(false)
  container:SetBackdrop(EdgelessFrameBackdrop)
  container:SetBackdropColor(0, 0, 0, 1)
  container:SetToplevel(true)
  container:SetPoint(anchorPoint, parent, anchorPoint, xOffset or 0, yOffset or 0)
  container:SetSize(width, height)
  return container
end

local containerPool = {}

function MM:CreateMenuContainer(parent, anchorPoint, width, height, xOffset, yOffset)
  local container = self:CreateContainer(parent, anchorPoint, width, height, xOffset, yOffset)
  container.LockFrame = CreateFrame("Frame", parent:GetName().."LockFrame", container)
  container.LockFrame:SetAllPoints()
  container.LockFrame:SetToplevel(true)
  container.LockFrame:EnableMouse(true)
  container.LockFrame:EnableMouseWheel(true)
  container.LockFrame:SetScript("OnMouseWheel", function() end) -- needed to prevent mousewheel from passing through
  container.LockFrame:Hide()
  table.insert(containerPool, container)
  return container
end

function MM:SetMenuContainersLocked(locked)
  for _, container in ipairs(containerPool) do
    if locked then
      container.LockFrame:Show()
    else
      container.LockFrame:Hide()
    end
  end
end

MM.FrameBackdrop = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true,
  tileSize = 32,
  edgeSize = 32,
  insets = {left = 8, right = 8, top = 8, bottom = 8}
}

-- function from WeakAuras Options for pretty border
function MM:CreateDecoration(frame, width)
  local deco = CreateFrame("Frame", nil, frame)
  deco:SetSize(width, 40)

  local bg1 = deco:CreateTexture(nil, "MEDIUM")
  bg1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  bg1:SetTexCoord(0.31, 0.67, 0, 0.63)
  bg1:SetAllPoints(deco)

  local bg2 = deco:CreateTexture(nil, "MEDIUM")
  bg2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  bg2:SetTexCoord(0.235, 0.275, 0, 0.63)
  bg2:SetPoint("RIGHT", bg1, "LEFT", 1, 0)
  bg2:SetSize(10, 40)

  local bg3 = deco:CreateTexture(nil, "MEDIUM")
  bg3:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
  bg3:SetTexCoord(0.72, 0.76, 0, 0.63)
  bg3:SetPoint("LEFT", bg1, "RIGHT", -1, 0)
  bg3:SetSize(10, 40)

  return deco
end