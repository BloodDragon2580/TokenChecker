if not LibStub then error("TokenChecker requires LibStub") end
local L = LibStub("AceLocale-3.0"):GetLocale("TokenChecker", false)

local lib = LibStub:GetLibrary("LibDataBroker-1.1");
local tokenIcon1 = "Interface\\Icons\\WoW_Token01";
local tokenIcon2 = "Interface\\Icons\\WoW_Token02";
local minutesOfTime = 43200;

local inactiveText = L["inactiv"]; -- 0 arg
local activeText = L["active"]; -- 2 arg, price, duration
local market = CreateFrame("frame");

local function partial(f, ...)
	local args = ...;
	return function(...)
		return f(args, ...);
	end
end

local function RequestNewPrice()
	C_WowTokenPublic.UpdateMarketPrice();
end

local function UpdateTooltip(self, tooltip)
	tooltip:AddLine(format(L["Price Watch"]));
	tooltip:AddLine();
	tooltip:AddLine(L["5 minutes"]);
	tooltip:AddLine(L["fast refresh"]);
end

local datamarket = lib:NewDataObject("TokenChecker", { type = "data source", text = inactiveText, icon = tokenIcon2, OnTooltipShow = partial(UpdateTooltip, market), OnClick = RequestNewPrice });

local function MarketPriceUpdated(self, event, ...)
	if event == "TOKEN_MARKET_PRICE_UPDATED" then
		local result = ...;
		self.marketPriceAvailable = result == LE_TOKEN_RESULT_SUCCESS;
		if (result == LE_TOKEN_RESULT_ERROR_DISABLED) then
			-- self.disabled = true;
		end
		if (self.marketPriceAvailable) then
			self.price, self.duration = C_WowTokenPublic.GetCurrentMarketPrice();
			if (WowToken_IsWowTokenAuctionDialogShown()) then
				self.price = C_WowTokenPublic.GetGuaranteedPrice();
			end
			self.goldPerMinute = self.price / minutesOfTime;
			self.goldPerDollar = self.price / 20;
			self.dollarPerGold = self.price / 15;
			self.priceDifference = self.dollarPerGold - self.goldPerDollar;
		end
		self.displayNeedsUpdate = true;
	end
end

local function UpdateDisplay(self, t)
	if (self.displayNeedsUpdate) then
		if (self.marketPriceAvailable) then
			local timeToSellString = _G[("AUCTION_TIME_LEFT%d_DETAIL"):format(self.duration)];
			datamarket.text = format(activeText, GetMoneyString(self.price, true), timeToSellString);
			datamarket.icon = tokenIcon1;
		else
			datamarket.text = format(inactiveText);
			datamarket.icon = tokenIcon2;
		end
	end
	self.displayNeedsUpdate = false;
end

market.displayNeedsUpdate = true;
market:SetScript("OnUpdate", UpdateDisplay);
market:SetScript("OnEvent", MarketPriceUpdated);
market:RegisterEvent("TOKEN_MARKET_PRICE_UPDATED");
market.timer = C_Timer.NewTicker(5*60, function()
	RequestNewPrice(); -- Update once every 5 minutes
end)
C_WowTokenPublic.UpdateMarketPrice();