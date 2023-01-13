local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

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
  automationPromptFrame:SetSize(256, 192)
  automationPromptFrame.Title = MM:CreateDecoration(automationPromptFrame, 40)
  automationPromptFrame.Title:SetPoint("TOP", 0, 24)
  automationPromptFrame.Title.Text = automationPromptFrame.Title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  automationPromptFrame.Title.Text:SetPoint("CENTER", automationPromptFrame.Title)
  automationPromptFrame.Title.Text:SetText("test")
end

local function showAutomationPrompt(automationName, automationTable)
  -- set title on automation prompt frame and adjust title decoration width
  -- release all widgets if already existing
  -- set up widget container for widget containers
  -- set up widget container for options
  -- set up widget container for estimated time
  -- set up widget container for buttons
  -- add checkbutton widget to options widget container for every relevant option
  -- add text widget to estimated time widget container and set time based on automation and selected options
  -- add button widgets to button widget container based on whether or not the current automation function is paused and set up appropriate scripts
  -- add all widget containers to the main widget container
  -- set prompt size based on the main widget container
  -- anchor based on prompt size
end

MM.AutomationUtil = {}

--LibStub("AceAddon-3.0"):GetAddon("MysticMaestro").AutomationUtil.ShowAutomationPrompt()   for testing
function MM.AutomationUtil.ShowAutomationPrompt(automationName, automationTable)
  if not automationPromptFrame then
    createAutomationPromptFrame()
  end
  showAutomationPrompt(automationName, automationTable)
end
