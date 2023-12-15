import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Float "mo:base/Float";
import Option "mo:base/Option";

import JSON "../utils/Json";
import Utils "../utils/Utils";
import Int "mo:base/Int";

import ENV "../utils/Env";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";

import ActionTypes "../types/action.types";
import EntityTypes "../types/entity.types";

module{
    public type StableConfigs = [EntityTypes.StableConfig]; 
    public type Actions = [ActionTypes.Action]; 

    public let Nft_Canister = "6uvic-diaaa-aaaap-abgca-cai"; //Game Collection
    public let ICRC1_Ledger = "tvmv4-uqaaa-aaaap-abt5q-cai"; //Game Token
    
    public let configs : StableConfigs = [
        //SHOP ACTIONS CONFIGS
            {
                cid = "shop_window_actions";
                fields = [
                    { fieldName = "buyItemA_Icp"; fieldValue = "verifyICP" },
                    { fieldName = "buyItemB_Icrc"; fieldValue = "verifyICRC" },
                    { fieldName = "buyItemC_ItemB"; fieldValue = "trade" },
                    { fieldName = "spend_icp_to_mint_test_nft"; fieldValue = "verifyICP" },
                    { fieldName = "burn_nft_tiket"; fieldValue = "verifyNftBurn" },
                    { fieldName = "nft_holding_verification"; fieldValue = "verifyNftHold" },
                ];
            },
            {
                cid = "buyItemA_Icp";
                fields = [
                    { fieldName = "name"; fieldValue = "ItemA Offer!" },
                    { fieldName = "description"; fieldValue = "Spend 0.001 ICP to receive an ItemA" },
                    { fieldName = "imageUrl"; fieldValue = "https://i.postimg.cc/65smkh6B/BoomDao.jpg" },
                ]; 
            },
            {
                cid = "buyItemB_Icrc";
                fields = [
                    { fieldName = "name"; fieldValue = "ItemB Offer!" },
                    { fieldName = "description"; fieldValue = "Spend 1 Test Token to receive an ItemB" },
                    { fieldName = "imageUrl"; fieldValue = "https://i.postimg.cc/65smkh6B/BoomDao.jpg" },
                ]; 
            },
            {
                cid = "buyItemC_ItemB";
                fields = [
                    { fieldName = "name"; fieldValue = "Trading" },
                    { fieldName = "description"; fieldValue = "Trade an in-game ItemB for an ItemC" },
                    { fieldName = "imageUrl"; fieldValue = "https://i.postimg.cc/65smkh6B/BoomDao.jpg" },
                ]; 
            },
            {
                cid = "spend_icp_to_mint_test_nft";
                fields = [
                    { fieldName = "name"; fieldValue = "Buy a Test NFT!" },
                    { fieldName = "description"; fieldValue = "Spend 0.001 ICP to get a \"Test NFT\"" },
                    { fieldName = "imageUrl"; fieldValue = "https://i.postimg.cc/65smkh6B/BoomDao.jpg" },
                ]; 
            },
            {
                cid = "burn_nft_tiket";
                fields = [
                    { fieldName = "name"; fieldValue = "Burn a Test NFT!" },
                    { fieldName = "description"; fieldValue = "Burn a Test NFT to get a random reward in return!" },
                    { fieldName = "imageUrl"; fieldValue = "https://i.postimg.cc/65smkh6B/BoomDao.jpg" },
                ]; 
            },
            {
                cid = "nft_holding_verification";
                fields = [
                    { fieldName = "name"; fieldValue = "TEST NFT HOLDING REWARD" },
                    { fieldName = "description"; fieldValue = "Get a reward for holding an nft of TEST NFT collection" },
                    { fieldName = "imageUrl"; fieldValue = "https://i.postimg.cc/65smkh6B/BoomDao.jpg" },
                ]; 
            },
        //Stats
            {
                cid = "spaceshipBaseStats";
                fields = [
                    { fieldName = "shield"; fieldValue = "10" },
                    { fieldName = "damage"; fieldValue = "3" },
                ]; 
            },
            {
                cid = "spaceshipTemplate";
                fields = [
                    { fieldName = "hull"; fieldValue = "5" },
                    { fieldName = "damageMul"; fieldValue = "1" },
                    { fieldName = "shieldMul"; fieldValue = "1" },
                ];
            },
            {
                cid = "spaceshipFormulas";
                fields = [
                    { fieldName = "@callerTotalDamage"; fieldValue = "{$config.spaceshipBaseStats.damage} * {$caller.spaceships.spaceshipA.damageMul}" },
                    { fieldName = "@targetTotalShield"; fieldValue = "{$config.spaceshipBaseStats.shield} * {$target.spaceships.spaceshipA.shieldMul}" },
                    { fieldName = "@newTargetHull"; fieldValue = "{$target.spaceships.spaceshipA.hull} - ({$config.spaceshipFormulas.@callerTotalDamage} - {$config.spaceshipFormulas.@targetTotalShield})>0" },
                    { fieldName = "@testFormula"; fieldValue = "(5 - (1 - 10))" },
                ]
            },
        //Tokens
            {
                cid = "icp_details";
                fields = [
                            { fieldName = "tag"; fieldValue = "token" },
                            { fieldName = "canister"; fieldValue = "ryjl3-tyaaa-aaaaa-aaaba-cai" },
                            { fieldName = "name"; fieldValue = "ICP" },
                            { fieldName = "description"; fieldValue = "This is the base Internet Computer Token" },
                            { fieldName = "urlLogo"; fieldValue = "https://cryptologos.cc/logos/internet-computer-icp-logo.png?v=026" },
                        ];
            },
            {
                cid = "test_token_details";
                fields = [
                            { fieldName = "tag"; fieldValue = "token" },
                            { fieldName = "canister"; fieldValue = ICRC1_Ledger },
                            { fieldName = "name"; fieldValue = "Test Token" },
                            { fieldName = "description"; fieldValue = "just an Test Token" },
                            { fieldName = "urlLogo"; fieldValue = "https://cryptologos.cc/logos/dogecoin-doge-logo.png?v=026" },
                        ];
            },
        //Nfts
            {
                cid = "the_moon_walker_details";
                fields = [
                            { fieldName = "tag"; fieldValue = "nft" },
                            { fieldName = "canister"; fieldValue = "er7d4-6iaaa-aaaaj-qac2q-cai" },
                            { fieldName = "isStandard"; fieldValue = "true" },
                            { fieldName = "name"; fieldValue = "The Moonwalkers" },
                            { fieldName = "description"; fieldValue = "Dope Characters" },
                            { fieldName = "urlLogo"; fieldValue = "https://i.postimg.cc/hvyLyfwh/The-Moon-Walker-Logo.png" },
                        ];
            },
            {
                cid = "poked_bots_details";
                fields = [
                            { fieldName = "tag"; fieldValue = "nft" },
                            { fieldName = "canister"; fieldValue ="bzsui-sqaaa-aaaah-qce2a-cai" },
                            { fieldName = "isStandard"; fieldValue = "true" },
                            { fieldName = "name"; fieldValue = "Poked Bots" },
                            { fieldName = "description"; fieldValue = "Dope Characters" },
                            { fieldName = "urlLogo"; fieldValue = "https://i.postimg.cc/d1Qn5P1H/image.png" },
                        ];
            },
            {
                cid = "test_nft_collection_details";
                fields = [
                            { fieldName = "tag"; fieldValue = "nft" },
                            { fieldName = "canister"; fieldValue = Nft_Canister },
                            { fieldName = "isStandard"; fieldValue = "false" },
                            { fieldName = "name"; fieldValue = "Test Nft Collection" },
                            { fieldName = "description"; fieldValue = "This is a test collection" },
                            { fieldName = "urlLogo"; fieldValue = "https://i.postimg.cc/65smkh6B/BoomDao.jpg" },
                        ];
            },
        //Items   
            {
                cid = "character_a";
                fields = [
                            { fieldName = "name"; fieldValue = "CharacterA" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "common" },
                        ];
            },
            {
                cid = "character_b";
                fields = [
                            { fieldName = "name"; fieldValue = "CharacterB" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "common" },
                        ];
            },   
            {
                cid = "character_c";
                fields = [
                            { fieldName = "name"; fieldValue = "CharacterC" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "common" },
                        ];
            },   
            {
                cid = "character_d";
                fields = [
                            { fieldName = "name"; fieldValue = "CharacterD" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "common" },
                        ];
            },
            {
                cid = "character_e";
                fields = [
                            { fieldName = "name"; fieldValue = "CharacterE" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "common" },
                        ];
            },
            {
                cid = "character_f";
                fields = [
                            { fieldName = "name"; fieldValue = "CharacterF" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "rare" },
                        ];
            },
            {
                cid = "character_g";
                fields = [
                            { fieldName = "name"; fieldValue = "CharacterG" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "rare" },
                        ];
            },
            {
                cid = "character_h";
                fields = [
                            { fieldName = "name"; fieldValue = "CharacterH" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "special" },
                        ];
            },
            {
                cid = "character_h";
                fields = [
                            { fieldName = "name"; fieldValue = "CharacterH" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "special" },
                        ];
            },
            //
            {
                cid = "item_a";
                fields = [
                            { fieldName = "name"; fieldValue = "ItemA" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "common" },
                        ];
            },
            {
                cid = "item_b";
                fields = [
                            { fieldName = "name"; fieldValue = "ItemB" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "common" },
                        ];
            },
            {
                cid = "item_c";
                fields = [
                            { fieldName = "name"; fieldValue = "ItemC" },
                            { fieldName = "description"; fieldValue = "just an item" },
                            { fieldName = "rarity"; fieldValue = "common" },
                        ];
            },
        //Others
    ];
    public let action : Actions = [
    //     //BURN NFT
        { 
            aid = "burn_nft_tiket";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = null;
                    entityConstraint = [];
                    nftConstraint = [
                        { 
                            nftConstraintType = #transfer { toPrincipal = "tulnw-tl2en-5kqoh-qdgf4-5y7k6-ig3on-htta2-35wv7-2u25c-yqoas-zae" };
                            canister = Nft_Canister;
                            metadata = null;
                        }
                    ];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "character_a"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                                { option = #updateEntity { wid = null; eid = "character_b"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                                { option = #updateEntity { wid = null; eid = "character_c"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                                { option = #updateEntity { wid = null; eid = "character_d"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //HOLD NFT
        { 
            aid = "nft_holding_verification";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = null;
                    entityConstraint = [];
                    nftConstraint = [
                        { 
                            nftConstraintType = #hold (#boomEXT); 
                            canister = Nft_Canister; 
                            metadata = null;
                        }
                    ];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "character_e"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                                { option = #updateEntity { wid = null; eid = "character_f"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                                { option = #updateEntity { wid = null; eid = "character_g"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                                { option = #updateEntity { wid = null; eid = "character_h"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //SPEND ICP TO MINT NFT 
        { 
            aid = "spend_icp_to_mint_test_nft";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { actionTimeInterval = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; }; actionExpirationTimestamp = null; };
                    entityConstraint = [];
                    nftConstraint = [];
                    icpConstraint = ? {
                            amount = 0.001; toPrincipal = "tulnw-tl2en-5kqoh-qdgf4-5y7k6-ig3on-htta2-35wv7-2u25c-yqoas-zae"
                        };
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { 
                                    option = #mintNft {
                                    name = "Test Nft";
                                    description = "Spend 0.001 ICP to purchase a Test NFT."; 
                                    imageUrl = ""; 
                                    canister  = Nft_Canister;
                                    assetId = "testAsset";
                                    collection = "Nft Reward";
                                    metadata = "metadata_A";
                                    };  weight = 100;
                                },
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //Mint Free Test NFTs
        { 
            aid = "mint_test_nft";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { actionTimeInterval = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; }; actionExpirationTimestamp = null; };
                    entityConstraint = [];
                    nftConstraint = [];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #mintNft {
                                    name = "Test Nft";
                                    description = "Mint a free Test Nft."; 
                                    imageUrl = ""; 
                                    canister  = Nft_Canister;
                                    assetId = "testAsset";
                                    collection = "Nft Reward";
                                    metadata = "metadata_B";
                                    };  weight = 100;
                                },
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //Mint 5 Free Test ICRC
        { 
            aid = "mint_test_icrc";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { actionTimeInterval = ? {  intervalDuration = 15_000_000_000; actionsPerInterval = 1; }; actionExpirationTimestamp = null; };
                    entityConstraint = [];
                    nftConstraint = [];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { 
                                    option = #transferIcrc {
                                        quantity = 5;
                                        canister = ICRC1_Ledger;
                                    };  weight = 100;
                                },
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //BUY ItemA WITH ICP
        { 
            aid = "buyItemA_Icp";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { actionTimeInterval = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; }; actionExpirationTimestamp = null;};
                    entityConstraint = [];
                    nftConstraint = [];
                    icpConstraint = ? {
                            amount = 0.001; toPrincipal = "tulnw-tl2en-5kqoh-qdgf4-5y7k6-ig3on-htta2-35wv7-2u25c-yqoas-zae"
                        };
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "item_a"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //BUY ItemB WITH ICRC
        { 
            aid = "buyItemB_Icrc";
            adminPrincipalIds = [];
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { actionTimeInterval = ? {  intervalDuration = 15_000_000_000; actionsPerInterval = 1; }; actionExpirationTimestamp = null;};
                    entityConstraint = [];
                    nftConstraint = [];
                    icpConstraint = null;
                    icrcConstraint = [
                        {
                            canister = ICRC1_Ledger; amount = 1; toPrincipal = "tulnw-tl2en-5kqoh-qdgf4-5y7k6-ig3on-htta2-35wv7-2u25c-yqoas-zae"
                        }
                    ];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null;  eid = "item_b"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; } ]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //TRADE ItemC WITH ItemA
        { 
            aid = "buyItemC_ItemB";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { actionTimeInterval = ? {  intervalDuration = 15_000_000_000; actionsPerInterval = 1; }; actionExpirationTimestamp = null;};
                    entityConstraint = [{
                    wid = null; 
                    eid = "item_b"; 
                    entityConstraintType = #greaterThanEqualToNumber {fieldName = "quantity"; value = 1.0};
                }];
                    nftConstraint = [];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "item_b"; updates = [#decrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }]; };  weight = 100;},
                            ]
                        },
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "item_c"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; }]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //  //Increment a collective score in world
        { 
            aid = "increment_collective_score";
            callerAction = null;
            targetAction = null;
            worldAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "collective_score"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
        },
    //  //Increment a local score=
        { 
            aid = "increment_local_score";
            callerAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "local_score"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //Increment leaderboard score
        { 
            aid = "increment_leaderboard_example";
            callerAction = null;
            targetAction = null;
            worldAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "$caller"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "test_leaderboard"; }]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
        },
    //     //Increment DamageMul
        { 
            aid = "incrementShipADamageMul";
            callerAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "spaceshipA"; updates = [#incrementNumber { fieldName = "damageMul"; fieldValue =  #formula "{$config.spaceshipTemplate.damageMul}"; }]; };  weight = 100;},
                            ]
                        },
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //Increment DamageMul
        { 
            aid = "incrementShipAShieldMul";
            callerAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "spaceshipA"; updates = [#incrementNumber { fieldName = "shieldMul"; fieldValue =  #formula "{$config.spaceshipTemplate.shieldMul}"; }]; };  weight = 100;},
                            ]
                        },
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //SETUP SPACESHIP
        { 
            aid = "setupShipA";
            callerAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "spaceshipA"; updates = [#setNumber { fieldName = "hull"; fieldValue =  #formula "{$config.spaceshipTemplate.hull}"; }]; };  weight = 100;},
                            ]
                        },
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "spaceshipA"; updates = [#setNumber { fieldName = "shieldMul"; fieldValue =  #formula "{$config.spaceshipTemplate.shieldMul}"; }]; };  weight = 100;},
                            ]
                        },
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "spaceshipA"; updates = [#setNumber { fieldName = "damageMul"; fieldValue =  #formula "{$config.spaceshipTemplate.damageMul}"; }]; };  weight = 100;},
                            ]
                        },
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "spaceshipA"; updates = [#setNumber { fieldName = "testFormulaA"; fieldValue =  #formula "(2+3)*5"; }]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
            worldAction = null;
        },
    //     //Attack Target
        { 
            aid = "attackTargetShipA";
            callerAction = null;
            targetAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "spaceshipA"; updates = [#setNumber { fieldName = "hull"; fieldValue =  #formula "{$config.spaceshipFormulas.@newTargetHull}"; }]; };  weight = 100;},
                            ]
                        },
                    ]
                };
            };
            worldAction = null;
        },
    //     //Create Room
        { 
            aid = "TestCreateRoom";
            callerAction = null;
            targetAction = null;
            worldAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "#room_test"; updates = [
                                    #renewTimestamp { fieldName = "sessionCreationTime"; fieldValue =  #number 0; },
                                    #setNumber { fieldName = "userCount"; fieldValue =  #number 1; },
                                    #addToList { fieldName = "users"; value =  "$caller"; },
                                    #setText { fieldName = "tag"; fieldValue = "room"; }
                                ]; };  weight = 100;},
                            ]
                        },
                    ]
                };
            };
        },
    //     //Join Room
        { 
            aid = "TestJoinRoom";
            callerAction = null;
            targetAction = null;
            worldAction = ? {
                actionConstraint = ? {
                    timeConstraint = null;
                    entityConstraint = [
                    {
                        wid = null; 
                        eid = "$args.roomId"; 
                        entityConstraintType = #containsText { fieldName = "users"; value = "$caller"; contains = false; };
                    },
                    {
                        wid = null; 
                        eid = "$args.roomId"; 
                        entityConstraintType = #lessThanNumber { fieldName = "userCount"; value = 2.0;};
                    }];
                    nftConstraint = [];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "$args.roomId"; updates = [
                                    #incrementNumber { fieldName = "userCount"; fieldValue =  #number 1; }, 
                                    #addToList { fieldName = "users"; value =  "$caller"; }
                                ]; };  weight = 100;},
                            ]
                        },
                    ]
                };
            };
        },
    //     //Leave Room
        { 
            aid = "TestLeaveRoom";
            callerAction = null;
            targetAction = null;
            worldAction = ? {
                actionConstraint = ? {
                    timeConstraint = null;
                    entityConstraint = [
                    {
                        wid = null; 
                        eid = "$args.roomId"; 
                        entityConstraintType = #containsText { fieldName = "users"; value = "$caller"; contains = true; };
                    },
                    {
                        wid = null; 
                        eid = "$args.roomId"; 
                        entityConstraintType = #greaterThanNumber { fieldName = "userCount"; value = 0.0 };
                    }];
                    nftConstraint = [];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; eid = "$args.roomId"; updates = [
                                    #decrementNumber { fieldName = "userCount"; fieldValue =  #number 1; }, 
                                    #removeFromList { fieldName = "users"; value =  "$caller"; }
                                ]; };  weight = 100;},
                            ]
                        },
                    ]
                };
            };
        },
//     //Multiplayer Action
        { 
            aid = "TestMultiplayerAction_GiftToken";
            callerAction = null;
            targetAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { 
                                    option = #transferIcrc {
                                        quantity = 5;
                                        canister = ICRC1_Ledger;
                                    };  weight = 100;
                                },
                            ]
                        }
                    ]
                };
            };
            worldAction = ? {
                actionConstraint = ? {
                    timeConstraint = null;
                    entityConstraint = [
                    {
                        wid = null; 
                        eid = "$args.roomId"; 
                        entityConstraintType = #containsText { fieldName = "users"; value = "$caller"; contains = true; };
                    }];
                    nftConstraint = [];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [];
                };
            };
        },
        { 
            aid = "TestMultiplayerAction_GiftItemB";
            callerAction = null;
            targetAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null;  eid = "item_b"; updates = [#incrementNumber { fieldName = "quantity"; fieldValue =  #number 1; }, #setText { fieldName = "tag"; fieldValue = "item"; } ]; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            worldAction = ? {
                actionConstraint = ? {
                    timeConstraint = null;
                    entityConstraint = [
                    {
                        wid = null; 
                        eid = "$args.roomId"; 
                        entityConstraintType = #containsText { fieldName = "users"; value = "$caller"; contains = true; };
                    }];
                    nftConstraint = [];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [];
                };
            };
        },
    ];
}