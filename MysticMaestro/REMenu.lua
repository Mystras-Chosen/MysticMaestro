local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local MYSTIC_ENCHANTS = MYSTIC_ENCHANTS

local AwAddonsTexturePath = "Interface\\AddOns\\AwAddons\\Textures\\"

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
            local enchantName = MM.RE_NAMES[enchantID]
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
          MM:SetResultSet({key})
          MM:GoToPage(1)
          MM:SetSelectedEnchantButton(1)
          if MM:IsAHEmbeddedMenuOpen() then
            MM:SelectMyAuctionByEnchantID(key)
            MM:ClearSelectedEnchantAuctions()
          end
          return key, enchantName
        else
          key, enchantName = next(queryResults)
          if key then
            enchantName = enchantName:match("|c........(.-)|r")
            MM:SetResultSet({key})
            MM:GoToPage(1)
            MM:SetSelectedEnchantButton(1)
            if MM:IsAHEmbeddedMenuOpen() then
              MM:SelectMyAuctionByEnchantID(key)
              MM:ClearSelectedEnchantAuctions()
            end
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

local numEnchantButtons = 8
local enchantButtons = {}
local prevPageButton, nextPageButton, pageTextFrame
local enchantContainer, statsContainer, graphContainer, currencyContainer
local initializeStandaloneMenuContainer, initializeMenu
do -- functions to initialize menu and menu container
  local FrameBackdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left = 8, right = 8, top = 8, bottom = 8}
  }

  function initializeStandaloneMenuContainer()
    local standaloneMenuContainer = CreateFrame("Frame", "MysticMaestroMenuContainer", UIParent)
    table.insert(UISpecialFrames, standaloneMenuContainer:GetName())
    standaloneMenuContainer:Hide()
    standaloneMenuContainer:EnableMouse(true)
    standaloneMenuContainer:SetMovable(true)
    standaloneMenuContainer:SetResizable(false)
    standaloneMenuContainer:SetFrameStrata("DIALOG")
    standaloneMenuContainer:SetBackdrop(FrameBackdrop)
    standaloneMenuContainer:SetBackdropColor(0, 0, 0, 1)
    standaloneMenuContainer:SetToplevel(true)
    standaloneMenuContainer:SetPoint("CENTER")
    standaloneMenuContainer:SetSize(635, 412)
    standaloneMenuContainer:SetClampedToScreen(true)
    standaloneMenuContainer:SetScript("OnHide", function(self) MM:HideMysticMaestroMenu() end)

    -- function from WeakAuras Options for pretty border
    local function CreateDecoration(frame, width)
      local deco = CreateFrame("Frame", nil, frame)
      deco:SetSize(width, 40)

      local bg1 = deco:CreateTexture(nil, "DIALOG")
      bg1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
      bg1:SetTexCoord(0.31, 0.67, 0, 0.63)
      bg1:SetAllPoints(deco)

      local bg2 = deco:CreateTexture(nil, "DIALOG")
      bg2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
      bg2:SetTexCoord(0.235, 0.275, 0, 0.63)
      bg2:SetPoint("RIGHT", bg1, "LEFT", 1, 0)
      bg2:SetSize(10, 40)

      local bg3 = deco:CreateTexture(nil, "DIALOG")
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
        HideUIPanel(MysticMaestroMenuContainer)
      end
    )
  end

  local mmf
  local function createMenu()
    mmf = CreateFrame("Frame", "MysticMaestroMenu", UIParent)
    mmf:Hide()
    mmf:SetSize(609, 378)
  end

  local function getOrbCurrency()
    return GetItemCount(98570)
  end

  local function getExtractCurrency()
    return GetItemCount(98463)
  end

  local enchantContainerHeight = 12
  local function updateCurrencyDisplay()
    currencyContainer.FontString:SetFormattedText("%s: |cFFFFFFFF%d|r %s %s: |cFFFFFFFF%d|r %s",
    "Orbs", getOrbCurrency(), CreateTextureMarkup("Interface\\Icons\\inv_custom_CollectionRCurrency", 64, 64, enchantContainerHeight, enchantContainerHeight, 0, 1, 0, 1),
    "Extracts", getExtractCurrency(), CreateTextureMarkup("Interface\\Icons\\Inv_Custom_MysticExtract", 64, 64, enchantContainerHeight, enchantContainerHeight, 0, 1, 0, 1))
  end

  local function createCurrencyContainer(parent)
    local width = parent:GetWidth()
    currencyContainer = CreateFrame("Frame", nil, parent)
    currencyContainer:SetSize(width, enchantContainerHeight)
    currencyContainer:SetPoint("BOTTOM", parent, "BOTTOM", 0, 3)
    currencyContainer.FontString = currencyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currencyContainer.FontString:SetPoint("CENTER", currencyContainer, "CENTER")
    currencyContainer.FontString:SetSize(currencyContainer:GetWidth(), currencyContainer:GetHeight())
    updateCurrencyDisplay()
  end

  local function setUpCurrencyDisplay(enchantContainer)
    createCurrencyContainer(enchantContainer)
  end

  local function enchantButton_OnLeave(self)
    GameTooltip:Hide()
    if self ~= MM:GetSelectedEnchantButton() then
      self.H:Hide()
    end
  end

  local function enchantButton_OnClick(self, button, down)
    if button == "LeftButton" then
      local filterDropdown = MM:GetFilterDropdown()
      if filterDropdown.open then
        filterDropdown.pullout:Close()
      end
      MM:SetSelectedEnchantButton(self)
    end
  end

  local function favoriteButton_OnClick(self, button, down)
    local enchantID = self:GetParent().enchantID
    
    MM.db.realm.FAVORITE_ENCHANTS[enchantID] = not MM.db.realm.FAVORITE_ENCHANTS[enchantID] or nil
    MM:UpdateFavoriteIndicator(self:GetParent())

    local insert = MM.db.realm.FAVORITE_ENCHANTS[enchantID] and "w" or " longer"
    MM:Print(MM:ItemLinkRE(enchantID).." is no"..insert.." a favorite.")
    if MM:IsAHEmbeddedMenuOpen() then
      MM:CacheMyAuctionResults()
      MM:RefreshMyAuctionsScrollFrame()
    end
  end

  local function craftButton_OnClick(self, button, down)
    local enchantID = self:GetParent().enchantID
    local bagID, containerIndex = MM:FindBlankInsignia()
    if enchantID and bagID ~= nil then
      RequestSlotReforgeEnchantment(bagID, containerIndex, enchantID)
      MM:Print("Applied to insignia: "..MM:ItemLinkRE(enchantID))
    elseif bagID == nil then
      MM:Print("No blank insignia found")
    else
      MM:Print("This shouldn't print")
    end
  end

  local function craftButton_OnEnter(self)
    self.Texture:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\anvil")
    self.Texture:SetDesaturated(false)
    self.ItemCount:Hide()
  end

  local function craftButton_OnLeave(self)
    self.Texture:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\bag")
    self.Texture:SetDesaturated(not self.isEnchantInBags)
    self.ItemCount:Show()
  end

  local function createEnchantButton(enchantContainer, i)
    local enchantButton = CreateFrame("Button", nil, enchantContainer)
    enchantButton:SetSize(enchantContainer:GetWidth()-54, 36) -- 202 
    enchantButton:SetPoint("TOP", enchantContainer, "TOP", 27, -(i-1)*36)
    enchantButton:SetScript("OnLeave", enchantButton_OnLeave)
    enchantButton:RegisterForClicks("AnyUp")
    enchantButton:SetScript("OnClick", enchantButton_OnClick)
    enchantButton:Hide()

    enchantButton.BG = enchantButton:CreateTexture(nil, "BACKGROUND")
    enchantButton.BG:SetTexture(AwAddonsTexturePath .. "CAOverhaul\\SpellSlot")
    enchantButton.BG:SetSize(250, 66)
    enchantButton.BG:SetPoint("CENTER")

    enchantButton.H = enchantButton:CreateTexture(nil, "OVERLAY")
    enchantButton.H:SetTexture(AwAddonsTexturePath .. "CAOverhaul\\SpellSlot_Highlight")
    enchantButton.H:SetSize(250, 59)
    enchantButton.H:SetPoint("CENTER")
    enchantButton.H:SetBlendMode("ADD")
    enchantButton.H:SetDesaturated()
    enchantButton.H:Hide()

    enchantButton.Icon = enchantButton:CreateTexture(nil, "ARTWORK")
    enchantButton.Icon:SetSize(32, 32)
    enchantButton.Icon:SetPoint("CENTER", -92, 0)

    enchantButton.IconBorder = enchantButton:CreateTexture(nil, "OVERLAY")
    enchantButton.IconBorder:SetSize(38, 38)
    enchantButton.IconBorder:SetPoint("CENTER", -92, 0)

    enchantButton.REText = enchantButton:CreateFontString()
    enchantButton.REText:SetFontObject(GameFontNormal)
    enchantButton.REText:SetPoint("CENTER")
    enchantButton.REText:SetJustifyH("CENTER")
    enchantButton.REText:SetSize(148, 36)

    enchantButton.FavoriteButton = CreateFrame("Button", nil, enchantButton)
    enchantButton.FavoriteButton:SetSize(16, 18)
    enchantButton.FavoriteButton:SetPoint("CENTER", enchantButton, "CENTER", -119, 9)
    enchantButton.FavoriteButton.Texture = enchantButton.FavoriteButton:CreateTexture(nil, "OVERLAY")
    enchantButton.FavoriteButton.Texture:SetSize(18, 18)
    enchantButton.FavoriteButton.Texture:SetPoint("CENTER", enchantButton.FavoriteButton, "CENTER", 1, 0)
    enchantButton.FavoriteButton.Texture:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\star")
    enchantButton.FavoriteButton:RegisterForClicks("AnyUp")
    enchantButton.FavoriteButton:SetScript("OnClick", favoriteButton_OnClick)
    
    enchantButton.FavoriteButton:Show()

    enchantButton.CraftButton = CreateFrame("Button", nil, enchantButton)
    enchantButton.CraftButton:SetSize(18, 18)
    enchantButton.CraftButton:SetPoint("CENTER", enchantButton, "CENTER", -119, -9)
    enchantButton.CraftButton.Texture = enchantButton.CraftButton:CreateTexture(nil, "BACKGROUND")
    enchantButton.CraftButton.Texture:SetSize(18, 18)
    enchantButton.CraftButton.Texture:SetPoint("CENTER", enchantButton.CraftButton, "CENTER", 0, 0)
    enchantButton.CraftButton.Texture:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\bag")
    enchantButton.CraftButton:RegisterForClicks("AnyUp")
    enchantButton.CraftButton:SetScript("OnClick", craftButton_OnClick)
    enchantButton.CraftButton:SetScript("OnEnter", craftButton_OnEnter)
    enchantButton.CraftButton:SetScript("OnLeave", craftButton_OnLeave)

    enchantButton.CraftButton.ItemCount = enchantButton.CraftButton:CreateFontString()
    enchantButton.CraftButton.ItemCount:SetFontObject(GameFontNormal)
    enchantButton.CraftButton.ItemCount:SetPoint("CENTER", enchantButton.CraftButton, "CENTER", 0, 0)
    enchantButton.CraftButton.ItemCount:SetJustifyH("CENTER")
    enchantButton.CraftButton.ItemCount:SetSize(148, 36)
    enchantButton.CraftButton.ItemCount:SetTextColor(1, 1, 1, 1)
    enchantButton.CraftButton.ItemCount:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    
    enchantButton.CraftButton:Show()

    return enchantButton
  end

  local function createEnchantButtons(enchantContainer)
    for i=1, numEnchantButtons do
      table.insert(enchantButtons, createEnchantButton(enchantContainer, i))
    end
  end

  local paginationVerticalPosition = 14
  local function createPageButton(enchantContainer, prevOrNext, xOffset, yOffset)
    local pageButton = CreateFrame("BUTTON", nil, enchantContainer)
    pageButton:SetSize(32, 32)
    pageButton:SetPoint("BOTTOM", enchantContainer, "BOTTOM", xOffset, yOffset)
    pageButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prevOrNext .."Page-Up")
    pageButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prevOrNext .."Page-Down")
    pageButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prevOrNext .."Page-Disabled")
    pageButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    pageButton:SetScript("OnClick", function(self)
      MM[prevOrNext.."Page"](MM)
    end)
    return pageButton
  end

  local function createPageTextFrame(enchantContainer, xOffset, yOffset)
    pageTextFrame = CreateFrame("FRAME", nil, enchantContainer)
    pageTextFrame:SetSize(60, 32)
    pageTextFrame:SetPoint("BOTTOM", enchantContainer, "BOTTOM", xOffset, yOffset)
    pageTextFrame.Text = pageTextFrame:CreateFontString()
    pageTextFrame.Text:SetFontObject(GameFontNormal)
    pageTextFrame.Text:SetAllPoints()
    pageTextFrame.Text:SetJustifyH("CENTER")
  end

  local function createPagination(enchantContainer)
    prevPageButton = createPageButton(enchantContainer, "Prev", -42, paginationVerticalPosition)
    nextPageButton = createPageButton(enchantContainer, "Next", 42, paginationVerticalPosition)
    createPageTextFrame(enchantContainer, 0, paginationVerticalPosition)
  end

  local refreshButton
  local function createRefreshButton(mmf)
    refreshButton = CreateFrame("BUTTON", nil, mmf)
    refreshButton:SetSize(18, 18)
    refreshButton:SetPoint("CENTER", mmf, "TOPLEFT", 186, -14)
    refreshButton:SetNormalTexture("Interface\\BUTTONS\\UI-RefreshButton")
    refreshButton:SetScript("OnClick",
    function(self)
      MM:SetSearchBarDefaultText()
      MM:FilterMysticEnchants()
      MM:GoToPage(1)
      if MM:IsAHEmbeddedMenuOpen() then
        MM:ResetAHExtension()
      end
    end)
  end

  local function updateSellableREsCache(bagIDs)
    for bagID in pairs(bagIDs) do
      if bagID ~= -2 and bagID ~= -4 then
        MM:UpdateSellableREsCache(bagID)
      end
    end
  end

  local function updateCraftIndicators()
    for _, button in ipairs(enchantButtons) do
      MM:UpdateCraftIndicator(button)
    end
  end

  local function bagUpdateHandler(bagIDs)
    if MysticMaestroMenu and MysticMaestroMenu:IsVisible() then
      updateCurrencyDisplay()
      updateSellableREsCache(bagIDs)
      updateCraftIndicators()
    end
  end

  function initializeMenu()
    createMenu()
    enchantContainer = MM:CreateContainer(mmf, "BOTTOMLEFT", 202, 334, 8, 8)
    enchantContainer:EnableMouseWheel()
    enchantContainer:SetScript("OnMouseWheel",
    function(self, delta)
      if delta == 1 then
        MM:PrevPage()
      else
        MM:NextPage()
      end
    end)
    statsContainer = MM:CreateContainer(mmf, "BOTTOMRIGHT", 378, 134, -8, 8)
    graphContainer = MM:CreateContainer(mmf, "BOTTOMRIGHT", 378, 170, -8, 171)
    MM:InitializeGraph("MysticEnchantStatsGraph", graphContainer, "BOTTOMLEFT", "BOTTOMLEFT", 0, 1, 378, 170)
    setUpCurrencyDisplay(enchantContainer)
    createEnchantButtons(enchantContainer)
    createPagination(enchantContainer)
    createRefreshButton(mmf)
    MM:RegisterBucketEvent({"BAG_UPDATE"}, 1, bagUpdateHandler)
    for bagID=0, 4 do
      MM:UpdateSellableREsCache(bagID)
    end
  end
end

do -- hook and display MysticMaestroMenu in AuctionFrame
  local function initAHTab()
    MM.AHTabIndex = AuctionFrame.numTabs+1
    local framename = "AuctionFrameTab"..MM.AHTabIndex
    local frame = CreateFrame("Button", framename, AuctionFrame, "AuctionTabTemplate")
    frame:SetID(MM.AHTabIndex);
    frame:SetText("Mystic Maestro");
    frame:SetPoint("LEFT", _G["AuctionFrameTab"..MM.AHTabIndex-1], "RIGHT", -8, 0);

    PanelTemplates_SetNumTabs (AuctionFrame, MM.AHTabIndex);
    PanelTemplates_EnableTab  (AuctionFrame, MM.AHTabIndex);
    return frame
  end

  local function MMTab_OnClick(self, index)
    if not MysticMaestroMenu then
      initializeMenu()
    end
    local index = self:GetID()
    if index ~= MM.AHTabIndex then
      AuctionPortraitTexture:Show()
      if MysticMaestroMenu:GetParent() == AuctionFrame and MysticMaestroMenu:IsVisible() then
        MM:HideMysticMaestroMenu()
        MM:HideAHExtension()
      end
    else
      AuctionPortraitTexture:Hide()
      AuctionFrameTopLeft:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\UI-AuctionFrame-MysticMaestro-TopLeft");
      AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Top");
      AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopRight");
      AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft");
      AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot");
      AuctionFrameBotRight:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\UI-AuctionFrame-MysticMaestro-BotRight");
      MysticMaestroMenu:ClearAllPoints()
      MysticMaestroMenu:SetPoint("BOTTOMLEFT", AuctionFrame, "BOTTOMLEFT", 13, 31)
      MysticMaestroMenu:SetParent(AuctionFrame)
      if MysticMaestroMenuContainer and MysticMaestroMenuContainer:IsVisible() then
        MysticMaestroMenuContainer:Hide()
      end
      MM:ShowMysticMaestroMenu()
      MM:ShowAHExtension()
    end
  end

  local mm_orig_AuctionFrameTab_OnClick
  function MM:REMenu_ADDON_LOADED(event, addonName)
    if addonName ~= "Blizzard_AuctionUI" then return end
    local tab = initAHTab()
    mm_orig_AuctionFrameTab_OnClick = AuctionFrameTab_OnClick
    AuctionFrameTab_OnClick = function(self, index, down)
      mm_orig_AuctionFrameTab_OnClick(self, index, down)
      MMTab_OnClick(self, index, down)
    end
    self:HookScript(AuctionFrame, "OnHide",
    function()
      if MysticMaestroMenu and MysticMaestroMenu:IsShown() and MysticMaestroMenu:GetParent() == AuctionFrame then
        self:HideMysticMaestroMenu()
        self:HideAHExtension()
      end
    end)
  end

  MM:RegisterEvent("ADDON_LOADED", "REMenu_ADDON_LOADED")
end

do  -- display MysticMaestroMenu in standalone container
  function MM:OpenStandaloneMenu()
    if not MysticMaestroMenuContainer then
      initializeStandaloneMenuContainer()
    end
    if not MysticMaestroMenu then
      initializeMenu()
    end
    MysticMaestroMenu:ClearAllPoints()
    MysticMaestroMenu:SetPoint("BOTTOMLEFT", MysticMaestroMenuContainer, "BOTTOMLEFT", 13, 9)
    MysticMaestroMenu:SetParent(MysticMaestroMenuContainer)
    self:ShowMysticMaestroMenu()
    MysticMaestroMenuContainer:Show()
  end
end

local statsContainerWidgets = {}
do -- show and hide MysticMaestroMenu
  local filterOptions = {
    "All Qualities",
    "Uncommon", 
    "Rare",
    "Epic",
    "Legendary",
    "-------------",
    "Known & Unknown",
    "Known",
    "Unknown",
    "-------------",
    "Favorites",
    "-------------",
    "In Bags",
    "-------------"
  }

  local function itemsToFilter(items)
    MM.db.realm.VIEWS.filter = {
      allQualities = items[1]:GetValue(),
      uncommon = items[2]:GetValue(),
      rare = items[3]:GetValue(),
      epic = items[4]:GetValue(),
      legendary = items[5]:GetValue(),
      allKnown = items[7]:GetValue(),
      known = items[8]:GetValue(),
      unknown = items[9]:GetValue(),
      favorites = items[11]:GetValue(),
      bags = items[13]:GetValue()
    }
    return MM.db.realm.VIEWS.filter
  end

  local function filterToItems(filterDropdown, filter)
    filterDropdown:SetItemValue(1, filter.allQualities)
    filterDropdown:SetItemValue(2, filter.uncommon)
    filterDropdown:SetItemValue(3, filter.rare)
    filterDropdown:SetItemValue(4, filter.epic)
    filterDropdown:SetItemValue(5, filter.legendary)
    filterDropdown:SetItemValue(7, filter.allKnown)
    filterDropdown:SetItemValue(8, filter.known)
    filterDropdown:SetItemValue(9, filter.unknown)
    filterDropdown:SetItemValue(11, filter.favorites)
    filterDropdown:SetItemValue(13, filter.bags)
  end

  local function filterDropdown_OnValueChanged(self, event, key, checked)
    local items = self.pullout.items
    if key == 1 then
      if checked then
        items[2]:SetValue(nil)
        items[3]:SetValue(nil)
        items[4]:SetValue(nil)
        items[5]:SetValue(nil)
      else
        items[1]:SetValue(true)
      end
    elseif key == 2 or key == 3 or key == 4 or key == 5 then
      if checked then
        if items[2]:GetValue() and items[3]:GetValue() and items[4]:GetValue() and items[5]:GetValue() then
          items[2]:SetValue(nil)
          items[3]:SetValue(nil)
          items[4]:SetValue(nil)
          items[5]:SetValue(nil)
          items[1]:SetValue(true)
        else
          items[1]:SetValue(nil)
        end
      else
        if not (items[2]:GetValue() or items[3]:GetValue() or items[4]:GetValue() or items[5]:GetValue()) then
          items[1]:SetValue(true)
        end
      end
    elseif key == 7 or key == 8 or key == 9 then
      items[7]:SetValue(key == 7 or nil)
      items[8]:SetValue(key == 8 or nil)
      items[9]:SetValue(key == 9 or nil)
    end
    if items[key]:GetValue() == checked or key > 1 and key < 6 and items[1]:GetValue() then
      MM:SetSearchBarDefaultText()
      MM:FilterMysticEnchants(itemsToFilter(items))
      MM:GoToPage(1)
      if MM:IsAHEmbeddedMenuOpen() then
        MM:ResetAHExtension()
      end
    end
  end

  local sortOptions = {
    "A - Z",
    "Z - A",
    "Min GpO",
    "Med GpO",
    "Mean GpO",
    "Max GpO",
    "10d_Min GpO",
    "10d_Med GpO",
    "10d_Mean GpO",
    "10d_Max GpO"
  }

  local function sortDropdown_OnValueChanged(self, event, key, checked)
    local items = self.pullout.items
    items[1]:SetValue(key == 1 or nil)
    items[2]:SetValue(key == 2 or nil)
    MM:SetSearchBarDefaultText()
    MM.db.realm.VIEWS.sort = key
    MM:FilterMysticEnchants()
    MM:SortMysticEnchants(key)
    MM:GoToPage(1)
  end

  local sortDropdown, filterDropdown

  function MM:GetFilterDropdown()
    return filterDropdown
  end

  local function setUpDropdownWidgets()
    filterDropdown = AceGUI:Create("Dropdown")
    filterDropdown.frame:SetParent(MysticMaestroMenu)
    filterDropdown:SetPoint("TOPRIGHT", MysticMaestroMenu, "TOPRIGHT", -6, 0)
    filterDropdown:SetWidth(160)
    filterDropdown:SetHeight(27)
    filterDropdown:SetMultiselect(true)
    filterDropdown:SetList(filterOptions)
    filterDropdown:SetItemDisabled(6, true)
    filterDropdown:SetItemDisabled(10, true)
    filterDropdown:SetItemDisabled(12, true)
    if not MM.db.realm.VIEWS.filter then
      filterDropdown:SetItemValue(1, true)
      filterDropdown:SetItemValue(7, true)
    else
      filterToItems(filterDropdown, MM.db.realm.VIEWS.filter)
    end
    filterDropdown:SetCallback("OnValueChanged", filterDropdown_OnValueChanged)
    filterDropdown.frame:Show()

    sortDropdown = AceGUI:Create("Dropdown")
    sortDropdown.frame:SetParent(MysticMaestroMenu)
    sortDropdown:SetPoint("TOPLEFT", MysticMaestroMenu, "TOPLEFT", 8, 0)
    sortDropdown:SetWidth(160)
    sortDropdown:SetHeight(27)
    sortDropdown:SetList(sortOptions)
    sortDropdown:SetValue(MM.db.realm.VIEWS.sort or 1)
    sortDropdown:SetCallback("OnValueChanged", sortDropdown_OnValueChanged)
    sortDropdown.frame:Show()
  end

  local defaultSearchText = "|cFF777777Search|r"

  local searchBar

  function MM:SetSearchBarDefaultText()
    searchBar:SetText(defaultSearchText)
    searchBar.editBox:ClearFocus()
  end

  local function setUpSearchWidget()
    searchBar = AceGUI:Create("EditBoxMysticMaestroREPredictor")
    searchBar.frame:SetParent(MysticMaestroMenu)
    searchBar:SetPoint("TOP", MysticMaestroMenu, "TOP")
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
        else
          searchBar.editBox:HighlightText()
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

  local function setUpStatisticsWidgets()
    for i=1, 12 do
      local label = AceGUI:Create("Label")
      local p = (i - 1) % 4 + 1
      local h = p == 1 and 22 or 28
      local w = i <= 4 and 90 or 110
      local x = i <= 4 and -185 or i <= 8 and -80 or 43
      local y = 77-h*p
      local j = i <= 4 and "RIGHT" or "CENTER"
      label.frame:SetParent(statsContainer)
      label:SetWidth(w)
      label:SetHeight(h)
      label:SetJustifyH(j)
      label:SetJustifyV("MIDDLE")
      label:SetPoint("TOPLEFT", statsContainer, "CENTER", x, y)
      label:SetFontObject(GameFontNormal)
      label.frame:Show()
      table.insert(statsContainerWidgets, label)
    end
  end

  function MM:ShowMysticMaestroMenu()
    setUpDropdownWidgets()
    setUpSearchWidget()
    setUpStatisticsWidgets()
    self:ClearGraph()
    self:ResetSellableREsCache()
    self:FilterMysticEnchants(MM.db.realm.VIEWS.filter or {allQualities = true, allKnown = true})
    self:GoToPage(1)
    MysticMaestroMenu:Show()
  end

  local function tearDownWidgets()
    sortDropdown:Release()
    filterDropdown:Release()
    searchBar:Release()
    for i=1, #statsContainerWidgets do
      statsContainerWidgets[i]:Release()
    end
    wipe(statsContainerWidgets)
  end

  function MM:HideMysticMaestroMenu()
    tearDownWidgets()
    MM:HideEnchantButtons()
    wipe(queryResults)
    MysticMaestroMenu:Hide()
  end

  function MM:HandleMenuSlashCommand()
    if MysticMaestroMenu and MysticMaestroMenu:IsVisible()
    and MysticMaestroMenu:GetParent() == MysticMaestroMenuContainer then
      HideUIPanel(MysticMaestroMenuContainer)
    else
      if AuctionFrame and AuctionFrame:IsVisible() and AuctionFrame.selectedTab == self.AHTabIndex then
        self:HideMysticMaestroMenu()
        self:HideAHExtension()
        HideUIPanel(AuctionFrame)
      end
      self:OpenStandaloneMenu()
    end
  end
end

local resultSet
do -- filter functions
  function MM:SetResultSet(set)
    resultSet = set
  end

  function MM:GetResultSet()
    return resultSet
  end

  local function qualityCheckMet(enchantID, filter)
    local quality = MYSTIC_ENCHANTS[enchantID].quality
    return filter.allQualities
    or filter.uncommon and quality == 2
    or filter.rare and quality == 3
    or filter.epic and quality == 4
    or filter.legendary and quality == 5
  end

  local function knownCheckMet(enchantID, filter)
    local known = IsReforgeEnchantmentKnown(enchantID)
    return filter.allKnown
    or filter.known and known
    or filter.unknown and not known
  end

  local function favoriteCheckMet(enchantID, filter)
    return not filter.favorites or MM.db.realm.FAVORITE_ENCHANTS[enchantID]
  end

  local function bagsCheckMet(enchantID, filter)
    return not filter.bags or MM:CountSellableREInBags(enchantID) > 0
  end

  function MM:FilterMysticEnchants(filter)
    filter = filter or MM.db.realm.VIEWS.filter
    MM.db.realm.VIEWS.filter = filter
    resultSet = {}
    for enchantID, enchantData in pairs(MYSTIC_ENCHANTS) do
      if enchantID ~= 0 and qualityCheckMet(enchantID, filter)
      and knownCheckMet(enchantID, filter) and favoriteCheckMet(enchantID, filter)
      and bagsCheckMet(enchantID, filter) then
        table.insert(resultSet, enchantID)
      end
    end
    self:SortMysticEnchants(MM.db.realm.VIEWS.sort or 1)
  end
end

do -- sort functions
  local itemKeyToSortFunctionKey = {
    "alphabetical_asc",
    "alphabetical_des",
    "goldperorb_min",
    "goldperorb_med",
    "goldperorb_mean",
    "goldperorb_max",
    "goldperorb_10d_min",
    "goldperorb_10d_med",
    "goldperorb_10d_mean",
    "goldperorb_10d_max",
  }

  local sortFunctions = {
    alphabetical_asc = function(k1, k2) return MM:Compare(MM.RE_NAMES[k1],MM.RE_NAMES[k2],"<") end,
    alphabetical_des = function(k1, k2) return MM:Compare(MM.RE_NAMES[k1],MM.RE_NAMES[k2],">") end,
    goldperorb_min = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"Min"), MM:OrbValue(k2,"Min"), ">") end,
    goldperorb_med = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"Med"), MM:OrbValue(k2,"Med"), ">") end,
    goldperorb_mean = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"Mean"), MM:OrbValue(k2,"Mean"), ">") end,
    goldperorb_max = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"Max"), MM:OrbValue(k2,"Max"), ">") end,
    goldperorb_10d_min = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"10d_Min"), MM:OrbValue(k2,"10d_Min"), ">") end,
    goldperorb_10d_med = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"10d_Med"), MM:OrbValue(k2,"10d_Med"), ">") end,
    goldperorb_10d_mean = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"10d_Mean"), MM:OrbValue(k2,"10d_Mean"), ">") end,
    goldperorb_10d_max = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"10d_Max"), MM:OrbValue(k2,"10d_Max"), ">") end,
  }

  function MM:SortMysticEnchants(itemKey)
    table.sort(resultSet, sortFunctions[itemKeyToSortFunctionKey[itemKey]])
  end
end

local currentPage = 1
do -- mystic enchant page functions
  local function updatePageButtons()
    local numPages = MM:GetNumPages()
    if numPages == 0 then
      prevPageButton:Disable()
      nextPageButton:Disable()
      pageTextFrame.Text:SetText("0/0")
      return
    end
    prevPageButton:Enable()
    nextPageButton:Enable()
    if currentPage == 1 then
      prevPageButton:Disable()
    end
    if currentPage == MM:GetNumPages() then
      nextPageButton:Disable()
    end
    pageTextFrame.Text:SetText(currentPage.."/"..MM:GetNumPages())
  end

  function MM:GetNumPages()
    return math.ceil(#resultSet / numEnchantButtons)
  end

  function MM:PrevPage()
    if currentPage == 1 then return end
    currentPage = currentPage - 1
    updatePageButtons()
    self:RefreshEnchantButtons()
  end

  function MM:NextPage()
    if currentPage == self:GetNumPages() then return end
    currentPage = currentPage + 1
    updatePageButtons()
    self:RefreshEnchantButtons()
  end

  function MM:GoToPage(page)
    local numPages = self:GetNumPages()
    if page < 1 or numPages ~= 0 and page > numPages then return end
    currentPage = page
    updatePageButtons()
    self:RefreshEnchantButtons()
  end
end

do -- show/hide and select/deselect mystic enchant button functions
  local enchantQualityColors = {
    [2] = { 0.117647,        1,        0 },
    [3] = {        0, 0.439216, 0.866667 },
    [4] = { 0.639216, 0.207843, 0.933333 },
    [5] = {        1, 0.501961,        0 },
  }

  local enchantQualityBorders = {
    [2] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_green",
    [3] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_Blue",
    [4] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_Purple",
    [5] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_Leg"
  }

  function MM:UpdateFavoriteIndicator(button)
    local isFavorite = self.db.realm.FAVORITE_ENCHANTS[button.enchantID]
    button.FavoriteButton.Texture:SetDesaturated(not isFavorite)
    button.FavoriteButton.Texture:SetVertexColor(1, 1, 1, isFavorite and 1 or .3)
  end

  function MM:UpdateCraftIndicator(button)
    local enchantID = button.enchantID
    local itemCount = MM:CountSellableREInBags(enchantID)
    if itemCount == 0 then
      button.CraftButton.Texture:SetDesaturated(not button.CraftButton:IsMouseOver())
      button.CraftButton.ItemCount:SetText(nil)
      button.CraftButton.isEnchantInBags = false
    else
      button.CraftButton.Texture:SetDesaturated(false)
      button.CraftButton.ItemCount:SetText(itemCount)
      button.CraftButton.isEnchantInBags = true
    end
  end


  local function updateEnchantButton(enchantID, buttonNumber)
    local button = enchantButtons[buttonNumber]
    button.enchantID = enchantID
    local enchantData = MYSTIC_ENCHANTS[enchantID]
    button.IconBorder:SetTexture(enchantQualityBorders[enchantData.quality])
    local enchantName, _, enchantIcon = GetSpellInfo(enchantData.spellID)
    button.Icon:SetTexture(enchantIcon)
    button.REText:SetText(enchantName)
    
    button:SetScript("OnEnter", function(self)
      if self ~= MM:GetSelectedEnchantButton() then
        self.H:Show()
      end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
      GameTooltip:SetHyperlink("|Hspell:"..enchantData.spellID.."|h[test]|h")
      GameTooltip:Show()
    end)
    local r, g, b = unpack(enchantQualityColors[enchantData.quality])
    local mult = .3
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
    MM:UpdateFavoriteIndicator(button)
    MM:UpdateCraftIndicator(button)
    button:Show()
  end

  function MM:ShowEnchantButtons()
    if #resultSet - 8 * (currentPage - 1) <= 0 then
      return
    end
    local index = 8 * (currentPage - 1) + 1
    local startIndex = index
    while index - startIndex < 8 and index <= #resultSet do
      updateEnchantButton(resultSet[index], index - startIndex + 1)
      index = index + 1
    end
  end

  function MM:HideEnchantButtons()
    for _, button in ipairs(enchantButtons) do
      button:Hide()
      button.H:SetDesaturated(true)
      button.H:Hide()
    end
    self:DeselectSelectedEnchantButton()
  end

  function MM:RefreshEnchantButtons()
    self:HideEnchantButtons()
    self:ShowEnchantButtons()
  end

  function MM:GetEnchantButtonByEnchantID(enchantID)
    for _, button in ipairs(enchantButtons) do
      if button.enchantID == enchantID then
        return button
      end
    end
  end

  local selectedEnchantButton

  function MM:GetSelectedEnchantButton()
    return selectedEnchantButton
  end

  function MM:SetSelectedEnchantButton(button)
    button = type(button) == "table" and button or enchantButtons[button]
    local lastSelectedButton = self:GetSelectedEnchantButton()
    if lastSelectedButton == button then return end
    button.H:Show()
    button.H:SetDesaturated(false)
    if lastSelectedButton then
      lastSelectedButton.H:SetDesaturated(true)
      lastSelectedButton.H:Hide()
    end
    self:PopulateGraph(button.enchantID)
    self:ShowStatistics(button.enchantID)
    if self:IsAHEmbeddedMenuOpen() then
      self:AsyncDisplayEnchantAuctions(button.enchantID) -- async populate scroll bars
      self:SelectMyAuctionByEnchantID(button.enchantID)
      self:ClearSelectedEnchantAuctions()
    end
    selectedEnchantButton = button
  end

  function MM:DeselectSelectedEnchantButton()
    if selectedEnchantButton then
      selectedEnchantButton.H:SetDesaturated(true)
      selectedEnchantButton.H:Hide()
    end
    self:ClearGraph()
    self:HideStatistics()
    if self:IsAHEmbeddedMenuOpen() then
      self:ResetAHExtension()
    end
    selectedEnchantButton = nil
  end
end

do -- show/hide statistics functions
  function MM:ShowStatistics(enchantID)
    local info = MM:StatObj(enchantID)
    local coinStr = {}
    if info then
      coinStr.min = GetCoinTextureString(info.Min)
      coinStr.d_min = MM:cTxt(GetCoinTextureString(info["10d_Min"]),"min")
      coinStr.mean = GetCoinTextureString(info.Mean)
      coinStr.d_mean = MM:cTxt(GetCoinTextureString(info["10d_Mean"]),"min")
      coinStr.dev = GetCoinTextureString(info.Dev)
      coinStr.d_dev = MM:cTxt(GetCoinTextureString(info["10d_Dev"]),"min")
      coinStr.med = GetCoinTextureString(info.Med)
      coinStr.d_med = MM:cTxt(GetCoinTextureString(info["10d_Med"]),"min")
      coinStr.max = GetCoinTextureString(info.Max)
      coinStr.d_max = MM:cTxt(GetCoinTextureString(info["10d_Max"]),"min")
      coinStr.gpo = GetCoinTextureString(MM:OrbValue(enchantID,"Min"))
      coinStr.d_gpo = MM:cTxt(GetCoinTextureString(MM:OrbValue(enchantID,"10d_Min")),"min")
      local daysAgo = MM:DaysAgoString(info.Last)
      if daysAgo == "" then daysAgo = "Just Now" end

      statsContainerWidgets[ 1]:SetText("")
      statsContainerWidgets[ 2]:SetText(MM:cTxt("Minimum:","yellow"))
      statsContainerWidgets[ 3]:SetText(MM:cTxt("Gold Per Orb:","yellow"))
      statsContainerWidgets[ 4]:SetText(MM:cTxt("Listed:","yellow"))
      statsContainerWidgets[ 5]:SetText(MM:cTxt("Last Seen:","yellow").."\n"..(daysAgo or "No Data"))
      statsContainerWidgets[ 6]:SetText(coinStr.min)
      statsContainerWidgets[ 7]:SetText(coinStr.gpo)
      statsContainerWidgets[ 8]:SetText(info.Count .. " (" .. info.Trinkets .. " Trinkets)")
      statsContainerWidgets[ 9]:SetText(MM:cTxt("10-Day Average:","yellow").."\n"..MM:cTxt("Calculate This","min"))
      statsContainerWidgets[10]:SetText(coinStr.d_min)
      statsContainerWidgets[11]:SetText(coinStr.d_gpo)
      statsContainerWidgets[12]:SetText(MM:cTxt(info["10d_Count"] .. " (" .. info["10d_Trinkets"] .. " Trinkets)","min"))
    end


-- MM:cTxt("10 Day: ","yellow")..coinStr.d_listed
-- MM:cTxt("Listed: ","yellow")..coinStr.listed

    -- ...." ("....")"
    -- ..coinStr.med.." ("..coinStr.d_med..")"
    -- ..coinStr.mean.." ("..coinStr.d_mean..")"
    -- ..coinStr.max.." ("..coinStr.d_max..")"
    -- ..coinStr.dev.." ("..coinStr.d_dev..")"
    -- ...." ("....")"


    for i=1, #statsContainerWidgets do
      statsContainerWidgets[i].frame:Show()
    end
  end
  
  function MM:HideStatistics()
    for i=1, #statsContainerWidgets do
      statsContainerWidgets[i].frame:Hide()
    end
  end
end