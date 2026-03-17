# rs_drugsell

Advanced drug selling system for QBCore using ox_target. Interact with local NPC pedestrians to sell drugs, but watch out - they might try to rob you!

## Features
- **Interact to Sell**: Use `ox_target` (Third Eye) on any pedestrian to offer drugs.
- **Smart Selling**: ped automatically chooses a random amount to buy (configurable).
- **Auto-Detect**: If you have multiple drug types, a menu opens. If you have only one, it sells automatically.
- **Visuals**: High-quality animations (handing over package) and clean `ox_lib` progress circles.
- **Robbery System**: Configurable chance for the buyer to scam you. They will take your drugs and attack you with a weapon.
- **Looting**: If you defend yourself and kill the thief, use `ox_target` on their body to retrieve your stolen drugs.
- **Police Alerts**: Integrated with `ps-dispatch` for sale alerts and robbery/fight alerts.
- **Economy**: Supports cash or 'markedbills' (metadata or stackable count supported).

## Dependencies
- [qb-core](https://github.com/qbcore-framework/qb-core) OR [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_target](https://github.com/overextended/ox_target)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ps-dispatch](https://github.com/Project-Sloth/ps-dispatch)

## Installation

1. **Download & Install Dependencies**: Ensure all dependencies above are installed and started before this resource.
2. **Add Items**: proper drug items must exist in your `qb-core/shared/items.lua` (or `ox_inventory/data/items.lua` if strictly using ox items).
   Example: Ensure your config item names match your `items.lua`.
3. **Config**: Adjust `config.lua` primarily for:
   - `Config.Drugs`: Item names and prices.
   - `Config.RobberyChance`: % chance to get robbed.
   - `Config.BlackMoneyType`: Set to `'count'` if your markedbills stack, or `'metadata'` if they are unique items.

## Usage
1. Have drugs in your inventory.
2. Hold `Left Alt` (default target key) and look at a pedestrian.
3. Select **"Offer Drugs"**.
4. If the deal goes well, you get paid.
5. If they try to rob you, defend yourself and loot them back using **"Retrieve Stolen Drugs"**.

## Credits
Created by **Kieran - RatedScripts**
- [Discord](https://discord.gg/MzTFVeHsfB)
- [GitHub](https://github.com/RatedScripts)

## License
**Do not resell, redistribute, or leak this script.**
This resource is created for private use. Does not grant permission for resale or claiming ownership.
