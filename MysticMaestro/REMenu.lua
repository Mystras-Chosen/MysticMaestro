local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local queryResults = {}
do -- Create RE search box widget "EditBoxMysticMaestroREPredictor"
  LibStub("AceGUI-3.0-Search-EditBox"):Register(
    "MysticMaestroREPredictor",
    {
      GetValues = function(self, text, _, max)
        wipe(queryResults)
        text = text:lower()
        for enchantID, enchantData in pairs(MYSTIC_ENCHANTS) do
          if enchantID ~= 0 then
            local enchantName = GetSpellInfo(enchantData.spellID)
            if enchantName and enchantName:lower():find(text) then
              queryResults[enchantID] = MM:cTxt(enchantName, tostring(enchantData.quality))
              max = max - 1
              if max == 0 then
                return queryResults
              end
            end
          end
        end
        return queryResults
      end,
      GetValue = function(self, text, key)
        local enchantName
        if key then
          enchantName = queryResults[key]:match("|c........(.-)|r")
          MM:PopulateGraph(key)
          MM:SetResultSet({key})
          MM:GoToPage(1)
          return key, enchantName
        else
          key, enchantName = next(queryResults)
          if key then
            enchantName = enchantName:match("|c........(.-)|r")
            MM:PopulateGraph(key)
            MM:SetResultSet({key})
            MM:GoToPage(1)
            return key, enchantName
          end
        end
      end,
      GetHyperlink = function(self, key)
        return "spell:" .. MYSTIC_ENCHANTS[key].spellID
      end
    }
  )

  -- IDK what this does, but it is required
  local myOptions = {
    type = "group",
    args = {
      editbox1 = {
        type = "input",
        dialogControl = "EditBoxMysticMaestroREPredictor",
        name = "Type a spell name",
        get = function()
        end,
        set = function(_, v)
          print(v)
        end
      }
    }
  }

  LibStub("AceConfig-3.0"):RegisterOptionsTable("MysticMaestro", myOptions)
end

local FrameBackdrop = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true,
  tileSize = 32,
  edgeSize = 32,
  insets = {left = 8, right = 8, top = 8, bottom = 8}
}

local EdgelessFrameBackdrop = {
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  tile = true,
  tileSize = 32,
  edgeSize = 32,
  insets = {left = 8, right = 8, top = 8, bottom = 8}
}

local standaloneMenuContainer
local function createStandaloneMenuContainer()
  standaloneMenuContainer = CreateFrame("Frame", "MysticMaestroFrameContainer", UIParent)
  standaloneMenuContainer:Hide()
  standaloneMenuContainer:EnableMouse(true)
  standaloneMenuContainer:SetMovable(true)
  standaloneMenuContainer:SetResizable(false)
  standaloneMenuContainer:SetFrameStrata("BACKGROUND")
  standaloneMenuContainer:SetBackdrop(FrameBackdrop)
  standaloneMenuContainer:SetBackdropColor(0, 0, 0, 1)
  standaloneMenuContainer:SetToplevel(true)
  standaloneMenuContainer:SetPoint("CENTER")
  standaloneMenuContainer:SetSize(635, 455)
  standaloneMenuContainer:SetClampedToScreen(true)

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

  local title = CreateDecoration(standaloneMenuContainer, 130)
  title:SetPoint("TOP", 0, 24)
  title:EnableMouse(true)
  title:SetScript(
    "OnMouseDown",
    function(f)
      f:GetParent():StartMoving()
    end
  )
  title:SetScript(
    "OnMouseUp",
    function(f)
      f:GetParent():StopMovingOrSizing()
    end
  )

  local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titletext:SetPoint("CENTER", title)
  titletext:SetText("Mystic Maestro")

  local close = CreateDecoration(standaloneMenuContainer, 17)
  close:SetPoint("TOPRIGHT", -30, 12)

  local closebutton = CreateFrame("BUTTON", nil, close, "UIPanelCloseButton")
  closebutton:SetPoint("CENTER", close, "CENTER", 1, -1)
  closebutton:SetScript(
    "OnClick",
    function()
      MM:CloseStandaloneMenu()
    end
  )
end

local menuContainerInitialized
local function initializeMenuContainer()
  createStandaloneMenuContainer()
  menuContainerInitialized = true
end

local mmf

local function createMenu()
  mmf = CreateFrame("Frame", "MysticMaestroFrame", UIParent)
  mmf:Hide()
  mmf:SetSize(609, 423)
  MM.MysticMaestroFrame = mmf
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

local function getOrbCurrency()
  return GetItemCount(98570)
end

local function getExtractCurrency()
  return GetItemCount(98463)
end

local currencyContainer
local enchantContainerHeight = 12
local function updateCurrencyDisplay()
  currencyContainer.FontString:SetFormattedText("%s: |cFFFFFFFF%d|r %s %s: |cFFFFFFFF%d|r %s",
  "Orbs", getOrbCurrency(), CreateTextureMarkup("Interface\\Icons\\inv_custom_CollectionRCurrency", 64, 64, enchantContainerHeight+8, enchantContainerHeight+8, 0, 1, 0, 1),
  "Extracts", getExtractCurrency(), CreateTextureMarkup("Interface\\Icons\\Inv_Custom_MysticExtract", 64, 64, enchantContainerHeight+8, enchantContainerHeight+8, 0, 1, 0, 1))
end

local function createCurrencyContainer(parent)
  local width = parent:GetWidth()
  currencyContainer = CreateFrame("Frame", nil, parent)
  currencyContainer:SetSize(width, enchantContainerHeight)
  currencyContainer:SetFrameStrata("LOW")
  currencyContainer:SetPoint("BOTTOM", parent, "BOTTOM", 0, 8)
  currencyContainer.FontString = currencyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  currencyContainer.FontString:SetPoint("CENTER", currencyContainer, "CENTER")
  currencyContainer.FontString:SetSize(currencyContainer:GetWidth(), currencyContainer:GetHeight())
  updateCurrencyDisplay()
end

local function setUpCurrencyDisplay(enchantContainer)
  createCurrencyContainer(enchantContainer)
  MM:RegisterBucketEvent({"BAG_UPDATE"}, .2, updateCurrencyDisplay)
end

local AwAddonsTexturePath = "Interface\\AddOns\\AwAddons\\Textures\\"
local function createEnchantButton(enchantContainer, i)
  local enchantButton = CreateFrame("Button", nil, enchantContainer)
  enchantButton:SetSize(enchantContainer:GetWidth() - 16, 36)
  enchantButton:SetPoint("TOP", enchantContainer, "TOP", 0, -(i-1)*36-8)
  enchantButton:SetFrameStrata("LOW")
  enchantButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
    self.H:Hide()
  end)
  enchantButton:Hide()

  enchantButton.BG = enchantButton:CreateTexture(nil, "LOW")
  enchantButton.BG:SetTexture(AwAddonsTexturePath .. "CAOverhaul\\SpellSlot")
  enchantButton.BG:SetSize(248, 66)
  enchantButton.BG:SetPoint("CENTER", 19, 0)

  enchantButton.H = enchantButton:CreateTexture(nil, "OVERLAY")
  enchantButton.H:SetTexture(AwAddonsTexturePath .. "CAOverhaul\\SpellSlot_Highlight")
  enchantButton.H:SetSize(248, 59)
  enchantButton.H:SetPoint("CENTER", 19, 0)
  enchantButton.H:SetBlendMode("ADD")
  enchantButton.H:Hide()

  enchantButton.Icon = enchantButton:CreateTexture(nil, "LOW")
  enchantButton.Icon:SetTexture("Interface\\Icons\\5_dragonfirebreath")
  enchantButton.Icon:SetSize(32, 32)
  enchantButton.Icon:SetPoint("CENTER", -74, 0)

  enchantButton.IconBorder = enchantButton:CreateTexture(nil, "OVERLAY")
  enchantButton.IconBorder:SetTexture(AwAddonsTexturePath .. "LootTex\\Loot_Icon_Purple")
  enchantButton.IconBorder:SetSize(38, 38)
  enchantButton.IconBorder:SetPoint("CENTER", -74, 0)

  enchantButton.REText = enchantButton:CreateFontString()
  enchantButton.REText:SetFontObject(GameFontNormal)
  enchantButton.REText:SetFont("Fonts\\FRIZQT__.TTF", 11)
  enchantButton.REText:SetPoint("CENTER", 19, 0)
  enchantButton.REText:SetText("|cff00ff00Blade Vortex|r")
  enchantButton.REText:SetJustifyH("CENTER")
  enchantButton.REText:SetSize(148, 36)

  return enchantButton
end

local enchantButtons = {}
local numEnchantButtons = 8
local function createEnchantButtons(enchantContainer)
  for i=1, numEnchantButtons do
    table.insert(enchantButtons, createEnchantButton(enchantContainer, i))
  end
end

local prevPageButton, nextPageButton

local function createPageButton(enchantContainer, prevOrNext, xOffset, yOffset)
  local pageButton = CreateFrame("BUTTON", nil, enchantContainer)
  pageButton:SetSize(32, 32)
  pageButton:SetPoint("BOTTOM", enchantContainer, "BOTTOM", xOffset, yOffset)
  pageButton:SetFrameStrata("LOW")
  pageButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prevOrNext .."Page-Up")
  pageButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prevOrNext .."Page-Down")
  pageButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prevOrNext .."Page-Disabled")
  pageButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  pageButton:SetScript("OnClick", function(self)
    MM[prevOrNext.."Page"](MM)
  end)
  return pageButton
end

local function createPagination(enchantContainer)
  prevPageButton = createPageButton(enchantContainer, "Prev", -32, 70)
  nextPageButton = createPageButton(enchantContainer, "Next", 32, 70)
end

local menuInitialized
local enchantContainer, statsContainer, graphContainer
local function initializeMenu()
  createMenu()
  enchantContainer = createContainer(mmf, "BOTTOMLEFT", 200, 396)
  enchantContainer:EnableMouseWheel()
  enchantContainer:SetScript("OnMouseWheel",
  function(self, delta)
    if delta == 1 then
      MM:PrevPage()
    else
      MM:NextPage()
    end
  end)
  statsContainer = createContainer(mmf, "BOTTOMRIGHT", 412, 192)
  graphContainer = createContainer(mmf, "BOTTOMRIGHT", 412, 198, 0, 198)
  MM:InitializeGraph("MysticEnchantStatsGraph", graphContainer, "BOTTOMLEFT", "BOTTOMLEFT", 8, 9, 396, 181)
  setUpCurrencyDisplay(enchantContainer)
  createEnchantButtons(enchantContainer)
  createPagination(enchantContainer)
  menuInitialized = true
end

local function anchorMenuToMenuContainer()
  mmf:ClearAllPoints()
  mmf:SetPoint("BOTTOMLEFT", standaloneMenuContainer, "BOTTOMLEFT", 13, 9)
end

local sortDropdown, filterDropdown
local function setUpDropdownWidgets()
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
end

local defaultSearchText = "|cFF777777Search|r"

local searchBar
local function setUpSearchWidget()
  searchBar = AceGUI:Create("EditBoxMysticMaestroREPredictor")
  searchBar:SetPoint("TOP", mmf, "TOP")
  searchBar:SetWidth(200)
  searchBar:SetText(defaultSearchText)
  searchBar.editBox:ClearFocus()
  searchBar:SetCallback(
    "OnEnterPressed",
    function(self, event, enchantID)
      self.editBox:ClearFocus()
    end
  )
  searchBar.editBox:HookScript(
    "OnEditFocusGained",
    function(self)
      if searchBar.lastText == defaultSearchText then
        searchBar:SetText("")
      end
    end
  )
  searchBar.editBox:HookScript(
    "OnEditFocusLost",
    function(self)
      if searchBar.lastText == "" then
        searchBar:SetText(defaultSearchText)
      end
    end
  )
  searchBar.frame:Show()
end

function MM:OpenStandaloneMenu()
  if not menuContainerInitialized then
    initializeMenuContainer()
  end
  if not menuInitialized then
    initializeMenu()
  end
  anchorMenuToMenuContainer()
  setUpDropdownWidgets()
  setUpSearchWidget()
  self:ClearGraph()
  self:FilterMysticEnchants({all = true})
  self:GoToPage(1)
  standaloneMenuContainer:Show()
  mmf:Show()
end

local function tearDownWidgets()
  sortDropdown:Release()
  filterDropdown:Release()
  searchBar:Release()
  MM:HideEnchantButtons()
end

function MM:CloseStandaloneMenu()
  tearDownWidgets()
  wipe(queryResults)
  standaloneMenuContainer:Hide()
  mmf:Hide()
end

function MM:HideEnchantButtons()
  for _, button in ipairs(enchantButtons) do
    button:Hide()
  end
end

local enchantQualityBorders = {
  [2] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_green",
  [3] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_Blue",
  [4] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_Purple",
  [5] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_Leg"
}

local resultSet

function MM:SetResultSet(set)
  resultSet = set
end

function MM:FilterMysticEnchants(filters)
  local filterByAll = filters.all
  local filterByQuality = filters.quality
  local filterByKnown = filters.known
  local filterByUnknown = filters.unknown

  resultSet = {}
  for enchantID, enchantData in pairs(MYSTIC_ENCHANTS) do
    if enchantID ~= 0 then
      if filterByAll or filterByQuality == enchantData.quality
      or filterByKnown and IsReforgeEnchantmentKnown(enchantID)
      or filterByKnown and not IsReforgeEnchantmentKnown(enchantID) then
        table.insert(resultSet, enchantID)
      end
    end
  end
end

local currentPage = 1
local function updatePageButtons()
  prevPageButton:Enable()
  nextPageButton:Enable()
  if currentPage == 1 then
    prevPageButton:Disable()
  end
  if currentPage == MM:GetNumPages() then
    nextPageButton:Disable()
  end
end

function MM:GetNumPages()
  return math.ceil(#resultSet / numEnchantButtons)
end

function MM:PrevPage()
  if currentPage == 1 then return end
  currentPage = currentPage - 1
  updatePageButtons()
  self:HideEnchantButtons()
  self:ShowEnchantButtons()
end

function MM:NextPage()
  if currentPage == self:GetNumPages() then return end
  currentPage = currentPage + 1
  updatePageButtons()
  self:HideEnchantButtons()
  self:ShowEnchantButtons()
end

function MM:GoToPage(page)
  if page < 1 or page > self:GetNumPages() then return end
  currentPage = page
  updatePageButtons()
  self:HideEnchantButtons()
  self:ShowEnchantButtons()
end

local enchantQualityColors = {
  [2] = { 0.117647,        1,        0 },
  [3] = {        0, 0.439216, 0.866667 },
  [4] = { 0.639216, 0.207843, 0.933333 },
  [5] = {        1, 0.501961,        0 },
}

local function updateEnchantButton(enchantID, buttonNumber)
  local button = enchantButtons[buttonNumber]
  local enchantData = MYSTIC_ENCHANTS[enchantID]
  button.IconBorder:SetTexture(enchantQualityBorders[enchantData.quality])
  local enchantName, _, enchantIcon = GetSpellInfo(enchantData.spellID)
  button.Icon:SetTexture(enchantIcon)
  button.REText:SetText(enchantName)
  
  button:SetScript("OnEnter", function(self)
    self.H:Show()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
    GameTooltip:SetHyperlink("|Hspell:"..enchantData.spellID.."|h[test]|h")
    GameTooltip:Show()
  end)
  local r, g, b = unpack(enchantQualityColors[enchantData.quality])
  local mult = .6
  if IsReforgeEnchantmentKnown(enchantID) then
    button.IconBorder:SetVertexColor(1, 1, 1)
    button.Icon:SetVertexColor(1, 1, 1)
    button.BG:SetVertexColor(1, 1, 1)
    button.REText:SetTextColor(r, g, b)
  else
    button.IconBorder:SetVertexColor(mult, mult, mult)
    button.Icon:SetVertexColor(mult, mult, mult)
    button.BG:SetVertexColor(mult, mult, mult)
    button.REText:SetTextColor(mult*r, mult*g, mult*b)
  end
  button:Show()
end

local enchantQualityColors = {
  [2] = { 0.117647,        1,        0 },
  [3] = {        0, 0.439216, 0.866667 },
  [4] = { 0.639216, 0.207843, 0.933333 },
  [5] = {        1, 0.501961,        0 },
}

local function updateEnchantButton(enchantID, buttonNumber)
  local button = enchantButtons[buttonNumber]
  local enchantData = MYSTIC_ENCHANTS[enchantID]
  button.IconBorder:SetTexture(enchantQualityBorders[enchantData.quality])
  local enchantName, _, enchantIcon = GetSpellInfo(enchantData.spellID)
  button.Icon:SetTexture(enchantIcon)
  button.REText:SetText(enchantName)
  
  button:SetScript("OnEnter", function(self)
    self.H:Show()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
    GameTooltip:SetHyperlink("|Hspell:"..enchantData.spellID.."|h[test]|h")
    GameTooltip:Show()
  end)
  local r, g, b = unpack(enchantQualityColors[enchantData.quality])
  local mult = .6
  if IsReforgeEnchantmentKnown(enchantID) then
    button.IconBorder:SetVertexColor(1, 1, 1)
    button.Icon:SetVertexColor(1, 1, 1)
    button.BG:SetVertexColor(1, 1, 1)
    button.REText:SetTextColor(r, g, b)
  else
    AHTEST = button
    button.IconBorder:SetVertexColor(mult, mult, mult)
    button.Icon:SetVertexColor(mult, mult, mult)
    button.BG:SetVertexColor(mult, mult, mult)
    button.REText:SetTextColor(mult*r, mult*g, mult*b)
  end
  button:Show()
end

-- resultSet is a list of mystic enchant enchant IDs
-- page 1 is the first page
function MM:ShowEnchantButtons()
  if #resultSet - 8 * (currentPage - 1) <= 0 then
    self:Print("No mystic enchants on page")
    return
  end
  local index = 8 * (currentPage - 1) + 1
  local startIndex = index
  while index - startIndex < 8 and index <= #resultSet do
    updateEnchantButton(resultSet[index], index - startIndex + 1)
    index = index + 1
  end
end