Config = {}

Config.Debug = false

-- Police Requirement
Config.MinimumPolice = 0 -- How many police needed online to sell

-- Sell Settings
Config.SellTime = 3000 -- Time in ms to complete sale
Config.SellChance = 60 -- % chance to successfully sell
Config.CallPoliceChance = 35 -- % chance to call police on fail
Config.RobberyChance = 40 -- % chance the ped tries to rob you instead of buying
Config.BlackMoney = true -- Enable black money rewards
Config.BlackMoneyItem = 'markedbills' -- Name of the item (e.g., 'markedbills', 'black_money')
Config.BlackMoneyType = 'count' -- 'metadata' (gives 1 item with worth) or 'count' (gives items equal to price)

-- Distance to ped checking
Config.MaxSellDistance = 2.0

-- Drug Items Configuration
Config.Drugs = {
    ['weed_ak47'] = {
        label = 'Bag of AK47',
        minPrice = 40,
        maxPrice = 80,
        minAmount = 3,
        maxAmount = 5
    },
    ['weed_purplehaze'] = {
        label = 'Bag of Purple Haze',
        minPrice = 40,
        maxPrice = 80,
        minAmount = 3,
        maxAmount = 5
    }
}

-- Peds that cannot be sold to (model hashes or names)
Config.BlacklistPeds = {
    "mp_m_freemode_01",
    "mp_f_freemode_01",
    -- Add more as needed
}
