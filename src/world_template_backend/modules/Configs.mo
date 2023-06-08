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

module{
    public type entityId = Text;
    public type gameId = Text;
    public type userId = Text;
    public type nodeId = Text;
    // ================ CONFIGS ========================= //
    type TokenConfig = 
    {
        name: Text;
        description : Text; 
        urlImg: Text; 
        canister : Text;
    };
    type NftConfig = 
    {
        name: Text;
        description : Text; 
        urlImg: Text; 
        canister : Text;
        assetId: Text;
        collection:  Text;
        metadata: Text;
    };
    type StatConfig = 
    {
        name: Text;
        description : Text; 
        urlImg: Text; 
        type_ : Text;
    };
    type ItemConfig = 
    {
        name: Text;
        description : Text; 
        urlImg: Text; 
        tag : Text;
        rarity: Text;
    };

    //Offer
    type OfferConfig = 
    {        
        title: Text;
        description: Text;
        amount : Float;
    };

    //ActionResult
    type CustomData = TDatabase.CustomData;
    
    public type UpdateStandardEntity = {
        weight: Float;
        update : {
            #incrementQuantity : (
                gameId,
                entityId,
                Float
            );
            #decrementQuantity : (
                gameId,
                entityId,
                Float
            );
            #incrementExpiration : (
                gameId,
                entityId,
                Nat
            );
            #decrementExpiration : (
                gameId,
                entityId,
                Nat
            );
        }
    };
    public type UpdateCustomEntity = {
        weight: Float;
        setCustomData : ?(gameId, entityId, CustomData);
    };
    public type ActionOutcome = {
        #standard : UpdateStandardEntity;
        #custom : UpdateCustomEntity;
    };
    public type ActionRoll = {
        outcomes: [ActionOutcome];
    };
    public type ActionResult = 
    {
        rolls: [ActionRoll];
    };

    //ActionConfig
    public type ActionDataType = 
    {
        #burnNft : {nftCanister: Text;};
        #spendTokens : {tokenCanister: Text; amt: Float; to : Text; };
        #spendEntities : {entities: [(gid : Text, eid : Text, quantity : Float)]};
        #claimStakingReward : { requiredAmount : Nat };
    };
    public type ActionConstraint = 
    {
        #timeConstraint: { intervalDuration: Nat; actionsPerInterval: Nat; };
        #entityConstraint : { entityId: Text; greaterThan: ?Nat; lessThan: ?Nat; };
    };
    public type ActionConfig = 
    {
        actionDataType: ActionDataType;
        actionResult: ActionResult;
        actionConstraints: ?[ActionConstraint];
    };

    //ConfigDataType
    public type ConfigDataType = {
        #token : TokenConfig;
        #nft : NftConfig;
        #stat : StatConfig;
        #item : ItemConfig;
        #offer : OfferConfig;
        #action : ActionConfig;
    };

    public type EntityConfig = {
        eid : Text;
        configDataType : ConfigDataType;
    };
    
    public type Configs = [EntityConfig]; 
    
    public let configs : Configs = [
        //TOKENS
        { 
            eid = "token_test";
            configDataType = #token { name = "Token Test"; description = "This is a test token"; urlImg = ""; canister = ENV.ICRC1_Ledger }
        },
        
        //NFTS
        { 
            eid = "pastry_reward"; 
            configDataType = #nft { name = "Pastry Reward"; description = "Burn it to mint an Pastry Nft"; urlImg = ""; canister = "jh775-jaaaa-aaaal-qbuda-cai"; assetId = "0"; collection = "Plethora Items"; metadata = "" }
        },
        
        //ITEMS
        { 
            eid = "pastry_candy_cake"; 
            configDataType = #item { name = "Thicc Boy"; description = "just an item"; urlImg = ""; tag = ""; rarity = "common"; }
        },
        { 
            eid = "pastry_candy_candy"; configDataType = #item { name = "The Candy Emperor"; description = "just an item"; urlImg = ""; tag = ""; rarity = "common"; }
        },
        { 
            eid = "pastry_candy_croissant"; 
            configDataType = #item { name = "Le Frenchy"; description = "just an item"; urlImg = ""; tag = ""; rarity = "common"; }
        },
        { 
            eid = "pastry_candy_cupcake"; 
            configDataType = #item { name = "Princess Sweet Cheeks"; description = "just an item"; urlImg = ""; tag = ""; rarity = "common"; }
        },
        { 
            eid = "pastry_candy_donut"; 
            configDataType = #item { name = " Donyatsu"; description = "just an item"; urlImg = ""; tag = ""; rarity = "common"; }
        },
        { 
            eid = "pastry_candy_ice_cream"; 
            configDataType = #item { name = "Prince Yummy Buddy"; description = "just an item"; urlImg = ""; tag = ""; rarity = "rare"; }
        },
        { 
            eid = "pastry_candy_marshmallow"; 
            configDataType = #item { name = "Sugar Baby"; description = "just an item"; urlImg = ""; tag = ""; rarity = "rare"; }
        },
        { 
            eid = "pastry_candy_chocolate"; 
            configDataType = #item { name = "Sir Chocobro"; description = "just an item"; urlImg = ""; tag = ""; rarity = "special"; }
        },

        { 
            eid = "item1"; 
            configDataType = #item { name = "Item 1"; description = "just an item"; urlImg = ""; tag = ""; rarity = "common"; }
        },
        { 
            eid = "item2"; 
            configDataType = #item { name = "Item 2"; description = "just an item"; urlImg = ""; tag = ""; rarity = "common"; }
        },
        
        //GACHAS
        { 
            eid = "test_nft_ic"; 
            configDataType = #gacha { rolls = 
        [
            {
                variables = [
                    { entity = {eid = "pastry_candy_cake"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 },
                    { entity = {eid = "pastry_candy_candy"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 },
                    { entity = {eid = "pastry_candy_chocolate"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 },
                    { entity = {eid = "pastry_candy_croissant"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 },
                    { entity = {eid = "pastry_candy_cupcake"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 },
                    { entity = {eid = "pastry_candy_donut"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 },
                    { entity = {eid = "pastry_candy_ice_cream"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 },
                    { entity = {eid = "pastry_candy_marshmallow"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 },
                ]
            }
                ]
            }
        },
        { 
            eid = "test_item_ic"; 
            configDataType = #gacha { rolls = 
        [
            {
                variables = [
                    { entity = {eid = "item1"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 }
                ]
            }
                ]
            }
        },
        { 
            eid = "test_item_rc"; 
            configDataType =#gacha { rolls = 
        [
            {
                variables = [
                    { entity = {eid = "item2"; gid = "game"; customData : ? TDatabase.CustomData = null; quantity = ?1; timestamp = null}; weight = 100 }
                ]
            }
                ]
            }
        },
        
        //OFFERS
        { 
            eid = "test_item_ic";
            configDataType = #offer {
            title = "test_item_ic";
            description = "test_item_ic";
            amount = 0.0001;
            }
        },
        
        //ACTIONS
        { 
            eid = "burnPastryRewardAction";
            configDataType =#action {
            actionDataType = #burnNft { nftCanister = ""; index = ""; };
            timeConstraint = ? {intervalDuration = 120_000_000_000; actionsPerInterval = 1};
            gachaRewardConfigId = "test_nft_ic";
            }
        },
        { 
            eid = "buyItem1_Icp";
            configDataType =#action {
            actionDataType = #spendTokens { tokenCanister =  ENV.Ledger; amt = 0.0001; to = ENV.paymenthub_canister_id; };
            timeConstraint = ? {intervalDuration = 120_000_000_000; actionsPerInterval = 1};
            gachaRewardConfigId = "test_item_ic";
            }
        },
        { 
            eid = "buyItem2_item1";
            configDataType =#action {
            actionDataType = #spendEntities { entities = [
                ("game_gid", "item1_eid", 5) //GameId, EntityId, Quantity
            ]};
            timeConstraint = ? {intervalDuration = 120_000_000_000; actionsPerInterval = 1};
            gachaRewardConfigId = "test_item_rc";
            }
        },
        { 
            eid = "buyItem2_Icrc";
            configDataType =#action {
            actionDataType = #spendTokens { tokenCanister =  ENV.ICRC1_Ledger; amt = 0.0001; to = ENV.paymenthub_canister_id; };
            timeConstraint = ? {intervalDuration = 120_000_000_000; actionsPerInterval = 1};
            gachaRewardConfigId = "test_item_rc";
        }
        }
        
        // add more items here...
    ];
}