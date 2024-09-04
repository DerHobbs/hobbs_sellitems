Config = {}

Config.NPCs = {
    Farmer = {  -- NPC configuration for Farmer
        name = "Farmer",
        model = "a_m_m_farmer_01",
        position = vector3(2418.80, 4992.06, 46.21),
        heading = 121.45,
        sellItems = {
            { item = "sandwich", minPrice = 1, maxPrice = 3, label = "Sandwich", price = 0 },
            { item = "rolex", minPrice = 50, maxPrice = 100, label = "Golden Watch", price = 0 },
        },
        blip = {  -- Blip configuration for map icon
            enabled = true,
            blipId = 1,
            color = 2,
            scale = 1.0,
            name = "Farmer Market"
        },
        priceResetInterval = 2 * 60 * 60,  -- Prices reset every 2 hours
        interactionDistance = 50.0,  -- Distance for NPC interaction
        animation = "WORLD_HUMAN_CLIPBOARD"
    },
    ElectronicsVendor = {  -- NPC configuration for Electronics Vendor
        name = "ElectronicsVendor",
        model = "a_m_y_business_02",
        position = vector3(-298.92, -1376.14, 41.17),
        heading = 180.0,
        sellItems = {
            { item = "gold_coin", minPrice = 50, maxPrice = 100, label = "Golden Coin", price = 0 },
            { item = "blueprint_ruston", minPrice = 300, maxPrice = 500, label = "Ruston Blueprint", price = 0 },
        },
        blip = {  -- Blip configuration for map icon
            enabled = true,
            blipId = 459,
            color = 3,
            scale = 1.2,
            name = "Electronics Vendor"
        },
        priceResetInterval = 3 * 60 * 60,  -- Prices reset every 3 hours
        interactionDistance = 50.0,
        animation = "WORLD_HUMAN_CLIPBOARD"
    }
}
