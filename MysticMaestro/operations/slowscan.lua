local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

function MM:HandleSlowScan()
	local AuctionFrame = _G["AuctionFrame"]
	if AuctionFrame and AuctionFrame:IsShown() then
		MM:Print("Auction house window is open and we did a slow scan! ;)")
	else
		MM:Print("Auction house window must be open to perform scan")
	end
end