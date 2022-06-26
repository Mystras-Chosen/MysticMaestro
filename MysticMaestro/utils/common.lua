local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:ValidateAHIsOpen()
    local AuctionFrame = _G["AuctionFrame"]
    if not AuctionFrame or not AuctionFrame:IsShown() then
        MM:Print("Auction house window must be open to perform scan")
        return false
    end
    return true
end
