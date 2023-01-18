local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local automationPopupFrame

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
  automationPopupFrame.Title:SetPoint("TOP", 0, 8)
  automationPopupFrame.Title.Text = automationPopupFrame.Title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  automationPopupFrame.Title.Text:SetPoint("CENTER", automationPopupFrame.Title)
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
  --automationPopupFrame.ProgressBar:SetStatusBarAtlas("skillbar_fill_flipbook_alchemy")
  automationPopupFrame.ProgressBar.Edge = CreateFrame("Frame", nil, automationPopupFrame.ProgressBar)
  automationPopupFrame.ProgressBar.Edge:SetPoint("TOPLEFT", automationPopupFrame.ProgressBar, "TOPLEFT", -5, 5)
  automationPopupFrame.ProgressBar.Edge:SetPoint("BOTTOMRIGHT", automationPopupFrame.ProgressBar, "BOTTOMRIGHT", 5, -5)
  automationPopupFrame.ProgressBar.Edge:SetBackdrop({
    edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
  })

  automationPopupFrame.ProgressBar:Hide()
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
  automationPopupFrame.ProgressBar:Hide()
end

local promptButtonWidth = 90

local function createPromptButton(automationTable, text, informStatus, xOffset, yOffset)
  local button = AceGUI:Create("Button")
  button:SetWidth(promptButtonWidth)
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

local function createPromptButtonWidgets(automationTable)
  if automationTable.Pause and automationTable:IsPaused() then
    createPromptButton(automationTable, "Continue", "continueClicked", -promptButtonWidth, -40)
    createPromptButton(automationTable, "Stop", "stopClicked", 0, -40)
    createPromptButton(automationTable, "Cancel", "cancelClicked", promptButtonWidth, -40)
  else
    createPromptButton(automationTable, "Start", "startClicked", -.5 * promptButtonWidth, -40)
    createPromptButton(automationTable, "Cancel", "cancelClicked", .5 * promptButtonWidth, -40)
  end
end

local function setPromptSize(automationTable)
    automationPopupFrame:SetSize(automationTable.Pause and automationTable:IsPaused() and 320 or 230, 100)
end

local function showAutomationPrompt()
  local automationTable = automationPopupFrame.AutomationTable
  createPromptButtonWidgets(automationTable)
  setPromptSize(automationTable)
  automationPopupFrame:Show()
end


local function createRunningWidgets(automationTable)
  if automationTable.Pause then
    createPromptButton(automationTable, "Pause", "pauseClicked", -45, -70)
  end
  createPromptButton(automationTable, "Stop", "stopClicked", automationTable.Pause and 45 or 0, -70)
end

local function setRunningSize(automationTable)
  automationPopupFrame:SetSize(300, 120)
end

local function showAutomationRunning()
  local automationTable = automationPopupFrame.AutomationTable
  createRunningWidgets(automationTable)
  setRunningSize(automationTable)
  automationPopupFrame.ProgressBar:Show()
  automationPopupFrame:Show()
end

local function hideAutomationPopup()
  automationPopupFrame:Hide()
end

MM.AutomationUtil = {}

local pendingTemplate

local validTemplates = {
  ["prompt"] = true,
  ["running"] = true
}

-- schedules the popup to show or hide in the OnUpdate script since Show and Hide can be called on the same frame
function MM.AutomationUtil.ShowAutomationPopup(automationName, automationTable, templateName)
  if not automationPopupFrame then
    createAutomationPopupFrame()
  end
  setPopupAutomation(automationName, automationTable)
  if validTemplates[templateName] then
    pendingTemplate = templateName
  else
    MM:Print("ERROR: Unrecognized template name: " .. pendingTemplate)
  end
end

function MM.AutomationUtil.HideAutomationPopup()
  pendingTemplate = false
end

local function calcBarColor(current, max)
  local percent = current / max
  if percent <= .5 then
      return 1, 2 * percent, 0, 1
  else
    return (2 - 2 * percent), 1, 0, 1
  end
end

function MM.AutomationUtil.SetProgressBarValues(current, max)
  automationPopupFrame.ProgressBar:SetMinMaxValues(0, max)
	automationPopupFrame.ProgressBar:SetValue(current)
	automationPopupFrame.ProgressBar:SetFormattedText("%d / %d", current, max)
  automationPopupFrame.ProgressBar:SetStatusBarColor(calcBarColor(current, max))
end

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    if pendingTemplate ~= nil then
      releasePopupWidgets()
      if pendingTemplate == "prompt" then
        showAutomationPrompt()
      elseif pendingTemplate == "running" then
        print("showing running")
        showAutomationRunning()
      else
        hideAutomationPopup()
      end
      pendingTemplate = nil
    end
  end
)
