local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local queryResults = {}
do -- Create RE search box widget "EditBoxMysticMaestroREPredictor"
  LibStub("AceGUI-3.0-Search-EditBox"):Register("MysticMaestroREPredictor", {

    GetValues = function(self, text, _, max)
      wipe(queryResults)
      text = text:lower()
      for enchantID, enchantData in pairs(MYSTIC_ENCHANTS) do
        if enchantID ~= 0 then
          local enchantName = GetSpellInfo(enchantData.spellID)
          if enchantName and enchantName:lower():find(text) then
            queryResults[enchantData.spellID] = enchantName
            max = max - 1
            if max == 0 then return queryResults end
          end
        end
      end
      return queryResults
    end,

    GetValue = function(self, text, key)
      if key then
        MM:ShowGraph(queryResults[key])
        return key, queryResults[key]
      else
        local key, enchantName = next(queryResults)
        if key then
          MM:ShowGraph(enchantName)
          return key, enchantName
        end
      end
    end,

    GetHyperlink = function(self, key)
      return "spell:" .. key
    end
  })

  -- IDK what this does, but it is required
  local myOptions = {
    type = "group",
    args = {
      editbox1 = {
        type = "input", 
        dialogControl = "EditBoxMysticMaestroREPredictor",
        name = "Type a spell name", 
        get = function ()   end,
        set = function (_, v)  print(v) end
      }
    }
  }

  LibStub("AceConfig-3.0"):RegisterOptionsTable("MysticMaestro", myOptions)
end

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

local standaloneMenu
do -- Create standalone menu to hold MysticMaestroFrame
  standaloneMenu = CreateFrame("Frame", "MysticMaestroFrameContainer", UIParent)
  standaloneMenu:Hide()
  standaloneMenu:EnableMouse(true)
  standaloneMenu:SetMovable(true)
  standaloneMenu:SetResizable(false)
  standaloneMenu:SetFrameStrata("BACKGROUND")
  standaloneMenu:SetBackdrop(FrameBackdrop)
  standaloneMenu:SetBackdropColor(0, 0, 0, 1)
  standaloneMenu:SetToplevel(true)
  standaloneMenu:SetPoint("CENTER")
  standaloneMenu:SetSize(635, 455)
  standaloneMenu:SetClampedToScreen(true)

  -- function from WeakAuras Options for pretty border
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
  
  local title = CreateDecoration(standaloneMenu, 130)
  title:SetPoint("TOP", 0, 24)
  title:EnableMouse(true)
  title:SetScript("OnMouseDown", function(f) f:GetParent():StartMoving() end)
  title:SetScript("OnMouseUp", function(f) f:GetParent():StopMovingOrSizing() end)
  
  local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titletext:SetPoint("CENTER", title)
  titletext:SetText("Mystic Maestro")
  
  
  local close = CreateDecoration(standaloneMenu, 17)
  close:SetPoint("TOPRIGHT", -30, 12)
  
  local closebutton = CreateFrame("BUTTON", nil, close, "UIPanelCloseButton")
  closebutton:SetPoint("CENTER", close, "CENTER", 1, -1)
  closebutton:SetScript("OnClick", function() MM:CloseStandaloneMenu() end)
end

local mmf = CreateFrame("Frame", "MysticMaestroFrame", UIParent)
mmf:Hide()
mmf:SetSize(609, 423)
MM.MysticMaestroFrame = mmf

local defaultSearchText = "|cFF777777Search|r"

local sortDropdown, filterDropdown, searchBar
local function setUpWidgets()
  sortDropdown = AceGUI:Create("Dropdown")
  sortDropdown:SetPoint("TOPLEFT", mmf, "TOPLEFT", 8, 0)
  sortDropdown:SetWidth(160)
  sortDropdown:SetHeight(27)
  sortDropdown.frame:Show()

  filterDropdown = AceGUI:Create("Dropdown")
  filterDropdown:SetPoint("TOPRIGHT", mmf, "TOPRIGHT", -6, 0)
  filterDropdown:SetWidth(160)
  filterDropdown:SetHeight(27)
  filterDropdown.frame:Show()

  searchBar = AceGUI:Create("EditBoxMysticMaestroREPredictor")
  searchBar:SetPoint("TOP", mmf, "TOP")
  searchBar:SetWidth(200)
  searchBar:SetText(defaultSearchText)
  searchBar.editBox:ClearFocus()
  searchBar:SetCallback("OnEnterPressed", function(self, event, enchantID) self.editBox:ClearFocus() end)
  searchBar.editBox:HookScript("OnEditFocusGained", function(self) if searchBar.lastText == defaultSearchText then searchBar:SetText("") end end)
  searchBar.editBox:HookScript("OnEditFocusLost", function(self) if searchBar.lastText == "" then searchBar:SetText(defaultSearchText) end end)
  searchBar.frame:Show()
end

function MM:OpenStandaloneMenu()
  mmf:ClearAllPoints()
  mmf:SetPoint("BOTTOMLEFT", standaloneMenu, "BOTTOMLEFT", 13, 9)
  setUpWidgets()
  standaloneMenu:Show()
  mmf:Show()
end

local function tearDownWidgets()
  sortDropdown:Release()
  filterDropdown:Release()
  searchBar:Release()
end


function MM:CloseStandaloneMenu()
  tearDownWidgets()
  wipe(queryResults)
  standaloneMenu:Hide()
  mmf:Hide()
end

local function createContainer(parent, anchorPoint, width, height, xOffset, yOffset)
  local container = CreateFrame("Frame", nil, parent)
  container:SetResizable(false)
  container:SetFrameStrata("BACKGROUND")
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

function MM:ShowGraph(enchantName)
  local graph = self:HandleGraph(enchantName)
  if graph then
    graph:ClearAllPoints()
    graph:SetPoint("BOTTOMLEFT", graphContainer, "BOTTOMLEFT", 9, 9)
  end
end