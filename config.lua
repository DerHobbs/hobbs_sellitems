Config = {}

Config.NPCs = {
    {
        name = "Farmer",
        model = "a_m_m_farmer_01",
        position = vector3(2418.80, 4992.06, 46.21),
        heading = 121.45,
        sellItems = {
            { item = "sandwich", minPrice = 1, maxPrice = 3, label = "Sandwich", price = 0 },
            { item = "rolex", minPrice = 50, maxPrice = 100, label = "Golden Watch", price = 0 },
            -- Add more items here
        },
        blip = {
            enabled = true,
            blipId = 1,  -- Blip Icon
            color = 2,  -- Blip color
            scale = 1.0,  -- Blip size
            name = "Farmer Market"  -- Blip name
        },
        priceResetInterval = 2 * 60 * 60,  -- Price reset interval: every 2 hours (in seconds)
        interactionDistance = 50.0,  -- Distance in meters for NPC spawn/despawn
        animation = "WORLD_HUMAN_CLIPBOARD"  -- Animation scenario
    },
    {
        name = "ElectronicsVendor",
        model = "a_m_y_business_02",
        position = vector3(-298.92, -1376.14, 41.17),
        heading = 180.0,
        sellItems = {
            { item = "gold_coin", minPrice = 50, maxPrice = 100, label = "Golden Coin", price = 0 },
            { item = "blueprint_ruston", minPrice = 300, maxPrice = 500, label = "Ruston Blueprint", price = 0 },
            -- Add more items here
        },
        blip = {
            enabled = true,
            blipId = 459,  -- Blip Icon
            color = 3,  -- Blip color
            scale = 1.2,  -- Blip size
            name = "Electronics Vendor"  -- Blip name
        },
        priceResetInterval = 3 * 60 * 60,  -- Price reset interval: every 3 hours (in seconds)
        interactionDistance = 50.0,  -- Distance in meters for NPC spawn/despawn
        animation = "WORLD_HUMAN_CLIPBOARD"  -- Animation scenario
    }
    -- Add more NPCs here
}

Config.Texts = {
    TargetMenuTitle = "Sell Items",
    ContextMenuTitle = "Sell Menu",
    SellAllTitle = "Sell All Available Items?",
    SellAllDescription = "Sell all your available items!",
    CurrentPrice = "Current Price: $",
    QuantityPrompt = "How many would you like to sell?",
    InvalidAmount = "Invalid amount.",
    SuccessSellAll = "All available items have been sold.",
    MenuHeader = "Select an item to sell",
    NoItemsToSell = "No items available to sell.",
    ConfirmSellTitle = "Are you sure?",
    ConfirmSellYes = "Yes, sell everything",
    ConfirmSellNo = "No, cancel",
    SellCancelled = "Sale cancelled.",
    SellSuccessTitle = "Sale Successful",
    SellSuccessMessage = "You sold %d %s for $%d.",
    SellErrorTitle = "Sale Failed",
    SellErrorMessage = "There was an error selling the items."
}