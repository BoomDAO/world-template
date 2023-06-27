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
    public type EntityConfigs = [EntityTypes.EntityConfig]; 
    public type ActionConfigs = [ActionTypes.ActionConfig]; 
    
    public let entityConfigs : EntityConfigs = [      
        // //ITEMS
        { 
            eid = "pastry_candy_cake"; 
            gid = "";
            name = ?"Thicc Boy"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?""; 
            rarity = ?"common"; 
            duration = null;
            metadata = "";
            tag = "item skin"; 

        },
        { 
            eid = "pastry_candy_candy";
            gid = "";
            name = ?"The Candy Emperor"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";  
            rarity = ?"common"; 
            duration = null; 
            metadata = "";
            tag = "item skin"; 
        },
        { 
            eid = "pastry_candy_croissant";
            gid = "";
            name = ?"Le Frenchy"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common"; 
            duration = null;
            metadata = "";
            tag = "item skin"; 
        },
        { 
            eid = "pastry_candy_cupcake"; 
            gid = "";
            name = ?"Princess Sweet Cheeks"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "pastry_candy_donut"; 
            gid = "";
            name = ?"Donyatsu"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "pastry_candy_ice_cream";
            gid = "";
            name = ?"Prince Yummy Buddy"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"rare";
            duration = null;
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "pastry_candy_marshmallow";
            gid = "";
            name = ?"Sugar Baby"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"rare";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "pastry_candy_chocolate";
            gid = "";
            name = ?"Sir Chocobro"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"special";
            duration = null;
            metadata = "";
            tag = "item skin";
        },

        { 
            eid = "item1";
            gid = "";
            name = ?"Item 1"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        { 
            eid = "item2";
            gid = "";
            name = ?"Item 2"; 
            description = ?"just an item"; 
            imageUrl = ?"";
            objectUrl = ?"";
            rarity = ?"common";
            duration = null; 
            metadata = "";
            tag = "item skin";
        },
        //// add more items here...
    ];
    public let actionConfigs : ActionConfigs = [
        //STAKE ICP
        { 
            aid = "stakeIcp";
            name = ?"Stake Icp";
            description = ?"You can try receive reward over time for staking at least 0.005 ICP";
            tag = ?"Claim Stake";
            actionPlugin = ? #claimStakingRewardIcp 
            { 
                requiredAmount = 0.005;//0.005 ICP
            };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = {
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "pastry_candy_cake", 1);  weight = 100;},
                        ]
                    }
                ]
            };
        },
        //STAKE ICRC
        { 
            aid = "stakeIcrc";
            name = ?"Stake Icrc";
            description = ?"You can try receive reward over time for staking at least 0.005 ICP";
            tag = ?"Claim Stake";
            actionPlugin = ? #claimStakingRewardIcrc 
            { 
                requiredAmount = 0.00005;//0.005 ICRC
                baseZeroCount = 100_000_000;
                canister = ENV.ICRC1_Ledger;
            };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = {
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "pastry_candy_candy", 1);  weight = 100;},
                        ]
                    }
                ]
            };
        },
        //STAKE NFT
        { 
            aid = "stakeNft";
            name = ?"Stake Nft";
            description = ?"You can try receive reward over time for staking at least 1 Nft";
            tag = ?"Claim Stake";
            actionPlugin = ? #claimNftStakingRewardNft 
            { 
                requiredAmount = 1;//0.005 ICRC
                canister = ENV.Nft_Canister;
            };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = {
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "pastry_candy_candy", 1);  weight = 100;},
                        ]
                    }
                ]
            };
        },
        //BURN NFT
        { 
            aid = "burnPastryRewardTiketAction";
            name = ?"Pastry Reward Spin";
            description = ?"You can burn Pastry Reward Nft to get a Pastry Reward!";
            tag = ?"BurnNft";
            actionPlugin = ? #burnNft { canister = "b5kkq-6iaaa-aaaal-qb6ga-cai"; };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = {
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "pastry_candy_cake", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "pastry_candy_candy", 1); weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "pastry_candy_chocolate", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "pastry_candy_croissant", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "pastry_candy_cupcake", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "pastry_candy_donut", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "pastry_candy_ice_cream", 1);  weight = 100;},
                            { option = #receiveEntityQuantity (null,"", "pastry_candy_marshmallow", 1);  weight = 100;},
                        ]
                    }
                ]
            };
        },
        //MINT NFT
        { 
            aid = "mint_pastry_reward_tikets_nft";
            name = ?"Mint a Pastry Reward Tikets Nft";
            description = ?"You get a \"Pastry Reward Nft\" 1 by spending just 0.0001 icp";
            tag = ?"Mint";
            actionPlugin = ? #verifyTransferIcp { amt = 0.0001; toPrincipal = ENV.paymenthub_canister_id };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #mintNft {
                                name = "Tiket";
                                description = "None"; 
                                imageUrl = ""; 
                                canister  = "b5kkq-6iaaa-aaaal-qb6ga-cai";
                                assetId = "Pastry Reward Tikets";
                                collection = "Pastry Reward";
                                metadata = "{\"usage\":\"pastry-variable-offer\"}";

                            }; weight = 100;},
                        ]
                    }
                ]
            };
        },
        //BUY ITEM1 WITH ICP
        { 
            aid = "buyItem1_Icp";
            name = ?"Item 1 Offer!";
            description = ?"You get a Item 1 by spending just 0.0001 icp";
            tag = ?"Offer";
            actionPlugin = ? #verifyTransferIcp { amt = 0.0001; toPrincipal = ENV.paymenthub_canister_id };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "item1", 1); weight = 100;},
                        ]
                    }
                ]
            };
        },
        //BUY ITEM2 WITH ICRC
        { 
            aid = "buyItem2_Icrc";
            name = ?"Item 2 Offer!";
            description = ?"";
            tag = ?"Offer";
            actionPlugin = ? #verifyTransferIcrc { canister = ENV.ICRC1_Ledger; amt = 0.00001; baseZeroCount = 100_000_000; toPrincipal = ENV.paymenthub_canister_id };
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "item2", 1); weight = 100;},
                        ]
                    }
                ]
            };
        },
        //TRADE ITEM2 WITH ITEM1
        { 
            aid = "buyItem1_Item2";
            name = ?"Trade Offer";
            description = ?"";
            tag = ?"Offer";
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = ? 
                [{
                    worldId = ""; 
                    groupId = ""; 
                    entityId = "Item2"; 
                    equalToAttribute = null; 
                    greaterThanOrEqualQuantity = ? 1.0; 
                    lessThanQuantity = null; 
                    notExpired = null;
            
                }];
            };
            actionResult = { 
                outcomes = [
                    {//Substract
                        possibleOutcomes = [
                            { option = #spendEntityQuantity (null, "", "item2", 1); weight = 100;},
                        ]
                    },
                    {//Add
                        possibleOutcomes = [
                            { option = #receiveEntityQuantity (null, "", "item1", 1); weight = 100;},
                        ]
                    }
                ]
            };
        },
    ];
}