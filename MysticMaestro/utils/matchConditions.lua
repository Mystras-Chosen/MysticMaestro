local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")
local options
local otherGreens = {
	Speedy = true,
	Improved = true,
	Defensive = true,
	Energizing = true,
	Camouflage = true,
	Debbie = true,
	Meating = true,
	Dispersing = true,
}

function MM:MatchNoRunes()
	if not options then options = MM.db.realm.OPTIONS end
	local eval = options.stopIfNoRunes and GetItemCount(98462) <= 0
	return eval and "No Runes" or nil
end

function MM:MatchQuality(currentEnchant)
	local quality = Enum.EnchantQualityEnum[currentEnchant.Quality]
	local eval = options.stopQuality.enabled and options.stopQuality[quality]
	return eval and "Quality Match" or nil
end

function MM:MatchUnknown(currentEnchant)
	local quality = Enum.EnchantQualityEnum[currentEnchant.Quality]
	local eval = options.stopUnknown.enabled and not currentEnchant.Known and options.stopUnknown[quality]
	return eval and "Unknown Match" or nil
end

function MM:MatchPrice(currentEnchant)
    local priceObj = Maestro(currentEnchant.SpellID)
		local quality = Enum.EnchantQualityEnum[currentEnchant.Quality]
    if not priceObj then return options.stopPrice.enabled and options.stopPrice[quality] and "Unknown Priced" end
		local eval = options.stopPrice.enabled and priceObj.Min >= options.stopPrice.value * 10000 and options.stopPrice[quality]
    return eval and "Price Match" or nil
end

function MM:MatchGreen(currentEnchant)
	local matchGreen, rxMatch, unknownLogic
	local quality = Enum.EnchantQualityEnum[currentEnchant.Quality]
	if options.green.enabled and quality == 2 then
		rxMatch = string.match(currentEnchant.SpellName,"^[a-zA-Z]+")
		unknownLogic = not options.green.unknown or (options.green.unknown and not currentEnchant.Known)
		matchGreen = options.green[rxMatch] or options.green.Other and otherGreens[rxMatch]
	end
	local eval = unknownLogic and matchGreen
	return eval and "Green Match" or nil
end

function MM:MatchShopping(currentEnchant)
	if not MM.db.realm.SHOPPING_LISTS then return end
	for _, list in ipairs (MM.db.realm.SHOPPING_LISTS) do
		if list.enable and not list.reforge and list.Enchants and list.Enchants[currentEnchant.SpellID] then
			return true, "Shopping List"
		elseif list.enable and list.reforge and list.Enchants and list.Enchants[currentEnchant.SpellID] then
			return true, false
		end
	end
end

function MM:MatchShoppingExtract(currentEnchant)
	if not MM.db.realm.SHOPPING_LISTS then return end
	if currentEnchant.Known then return end
	for _, list in ipairs (MM.db.realm.SHOPPING_LISTS) do
		if list.enable and list.extract and list.Enchants and list.Enchants[currentEnchant.SpellID] then
			return true
		end
	end
end

function MM:MatchExtractable(currentEnchant)
	if not options then options = MM.db.realm.OPTIONS end

	if (MM:MatchUnknown(currentEnchant) and options.stopUnknown.extract)
	or (MM:MatchGreen(currentEnchant) and options.green.extract)
	or MM:MatchShoppingExtract(currentEnchant) then
		return true
	end
end

function MM:MatchConfiguration(currentEnchant)
	if not options then options = MM.db.realm.OPTIONS end
	local enable, forgeType = MM:MatchShopping(currentEnchant)
	if enable then return forgeType end
	
	-- Evaluate the enchant against our options
	return MM:MatchQuality(currentEnchant)
	or MM:MatchUnknown(currentEnchant)
	or MM:MatchGreen(currentEnchant)
	or MM:MatchPrice(currentEnchant)
end