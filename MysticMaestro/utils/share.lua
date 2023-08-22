-- **********************************************************************
-- EnchantListShare:
--	<local>SpamProtect(name)
-- 	MM:OnEnable()
--	MM:GetEnchantList(wlstrg,sendername)
--	MM:OnCommReceived(prefix, message, distribution, sender)
-- **********************************************************************
local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local playerName = UnitName("player")
local realmName = GetRealmName()
local SpamFilter = {}
local SpamFilterTime = 10
local dewdrop = AceLibrary("Dewdrop-2.0")

-- Colours stored for code readability
local GREY = "|cff999999"
local RED = "|cffff0000"
local WHITE = "|cffFFFFFF"
local GREEN = "|cff1eff00"
local PURPLE = "|cff9F3FFF"
local BLUE = "|cff0070dd"
local ORANGE = "|cffFF8400"

--[[
<local> SpamProtect(name)
Check Spamfilter table
]]
local function SpamProtect(name)
	if not name then return true end
	if SpamFilter[string.lower(name)] then
		if GetTime() - SpamFilter[string.lower(name)] > SpamFilterTime then
			SpamFilter[string.lower(name)] = nil
			return true
		else
			return false
		end
	else
		return true
	end
end

--[[
MM:GetEnchantList(wlstrg,sendername)
Get the EnchantList, Deserialize it and save it in the savedvariables table
]]
function MM:GetEnchantList(wlstrg,sendername)
	local success, wltab = MM:Deserialize(wlstrg)
	if success then
		tinsert(MM.shoppingLists, {Name = wltab.Name, extract = false, enable = false, reforge = false, Enchants = wltab.Enchants})
		MM:MenuInitialize()
	end
end

--[[
StaticPopupDialogs["MYSTICMAESTRO_GET_SHOPPINGLIST"]
This is shown, if someone send you a Enchantlist
]]
StaticPopupDialogs["MYSTICMAESTRO_GET_SHOPPINGLIST"] = {
	text = "%s sends you an Shopping list. Accept?",
	button1 = ACCEPT,
	button2 = CANCEL,
	OnShow = function()
		this:SetFrameStrata("TOOLTIP")
	end,
	OnAccept = function(self,data)
		MM:SendCommMessage("MysticMaestroShoppingList", "AcceptShoppingList", "WHISPER", data)
	end,
	OnCancel = function (self,data)
		MM:SendCommMessage("MysticMaestroShoppingList", "CancelShoppingList", "WHISPER", data)
	end,
	timeout = 15,
	whileDead = 1,
	hideOnEscape = 1
}

--[[
MM:OnCommReceived(prefix, message, distribution, sender)
Incomming messages from AceComm
]]
function MM:ShareComm(prefix, message, distribution, sender)
	if message == "SpamProtect" then
		local _,_,timeleft = string.find( 10-(GetTime() - SpamFilter[string.lower(sender)]), "(%d+)%.")
		DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticMaestro"..": "..RED.."You must wait "..WHITE..timeleft..RED.." seconds before you can send a new EnchantList too "..WHITE..sender..RED..".")
	elseif message == "FinishSend" then
		SpamFilter[string.lower(sender)] = GetTime()
	elseif message == "AcceptShoppingList" then
		local wsltable = {}
			wsltable.Enchants = MM.shoppingLists[MM.shoppingLists.currentSelectedList].Enchants
			wsltable.Name = MM.shoppingLists[MM.shoppingLists.currentSelectedList].Name
		local sendData = MM:Serialize(wsltable)
		MM:SendCommMessage("MysticMaestroShoppingList", sendData, "WHISPER", sender)
	elseif message == "ShoppingListRequest" then
		if MM.db.realm.OPTIONS.enableShare then
			if MM.db.realm.OPTIONS.enableShareCombat then
				if UnitAffectingCombat("player") then
					MM:SendCommMessage("MysticMaestroShoppingList", "CancelShoppingList", "WHISPER", sender)
					DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticMaestro"..": "..WHITE..sender..RED.." tried to send you a shopping list. Rejected because you are in combat.")
				else
					local dialog = StaticPopup_Show("MYSTICMAESTRO_GET_SHOPPINGLIST", sender)
					if ( dialog ) then
						dialog.data = sender
					end
				end
			else
				local dialog = StaticPopup_Show("MYSTICMAESTRO_GET_SHOPPINGLIST", sender)
				if ( dialog ) then
					dialog.data = sender
				end
			end
		else
			MM:SendCommMessage("MysticMaestroShoppingList", "CancelShoppingList", "WHISPER", sender)
		end

	elseif message == "CancelShoppingList" then
		DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticMaestro"..": "..WHITE..sender..RED.." rejects your Shopping List.")
	else
		SpamFilter[string.lower(sender)] = GetTime()
		MM:GetEnchantList(message,sender)
		MM:SendCommMessage("MysticMaestroShoppingList", "FinishSend", "WHISPER", sender)
	end
end

--[[
StaticPopupDialogs["MYSTICMAESTRO_SEND_SHOPPINGLIST"]
This is shown, if you want too share a EnchantList
]]
StaticPopupDialogs["MYSTICMAESTRO_SEND_SHOPPINGLIST"] = {
	text = "Send Shopping List (%s)",
	button1 = "Send",
	button2 = "Cancel",
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnAccept = function()
		local name = _G[this:GetParent():GetName().."EditBox"]:GetText()
		if name == "" then return end
		if string.lower(name) == string.lower(playerName) then
			DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticMaestro"..": "..RED.."You can't send ShoppingLists to yourself.")
		else
			if SpamProtect(string.lower(name)) then
				MM:SendCommMessage("MysticMaestroShoppingList", "ShoppingListRequest", "WHISPER", name)
			else
				local _,_,timeleft = string.find( 10-(GetTime() - SpamFilter[string.lower(name)]), "(%d+)%.")
				DEFAULT_CHAT_FRAME:AddMessage(BLUE.."MysticMaestro"..": "..RED.."You must wait "..WHITE..timeleft..RED.." seconds before you can send a new EnchantList to "..WHITE..name..RED..".")
			end
		end
	end,
	hasEditBox = 1,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

--[[
StaticPopupDialogs["MYSTICMAESTRO_IMPORT_SHOPPINGLIST"]
This is shown, if you want too import an EnchantList
]]
StaticPopupDialogs["MYSTICMAESTRO_IMPORT_SHOPPINGLIST"] = {
	text = "Paste List String To Import",
	button1 = "Import",
	button2 = "Cancel",
	OnShow = function(self)
		dewdrop:Close()
		self:SetFrameStrata("TOOLTIP")
	end,
	OnAccept = function()
		local data = string.sub(_G[this:GetParent():GetName().."EditBox"]:GetText(), 5)
		local success, wltab = MM:Deserialize(data)
	if success then
		tinsert(MM.shoppingLists, {Name = wltab.Name, enable = false, reforge = false, extract = false, Enchants = wltab.Enchants})
		MM:MenuInitialize()
	end
	end,
	hasEditBox = 1,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

function MM:exportString()
	local data = {};
	data.Enchants = MM.shoppingLists[MM.shoppingLists.currentSelectedList].Enchants
	data.Name = MM.shoppingLists[MM.shoppingLists.currentSelectedList].Name;
	Internal_CopyToClipboard("MMSL:"..MM:Serialize(data));
end
