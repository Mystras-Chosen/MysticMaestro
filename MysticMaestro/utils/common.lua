local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:ValidateAHIsOpen()
    local AuctionFrame = _G["AuctionFrame"]
    if not AuctionFrame or not AuctionFrame:IsShown() then
        MM:Print("Auction house window must be open to perform scan")
        return false
    end
    return true
end

function MM:UpdateDatabase()
    local listings = self.db.realm.RE_AH_LISTINGS or {}
    local stats = self.db.realm.RE_AH_STATISTICS or {}
    for _, enchantData in pairs(MYSTIC_ENCHANTS) do
        local spellID = enchantData.spellID
        if spellID ~= 0 then
            local spellName = GetSpellInfo(spellID)
            if listings[spellName] == nil then
                listings[spellName] = {}
                statistics[spellName] = {}
            end
        end
    end
    self.db.realm.RE_AH_LISTINGS, self.db.realm.RE_AH_STATISTICS = listings, stats
    setmetatable(self.db.realm.RE_AH_LISTINGS, enchantMT)
    setmetatable(self.db.realm.RE_AH_STATISTICS, enchantMT)
end
