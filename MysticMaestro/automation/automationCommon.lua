local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local automationPromptFrame

local function createAutomationPromptFrame()
  -- set up widget container
  automationPromptFrame = CreateFrame("Frame", nil, MysticMaestroMenu)
  automationPromptFrame:SetResizable(false)
  automationPromptFrame:SetFrameStrata("DIALOG")
  automationPromptFrame:SetBackdrop(MM.FrameBackdrop)
  automationPromptFrame:SetBackdropColor(0, 0, 0, 1)
  automationPromptFrame:SetToplevel(true)
  automationPromptFrame:SetPoint("CENTER")
  automationPromptFrame.Title = MM:CreateDecoration(automationPromptFrame, 40)
  automationPromptFrame.Title:SetPoint("TOP", 0, 8)
  automationPromptFrame.Title.Text = automationPromptFrame.Title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  automationPromptFrame.Title.Text:SetPoint("CENTER", automationPromptFrame.Title)
end

local function setPromptAutomation(automationName, automationTable)
  automationPromptFrame.Title.Text:SetText(automationName)
  automationPromptFrame.Title:SetSize(automationPromptFrame.Title.Text:GetWidth() + 8, 40)
  automationPromptFrame.AutomationTable = automationTable
end

local promptWidgets = {}

local function releasePromptWidgets()
  for _, widget in ipairs(promptWidgets) do
    widget:Release()
  end
  promptWidgets = {}
end

local promptButtonWidth = 90

local function createPromptButton(automationTable, text, informStatus, xOffset)
  local button = AceGUI:Create("Button")
  button:SetWidth(promptButtonWidth)
  button:SetText(text)
  button:SetPoint("TOP", automationPromptFrame, "TOP", xOffset, -40)
  button:SetCallback("OnClick",
    function()
      MM.AutomationUtil.HideAutomationPrompt()
      MM.AutomationManager:Inform(automationTable, informStatus)
    end
  )
  button.frame:SetParent(automationPromptFrame)
  button.frame:Show()
  table.insert(promptWidgets, button)
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
    automationPromptFrame:SetSize(automationTable.Pause and automationTable:IsPaused() and 300 or 200, 100)
end

local function showAutomationPrompt()
  local automationTable = automationPromptFrame.AutomationTable
  releasePromptWidgets()
  createButtonWidgets(automationTable)
  setPromptSize(automationTable)
  automationPromptFrame:Show()
end

local function hideAutomationPrompt()
  releasePromptWidgets()
  automationPromptFrame:Hide()
end

local pendingVisibilityStatus

MM.AutomationUtil = {}

function MM.AutomationUtil.ShowAutomationPrompt(automationName, automationTable)
  if not automationPromptFrame then
    createAutomationPromptFrame()
  end
  setPromptAutomation(automationName, automationTable)
  pendingVisibilityStatus = true
end

function MM.AutomationUtil.HideAutomationPrompt()
  pendingVisibilityStatus = false
end

MM.OnUpdateFrame:HookScript("OnUpdate",
  function()
    if pendingVisibilityStatus ~= nil then
      if pendingVisibilityStatus then
        showAutomationPrompt()
      else
        hideAutomationPrompt()
      end
      pendingVisibilityStatus = nil
    end
  end
)
