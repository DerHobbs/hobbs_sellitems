# NPC Item Selling Script

This script enables players to interact with NPCs to sell various items. You can place NPCs at specific locations, customize their animations, set dynamic prices, and ensure secure transactions.
https://streamable.com/drfbfy
## Features

- **NPC Interaction:** Allows players to sell items.
- **Dynamic Pricing:** Item prices are set within a configurable range and reset at specified intervals.
- **Customizable NPCs:** Easily configure NPC models, positions, animations, and map blips.
- **Secure Transactions:** Server-side checks prevent exploitation by validating item quantities before sale.
- **Camera Focus:** Smooth camera transition to focus on the NPC during interactions.
- **Sell All Option:** Players can sell all available items in a single transaction.
- **User Feedback:** Notifications inform players of successful or failed transactions.

## Requirements

Ensure the following dependencies are installed and running:

- **[ox_target](https://github.com/overextended/ox_target):** Used for targeting and interacting with NPCs.
- **[ox_inventory](https://github.com/overextended/ox_inventory):** Manages player inventories and items.
- **[ox_lib](https://github.com/overextended/ox_lib):** Provides utilities like notifications, context menus, and more.
- **[qbx_core](https://github.com/qbox-project/qbx_core):** Core framework for handling player data and server-side functions.

## Configuration

### NPC Settings
Edit the `Config.NPCs` table to define NPC attributes:

```lua
Config.NPCs = {
    {
        name = "Farmer",
        model = "a_m_m_farmer_01",
        position = vector3(2418.80, 4992.06, 46.21),
        heading = 121.45,
        sellItems = {
            { item = "sandwich", minPrice = 1, maxPrice = 3, label = "Sandwich", price = 0 },
            { item = "rolex", minPrice = 50, maxPrice = 100, label = "Gold Watch", price = 0 },
        },
        blip = {
            enabled = true,
            blipId = 1,
            color = 2,
            scale = 1.0,
            name = "Farmer Market"
        },
        priceResetInterval = 2 * 60 * 60, -- Price reset every 2 hours (in seconds)
        interactionDistance = 50.0,       -- Distance in meters for NPC spawn/despawn
        animation = "WORLD_HUMAN_CLIPBOARD"
    },
    -- Add more NPCs as needed
}

## Text Customization

All text displayed to players can be customized in the `Config.Texts` section:

```lua
Config.Texts = {
    TargetMenuTitle = "Sell Items",
    ContextMenuTitle = "Selling Menu",
    SellAllTitle = "Sell All Items?",
    SellAllDescription = "Sell all available items!",
    CurrentPrice = "Current Price: $",
    QuantityPrompt = "How many would you like to sell?",
    InvalidAmount = "Invalid amount.",
    SuccessSellAll = "All available items have been sold.",
    MenuHeader = "Choose an item to sell",
    NoItemsToSell = "No items available to sell.",
    ConfirmSellTitle = "Are you sure?",
    ConfirmSellYes = "Yes, sell all",
    ConfirmSellNo = "No, cancel",
    SellCancelled = "Sale cancelled.",
    SellSuccessTitle = "Sale Successful",
    SellSuccessMessage = "You sold %d %s for $%d.",
    SellErrorTitle = "Sale Failed",
    SellErrorMessage = "An error occurred while selling the items."
}
```

## Usage
Configure NPCs: Customize the NPCs by editing the Config.NPCs table with your desired settings.
Adjust Texts: Modify the Config.Texts to suit your server's language and messaging style.
Deploy: Add the script to your resource folder and ensure hobbs_sellitem in your server.cfg.

Contribution
Feel free to fork this repository and submit pull requests if you'd like to contribute or improve the script. For any issues or suggestions, please open an issue on GitHub.
