local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local ahExtensionMenu

local function createContainerFrame()
  ahExtensionMenu = CreateFrame("Frame", "MysticMaestroMenuAHExtension", UIParent)
  ahExtensionMenu:SetSize(180, 378)
end

local buttonHeight = 16

local function createListingButton(parent, listingName)
  local listingButton = CreateFrame("Button", listingName, parent)
  listingButton:SetSize(parent:GetWidth(), buttonHeight)
  listingButton:SetHighlightTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight", "ADD")
  listingButton.HighlightTexture = listingButton:GetHighlightTexture()
  listingButton.HighlightTexture:SetTexCoord(0, 1, 0, 0.578125)

  listingButton.price = CreateFrame("Frame", listingName.."Price", listingButton, "SmallMoneyFrameTemplate")
  MoneyFrame_SetType(listingButton.price, "AUCTION")
  listingButton.price:SetPoint("LEFT")
  listingButton.price:SetSize(parent:GetWidth(), buttonHeight)
  return listingButton
end

local auctionScrollFrameWidth = 195
local function createAuctionsScrollFrame(name, title, parent, numRows)
  local scrollFrame = CreateFrame("ScrollFrame", name.."ScrollFrame", parent, "FauxScrollFrameTemplate")
  scrollFrame:SetSize(auctionScrollFrameWidth - 24, buttonHeight * numRows)
  scrollFrame:SetPoint("LEFT")
  scrollFrame:SetScript("OnVerticalScroll",
    function(self, value, itemsHeight, updateFunction)
      
    
    end
  )
  scrollFrame.Title = scrollFrame:CreateFontString(name.."Title", "OVERLAY", "GameTooltipText")
  scrollFrame.Title:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 2)
  scrollFrame.Title:SetText(title)
  scrollFrame.buttons = {}
  for i=1, numRows do
    local listingButton = createListingButton(scrollFrame, name.."Button"..i)
    listingButton:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, (1-i)*buttonHeight)
    table.insert(scrollFrame.buttons, listingButton)
  end
  return scrollFrame
end

local myAuctionsScrollFrame
local myAuctionsButtonCount = 8
local function createMyAuctionsScrollFrame()
  myAuctionsScrollFrame = MM:CreateContainer(ahExtensionMenu, "TOPRIGHT", auctionScrollFrameWidth, buttonHeight * myAuctionsButtonCount, -11, -40)
  myAuctionsScrollFrame.scrollframe = createAuctionsScrollFrame("MysticMaestroMyAuctions", "My Auctions", myAuctionsScrollFrame, myAuctionsButtonCount)
end

local selectedEnchantAuctionsScrollFrame
local selectedEnchantAuctionsButtonCount = 6
local function createSelectedEnchantAuctionsScrollFrame()
  selectedEnchantAuctionsScrollFrame = MM:CreateContainer(ahExtensionMenu, "BOTTOMRIGHT", auctionScrollFrameWidth, buttonHeight * selectedEnchantAuctionsButtonCount, -11, 40)
  selectedEnchantAuctionsScrollFrame.scrollframe = createAuctionsScrollFrame("MysticMaestroSelectedEnchantAuctions", "Selected Enchant Auctions", selectedEnchantAuctionsScrollFrame, selectedEnchantAuctionsButtonCount)
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
  MysticMaestroMenuAHExtension:Show()
  MysticMaestroMenuAHExtension:ClearAllPoints()
  MysticMaestroMenuAHExtension:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", 0, 0)
  MysticMaestroMenuAHExtension:SetParent(AuctionFrame)
end

function MM:HideAHExtension()
  MysticMaestroMenuAHExtension:Hide()
end