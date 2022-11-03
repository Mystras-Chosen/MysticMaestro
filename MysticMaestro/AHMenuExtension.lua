local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local ahExtensionMenu

local function createContainerFrame()
  ahExtensionMenu = CreateFrame("Frame", "MysticMaestroMenuAHExtension", UIParent)
  ahExtensionMenu:SetSize(212, 378)
end

local buttonHeight = 16
local auctionScrollFrameWidth = 195

local selectedMyAuctionData

function MM:GetSelectedMyAuctionData()
  return selectedMyAuctionData
end

function MM:SetSelectedMyAuctionData(data)
  selectedMyAuctionData = data
end

function MM:DeselectSelectedMyAuctionData()
  self:SetSelectedMyAuctionData(nil)
  local myAuctionsButton = MM:GetMyAuctionsScrollFrame().buttons
  for _, button in ipairs(myAuctionsButton) do
      button.H:Hide()
  end
end

local selectedSelectedEnchantAuctionData

function MM:GetSelectedSelectedEnchantAuctionData()
  return selectedSelectedEnchantAuctionData
end

function MM:SetSelectedSelectedEnchantAuctionData(data)
  if data == nil then
    self:DisableUndercutButton()
    self:DisableBuyoutCancelButton()
  end
  selectedSelectedEnchantAuctionButtonData = data
end

function MM:DeselectSelectedSelectedEnchantAuctionData()
  self:SetSelectedSelectedEnchantAuctionData(nil)

  local selectedEnchantAuctionsButtons = MM:GetSelectedEnchantAuctionsScrollFrame().buttons
  for _, button in ipairs(selectedEnchantAuctionsButtons) do
      button.H:Hide()
  end
end

local function createMyAuctionsButton(parent, listingName)
  local listingButton = CreateFrame("Button", listingName, parent)
  listingButton:SetSize(parent:GetWidth(), buttonHeight)
  listingButton.H = listingButton:CreateTexture(nil, "OVERLAY")
  listingButton.H:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
  listingButton.H:SetAllPoints()
  listingButton.H:SetBlendMode("ADD")
  listingButton.H:SetTexCoord(0, 1, 0, 0.578125)
  listingButton.H:Hide()

  listingButton.auctionCount = listingButton:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  listingButton.auctionCount:SetPoint("LEFT")

  listingButton.enchantName = listingButton:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  listingButton.enchantName:SetPoint("LEFT", listingButton, "LEFT", 10, 0)

  listingButton:SetScript("OnClick",
    function(self)
      MM:DeselectSelectedMyAuctionData()
      MM:SetSelectedMyAuctionData(self.data)
      if self.data.yours == false then
        MM:EnableUndercutButton()
      else
        MM:DisableUndercutButton()
      end

      self.H:Show()
      self.H:SetDesaturated(false)

      MM:SetSearchBarDefaultText()
      MM:SetResultSet({self.data.enchantID})
      MM:GoToPage(1)
      MM:SetSelectedEnchantButton(1)
    end
  )

  listingButton:SetScript("OnLeave",
    function(self)
      if self.data ~= MM:GetSelectedMyAuctionData() then
        self.H:Hide()
      end
    end
  )

  listingButton:SetScript("OnEnter",
    function(self)
      if self.data ~= MM:GetSelectedMyAuctionData() then
        self.H:Show()
        self.H:SetDesaturated(true)
      end
    end
  )

  return listingButton
end

local function createSelectedAuctionsButton(parent, listingName)
  local listingButton = CreateFrame("Button", listingName, parent)
  listingButton:SetSize(parent:GetWidth(), buttonHeight)
  listingButton.H = listingButton:CreateTexture(nil, "OVERLAY")
  listingButton.H:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
  listingButton.H:SetAllPoints()
  listingButton.H:SetBlendMode("ADD")
  listingButton.H:SetTexCoord(0, 1, 0, 0.578125)
  listingButton.H:Hide()
  
  listingButton.icon = listingButton:CreateTexture(nil, "OVERLAY")
  listingButton.icon:SetSize(buttonHeight, buttonHeight)
  listingButton.icon:SetPoint("LEFT")

  listingButton.price = CreateFrame("Frame", listingName.."Price", listingButton, "SmallMoneyFrameTemplate")
  MoneyFrame_SetType(listingButton.price, "AUCTION")
  listingButton.price:SetPoint("LEFT", listingButton.icon, "RIGHT", 0, 0)
  listingButton.price:SetSize(parent:GetWidth(), buttonHeight)

  listingButton.price.Suffix = listingButton.price:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  listingButton.price.Suffix:SetPoint("RIGHT", listingButton, "RIGHT", 0, 0)

  listingButton:SetScript("OnClick",
    function(self)
      MM:DeselectSelectedSelectedEnchantAuctionData()
      MM:SetSelectedSelectedEnchantAuctionData(self.data)
      if self.data.yours then
        MM:DisableUndercutButton()
      else
        MM:EnableUndercutButton()
      end
      self.H:Show()
      self.H:SetDesaturated(false)
    end
  )

  listingButton:SetScript("OnLeave",
    function(self)
      if self.data ~= MM:GetSelectedSelectedEnchantAuctionData() then
        self.H:Hide()
      end
    end
  )

  listingButton:SetScript("OnEnter",
    function(self)
      if self.data ~= MM:GetSelectedSelectedEnchantAuctionData() then
        self.H:Show()
        self.H:SetDesaturated(true)
      end
    end
  )

  return listingButton
end

local function createAuctionsScrollFrame(name, title, parent, numRows, buttonCreateFunc)
  local scrollFrame = CreateFrame("ScrollFrame", name.."ScrollFrame", parent, "FauxScrollFrameTemplate")
  scrollFrame:SetSize(auctionScrollFrameWidth - 24, buttonHeight * numRows)
  scrollFrame:SetPoint("LEFT")
  scrollFrame.Title = scrollFrame:CreateFontString(name.."Title", "OVERLAY", "GameTooltipText")
  scrollFrame.Title:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 2)
  scrollFrame.Title:SetText(title)
  scrollFrame.buttons = {}
  
  for i=1, numRows do
    local listingButton = buttonCreateFunc(scrollFrame, name.."Button"..i)
    listingButton:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, (1-i)*buttonHeight)
    table.insert(scrollFrame.buttons, listingButton)
  end

  return scrollFrame
end


local function myAuctionsScrollFrame_Update(self)
  local buttons = self.buttons
  local results = MM:GetMyAuctionsResults()
  FauxScrollFrame_Update(self, #results, #buttons, buttonHeight, nil, nil, nil, nil, nil, nil, true)
  local offset = FauxScrollFrame_GetOffset(self)

  for line = 1, #buttons do
    local lineplusoffset = line + offset
    local button = buttons[line]
    if lineplusoffset > #results then
      button:Hide()
      button.data = nil
    else
      local result = results[lineplusoffset]
      button.data = result
      button.auctionCount:SetText(#result.data)
      local reData = GetREData(result.enchantID)
      button.enchantName:SetText(MM:cTxt(reData.spellName, tostring(reData.quality)))
      button:Show()
    end
  end
end

local function selectEnchantAuctionsScrollFrame_Update(self)
  local buttons = self.buttons
  local results = MM:GetSelectedEnchantAuctionsResults()
  FauxScrollFrame_Update(self, #results, #buttons, buttonHeight, nil, nil, nil, nil, nil, nil, true)
  local offset = FauxScrollFrame_GetOffset(self)
  local selectedEnchant = MM:GetSelectedSelectedEnchantAuctionData()
  -- go through each button and set visibility and associate with results
  for line = 1, #buttons do
    local lineplusoffset = line + offset
    local button = buttons[line]
    MM:EnableSelectEnchantAuctionButton(button)
    if lineplusoffset > #results then
      button:Hide()
      button.data = nil
    else
      local result = results[lineplusoffset]
      button.price.Suffix:SetText(result.yours and "  (yours)" or nil)
      MoneyFrame_Update(button.price, result.buyoutPrice)
      button.data = result
      button.icon:SetTexture(result.icon)
      button:Show()
      MM:EnableSelectEnchantAuctionButton(button)
      if button.data == selectedEnchant then
        button.H:Show()
        button.H:SetDesaturated(false)
      elseif button:IsMouseOver() then
        button.H:Show()
        button.H:SetDesaturated(true)
      else
        button.H:Hide()
        button.H:SetDesaturated(true)
      end
    end
  end
end

local myAuctionsScrollFrame

function MM:GetMyAuctionsScrollFrame()
  return myAuctionsScrollFrame
end

function MM:SetMyAuctionsScrollFrame(scrollFrame)
  myAuctionsScrollFrame = scrollFrame
end

local myAuctionsButtonCount = 10

local function createMyAuctionsScrollFrame()
  local myAuctionsScrollFrameContainer = MM:CreateContainer(ahExtensionMenu, "TOPRIGHT", auctionScrollFrameWidth, buttonHeight * myAuctionsButtonCount, -11, -50)
  local scrollFrame = createAuctionsScrollFrame(
    "MysticMaestroMyAuctions",
    "My Auctions",
    myAuctionsScrollFrameContainer,
    myAuctionsButtonCount,
    createMyAuctionsButton
  )
  scrollFrame:SetScript("OnVerticalScroll",
    function(self, offset)
      FauxScrollFrame_OnVerticalScroll(self, offset, buttonHeight, myAuctionsScrollFrame_Update)
    end
  )
  MM:SetMyAuctionsScrollFrame(scrollFrame)
end

local selectedEnchantAuctionsScrollFrame

function MM:GetSelectedEnchantAuctionsScrollFrame()
  return selectedEnchantAuctionsScrollFrame
end

function MM:SetSelectedEnchantAuctionsScrollFrame(scrollFrame)
  selectedEnchantAuctionsScrollFrame = scrollFrame
end

local selectedEnchantAuctionsButtonCount = 6

local function createSelectedEnchantAuctionsScrollFrame()
  local selectedEnchantAuctionsScrollFrameContainer = MM:CreateContainer(ahExtensionMenu, "BOTTOMRIGHT", auctionScrollFrameWidth, buttonHeight * selectedEnchantAuctionsButtonCount, -11, 40)
  local scrollFrame = createAuctionsScrollFrame(
    "MysticMaestroSelectedEnchantAuctions",
    "Selected Enchant Auctions",
    selectedEnchantAuctionsScrollFrameContainer,
    selectedEnchantAuctionsButtonCount,
    createSelectedAuctionsButton
  )
  scrollFrame:SetScript("OnVerticalScroll",
    function(self, offset)
      FauxScrollFrame_OnVerticalScroll(self, offset, buttonHeight, selectEnchantAuctionsScrollFrame_Update)
    end
  )
  MM:SetSelectedEnchantAuctionsScrollFrame(scrollFrame)
end

local function initAHExtension()
  createContainerFrame()
  createMyAuctionsScrollFrame()
  createSelectedEnchantAuctionsScrollFrame()
end

local undercutButton, buyCancelbutton
local function setUpButtonWidgets()
  undercutButton = AceGUI:Create("Button")
  undercutButton.frame:SetParent(ahExtensionMenu)
  undercutButton:SetPoint("BOTTOMLEFT", ahExtensionMenu, "BOTTOMLEFT", 0, 15)
  undercutButton:SetWidth(82)
  undercutButton:SetHeight(22)
  undercutButton:SetText("Undercut")
  undercutButton:SetCallback("OnClick",
    function(self, event)
      print("relist clicked")
    end
  )
  undercutButton.frame:Show()
  

  buyCancelbutton = AceGUI:Create("Button")
  buyCancelbutton.frame:SetParent(ahExtensionMenu)
  buyCancelbutton:SetPoint("BOTTOMRIGHT", ahExtensionMenu, "BOTTOMRIGHT", -6, 15)
  buyCancelbutton:SetWidth(124)
  buyCancelbutton:SetHeight(22)
  buyCancelbutton:SetText("Buyout/Cancel")
  buyCancelbutton:SetCallback("OnClick",
    function(self, event)
      -- local selectedAuctionData = MM:GetSelectedAuctionData()
      -- if not selectedAuctionData then error("Buyout click when no selected auction") return end
      -- if selectedAuctionData.yours then
      --   print("cancel auction in selected enchant auctions")
      -- elseif selectedAuctionData.yours == false then
      --   print("Buy selected auction")
      -- else
      --   print("cancel auction in my auctions")
      -- end
      print("Selected My Auction: " .. tostring(MM:GetSelectedMyAuctionData()))
      print("Selected Selected Enchant Auction: " .. tostring(MM:GetSelectedSelectedEnchantAuctionData()))
    end
  )
  buyCancelbutton.frame:Show()
end

local function tearDownButtonWidgets()
  undercutButton:Release()
  buyCancelbutton:Release()
end

function MM:DisableUndercutButton()
  --undercutButton:SetDisabled(true)
end

function MM:EnableUndercutButton()
  undercutButton:SetDisabled(false)
end

function MM:DisableBuyoutCancelButton()
  --buyCancelbutton:SetDisabled(true)
end

function MM:EnableBuyoutCancelButton()
  buyCancelbutton:SetDisabled(false)
end

function MM:ShowAHExtension()
  if not MysticMaestroMenuAHExtension then
    initAHExtension()
  end
  setUpButtonWidgets()
  myAuctionsScrollFrame_Update(self:GetMyAuctionsScrollFrame())
  selectEnchantAuctionsScrollFrame_Update(self:GetSelectedEnchantAuctionsScrollFrame())
  MysticMaestroMenuAHExtension:Show()
  MysticMaestroMenuAHExtension:ClearAllPoints()
  MysticMaestroMenuAHExtension:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", 0, 0)
  MysticMaestroMenuAHExtension:SetParent(AuctionFrame)
end

function MM:HideAHExtension()
  tearDownButtonWidgets()
  MysticMaestroMenuAHExtension:Hide()
  self:DeselectSelectedAuctionData()
  self:ClearMyAuctions()
  self:ClearSelectedEnchantAuctions()
end

function MM:PopulateMyAuctions(results)
  myAuctionsScrollFrame_Update(self:GetMyAuctionsScrollFrame())
end

function MM:PopulateSelectedEnchantAuctions(results)
  self:SetSelectedEnchantAuctionsResults(results)
  selectEnchantAuctionsScrollFrame_Update(self:GetSelectedEnchantAuctionsScrollFrame())
end

local selectedEnchantAuctionsResults
function MM:GetSelectedEnchantAuctionsResults()
  self:SetSelectedEnchantAuctionsResults(selectedEnchantAuctionsResults or {})
  return selectedEnchantAuctionsResults
end

function MM:SetSelectedEnchantAuctionsResults(results)
  selectedEnchantAuctionsResults = results
end

function MM:ClearMyAuctions()
  self:PopulateMyAuctions({})
end

function MM:ClearSelectedEnchantAuctions()
  self:SetSelectedSelectedEnchantAuctionData(nil)
  self:PopulateSelectedEnchantAuctions({})
  self:DeactivateSelectScanListener()
end

local function setMoneyButtonTransparency(button, alpha)
  local moneyFrameName = button.price:GetName()
  _G[moneyFrameName.."GoldButton"]:GetNormalTexture():SetVertexColor(1, 1, 1, alpha)
  _G[moneyFrameName.."GoldButtonText"]:SetTextColor(1, 1, 1, alpha)
  _G[moneyFrameName.."SilverButton"]:GetNormalTexture():SetVertexColor(1, 1, 1, alpha)
  _G[moneyFrameName.."SilverButtonText"]:SetTextColor(1, 1, 1, alpha)
  _G[moneyFrameName.."CopperButton"]:GetNormalTexture():SetVertexColor(1, 1, 1, alpha)
  _G[moneyFrameName.."CopperButtonText"]:SetTextColor(1, 1, 1, alpha)
  button.price.Suffix:SetTextColor(1, 1, 1, alpha)
end

function MM:DisableSelectEnchantAuctionButton(button)
  setMoneyButtonTransparency(button, .3)
  button:Disable()
end

function MM:EnableSelectEnchantAuctionButton(button)
  setMoneyButtonTransparency(button, 1)
  button:Enable()
end

function MM:MyAuctions_AUCTION_OWNED_LIST_UPDATE()
  local results = self:GetMyAuctionsResults()
end