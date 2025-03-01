Config = {}

Config.NPCs = {
    Farmer = {  -- NPC configuration for Farmer
        name = "Farmer", -- Name of the NPC
        model = "a_m_m_farmer_01", -- Model of the NPC
        position = vector3(2418.80, 4992.06, 46.21), -- Position of the NPC
        heading = 121.45,
        -- If only a specific job is to have access, example example { name = farmer, grade = 1 },
        -- if everyone should have access then false
        requiredJob = false, -- Jobs the NPC won't talk to if they don't need it then false.
        requiredGang = { name = "ballas", grade = 0 }, -- Gangs the NPC won't talk to if they don't need it then false.
        blacklistedJobs = { "police", "sheriff" },  -- Keine ausgeschlossenen Jobs
        sellItems = {--Item to sell
            { item = "sandwich", minPrice = 1, maxPrice = 3, label = "Sandwich", price = 0 },
            { item = "rolex", minPrice = 50, maxPrice = 100, label = "Golden Watch", price = 0 },
        },
        blip = {  -- Blip configuration for map icon
            enabled = true, -- If you want to show the blip on the map
            blipId = 1, -- Blip ID
            color = 2, -- Blip color
            scale = 1.0, -- Blip size
            name = "Farmer Market" -- Blip name
        },
        priceResetInterval = 2 * 60 * 60,  -- Prices reset every 2 hours
        interactionDistance = 50.0,  -- Distance for NPC interaction
        animation = "WORLD_HUMAN_CLIPBOARD" -- Animation the NPC should play
    },
    ElectronicsVendor = {  -- NPC configuration for Electronics Vendor
        name = "ElectronicsVendor",
        model = "a_m_y_business_02",
        position = vector3(-298.92, -1376.14, 41.17),
        heading = 180.0,
        requiredJob = { name = "autoexotic", grade = 1 },
        requiredGang = false,
        blacklistedJobs = false,
        sellItems = {
            { item = "gold_coin", minPrice = 50, maxPrice = 100, label = "Golden Coin", price = 0 },
            { item = "blueprint_ruston", minPrice = 300, maxPrice = 500, label = "Ruston Blueprint", price = 0 },
        },
        blip = {
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