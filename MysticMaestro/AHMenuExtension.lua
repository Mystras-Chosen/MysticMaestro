local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local ahExtensionMenu

local function createContainerFrame()
  ahExtensionMenu = CreateFrame("Frame", "MysticMaestroMenuAHExtension", UIParent)
  ahExtensionMenu:SetSize(180, 378)
end

local buttonHeight = 16
local auctionScrollFrameWidth = 195

local selectedEnchantAuctionID

function MM:GetSelectedEnchantAuctionID()
  self:SetSelectedEnchantAuctionID(selectedEnchantAuctionID or {})
end

function MM:SetSelectedEnchantAuctionID(id)
  selectedEnchantAuctionID = id
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

  listingButton.statusIcon = listingButton:CreateTexture(nil, "OVERLAY")
  listingButton.statusIcon:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\white_square")
  listingButton.statusIcon:SetSize(buttonHeight, buttonHeight)
  listingButton.statusIcon:SetPoint("LEFT")

  listingButton.itemIcon = listingButton:CreateTexture(nil, "OVERLAY")
  listingButton.itemIcon:SetSize(buttonHeight, buttonHeight)
  listingButton.itemIcon:SetPoint("LEFT", listingButton.statusIcon, "RIGHT", 0, 0)

  listingButton.text = listingButton:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  listingButton.text:SetPoint("LEFT", listingButton.itemIcon, "RIGHT", 0, 0)


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
  
  listingButton.price = CreateFrame("Frame", listingName.."Price", listingButton, "SmallMoneyFrameTemplate")
  MoneyFrame_SetType(listingButton.price, "AUCTION")
  listingButton.price:SetPoint("LEFT")
  listingButton.price:SetSize(parent:GetWidth(), buttonHeight)

  listingButton.price.Suffix = listingButton.price:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  listingButton.price.Suffix:SetPoint("LEFT", listingName.."PriceCopperButton", "RIGHT", 0, 0)

  listingButton:SetScript("OnClick",
    function(self)
      MM:SetSelectedEnchantAuctionID(self.id)
      for _, button in ipairs(parent.buttons) do
        if button.id ~= selectedEnchantAuctionID then
          button.H:Hide()
        end
      end
      self.H:Show()
      self.H:SetDesaturated(false)
    end
  )

  listingButton:SetScript("OnLeave",
    function(self)
      if self.id ~= selectedEnchantAuctionID then
        self.H:Hide()
      end
    end
  )

  listingButton:SetScript("OnEnter",
    function(self)
      if self.id ~= selectedEnchantAuctionID then
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
      button.id = nil
    else
      local result = results[lineplusoffset]
      button.id = result.id
      button.itemIcon:SetTexture(result.icon)
      local reData = GetREData(result.enchantID)

      print(result.enchantID)
      print(reData.spellName)
      button.text:SetText(MM:cTxt(reData.spellName, tostring(reData.quality)))
      button:Show()
    end
  end
end

local function selectEnchantAuctionsScrollFrame_Update(self)
  local buttons = self.buttons
  local results = MM:GetSelectedEnchantAuctionsResults()
  FauxScrollFrame_Update(self, #results, #buttons, buttonHeight, nil, nil, nil, nil, nil, nil, true)
  local offset = FauxScrollFrame_GetOffset(self)

  -- go through each button and set visibility and associate with results
  for line = 1, #buttons do
    local lineplusoffset = line + offset
    local button = buttons[line]
    MM:EnableSelectEnchantAuctionButton(button)
    if lineplusoffset > #results then
      button:Hide()
      button.id = nil
    else
      local result = results[lineplusoffset]
      button.price.Suffix:SetText(result.yours and "  (yours)" or nil)
      MoneyFrame_Update(button.price, result.buyoutPrice)
      button.id = result.id
      button:Show()
      MM:EnableSelectEnchantAuctionButton(button)
      if button.id == selectedEnchantAuctionID then
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








local myAuctionsScrollFrameContainer
local myAuctionsButtonCount = 10
local function createMyAuctionsScrollFrame()
  myAuctionsScrollFrameContainer = MM:CreateContainer(ahExtensionMenu, "TOPRIGHT", auctionScrollFrameWidth, buttonHeight * myAuctionsButtonCount, -11, -50)
  myAuctionsScrollFrameContainer.scrollFrame = createAuctionsScrollFrame(
    "MysticMaestroMyAuctions",
    "My Auctions",
    myAuctionsScrollFrameContainer,
    myAuctionsButtonCount,
    createMyAuctionsButton
  )
  myAuctionsScrollFrameContainer.scrollFrame:SetScript("OnVerticalScroll",
    function(self, offset)
      FauxScrollFrame_OnVerticalScroll(self, offset, buttonHeight, myAuctionsScrollFrame_Update)
    end
  )
end

local selectedEnchantAuctionsScrollFrameContainer
local selectedEnchantAuctionsButtonCount = 6
local function createSelectedEnchantAuctionsScrollFrame()
  selectedEnchantAuctionsScrollFrameContainer = MM:CreateContainer(ahExtensionMenu, "BOTTOMRIGHT", auctionScrollFrameWidth, buttonHeight * selectedEnchantAuctionsButtonCount, -11, 40)
  selectedEnchantAuctionsScrollFrameContainer.scrollFrame = createAuctionsScrollFrame(
    "MysticMaestroSelectedEnchantAuctions",
    "Selected Enchant Auctions",
    selectedEnchantAuctionsScrollFrameContainer,
    selectedEnchantAuctionsButtonCount,
    createSelectedAuctionsButton
  )
  selectedEnchantAuctionsScrollFrameContainer.scrollFrame:SetScript("OnVerticalScroll",
    function(self, offset)
      FauxScrollFrame_OnVerticalScroll(self, offset, buttonHeight, selectEnchantAuctionsScrollFrame_Update)
    end
  )
end

local function initAHExtension()
  createContainerFrame()
  createMyAuctionsScrollFrame()
  createSelectedEnchantAuctionsScrollFrame()
end

function MM:ShowAHExtension()
  if not MysticMaestroMenuAHExtension then
    initAHExtension()
  end
  myAuctionsScrollFrame_Update(myAuctionsScrollFrameContainer.scrollFrame)
  selectEnchantAuctionsScrollFrame_Update(selectedEnchantAuctionsScrollFrameContainer.scrollFrame)
  MysticMaestroMenuAHExtension:Show()
  MysticMaestroMenuAHExtension:ClearAllPoints()
  MysticMaestroMenuAHExtension:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", 0, 0)
  MysticMaestroMenuAHExtension:SetParent(AuctionFrame)
end

function MM:HideAHExtension()
  MysticMaestroMenuAHExtension:Hide()
  self:ClearMyAuctions()
  self:ClearSelectedEnchantAuctions()
end

function MM:PopulateMyAuctions(results)
  myAuctionsScrollFrame_Update(myAuctionsScrollFrameContainer.scrollFrame)
end

function MM:PopulateSelectedEnchantAuctions(results)
  self:SetSelectedEnchantAuctionsResults(results)
  selectEnchantAuctionsScrollFrame_Update(selectedEnchantAuctionsScrollFrameContainer.scrollFrame)
end

local function getMyAuctionInfo(i)
  local _, icon, _, quality, _, _, _, _, buyoutPrice = GetAuctionItemInfo("owner", i)
  local enchantID = GetAuctionItemMysticEnchant("owner", i)
  return icon, quality, buyoutPrice, enchantID
end

function MM:GetMyAuctionsResults()
  local myAuctionsResults = {}
  local numPlayerAuctions = GetNumAuctionItems("owner")
  for i=1, numPlayerAuctions do
    print(getMyAuctionInfo(i))
    local icon, quality, buyoutPrice, enchantID = getMyAuctionInfo(i)
    if buyoutPrice and quality >= 3 and enchantID then
      table.insert(myAuctionsResults, {
        id = i,
        icon = icon,
        buyoutPrice = buyoutPrice,
        enchantID = enchantID
      })
    end
  end
  return myAuctionsResults
end

local selectedEnchantAuctionsResults
function MM:GetSelectedEnchantAuctionsResults()
  self:SetSelectedEnchantAuctionsResults(selectedEnchantAuctionsResults or {})
  return selectedEnchantAuctionsResults
end

function MM:SetSelectedEnchantAuctionsResults(results)
  self:SetSelectedEnchantAuctionID(nil)
  selectedEnchantAuctionsResults = results
end

function MM:ClearMyAuctions()
  self:PopulateMyAuctions({})
end

function MM:ClearSelectedEnchantAuctions()
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