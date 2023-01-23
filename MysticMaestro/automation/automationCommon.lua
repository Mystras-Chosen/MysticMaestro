local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local automationPopupFrame

local AnimateTexCoords = AnimateTexCoords

local function createAutomationPopupFrame()
  -- set up widget container
  automationPopupFrame = CreateFrame("Frame", nil, MysticMaestroMenu)
  automationPopupFrame:SetResizable(false)
  automationPopupFrame:SetFrameStrata("DIALOG")
  automationPopupFrame:SetBackdrop(MM.FrameBackdrop)
  automationPopupFrame:SetBackdropColor(0, 0, 0, 1)
  automationPopupFrame:SetToplevel(true)
  automationPopupFrame:SetPoint("CENTER")
  automationPopupFrame.Title = MM:CreateDecoration(automationPopupFrame, 40)
  automationPopupFrame.Title:SetPoint("TOP", 0, 12)
  automationPopupFrame.Title.Text = automationPopupFrame.Title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  automationPopupFrame.Title.Text:SetPoint("CENTER", automationPopupFrame.Title)
  -- setup progress bar variables
  local statusBarAtlas = "skillbar_fill_flipbook_alchemy"
  -- local statusBarAtlas = "skillbar_fill_flipbook_blacksmithing"
  -- local statusBarAtlas = "skillbar_fill_flipbook_enchanting"
  -- local statusBarAtlas = "skillbar_fill_flipbook_engineering"
  -- local statusBarAtlas = "skillbar_fill_flipbook_inscription"
  -- local statusBarAtlas = "skillbar_fill_flipbook_jewelcrafting"
  -- local statusBarAtlas = "skillbar_fill_flipbook_leatherworking"
  -- local statusBarAtlas = "skillbar_fill_flipbook_tailoring"
  -- local statusBarAtlas = "skillbar_fill_flipbook_herbalism"
  -- local statusBarAtlas = "skillbar_fill_flipbook_mining"
  -- local statusBarAtlas = "skillbar_fill_flipbook_skinning"
  -- local statusBarAtlas = "skillbar_fill_flipbook_cooking"
  -- local statusBarAtlas = "skillbar_fill_flipbook_fishing"
  local atlas = AtlasUtil:GetAtlasInfo(statusBarAtlas)
  local frameWidth, frameHeight = 856, 34
  local frames = (atlas.height / frameHeight) * 2
  local fps = 26
  automationPopupFrame.ProgressBar = CreateFrame("Frame", nil, automationPopupFrame, "BetterStatusBarTemplate")
  automationPopupFrame.ProgressBar:SetPoint("CENTER", automationPopupFrame, "TOP", 0, -53)
  automationPopupFrame.ProgressBar:SetSize(230, 16)
  automationPopupFrame.ProgressBar:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true,
    tileSize = 12
  })
  automationPopupFrame.ProgressBar:SetBackdropColor(0, 0, 0, .8)
  automationPopupFrame.ProgressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  automationPopupFrame.ProgressBar:SetStatusBarAtlas(statusBarAtlas)
  automationPopupFrame.ProgressBar.Edge = CreateFrame("Frame", nil, automationPopupFrame.ProgressBar)
  automationPopupFrame.ProgressBar.Edge:SetPoint("TOPLEFT", automationPopupFrame.ProgressBar, "TOPLEFT", -5, 5)
  automationPopupFrame.ProgressBar.Edge:SetPoint("BOTTOMRIGHT", automationPopupFrame.ProgressBar, "BOTTOMRIGHT", 5, -5)
  automationPopupFrame.ProgressBar.Edge:SetBackdrop({
    edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
  })
  automationPopupFrame.ProgressBar:SetStatusBarFlipbookAtlas(statusBarAtlas, frameWidth, frameHeight, frames, fps)
  automationPopupFrame.ProgressBar.flipbook:Play()
  automationPopupFrame.ProgressBar:Hide()

  automationPopupFrame.WaitIndicator = CreateFrame("Frame", nil, automationPopupFrame)
  automationPopupFrame.WaitIndicator:SetPoint("CENTER", automationPopupFrame, "BOTTOMLEFT", 54, 48)
  automationPopupFrame.WaitIndicator:SetSize(54, 54)
  automationPopupFrame.WaitIndicator.T = automationPopupFrame.WaitIndicator:CreateTexture(nil, "ARTWORK")
  automationPopupFrame.WaitIndicator.T:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\spinning_arrows")
  automationPopupFrame.WaitIndicator.T:SetAllPoints()
  automationPopupFrame.WaitIndicator:SetScript("OnUpdate",
    function(self, elapsed)
      AnimateTexCoords(self.T, 1024, 1024, 128, 128, 50, elapsed, .02)
    end
  )
  automationPopupFrame.WaitIndicator:Hide()

  automationPopupFrame.AlertIndicator = CreateFrame("Frame", nil, automationPopupFrame)
  automationPopupFrame.AlertIndicator:SetPoint("CENTER", automationPopupFrame, "TOPLEFT", 54, -66)
  automationPopupFrame.AlertIndicator:SetSize(48, 48)
  automationPopupFrame.AlertIndicator.T = automationPopupFrame.AlertIndicator:CreateTexture(nil, "ARTWORK")
  automationPopupFrame.AlertIndicator.T:SetTexture(STATICPOPUP_TEXTURE_ALERT)
  automationPopupFrame.AlertIndicator.T:SetAllPoints()
  automationPopupFrame.AlertIndicator:Hide()
end

local function setPopupAutomation(automationName, automationTable)
  automationPopupFrame.Title.Text:SetText(automationName)
  automationPopupFrame.Title:SetSize(automationPopupFrame.Title.Text:GetWidth() + 8, 40)
  automationPopupFrame.AutomationTable = automationTable
end

local popupWidgets = {}

local function releasePopupWidgets()
  for _, widget in ipairs(popupWidgets) do
    widget:Release()
  end
  popupWidgets = {}
end

local popupButtonWidth = 90

local function createButtonWidget(automationTable, text, informStatus, xOffset, yOffset)
  local button = AceGUI:Create("Button")
  button:SetWidth(popupButtonWidth)
  button:SetText(text)
  button:SetPoint("TOP", automationPopupFrame, "TOP", xOffset, yOffset)
  button:SetCallback("OnClick",
    function()
      MM.AutomationUtil.HideAutomationPopup()
      MM.AutomationManager:Inform(automationTable, informStatus)
    end
  )
  button.frame:SetParent(automationPopupFrame)
  button.frame:Show()
  table.insert(popupWidgets, button)
  return button
end

local function createLabelWidget(text, textHeight, width, height, xOffset, yOffset)
  local label = AceGUI:Create("Label")
  label:SetPoint("TOP", automationPopupFrame, "TOP", xOffset, yOffset)
  label:SetWidth(width)
  label:SetHeight(height)
  label:SetText(text)
  label:SetFont(GameFontHighlightSmall:GetFont(), textHeight)
  label.frame:SetParent(automationPopupFrame)
  label.frame:Show()
  table.insert(popupWidgets, label)
  return label

end

local function hideAutomationPopup()
  automationPopupFrame:Hide()
  automationPopupFrame.ProgressBar:Hide()
  releasePopupWidgets()
end

MM.AutomationUtil = {}

local function validateInterface(template)
  return template.Show and type(template.Show) == "function"
    and template.Hide and type(template.Hide) == "function"
end

local registeredTemplates = {}
function MM.AutomationUtil.RegisterPopupTemplate(name, template)
  if validateInterface(template) then
    registeredTemplates[name] = template
  else
    MM:Print("ERROR: Automation popup template \"".. tostring(name) .. "\" has an invalid interface")
  end
end

local pendingTemplate, currentTemplate

-- schedules the popup to show or hide in the OnUpdate script since Show and Hide can be called on the same frame
function MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, templateName)
  if not automationPopupFrame then
    createAutomationPopupFrame()
  end
  setPopupAutomation(automationName, automationTable)
  if registeredTemplates[templateName] then
    pendingTemplate = templateName
  else
    MM:Print("ERROR: Unrecognized template name: " .. pendingTemplate)
  end
end

function MM.AutomationUtil.HideAutomationPopup()
  pendingTemplate = false
end

local displayMode

function MM.AutomationUtil.SetProgressBarDisplayMode(mode)
  displayMode = mode
end

function MM.AutomationUtil.SetProgressBarValues(current, max)
  automationPopupFrame.ProgressBar:SetValue(current)
  if displayMode == "value" then
    automationPopupFrame.ProgressBar:SetFormattedText("%d / %d", current, max)
  elseif displayMode == "percent" then
    automationPopupFrame.ProgressBar:SetFormattedText("%d %%", math.floor(current/max * 100))
  elseif displayMode == "none" then
    automationPopupFrame.ProgressBar:SetText("")
  elseif display ~= nil then
    MM:Print("ERROR: Automation popup progress bar has invalid display mode")
  else
    MM:Print("ERROR: Automation popup progress bar display mode not set")
  end
end

function MM.AutomationUtil.SetProgressBarMinMax(min, max)
  automationPopupFrame.ProgressBar:SetMinMaxValues(min, max)
end

function MM.AutomationUtil.AppendProgressBarText(appendText, appendBefore)
  local existingText = automationPopupFrame.ProgressBar.Text:GetText() or ""
  automationPopupFrame.ProgressBar:SetText(appendBefore and appendText .. existingText or existingText .. appendText)
end

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    if pendingTemplate ~= nil then
      releasePopupWidgets()
      if pendingTemplate then
        if currentTemplate then
          registeredTemplates[currentTemplate].Hide()
        end
        currentTemplate = pendingTemplate
        registeredTemplates[currentTemplate].Show()
        automationPopupFrame:Show()
      else
        registeredTemplates[currentTemplate].Hide()
        currentTemplate = nil
        automationPopupFrame:Hide()
      end
      pendingTemplate = nil
    end
  end
)


local function createPromptButtonWidgets(automationTable)
  if automationTable.Pause and automationTable:IsPaused() then
    createButtonWidget(automationTable, "Continue", "continueClicked", -popupButtonWidth, -40)
    createButtonWidget(automationTable, "Stop", "stopClicked", 0, -40)
    createButtonWidget(automationTable, "Cancel", "cancelClicked", popupButtonWidth, -40)
  else
    createButtonWidget(automationTable, "Start", "startClicked", -.5 * popupButtonWidth, -40)
    createButtonWidget(automationTable, "Cancel", "cancelClicked", .5 * popupButtonWidth, -40)
  end
end

local function setPromptSize(automationTable)
    automationPopupFrame:SetSize(automationTable.Pause and automationTable:IsPaused() and 320 or 230, 100)
end

MM.AutomationUtil.RegisterPopupTemplate("prompt",
  {
    Show = function()
      local automationTable = automationPopupFrame.AutomationTable
      createPromptButtonWidgets(automationTable)
      setPromptSize(automationTable)
    end,
    Hide = function()
      -- no special handling
    end
  }
)


local function createRunningWidgets(automationTable)
  if automationTable.Pause then
    createButtonWidget(automationTable, "Pause", "pauseClicked", -45, -70)
  end
  createButtonWidget(automationTable, "Stop", "stopClicked", automationTable.Pause and 45 or 0, -70)
end

local function setRunningSize(w, h)
  if w and h then
    automationPopupFrame:SetSize(w, h)
  else
    automationPopupFrame:SetSize(300, 120)
  end
end

MM.AutomationUtil.RegisterPopupTemplate("running",
  {
    Show = function()
      local automationTable = automationPopupFrame.AutomationTable
      createRunningWidgets(automationTable)
      setRunningSize()
      automationPopupFrame.ProgressBar:Show()
    end,
    Hide = function()
      automationPopupFrame.ProgressBar:Hide()
    end
  }
)

local function setNoPostProcessingSize()
  setRunningSize()
end

MM.AutomationUtil.RegisterPopupTemplate("noPostProcessing",
  {
    Show = function()
      local automationTable = automationPopupFrame.AutomationTable
      createButtonWidget(automationTable, "Done", "doneClicked", 0, -70)
      setNoPostProcessingSize()
      automationPopupFrame.ProgressBar:Show() -- progress bar should already be sized and playing
    end,
    Hide = function()
      automationPopupFrame.ProgressBar:Hide()
    end
  }
)

local function setGetAllScanSize()
  automationPopupFrame:SetSize(380, 180)
end

MM.AutomationUtil.RegisterPopupTemplate("getAllScan",
  {
    Show = function()
      local automationTable = automationPopupFrame.AutomationTable
      createButtonWidget(automationTable, "Stop", "stopClicked", 0, -122)
      createLabelWidget("First GetAll scan after server restart may take up to 12 minutes.\n\nDO NOT CLOSE AUCTION HOUSE", 14, 240, 80, 32, -34)
      setGetAllScanSize()
      automationPopupFrame.WaitIndicator:Show()
      automationPopupFrame.AlertIndicator:Show()
    end,
    Hide = function()
      automationPopupFrame.WaitIndicator:Hide()
      automationPopupFrame.AlertIndicator:Hide()
    end
  }
)