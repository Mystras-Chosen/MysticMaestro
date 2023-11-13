local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
-- Colours stored for code readability
local WHITE = "|cffFFFFFF"
local GREEN = "|cff1eff00"
local BLUE = "|cff0070dd"
local ORANGE = "|cffFF8400"
local GOLD  = "|cffffcc00"
local LIGHTBLUE = "|cFFADD8E6"
local ORANGE2 = "|cFFFFA500"
local CYAN =  "|cff00ffff"

-- API for other addons to get information about an RE
function Maestro(reID)
	return MM:DeepClone(MM:StatObj(reID))
end

function MM:Round(num, numDecimalPlaces, alwaysDown)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + (alwaysDown and 0 or 0.5)) / mult
end

function MM:Compare(a,b,comparitor,bigger)
	a = a or math.huge
	b = b or math.huge
	if a == math.huge or b == math.huge then
		if bigger then
			return a > b
		else
			return a < b
		end
	end
	
	if comparitor == ">" then
		return a > b
	elseif comparitor == ">=" then
		return a >= b
	elseif comparitor == "<" then
		return a < b
	elseif comparitor == "<=" then
		return a <= b
	elseif comparitor == "==" then
		return a == b
	elseif comparitor == "~=" then
		return a ~= b
	end
end

local function findAboveMin(list)
	for _, v in pairs(list) do
		if v.buyoutPrice >= MM.db.realm.OPTIONS.postMin * 10000 then
			return MM:PriceCorrection(v,list)
		end
	end
	return MM.db.realm.OPTIONS.postDefault * 10000, true
end

local function ifUnder(obj,list)
	local fetched
	if MM.db.realm.OPTIONS.postIfUnder == "UNDERCUT" then
		return obj.buyoutPrice, obj.yours
	elseif MM.db.realm.OPTIONS.postIfUnder == "IGNORE" then
		return findAboveMin(list)
	elseif MM.db.realm.OPTIONS.postIfUnder == "DEFAULT" then
		return MM.db.realm.OPTIONS.postDefault * 10000, true
	elseif MM.db.realm.OPTIONS.postIfUnder == "MAX" then
		return MM.db.realm.OPTIONS.postMax * 10000, true
	elseif MM.db.realm.OPTIONS.postIfUnder == "KEEP" then
		return false
	elseif MM.db.realm.OPTIONS.postIfUnder == "MEAN10" then
		fetched = MM:StatObj(obj.SpellID)
		return fetched and fetched["10d_Mean"] or MM.db.realm.OPTIONS.postDefault * 10000, true
	elseif MM.db.realm.OPTIONS.postIfUnder == "MEDIAN10" then
		fetched = MM:StatObj(obj.SpellID)
		return fetched and fetched["10d_Med"] or MM.db.realm.OPTIONS.postDefault * 10000, true
	elseif MM.db.realm.OPTIONS.postIfUnder == "MAX10" then
		fetched = MM:StatObj(obj.SpellID)
		return fetched and fetched["10d_Max"] or (MM.db.realm.OPTIONS.postMax * 10000), true
	end
end

local function ifOver(obj)
	local fetched
	if MM.db.realm.OPTIONS.postIfOver == "UNDERCUT" then
		return obj.buyoutPrice, obj.yours
	elseif MM.db.realm.OPTIONS.postIfOver == "DEFAULT" then
		return MM.db.realm.OPTIONS.postDefault * 10000, true
	elseif MM.db.realm.OPTIONS.postIfOver == "MAX" then
		return MM.db.realm.OPTIONS.postMax * 10000, true
	elseif MM.db.realm.OPTIONS.postIfOver == "MEAN10" then
		fetched = MM:StatObj(obj.SpellID)
		return fetched and fetched["10d_Mean"] or (MM.db.realm.OPTIONS.postDefault * 10000), true
	elseif MM.db.realm.OPTIONS.postIfOver == "MEDIAN10" then
		fetched = MM:StatObj(obj.SpellID)
		return fetched and fetched["10d_Med"] or (MM.db.realm.OPTIONS.postDefault * 10000), true
	elseif MM.db.realm.OPTIONS.postIfOver == "MAX10" then
		fetched = MM:StatObj(obj.SpellID)
		return fetched and fetched["10d_Max"] or (MM.db.realm.OPTIONS.postMax * 10000), true
	end
end

-- When listing an auction, we determine what kind of undercut to perform.
-- Using the two functions from above, we determine how to price the enchant.
function MM:PriceCorrection(obj,list)
	if obj.buyoutPrice < MM.db.realm.OPTIONS.postMin * 10000 then
		return ifUnder(obj,list)
	elseif obj.buyoutPrice > MM.db.realm.OPTIONS.postMax * 10000 then
		return ifOver(obj)
	else
		return obj.buyoutPrice, obj.yours
	end
end

local EnchantQualitySettings = {
	[5] = "\124cFFFF8000", -- 255, 128, 0
	[4] = "\124cFFA335EE", -- 163, 53, 238
	[3] = "\124cFF0070DD", -- 0, 112, 221
	[2] = "\124cFF1EFF00", -- 30, 255, 0
}

-- Creates a Quality colored item link for use in text
function MM:ItemLinkRE(SpellID)
	if SpellID == 0 then return "" end
	local enchantData = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
	if not enchantData then return "" end
	local quality = Enum.EnchantQualityEnum[enchantData.Quality]
	local color = EnchantQualitySettings[quality]
	return color .. "\124Hspell:" .. enchantData.SpellID .. "\124h[" .. enchantData.SpellName .. "]\124h\124r"
end

-- Inhouse version of the previous function
function MM:GetREInSlot(bag,slot)
	local itemLink = select(7, GetContainerItemInfo(bag, slot))
	if not itemLink then return end
	local itemID = GetItemInfoFromHyperlink(itemLink)
	if not itemID then return end
	local enchant = C_MysticEnchant.GetEnchantInfoByItem(itemID)
	return enchant
end

-- split up cache by bagID so BAG_UPDATE doesn't have to refresh the entire cache every time
local sellableREsInBagsCache = setmetatable({ [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }, {
	__index = function(t, SpellID)
		local count = 0
		for bagID=0, 4 do
			count = count + (t[bagID][SpellID] or 0)
		end
		return count
	end
})

-- get number of sellable REs with that ID in bags
-- pass "blanks" to get the number of blank trinkets in bags
function MM:CountSellableREInBags(SpellID)
	return sellableREsInBagsCache[SpellID]
end

-- Create a cache of the scrolls available in bags
function MM:UpdateSellableREsCache(bagID)
	local newContainerCache = {}
	local itemName
	for containerIndex=1, GetContainerNumSlots(bagID) do
		local _,count,_,_,_,_,itemLink = GetContainerItemInfo(bagID, containerIndex)
		local enchant = MM:GetREInSlot(bagID, containerIndex)
		if itemLink then
			itemName = GetItemInfo(itemLink)
			if enchant and not enchant.IsWorldforged then
				newContainerCache[enchant.SpellID] = (newContainerCache[enchant.SpellID] or 0) + (count or 1)
			elseif MM:IsUntarnished(itemName) then
				newContainerCache["blanks"] = (newContainerCache["blanks"] or 0) + 1
			end
		end
	end
	sellableREsInBagsCache[bagID] = newContainerCache
end

-- cache helper
function MM:ResetSellableREsCache()
	for bagID=0, 4 do
		self:UpdateSellableREsCache(bagID)
	end
end

-- cache helper
function MM:GetSellableREs()
	local sellableREs = {}
	for bagID=0, 4 do
		for SpellID, count in pairs(sellableREsInBagsCache[bagID]) do
			if SpellID ~= "blanks" then
				sellableREs[SpellID] = count
			end
		end
	end
	return sellableREs
end

function MM:CompareTime(a,b)
	local time = difftime(a,b)
	local yDif = floor(time / 31536000)
	local dDif = floor(mod(time, 31536000) / 86400)
	local hDif = floor(mod(time, 86400) / 3600)
	local mDif = floor(mod(time, 3600) / 60)
	local sDif = floor(mod(time, 60))
	return {year = yDif, day = dDif, hour = hDif, min = mDif, sec = sDif}
end

function MM:DaysAgoString(stamp)
	local string = ""
	if stamp == 0 then return "No Scan Data" end
	local dif = MM:CompareTime(time(),stamp)
	if dif.year > 0 then
		string = string .. dif.year .. " year" .. (dif.year > 1 and "s" or "")
	elseif dif.day > 0 then
		string = string .. dif.day .. " day" .. (dif.day > 1 and "s" or "")
	elseif dif.hour > 0 then
		string = string .. dif.hour .. " hour" .. (dif.hour > 1 and "s" or "")
	elseif dif.min > 0 then
		string = string .. dif.min .. " minute" .. (dif.min > 1 and "s" or "")
	elseif dif.sec > 0 then
		string = string .. dif.sec .. " second" .. (dif.sec > 1 and "s" or "")
	end
	if string ~= "" then
		string = string .. " ago."
	end
	return string
end

function MM:TimeToDate(stamp)
	local d = date("*t",stamp)
	return time({year=d.year, month=d.month, day=d.day, hour=24})
end

function MM:DaysAgo(days)
	local stamp = MM:TimeToDate(time())
	local t = date("*t",stamp)
	t.day = t.day - days
	return time(t)
end

-- print out the object to chat
function MM:Dump(orig, depth)
	if not depth then print("Line","Key","Value") end
	depth = depth or 0
	local depthStr = ""
	for i=1, depth do depthStr = depthStr .. " |" end
	for k, v in next, orig do
		 local splitStr =  (type(v) == 'table' and '\\' or ' ')
		 print("|"..depthStr..splitStr, k, v)
		 if type(v) == "table" then dump(v,depth+1) end
	end
end

-- calculate the variance between values
function MM:Variance(tbl,mean)
	local dif
	local sum, count = 0, 0
	for k, v in pairs(tbl) do
		if type(v) == "number" then
			dif = v - mean
			sum = sum + (dif * dif)
			count = count + 1
		end
	end
	return ( sum / count )
end

-- use the variance to calculate standard deviation
function MM:StdDev(tbl,mean)
	local variance = MM:Variance(tbl,mean)
	return math.sqrt(variance)
end

local qualityCost = {
	[2] = 6,
	[3] = 12,
	[4] = 20,
	[5] = 50
}

-- return an orb cost for each quality of enchants
function MM:OrbCost(reID)
	local enchant = C_MysticEnchant.GetEnchantInfoBySpell(reID)
	local quality = Enum.EnchantQualityEnum[enchant.Quality]
	return qualityCost[quality]
end

local qualityValue = {
	uncommon = 2,
	rare = 3,
	epic = 4,
	legendary = 5
}

-- list of mystic enchant IDs ordered alphabetically by their spell name
function MM:GetAlphabetizedEnchantList(qualityName)
	local enchants = MM[qualityName:upper() .. "_ENCHANTS"]
	if not enchants then
		enchants = {}
		local enchantList = C_MysticEnchant.QueryEnchants(9999,1,"",{})
		for _, enchant in pairs(enchantList) do
			local quality = Enum.EnchantQualityEnum[enchant.Quality]
			if quality == qualityValue[qualityName] and not enchant.IsWorldforged then
				table.insert(enchants, enchant.SpellID)
				enchants[enchant.SpellID] = true
			end
		end
		table.sort(enchants,
			function(k1, k2)
				local enchant1 = C_MysticEnchant.GetEnchantInfoBySpell(k1)
				local enchant2 = C_MysticEnchant.GetEnchantInfoBySpell(k2)
				return MM:Compare(enchant1.SpellName,enchant2.SpellName,"<")
			end
		)
		MM[qualityName:upper() .. "_ENCHANTS"] = enchants
	end
	return enchants
end

-- return a copy of the table table
function MM:Clone(table)
	if type(table) ~= "table" then return end
	local new = {}	-- create a new table
	for i, v in pairs(table) do
		if type(v) == "table" then
			v = AtlasLoot:CloneTable(v)
		end
		new[i] = v
	end
	return new
end

function MM:DeepClone(orig, copies)
	-- Deep clone for complex table copy
	-- Only use orig param, 2nd param for internal use
	copies = copies or {}
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		if copies[orig] then
			copy = copies[orig]
		else
			copy = {}
			copies[orig] = copy
			for orig_key, orig_value in next, orig, nil do
				copy[MM:DeepClone(orig_key, copies)] = MM:DeepClone(orig_value, copies)
			end
			setmetatable(copy, MM:DeepClone(getmetatable(orig), copies))
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function MM:CombineListsLimited(l1,l2,maximum)
	-- combine two number lists, limit by a maximum value
	local list = {}
	for k, v in next, l1 do
		if not maximum or maximum and type(v) == 'number' and v <= maximum then
			table.insert(list, v)
		end
	end
	return list
end

function MM:Lowest(a,b)
	local lowest
	if a and b then
		lowest = a < b and a or b
	elseif a then
		lowest = a
	elseif b then
		lowest = b
	end
	return lowest
end

-- returns the price stats for a given enchant
function MM:StatObj(reID)
	local stats = self.data.RE_AH_STATISTICS[reID]
	return stats and stats.current
end


local colors = {
	["gold"] = "|cffffd700",
	["green"] = "|cff00ff00",
	["red"] = "|cffff0000",
	["yellow"] = "|cffffff00",
	["white"] = "|cffffffff",
	["min"] = "|cff03fffb",
	["med"] = "|cff00c25e",
	["mean"] = "|cffc29e00",
	["max"] = "|cffff0000",
	["2"] = "|cff1eff00",
	["3"] = "|cff0070dd",
	["4"] = "|cffa335ee",
	["5"] = "|cffff8000",
	["RE_QUALITY_UNCOMMON"] = "|cff1eff00",
	["RE_QUALITY_RARE"] = "|cff0070dd",
	["RE_QUALITY_EPIC"] = "|cffa335ee",
	["RE_QUALITY_LEGENDARY"] = "|cffff8000",
	["RE_QUALITY_ARTIFACT"] = "|cffff8000",
	["RE_QUALITY_HEIRLOOM"] = "|cffff8000",
}
-- Color text using the above table
function MM:cTxt(text, color)
	return (colors[color] or "|cffffffff") .. text .. "|r"
end

function MM:IsREKnown(SpellID)
	local enchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
	return enchant and enchant.Known or false
end

function MM:IsMoving()
	return GetUnitSpeed("player") ~= 0
end

-- determine if an enchant is extractable
local lastExtracted = 0
function MM:Extract(enchant)
	if enchant.Known then return end
	if GetItemCount(98463) and (GetItemCount(98463) > 0) then
		if lastExtracted ~= enchant.SpellID then
			MM:Print("Extracting enchant:" .. MM:ItemLinkRE(enchant.SpellID))
			lastExtracted = enchant.SpellID
		end
		local itemGuid = MM:FindScrollByItem(enchant.ItemID)
		MM:RegisterEvent("UNIT_SPELLCAST_FAILED")
		C_MysticEnchant.DisenchantItem(itemGuid)
		MM:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		MM:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
		return true
	else
		MM:Print("Out of extracts for:" .. MM:ItemLinkRE(enchant.SpellID))
	end
end

function MM:FindScrollByItem(itemID)
	if not itemID then return end

	local inventoryList = C_MysticEnchant.GetMysticScrolls()
	for _, scroll in ipairs(inventoryList) do
		if scroll.Entry == itemID then return scroll.Guid end
	end
end

-- Return the item GUID of a reforgable scroll
function MM:FindReforgableScroll()
	local inventoryList = C_MysticEnchant.GetMysticScrolls()

	for _, scroll in ipairs(inventoryList) do
		local enchantInfo = C_MysticEnchant.GetEnchantInfoByItem(scroll.Entry)

		if scroll.Entry == 992720 -- Untarnished Mystic Scroll
		or enchantInfo and not enchantInfo.Worldforged and not MM:MatchConfiguration(enchantInfo) then
			return scroll.Guid
		end
	end
end

-- Return determine if scroll exists, or buy new one
function MM:FindUntarnishedScroll()
	local inventoryList = C_MysticEnchant.GetMysticScrolls()
	for _, scroll in ipairs(inventoryList) do
		if scroll.Entry == 992720 then -- Untarnished Mystic Scroll
			return true
		end
	end
	MM.enchantScroll = true
	MM:PurchaseScroll()
end

-- Remove extracted enchant from extract list
function MM:RemoveExtractedFromList(SpellID)
	if not self.db.realm.OPTIONS.removeFound then return end
	local enchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
	if not enchant then return end
	for _, list in ipairs(MM.shoppingLists) do
		if list.enable and list.extract and list.Enchants[SpellID] then
			list.Enchants[SpellID] = nil
			local icon = select(3, GetSpellInfo(SpellID))
			local wrapper = IconClass(icon)
			local enchantColor = colors[enchant.Quality]
			MM:Print(format("%s |Hspell:%s|h%s[%s]|r|h%s", wrapper:GetIconString(), SpellID, enchantColor, enchant.SpellName, " Mystic Enchant has been removed from shopping list "..list.Name))
			if MysticMaestro_ListFrame_ScrollFrame and MysticMaestro_ListFrame_ScrollFrame:IsVisible() then
				MysticMaestro_ListFrame_ScrollFrameUpdate()
			end
		end
	end
end

-- Display msg on new enchant learned
function MM:EnchantLearnedMsg(SpellID)
	if not self.db.realm.OPTIONS.notificationLearned then return end
	local enchant = C_MysticEnchant.GetEnchantInfoBySpell(SpellID)
	if not enchant then return end
	local icon = select(3, GetSpellInfo(SpellID))
	local wrapper = IconClass(icon)
	local enchantColor = colors[enchant.Quality]
	MM:Print(format("%s |Hspell:%s|h%s[%s]|r|h%s", wrapper:GetIconString(), SpellID, enchantColor, enchant.SpellName, " RE has been unlocked!"))
end

-- Notification function for the LEARNED event
function MM:MYSTIC_ENCHANT_LEARNED(event, SpellID)
	MM:GuildTooltipsEnchantLearned(SpellID)
	MM:RemoveExtractedFromList(SpellID)
	MM:EnchantLearnedMsg(SpellID)
end

-- determine the count of Mystic Orbs
function MM:GetOrbCurrency()
	return GetItemCount(98570)
end

function MM:IsUntarnished(itemName)
	if not itemName then return false end
	return itemName:find("Untarnished Mystic Scroll")
end

-- returns true, if player has item with given ID in inventory or bags and it's not on cooldown
function MM:HasItem(itemID)
	local item, found, id
	-- scan bags
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			item = GetContainerItemLink(bag, slot)
			if item then
				found, _, id = item:find('^|c%x+|Hitem:(%d+):.+')
				if found and tonumber(id) == itemID then
					return true, bag, slot
				end
			end
		end
	end
	return false
end

-- Used to create a dewdrop menu from a table
function MM:OpenDewdropMenu(self, menuList, skipRegister)
	if MM.dewdrop:IsOpen(self) then MM.dewdrop:Close() return end
	if not skipRegister then
		MM.dewdrop:Register(self,
			'point', function(parent)
				return "TOP", "BOTTOM"
			end,
			'children', function(level, value)
				local altar
			for _, menu in pairs(menuList[level]) do
					
				if menu.altar then
					altar = MM:AddAltar()
					if altar then
						menu = altar
					end
				end
				if (menu and not menu.altar) or (altar and menu.altar) then

					if menu.divider then
						local text = WHITE.."----------------------------------------------------------------------------------------------------"
						MM.dewdrop:AddLine(
							'text' , text:sub(1, menu.divider),
							'textHeight', 13,
							'textWidth', 13,
							'isTitle', true,
							'notCheckable', true
						)
					else
						MM.dewdrop:AddLine(
						'text', menu.text,
						'func', menu.func,
						'closeWhenClicked', menu.closeWhenClicked,
						'textHeight', menu.textHeight,
						'textWidth', menu.textWidth,
						'notCheckable', menu.notCheckable,
						'tooltip', menu.tooltip,
						'secure', menu.secure,
						'icon', menu.icon
					)
					end
					-- create close button
					if menu.close then
						MM.dewdrop:AddLine(
							'text', "Close Menu",
							'textR', 0,
							'textG', 1,
							'textB', 1,
							'textHeight', 12,
							'textWidth', 12,
							'closeWhenClicked', true,
							'notCheckable', true
						)
					end
				end
			end
		end,
		'dontHook', true
		)
	end
	MM.dewdrop:Open(self)
	return true
end

local altarItemIDs = {
	1903513, -- Normal Altar
	8210192, -- Build Master's Mystic Enchanting Altar
	406, -- Felforged Enchanting Altar
	8210195, -- Mystic Enchating Altar (League 4 - Druid)
	8210196, -- Mystic Enchating Altar (League 4 - Hunter)
	8210197, -- Mystic Enchating Altar (League 4 - Mage)
	8210198, -- Mystic Enchating Altar (League 4 - Paladin)
	8210199, -- Mystic Enchating Altar (League 4 - Priest)
	8210200, -- Mystic Enchating Altar (League 4 - Rogue)
	8210201, -- Mystic Enchating Altar (League 4 - Shaman)
	8210202, -- Mystic Enchating Altar (League 4 - Warlock)
	8210203, -- Mystic Enchating Altar (League 4 - Warrior)
}

-- caches and returns an items cooldown 
function MM:ReturnItemCooldown(itemID)
	if not MM.db.char.SavedCooldown then MM.db.char.SavedCooldown = {} end
	local sCd = MM.db.char.SavedCooldown
	local startTime, duration = GetItemCooldown(itemID)

	if not sCd[itemID] or GetTime() > (sCd[itemID][1] + sCd[itemID][2]) or sCd[itemID][1] == 0 or sCd[itemID][2] == 0  then
		sCd[itemID] = {startTime, duration}
	elseif GetTime() < (sCd[itemID][1] + sCd[itemID][2]) then
		startTime = sCd[itemID][1]
		duration = sCd[itemID][2]
	end
	return math.ceil(((duration - (GetTime() - startTime))/60))
end

-- returns the mystic enchanting altar with the lowest cooldown remaining
function MM:ReturnAltar()
	local list
	for _, altarID in pairs(altarItemIDs) do
		if C_VanityCollection.IsCollectionItemOwned(altarID) then
			if not list then list = {} end
			local name, itemLink, _, _, _, _, _, _, _, icon = GetItemInfo(altarID)
			local cooldown = MM:ReturnItemCooldown(altarID)
			tinsert(list,{name,cooldown,icon,itemLink, altarID})
		end
	end
	if not list then return end
	local lowestCD
	for _, altar in pairs(list) do
		if not lowestCD or altar[2] < lowestCD[2] then
			lowestCD = altar
		end
	end
	return lowestCD
end

-- deletes any mystic altars in the players inventory
function MM:RemoveAltars(arg2)
	if arg2 ~= "Summon Mystic Altar" or not MM.db.realm.OPTIONS.deleteAltar then return end
	for _, itemID in pairs(altarItemIDs) do
		local found, bag, slot = MM:HasItem(itemID)
		if found then
			PickupContainerItem(bag, slot)
			DeleteCursorItem()
		end
	end
	MM:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end


-- add altar summon button via dewdrop secure
function MM:AddAltar()
	local altar = MM:ReturnAltar()
	if not altar then return end
		local name, cooldown, icon, itemLink, itemID = unpack(altar)
		local text = name
		if cooldown > 0 then
		text = name.." |cFF00FFFF("..cooldown.." ".. "mins" .. ")"
		end
		local secure = {
		type1 = 'item',
		item = name
		}
		return {text = text, secure = secure, func = function() if not MM:HasItem(itemID) then RequestDeliverVanityCollectionItem(itemID) else if MM.db.realm.OPTIONS.deleteAltar then MM:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") end MM.dewdrop:Close() end end, icon = icon, textHeight = 12, textWidth = 12}
end

-- open browser link base on type or id/string
function MM:OpenDBURL(self, Type)
	local ID = self.enchantInfo.ItemID
	if Type == "spell" then ID = self.enchantInfo.SpellID end
	OpenAscensionDBURL("?"..Type.."="..ID)
end

-- for sending links to party/raid/guild chat
function MM:Chatlink(self, chatType, type)
	local spellLink = LinkUtil:GetSpellLink(self.enchantInfo.SpellID)
	local itemID = self.enchantInfo.ItemID
	if type == "spell" then
			SendChatMessage(spellLink ,chatType)
	elseif type == "item" then
		local item = Item:CreateFromID(itemID)
		if not (item:GetInfo()) then
			item:ContinueOnLoad(function(itemId)
				SendChatMessage(select(2,GetItemInfo(itemID)) ,chatType)
			end)
		else
			SendChatMessage(select(2,GetItemInfo(itemID)) ,chatType)
		end
	end
end

function MM:CalculateKnowEnchants()
	local enchantCount = {
		totalEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_UNKNOWN})),
		knownEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN})),
		totalNormalEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_UNKNOWN,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})),
		knownNormalEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})),
		totalWorldForgedEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_UNKNOWN,Enum.ECFilters.RE_FILTER_WORLDFORGED})),
		knownWorldForgedEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_WORLDFORGED})),
		totalCommonEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_UNKNOWN,Enum.ECFilters.RE_FILTER_UNCOMMON,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})),
		knownCommonEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_UNCOMMON,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})),
		totalRareEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_UNKNOWN,Enum.ECFilters.RE_FILTER_RARE,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})),
		knownRareEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_RARE,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})),
		totalEpicEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_UNKNOWN,Enum.ECFilters.RE_FILTER_EPIC,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})),
		knownEpicEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_EPIC,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})),
		totalLegendaryEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_UNKNOWN,Enum.ECFilters.RE_FILTER_LEGENDARY,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED})),
		knownLegendaryEnchants = select(2, C_MysticEnchant.QueryEnchants(1, 1, "", {Enum.ECFilters.RE_FILTER_KNOWN,Enum.ECFilters.RE_FILTER_LEGENDARY,Enum.ECFilters.RE_FILTER_NOT_WORLDFORGED}))
	}
	enchantCount.unknownEnchants = enchantCount.totalEnchants - enchantCount.knownEnchants
	enchantCount.unknownNormalEnchants = enchantCount.totalNormalEnchants - enchantCount.knownNormalEnchants
	enchantCount.unknownWorldForgedEnchants = enchantCount.totalWorldForgedEnchants - enchantCount.knownWorldForgedEnchants
	enchantCount.unknownCommonEnchants = enchantCount.totalCommonEnchants - enchantCount.knownCommonEnchants
	enchantCount.unknownRareEnchants = enchantCount.totalRareEnchants - enchantCount.knownRareEnchants
	enchantCount.unknownEpicEnchants = enchantCount.totalEpicEnchants - enchantCount.knownEpicEnchants
	enchantCount.unknownLegendaryEnchants = enchantCount.totalLegendaryEnchants - enchantCount.knownLegendaryEnchants

	return enchantCount
end

function MM:EnchantCountTooltip(self, enchants)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine("Enchant Numbers")
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(select(4, GetItemQualityColor(2)).."Uncommon Enchants")
	GameTooltip:AddLine("|cffffffffKnown: "..enchants.knownCommonEnchants.."/"..enchants.totalCommonEnchants)
	GameTooltip:AddLine("|cffffffffUnknown: "..enchants.unknownCommonEnchants)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(select(4, GetItemQualityColor(3)).."Rare Enchants")
	GameTooltip:AddLine("|cffffffffKnown: "..enchants.knownRareEnchants.."/"..enchants.totalRareEnchants)
	GameTooltip:AddLine("|cffffffffUnknown: "..enchants.unknownRareEnchants)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(select(4, GetItemQualityColor(4)).."Epic Enchants")
	GameTooltip:AddLine("|cffffffffKnown: "..enchants.knownEpicEnchants.."/"..enchants.totalEpicEnchants)
	GameTooltip:AddLine("|cffffffffUnknown: "..enchants.unknownEpicEnchants)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(select(4, GetItemQualityColor(5)).."Legendary Enchants")
	GameTooltip:AddLine("|cffffffffKnown: "..enchants.knownLegendaryEnchants.."/"..enchants.totalLegendaryEnchants)
	GameTooltip:AddLine("|cffffffffUnknown: "..enchants.unknownLegendaryEnchants)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine(CYAN.."Worldforged Enchants")
	GameTooltip:AddLine("|cffffffffKnown: "..enchants.knownWorldForgedEnchants.."/"..enchants.totalWorldForgedEnchants)
	GameTooltip:AddLine("|cffffffffUnknown: "..enchants.unknownWorldForgedEnchants)
	GameTooltip:Show()
end
-- itemLink, enchantData, buyoutPrice, seller, duration, icon
function MM:GetAuctionMysticEnchantInfo(listingType, index)
	local itemLink = GetAuctionItemLink(listingType, index)
	if not itemLink then return end
	local itemID = GetItemInfoFromHyperlink(itemLink)
	local enchantData = C_MysticEnchant.GetEnchantInfoByItem(itemID)
	local duration = GetAuctionItemTimeLeft(listingType, index)
	local icon,_ ,_ ,_ ,_ ,_ ,_ ,buyoutPrice, _, _, seller = select(2, GetAuctionItemInfo(listingType, index))
	return itemLink, enchantData, buyoutPrice, seller, duration, icon
end

function MM:Dots()
	local floorTime = math.floor(GetTime())
	return floorTime % 3 == 0 and "." or (floorTime % 3 == 1 and ".." or "...")
end

function MM:AltarLevelRequiredRolls()
	if not MM.db.realm.ALTARLEVEL then MM.db.realm.ALTARLEVEL = {} end

	--works out how many rolls on the current item type it will take to get the next altar level
	local progress, level = C_MysticEnchant.GetProgress()

	if MM.db.realm.ALTARLEVEL.lastLevel ~= level or not MM.db.realm.ALTARLEVEL.lastProgress then
		MM.db.realm.ALTARLEVEL.lastLevel = level
		MM.db.realm.ALTARLEVEL.lastProgress = progress
	end

	local progressDif = progress - MM.db.realm.ALTARLEVEL.lastProgress

	if progressDif == 0 then return end

	if progressDif ~= 0 and (not MM.db.realm.ALTARLEVEL.lastProgressDif or MM.db.realm.ALTARLEVEL.lastProgressDif > progressDif) then
		MM.db.realm.ALTARLEVEL.lastProgressDif = progressDif
	end
	local rollCorrection = 0
	if MM.db.realm.ALTARLEVEL.lastProgressDif < progressDif then
		progressDif = MM.db.realm.ALTARLEVEL.lastProgressDif
		rollCorrection = 1
	end

	MM.db.realm.ALTARLEVEL.lastProgress = progress

	local rollsNeeded = (100 - progress) / progressDif

	MM.db.realm.ALTARLEVEL.rollsNeeded = math.ceil(rollsNeeded - rollCorrection)
end

function MM:CheckRealmA52()
	local realm = GetRealmMask()
	return realm == Enum.RealmMask.Area52
end