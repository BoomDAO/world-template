import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Float "mo:base/Float";
import Option "mo:base/Option";

import JSON "../utils/Json";
import RandomUtil "../utils/RandomUtil";
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
    public let ICRC1_Ledger = "6bszp-caaaa-aaaap-abgbq-cai"; //Game Token
    
    public let configs : StableConfigs = [
            //Tokens
            {
                cid = "icp_details";
                fields = [
                            ("tag", "token"),
                            ("canister","ryjl3-tyaaa-aaaaa-aaaba-cai"),
                            ("name", "ICP"),
                            ("description", "This is the base Internet Computer Token"),
                            ("urlLogo", "https://cryptologos.cc/logos/internet-computer-icp-logo.png?v=026"),
                        ];
            },
            {
                cid = "test_token_details";
                fields = [
                            ("tag", "token"),
                            ("canister","6bszp-caaaa-aaaap-abgbq-cai"),
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
                            ("canister","er7d4-6iaaa-aaaaj-qac2q-cai"),
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
                            ("canister","6uvic-diaaa-aaaap-abgca-cai"),
                            ("isStandard", "false"),
                            ("name", "Test Nft Collection"),
                            ("description", "This is a test collection"),
                            ("urlLogo", "https://i.postimg.cc/65smkh6B/BoomDao.jpg"),
                        ];
            },
            //Others   
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
    ];
    public let action : Actions = [
    //     //BURN NFT
        { 
            aid = "burn_nft_tiket";
            name = ?"Burn a Test NFT!";
            description = ?"Burn a Test NFT to get a random reward in return!";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"BurnNft";
            actionPlugin = ? #verifyBurnNfts { canister = Nft_Canister; requiredNftMetadata = ?[]; };
            actionConstraint = null;
            actionResult = {
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "character_a"; field = "quantity"; value =  1;};  weight = 100;},
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "character_b"; field = "quantity"; value =  1;};  weight = 100;},
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "character_c"; field = "quantity"; value =  1;};  weight = 100;},
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "character_d"; field = "quantity"; value =  1;};  weight = 100;},
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "character_e"; field = "quantity"; value =  1;};  weight = 100;},
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "character_f"; field = "quantity"; value =  1;};  weight = 100;},
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "character_g"; field = "quantity"; value =  1;};  weight = 100;},
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "character_h"; field = "quantity"; value =  1;};  weight = 100;},
                        ]
                    }
                ]
            };
        },
    //     //SPEND ICP TO MINT NFT 
        { 
            aid = "spend_icp_to_mint_test_nft";
            name = ?"Buy a Test NFT!";
            description = ?"Spend 0.001 ICP to get a \"Test NFT\" ";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Mint";
            actionPlugin = ? #verifyTransferIcp { amt = 0.001; toPrincipal = ENV.PaymentHubCanisterId };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #mintNft {
                                index = null;
                                name = "Test Nft";
                                description = "Spend 0.001 ICP to purchase a Test NFT."; 
                                imageUrl = ""; 
                                canister  = Nft_Canister;
                                assetId = "testAsset";
                                collection = "Nft Reward";
                                metadata = "samir";
                            }; weight = 100;},
                        ]
                    }
                ]
            };
        },
    //     //Mint Free Test NFTs
        { 
            aid = "mint_test_nft";
            name = ?"Mint a free Test NFT!";
            description = ?"Mint Two Free Test NFT";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = null;
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #mintNft {
                                index = null;
                                name = "Test Nft";
                                description = "Mint a free Test NFT"; 
                                imageUrl = ""; 
                                canister  = Nft_Canister;
                                assetId = "testAsset";
                                collection = "Nft Reward";
                                metadata = "jack";
                            }; weight = 100;},
                        ]
                    },
                ]
            };
        },
    //     //Mint 5 Free Test ICRC
        { 
            aid = "mint_test_icrc";
            name = ?"Test ICRC";
            description = ?"Mint 5 Free Test Token";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = null;
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #mintToken {
                                quantity = 5;
                                canister = ICRC1_Ledger;
                            }; weight = 100;},
                        ]
                    }
                ]
            };
        },
    //     //BUY ItemA WITH ICP
        { 
            aid = "buyItemA_Icp";
            name = ?"ItemA Offer!";
            description = ?"Spend 0.001 ICP to receive an ItemA";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Offer";
            actionPlugin = ? #verifyTransferIcp { amt = 0.001; toPrincipal = ENV.PaymentHubCanisterId };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "item_a"; field = "quantity"; value =  1;};  weight = 100;},
                        ]
                    }
                ]
            };
        },
    //     //BUY ItemB WITH ICRC
        { 
            aid = "buyItemB_Icrc";
            name = ?"ItemB Offer!";
            description = ?"Spend 1 Test Token to receive an ItemB";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Offer";
            actionPlugin = ? #verifyTransferIcrc { canister = ICRC1_Ledger; amt = 1; toPrincipal = ENV.PaymentHubCanisterId };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "item_b"; field = "quantity"; value =  1;};  weight = 100;},
                        ]
                    }
                ]
            };
        },
    //     //TRADE ItemC WITH ItemB
        { 
            aid = "buyItemC_ItemB";
            name = ?"Trading";
            description = ?"Trade an in-game ItemB for an ItemC";
            imageUrl = ?"https://i.postimg.cc/65smkh6B/BoomDao.jpg";
            tag = ?"Offer";
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 15_000_000_000; actionsPerInterval = 1; };
                entityConstraint = ? //to replace this two constraints for a greaterThanOrEqualTo
                [{
                    wid = ?"6irst-uiaaa-aaaap-abgaa-cai"; 
                    gid = "item"; 
                    eid = "item_b"; 
                    fieldName = "quantity";
                    validation = #greaterThanEqualToNumber 1.0;
                }];
            };
            actionResult = { 
                outcomes = [
                    {//Substract
                        possibleOutcomes = [
                            { option = #decrementNumber { wid = null; gid = "item"; eid = "item_b"; field = "quantity"; value =  1.0;};  weight = 100;},
                        ]
                    },
                    {//Add
                        possibleOutcomes = [
                            { option = #incrementNumber { wid = null; gid = "item"; eid = "item_c"; field = "quantity"; value =  1.0;};  weight = 100;},
                        ]
                    }
                ]
            };
        },
    ];
}