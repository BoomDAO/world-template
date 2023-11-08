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
    public let ICRC1_Ledger = "qsnar-gqaaa-aaaam-abxnq-cai"; //Game Token
    
    public let configs : StableConfigs = [
            //Tokens
            {
                cid = "icp_details";
                fields = [
                            ("tag", "token"),
                            ("canister", "ryjl3-tyaaa-aaaaa-aaaba-cai"),
                            ("name", "ICP"),
                            ("description", "This is the base Internet Computer Token"),
                            ("urlLogo", "https://cryptologos.cc/logos/internet-computer-icp-logo.png?v=026"),
                        ];
            },
            {
                cid = "test_token_details";
                fields = [
                            ("tag", "token"),
                            ("canister", ICRC1_Ledger),
                            ("name", "Test Token"),
                            ("description", "just an Test Token"),
                            ("urlLogo", "https://cryptologos.cc/logos/dogecoin-doge-logo.png?v=026"),
                        ];
            },
            //Nfts
            {
                cid = "the_moon_walker_details";
                fields = [
                            ("tag", "nft"),
                            ("canister", "er7d4-6iaaa-aaaaj-qac2q-cai"),
                            ("isStandard", "true"),
                            ("name", "The Moonwalkers"),
                            ("description", "Dope Characters"),
                            ("urlLogo", "https://i.postimg.cc/hvyLyfwh/The-Moon-Walker-Logo.png"),
                        ];
            },
            {
                cid = "poked_bots_details";
                fields = [
                            ("tag", "nft"),
                            ("canister","er7d4-6iaaa-aaaaj-qac2q-cai"),
                            ("isStandard", "true"),
                            ("name", "Poked Bots"),
                            ("description", "Dope Characters"),
                            ("urlLogo", "https://i.postimg.cc/d1Qn5P1H/image.png"),
                        ];
            },
            {
                cid = "test_nft_collection_details";
                fields = [
                            ("tag", "nft"),
                            ("canister", Nft_Canister),
                            ("isStandard", "false"),
                            ("name", "Test Nft Collection"),
                            ("description", "This is a test collection"),
                            ("urlLogo", "https://i.postimg.cc/65smkh6B/BoomDao.jpg"),
                        ];
            },
            //Items   
            {
                cid = "character_a";
                fields = [
                            ("name", "CharacterA"),
                            ("description", "just an item"),
                            ("rarity", "common"),
                        ];
            },
            {
                cid = "character_b";
                fields = [
                            ("name", "CharacterB"),
                            ("description", "just an item"),
                            ("rarity", "common"),
                        ];
            },   
            {
                cid = "character_c";
                fields = [
                            ("name", "CharacterC"),
                            ("description", "just an item"),
                            ("rarity", "common"),
                        ];
            },   
            {
                cid = "character_d";
                fields = [
                            ("name", "CharacterD"),
                            ("description", "just an item"),
                            ("rarity", "common"),
                        ];
            },
            {
                cid = "character_e";
                fields = [
                            ("name", "CharacterE"),
                            ("description", "just an item"),
                            ("rarity", "common"),
                        ];
            },
            {
                cid = "character_f";
                fields = [
                            ("name", "CharacterF"),
                            ("description", "just an item"),
                            ("rarity", "rare"),
                        ];
            },
            {
                cid = "character_g";
                fields = [
                            ("name", "CharacterG"),
                            ("description", "just an item"),
                            ("rarity", "rare"),
                        ];
            },
            {
                cid = "character_h";
                fields = [
                            ("name", "CharacterH"),
                            ("description", "just an item"),
                            ("rarity", "special"),
                        ];
            },
            {
                cid = "character_h";
                fields = [
                            ("name", "CharacterH"),
                            ("description", "just an item"),
                            ("rarity", "special"),
                        ];
            },
            //
            {
                cid = "item_a";
                fields = [
                            ("name", "ItemA"),
                            ("description", "just an item"),
                            ("rarity", "common"),
                        ];
            },
            {
                cid = "item_b";
                fields = [
                            ("name", "ItemB"),
                            ("description", "just an item"),
                            ("rarity", "common"),
                        ];
            },
            {
                cid = "item_c";
                fields = [
                            ("name", "ItemC"),
                            ("description", "just an item"),
                            ("rarity", "common"),
                        ];
            },
            //Others
            {
                cid = "shop_window_actions";
                fields = [
                            ("buyItemA_Icp", "verifyICP"),
                            ("buyItemB_Icrc", "verifyICRC"),
                            ("buyItemC_ItemB", "trade"),
                            ("spend_icp_to_mint_test_nft", "verifyICP"),
                            ("burn_nft_tiket", "verifyNftBurn"),
                            ("nft_holding_verification", "verifyNftHold"),
                        ];
            },
    ];
    public let action : Actions = [
    //     //BURN NFT
        { 
            aid = "burn_nft_tiket";
            name = ?"Burn a Test NFT!";
            description = ?"Burn a Test NFT to get a random reward in return!";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"BurnNft";
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
                                { option = #updateEntity { wid = null; gid = "item"; eid = "character_a"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                                { option = #updateEntity { wid = null; gid = "item"; eid = "character_b"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                                { option = #updateEntity { wid = null; gid = "item"; eid = "character_c"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                                { option = #updateEntity { wid = null; gid = "item"; eid = "character_d"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
        },
    //     //BURN NFT
        { 
            aid = "nft_holding_verification";
            name = ?"TEST NFT HOLDING REWARD";
            description = ?"Get a reward for holding an nft of TEST NFT collection";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"HoldNft";
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
                                { option = #updateEntity { wid = null; gid = "item"; eid = "character_e"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                                { option = #updateEntity { wid = null; gid = "item"; eid = "character_f"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                                { option = #updateEntity { wid = null; gid = "item"; eid = "character_g"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                                { option = #updateEntity { wid = null; gid = "item"; eid = "character_h"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
        },
    //     //SPEND ICP TO MINT NFT 
        { 
            aid = "spend_icp_to_mint_test_nft";
            name = ?"Buy a Test NFT!";
            description = ?"Spend 0.001 ICP to get a \"Test NFT\" ";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Mint";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
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
                                    index = null;
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
        },
    //     //Mint Free Test NFTs
        { 
            aid = "mint_test_nft";
            name = ?"Mint a free Test NFT!";
            description = ?"Mint Two Free Test NFT";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = null;
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
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
                                    index = null;
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
        },
    //     //Mint 5 Free Test ICRC
        { 
            aid = "mint_test_icrc";
            name = ?"Test ICRC";
            description = ?"Mint 5 Free Test Token";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = null;
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
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
        },
    //     //BUY ItemA WITH ICP
        { 
            aid = "buyItemA_Icp";
            name = ?"ItemA Offer!";
            description = ?"Spend 0.001 ICP to receive an ItemA";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Offer";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
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
                                { option = #updateEntity { wid = null; gid = "item"; eid = "item_a"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
        },
    //     //BUY ItemB WITH ICRC
        { 
            aid = "buyItemB_Icrc";
            name = ?"ItemB Offer!";
            description = ?"Spend 1 Test Token to receive an ItemB";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Offer";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
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
                                { option = #updateEntity { wid = null; gid = "item"; eid = "item_b"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
        },
    //     //TRADE ItemC WITH ItemA
        { 
            aid = "buyItemC_ItemB";
            name = ?"Trading";
            description = ?"Trade an in-game ItemA for an ItemC";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Offer";
            callerAction = ? {
                actionConstraint = ? {
                    timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                    entityConstraint = [{
                    wid = null; 
                    gid = "item"; 
                    eid = "item_a"; 
                    fieldName = "quantity";
                    validation = #greaterThanEqualToNumber 1.0;
                }];
                    nftConstraint = [];
                    icpConstraint = null;
                    icrcConstraint = [];
                };
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; gid = "item"; eid = "item_a"; updateType = #decrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                            ]
                        },
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; gid = "item"; eid = "item_c"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
            targetAction = null;
        },
//     //Increment a collective score in world
        { 
            aid = "increment_collective_score";
            name = null;
            description = null;
            imageUrl = null;
            tag = null;
            callerAction = null;
            targetAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; gid = "general"; eid = "collective_score"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
        },
//     //Increment leaderboard score
        { 
            aid = "increment_leaderboard_example";
            name = null;
            description = null;
            imageUrl = null;
            tag = null;
            callerAction = null;
            targetAction = ? {
                actionConstraint = null;
                actionResult = {
                    outcomes = [
                        {
                            possibleOutcomes = [
                                { option = #updateEntity { wid = null; gid = "leaderboard_example"; eid = "$caller"; updateType = #incrementNumber { field = "quantity"; value =  #number 1; }; };  weight = 100;},
                            ]
                        }
                    ]
                };
            };
        },
    ];
}