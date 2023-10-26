local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local WHITE = "|cffFFFFFF"

local function addLinesTooltip(tt, SpellID, Known)
	if not MM.db.realm.OPTIONS.ttEnable then return end
	local enchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
	if not enchant then return end
	local stats = MM:StatObj(SpellID)
	if MM.db.realm.OPTIONS.ttKnownIndicator and enchant then
		local indicator
		if enchant.Known then
			indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_green", 64, 64, 16, 16, 0, 1, 0, 1)
		else
			indicator = CreateTextureMarkup("Interface\\Icons\\ability_felarakkoa_feldetonation_red", 64, 64, 16, 16, 0, 1, 0, 1)
		end
		tt:AppendText("   "..indicator)
	end
	tt:AddDoubleLine(MM:cTxt(enchant.SpellName, enchant.Quality), MM:DaysAgoString(stats and stats.Last or 0),1,1,0,1,1,1)
	if stats ~= nil and stats.Last ~= nil then
		local temp
		if MM.db.realm.OPTIONS.ttMin then
			temp = GetCoinTextureString(MM:Round(stats.Min or 0.0))
			tt:AddDoubleLine("Current Min", temp,1,1,0,1,1,1)
		end
		if MM.db.realm.OPTIONS.ttMed then
			temp = GetCoinTextureString(MM:Round(stats.Med or 0.0))
			tt:AddDoubleLine("Current Median", temp,1,1,0,1,1,1)
		end
		if MM.db.realm.OPTIONS.ttMean then
			temp = GetCoinTextureString(MM:Round(stats.Mean or 0.0))
			tt:AddDoubleLine("Current Mean", temp,1,1,0,1,1,1)
		end
		if MM.db.realm.OPTIONS.ttMax then
			temp = GetCoinTextureString(MM:Round(stats.Max or 0.0))
			tt:AddDoubleLine("Current Max", temp,1,1,0,1,1,1)
		end
		if MM.db.realm.OPTIONS.ttGPO then
			temp = MM:OrbValue(SpellID)
			tt:AddDoubleLine("Current GPO", MM:cTxt(GetCoinTextureString(temp), temp > 10000 and "gold" or "red"),1,1,0)
		end
		if MM.db.realm.OPTIONS.ttTENMin then
			temp = GetCoinTextureString(MM:Round(stats["10d_Min"] or 0.0))
			tt:AddDoubleLine("10-Day Min", MM:cTxt(temp,"min"),1,1,0)
		end
		if MM.db.realm.OPTIONS.ttTENMed then
			temp = GetCoinTextureString(MM:Round(stats["10d_Med"] or 0.0))
			tt:AddDoubleLine("10-Day Median", MM:cTxt(temp,"min"),1,1,0)
		end
		if MM.db.realm.OPTIONS.ttTENMean then
			temp = GetCoinTextureString(MM:Round(stats["10d_Mean"] or 0.0))
			tt:AddDoubleLine("10-Day Mean", MM:cTxt(temp,"min"),1,1,0)
		end
		if MM.db.realm.OPTIONS.ttTENMax then
			temp = GetCoinTextureString(MM:Round(stats["10d_Max"] or 0.0))
			tt:AddDoubleLine("10-Day Max", MM:cTxt(temp,"min"),1,1,0)
		end
		if MM.db.realm.OPTIONS.ttTENGPO then
			temp = MM:OrbValue(SpellID,"10d_Min")
			tt:AddDoubleLine("10-Day GPO", MM:cTxt(GetCoinTextureString(temp), temp > 10000 and "gold" or "red"),1,1,0)
		end
	end
	tt:AddLine(" ")
	if MM.db.realm.OPTIONS.ttGuildEnable and not Known then
		local knownBye = MM:GetMysticCharList(SpellID)
		if knownBye then
			tt:AddDoubleLine("Enchant Known By:", WHITE.. knownBye)
			tt:AddLine(" ")
		end
	end
end

function MM:TooltipHandlerItem(tooltip)
	local _,link = tooltip:GetItem()
	if not link then return end
	local itemID = GetItemInfoFromHyperlink(link)
	if not itemID then return end
	local enchant = C_MysticEnchant.GetEnchantInfoByItem(itemID)
	if not enchant then return end
	addLinesTooltip(tooltip, enchant.SpellID)
end

local lastLook = {}
-- adds to a spells tooltip what rare worldforged enchants you are missing for it
-- lable for the type is removed if you have it unlearned in your inventory as well
function MM:WorldforgedTooltips(SpellName, SpellID)
	local inCombat = UnitAffectingCombat("player")
	if inCombat and lastLook[SpellID] then
		return lastLook[SpellID]
	elseif inCombat then return end

	-- get list of scrolls and turn it into a keyd table to make it eaiser to check
	local scrolls = {}
	for _, scroll in pairs(C_MysticEnchant.GetMysticScrolls()) do
		scrolls[scroll.Entry] = true
	end
	-- query enchant by spell name only returns if there rare/worldforged and unlearned
	local wfList = ""
	local gathered = {}
	local enchants = C_MysticEnchant.QueryEnchants(99, 1, SpellName, {
		Enum.ECFilters.RE_FILTER_UNKNOWN,
		Enum.ECFilters.RE_FILTER_WORLDFORGED,
		Enum.ECFilters.RE_FILTER_RARE
	})
	if #enchants == 0 then return end
		for _, enchant in pairs(enchants) do
			if not scrolls[enchant.ItemID] then
				local name = string.match(enchant.SpellName,"^[a-zA-Z'-]+")
				
				if gathered[name] then return end
				gathered[name] = true

				wfList = wfList == "" and name or wfList..", "..name
			end
		end
		wfList = WHITE..wfList
		lastLook[SpellID] = "Missing WorldForged Enchants: "..wfList
		return "Missing WorldForged Enchants: "..wfList
end

function MM:TooltipHandlerSpell(tooltip)
	local SpellName, _, SpellID = tooltip:GetSpell()
	local enchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
	if enchant then
		addLinesTooltip(tooltip, SpellID, enchant.Known)
	elseif MM.db.realm.OPTIONS.worldforgedTooltip then
		local worldForgedTip = MM:WorldforgedTooltips(SpellName, SpellID)
		if worldForgedTip then
			tooltip:AddLine(" ")
			tooltip:AddLine(worldForgedTip)
		end
	end
end



-------------------------------------------------------------------------------------
---------------------------- Guild Tooltips------------------------------------------
-------------------------------------------------------------------------------------
local guildName
local playerName = UnitName("player")
function MM:GetPlayerDetails()
	guildName = GetGuildInfo("Player")
	MM.guildName = guildName
	MM.playerName = playerName
end

--Setup for addon database
function MM:GuildTooltips_Setup()
	if not MM.guildTooltips.Accounts[guildName] and guildName then
		MM.guildTooltips.Accounts[guildName] = { accountKey = playerName , charList = {playerName}, displayName = playerName }
	end
	if not MM.guildTooltips.Guilds[guildName] and guildName then
		MM.guildTooltips.Guilds[guildName] = {}
	end
	if guildName then
		if MM.guildTooltips.Accounts[guildName].accountKey ~= playerName then
			local nameChecked = false
				for i , v in pairs(MM.guildTooltips.Accounts[guildName].charList) do
					if v == playerName then
							nameChecked = true
					end
				end
			if not nameChecked then
			table.insert(MM.guildTooltips.Accounts[guildName].charList, playerName)
			end
		end
	end
end

function MM:BuildKnownList()
	local enchants = C_MysticEnchant.QueryEnchants(9999, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN, Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})
	local knownList = {}
		for _, enchant in pairs(enchants) do
			knownList[enchant.SpellID] = 1
		end
		return knownList
end

--Sends enchant list to people with addon in guild
function MM:GuildTooltipsBroadcast(ComID, SpellID, throttle)
	local sendData = {}
	if guildName ~= nil then
		sendData.accountKey = MM.guildTooltips.Accounts[guildName].accountKey
		sendData.displayName = MM.guildTooltips.Accounts[guildName].displayName
		sendData.enchantCount = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN, Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED}))
		sendData.newEnchant = SpellID
		if ComID == "MAESTRO_GUILD_ENCHANT_UPDATE" then
			sendData.knownList = MM:BuildKnownList()
		end
		sendData = MM:Serialize(sendData)
		MM:SendCommMessage(ComID, sendData, "GUILD", playerName, throttle)
	end
end

--Receive enchant list of other people with the addon in guild
function MM:EnchantCom(prefix, message, distribution, sender)
	if sender == playerName  then return end
	if not MM.guildTooltips.Guilds[guildName].enchants then MM.guildTooltips.Guilds[guildName].enchants = {} end
	if not MM.guildTooltips.Guilds[guildName].Accounts then MM.guildTooltips.Guilds[guildName].Accounts = {} end
	local gAccounts = MM.guildTooltips.Guilds[guildName].Accounts
	local enchants = MM.guildTooltips.Guilds[guildName].enchants
	
	local success, data = MM:Deserialize(message)
	if success then
		if not gAccounts[data.accountKey] then gAccounts[data.accountKey] = {} end
		gAccounts[data.accountKey].displayName = data.displayName
		if data.newEnchant then
			if not enchants[data.newEnchant] then enchants[data.newEnchant] = {} end
			enchants[data.newEnchant][data.accountKey] = true
			gAccounts[data.accountKey].enchantCount = data.enchantCount
		end
		local function countCheck()
			if not gAccounts[data.accountKey].enchantCount then return true end
			if data.enchantCount and data.enchantCount ~= gAccounts[data.accountKey].enchantCount then return true end
		end
		if prefix == "MAESTRO_GUILD_ENCHANT_UPDATE" and data.knownList and countCheck() then
			for enchant, _ in pairs(data.knownList) do
				if not enchants[enchant] then enchants[enchant] = {} end
				enchants[enchant][data.accountKey] = true
			end
			gAccounts[data.accountKey].enchantCount = data.enchantCount
		end
		if prefix == "MAESTRO_GUILD_TOOLTIPS_SEND" then
			MM:GuildTooltipsBroadcast("MAESTRO_GUILD_ENCHANT_UPDATE")
		end
	end
end

--Gets the list of people with that enchant to add to tooltip
function MM:GetMysticCharList(SpellID)
	local returnNames
	local guildInfo = MM.guildTooltips.Guilds[guildName]
	if guildInfo and guildInfo.enchants and guildInfo.enchants[SpellID] then
		for char, _ in pairs(guildInfo.enchants[SpellID]) do
			if returnNames and guildInfo.Accounts[char].displayName then
				returnNames = "|cffffffff" .. returnNames .. "|cFF66CDAA||" .. "|cffffffff".. guildInfo.Accounts[char].displayName
			elseif guildInfo.Accounts[char] and guildInfo.Accounts[char].displayName then
				returnNames = "|cffffffff" .. guildInfo.Accounts[char].displayName
			end
		end
		return returnNames
	end
end

--Sends updated display name to other addons if its swaped
function MM:GuildTooltips_DisplayNameUpdate(name, key)
	if guildName ~= nil then
		MM:GuildTooltipsBroadcast("MAESTRO_GUILD_TOOLTIPS_SEND")
	end
end

-- Sends new learned enchant to other addons
function MM:GuildTooltipsEnchantLearned(SpellID)
	if SpellID and guildName then
		MM:GuildTooltipsBroadcast("MAESTRO_GUILD_TOOLTIPS_SEND", SpellID)
	end
end

function MM:EnableGuildTooltips()
	if MM.db.realm.OPTIONS.ttGuildEnable then
		MM:RegisterComm("MAESTRO_GUILD_TOOLTIPS_SEND")
		MM:RegisterComm("MAESTRO_GUILD_ENCHANT_UPDATE")
	else
		MM:UnregisterComm("MAESTRO_GUILD_TOOLTIPS_SEND")
		MM:UnregisterComm("MAESTRO_GUILD_ENCHANT_UPDATE")
	end
end