Config = Config or {}

Config.Inventory = 'rsg-inventory' -- Only used for image purposes
Config.Locations = {
    ['blackmarket1'] = { -- Unique ID of the blackmarket, must be unique!
        label = 'Blackmarket 1', -- The name of the blackmarket can be anything
        ped = 'amsp_robsdgunsmith_males_01', -- The model of the Blackmarket ped
        coords = vec4(-318.40, 819.43, 118.69, 11.82), -- The location of the ped, HAS TO BE VECTOR4
        sellItems = { -- Leave as an empty table if you don't want it to sell anything!
            {
                label = 'Crossover Navy Revolver', -- Simply a label for the item, can be anything.
                name = 'weapon_revolver_navy_crossover', -- The spawncode for the item itself from items.lua
                amount = 5, -- The amount of items you can buy the current session if globalAmount is true
                price = 400, -- The price of the item!
            },
            {
                label = 'doublebarrel shotgun exotic',
                name = 'weapon_shotgun_doublebarrel_exotic',
                --image = 'lockpick_wagon',
                amount = 10,
                price = 1000,
            },
            {
                label = 'Pump Shotgun',
                name = 'weapon_shotgun_pump',
                amount = 10,
                price = 1000,
            },
            {
                label = 'collector machete',
                name = 'weapon_melee_machete_collector',
                --image = 'provision_jewelry_box', -- Only needed if the name of the image is different to the item name! DO NOT ADD THE EXTENSION!
                amount = 5,
                price = 250,
            },
            {
                label = 'dynamite',
                name = 'weapon_thrown_dynamite',
                amount = 5,
                price = 500,
            },
            {
                label = 'poisonbottle',
                name = 'weapon_thrown_poisonbottle',
                amount = 25,
                price = 50,
            },
            {
                label = 'shotgun ammo',
                name = 'ammo_box_shotgun',
                amount = 50,
                price = 10,
            },
            {
                label = 'legendarymap',
                name = 'legendarymap',
                image = 'treasuremap', 
                amount = 5,
                price = 1500,
            },
        },
        buyItems = {
            {
                label = 'goldbar',
                --image = 'provision_key_house',
                name = 'goldbar',
                amount = 10, -- The amount of items you can sell the current session if globalAmount is true
                price = 1000,
            },
            {
                label = 'indiancigar',
                --image = 'provision_key_house2',
                name = 'indiancigar',
                amount = 100,
                price = 20,
            },
            {
                label = 'cursed_cigar',
                --image = 'provision_key_house2',
                name = 'cursed_cigar',
                amount = 100,
                price = 50,
            },
            {
                label = 'claimlease',
                --image = 'provision_key_house2',
                name = 'claimlease',
                amount = 100,
                price = 30,
            },
            {
                label = 'pocket watch platinum',
                --image = 'provision_key_house2',
                name = 'pocket_watch_platinum',
                amount = 10,
                price = 200,
            },
            {
                label = 'pocket watch silver',
                --image = 'provision_key_house2',
                name = 'pocket_watch_silver',
                amount = 20,
                price = 100,
            },
            {
                label = 'pocket watch gold',
                --image = 'provision_key_house2',
                name = 'pocket_watch_gold',
                amount = 20,
                price = 300,
            },
        },
        globalAmount = true, -- Whether or not the player has a limit of items to buy or sell per game session!
    }
}