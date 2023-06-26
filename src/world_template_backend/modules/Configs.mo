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
import TDatabase "../types/world.types";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";

module{
    // ================ CONFIGS ========================= //
    public type EntityConfig = 
    {
        eid: Text;
        gid: Text;
        name: ?Text;
        description: ?Text;
        imageUrl: ?Text;
        objectUrl: ?Text;
        rarity: ?Text;
        duration: ?Nat;
        tag: Text;
        metadata: Text;
    };

    //ActionResult
    public type entityId = Text;
    public type groupId = Text;
    public type worldId = ?Text;

    public type attribute = Text;
    public type quantity = Float;
    public type duration = Nat;
    
    public type MintToken = 
    {
        name: Text;
        description : Text; 
        imageUrl: Text; 
        canister : Text;
    };
    public type MintNft = 
    {
        name: Text;
        description : Text; 
        imageUrl: Text; 
        canister : Text;
        assetId: Text;
        collection:  Text;
        metadata: Text;
    };
    public type ActionOutcomeOption = {
        weight: Float;
        option : {
            #mintToken : MintToken;
            #mintNft : MintNft;
            #setEntityAttribute : (
                worldId,
                groupId,
                entityId,
                attribute
            );
            #spendEntityQuantity : (
                worldId,
                groupId,
                entityId,
                quantity
            );
            #receiveEntityQuantity : (
                worldId,
                groupId,
                entityId,
                quantity
            );
            #renewEntityExpiration : (
                worldId,
                groupId,
                entityId,
                duration
            );
            #reduceEntityExpiration : (
                worldId,
                groupId,
                entityId,
                duration
            );
            #deleteEntity : (
                worldId,
                groupId,
                entityId
            );
        }
    };
    public type ActionOutcome = {
        possibleOutcomes: [ActionOutcomeOption];
    };
    public type ActionResult = {
        outcomes: [ActionOutcome];
    };

    //ActionConfig
    public type ActionArg = 
    {
        #default : {actionId: Text; };
        #burnNft : {actionId: Text; index: Nat32; };
        #spendTokens : {actionId: Text; hash: Nat64; };
        #claimStakingReward : {actionId: Text; };
    };

    public type ActionPlugin = 
    {
        #burnNft : {nftCanister: Text;};
        #spendTokens : {tokenCanister: ? Text; amt: Float; baseZeroCount: Nat;  toPrincipal : Text; };
        #claimStakingReward : { requiredAmount : Float; baseZeroCount: Nat; tokenCanister: Text; };
    };
    public type ActionConstraint = 
    {
        timeConstraint: ? {
            intervalDuration: Nat; 
            actionsPerInterval: Nat; 
        };
        entityConstraint : ? [{ 
            worldId: Text; 
            groupId: Text; 
            entityId: Text; 
            equalToAttribute: ?Text; 
            greaterThanOrEqualQuantity: ?Float; 
            lessThanQuantity: ?Float; 
            notExpired: ?Bool
        }];
    };
    public type ActionConfig = 
    {
        aid : Text;
        name : ?Text;
        description : ?Text;
        tag : ?Text;
        actionPlugin: ?ActionPlugin;
        actionConstraint: ?ActionConstraint;
        actionResult: ActionResult;
    };

    //ConfigDataType

    public type EntityConfigs = [EntityConfig]; 
    public type ActionConfigs = [ActionConfig]; 
    
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
        { 
            aid = "stakeIcp";
            name = ?"Stake Icp";
            description = ?"You can try receive reward over time for staking at least 0.005 ICP";
            tag = ?"Claim Stake";
            actionPlugin = ? #claimStakingReward 
            { 
                requiredAmount = 0.005;//0.005 ICP
                baseZeroCount = 100_000_000;
                tokenCanister = ENV.Ledger
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
        { 
            aid = "stakeIcrc";
            name = ?"Stake Icrc";
            description = ?"You can try receive reward over time for staking at least 0.005 ICP";
            tag = ?"Claim Stake";
            actionPlugin = ? #claimStakingReward 
            { 
                requiredAmount = 0.00005;//0.005 ICRC
                baseZeroCount = 100_000_000;
                tokenCanister = ENV.ICRC1_Ledger;
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
        { 
            aid = "burnPastryRewardTiketAction";
            name = ?"Pastry Reward Spin";
            description = ?"You can burn Pastry Reward Nft to get a Pastry Reward!";
            tag = ?"BurnNft";
            actionPlugin = ? #burnNft { nftCanister = "b5kkq-6iaaa-aaaal-qb6ga-cai"; };
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
        { 
            aid = "mint_pastry_reward_tikets_nft";
            name = ?"Mint a Pastry Reward Tikets Nft";
            description = ?"You get a \"Pastry Reward Nft\" 1 by spending just 0.0001 icp";
            tag = ?"Mint";
            actionPlugin = ? #spendTokens { tokenCanister =  null; amt = 0.0001; baseZeroCount = 100_000_000; toPrincipal = ENV.paymenthub_canister_id };
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
        { 
            aid = "buyItem1_Icp";
            name = ?"Item 1 Offer!";
            description = ?"You get a Item 1 by spending just 0.0001 icp";
            tag = ?"Offer";
            actionPlugin = ? #spendTokens { tokenCanister =  null; amt = 0.0001; baseZeroCount = 100_000_000; toPrincipal = ENV.paymenthub_canister_id };
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
        { 
            aid = "buyItem2_Icrc";
            name = ?"Item 2 Offer!";
            description = ?"";
            tag = ?"Offer";
            actionPlugin = ? #spendTokens { tokenCanister = ? ENV.ICRC1_Ledger; amt = 0.00001; baseZeroCount = 100_000_000; toPrincipal = ENV.paymenthub_canister_id };
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
        { 
            aid = "buyItem1_Item2";
            name = ?"Trade Offer";
            description = ?"";
            tag = ?"Offer";
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
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
                { 
            aid = "buyPastrySpinNft_Item1";
            name = ?"Buy Pastry Spin Nft";
            description = ?"";
            tag = ?"Offer";
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
            };
            actionResult = { 
                outcomes = [
                    {//Substract
                        possibleOutcomes = [
                            { 
                                option = #mintNft 
                                {
                                    assetId = "0";
                                    canister = "b5kkq-6iaaa-aaaal-qb6ga-cai";
                                    collection = "NFT Ticket Test";
                                    description = ""; 
                                    imageUrl = ""; 
                                    metadata = ""; 
                                    name = ""
                                }; 
                                weight = 100;
                            },
                        ]
                    },
                    {//Add
                        possibleOutcomes = [
                            { option = #spendEntityQuantity (null, "", "item1", 1); weight = 100;},
                        ]
                    }
                ]
            };
        },
        { 
            aid = "burn_pastrySpinNft";
            name = ?"Burn Pastry Spin Nft";
            description = ?"";
            tag = ?"BurnNft";
            actionPlugin = null;
            actionConstraint = ? {
                timeConstraint = ? { intervalDuration = 120_000_000_000; actionsPerInterval = 1; };
                entityConstraint = null;
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