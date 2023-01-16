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

local promptButtonWidth = 90

local function createPromptButton(automationTable, text, informStatus, xOffset)
  local button = AceGUI:Create("Button")
  button:SetWidth(promptButtonWidth)
  button:SetText(text)
  button:SetPoint("TOP", automationPopupFrame, "TOP", xOffset, -40)
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

local function createButtonWidgets(automationTable)
  if automationTable.Pause and automationTable:IsPaused() then
    createPromptButton(automationTable, "Continue", "continueClicked", -promptButtonWidth)
    createPromptButton(automationTable, "Stop", "stopClicked", 0)
    createPromptButton(automationTable, "Cancel", "cancelClicked", promptButtonWidth)
  else
    createPromptButton(automationTable, "Start", "startClicked", -.5 * promptButtonWidth)
    createPromptButton(automationTable, "Cancel", "cancelClicked", .5 * promptButtonWidth)
  end
end

local function setPromptSize(automationTable)
    automationPopupFrame:SetSize(automationTable.Pause and automationTable:IsPaused() and 300 or 200, 100)
end

local function showAutomationPrompt()
  local automationTable = automationPopupFrame.AutomationTable
  createButtonWidgets(automationTable)
  setPromptSize(automationTable)
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

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    if pendingTemplate ~= nil then
      releasePopupWidgets()
      if pendingTemplate == "prompt" then
        showAutomationPrompt()
      elseif pendingTemplate == "running" then
        print("showing running")
        -- TODO showAutomationRunning()
      else
        hideAutomationPopup()
      end
      pendingTemplate = nil
    end
  end
)
