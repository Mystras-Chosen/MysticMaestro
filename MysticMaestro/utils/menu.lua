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