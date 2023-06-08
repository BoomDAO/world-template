import A "mo:base/AssocList";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Char "mo:base/Char";
import Error "mo:base/Error";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Map "mo:map/Map";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Int8 "mo:base/Int8";
import Iter "mo:base/Iter";
import L "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Trie2D "mo:base/Trie";

import JSON "../utils/Json";
import Parser "../utils/Parser";
import ENV "../utils/Env";
import Utils "../utils/Utils";
import Leaderboard "../modules/Leaderboard";
import Json "../utils/Json";
import RandomUtil "../utils/RandomUtil";
import EXTCORE "../utils/Core";
import EXT "../types/ext.types";
import AccountIdentifier "../utils/AccountIdentifier";
import ICP "../types/icp.types";
import ICRC1 "../types/icrc.types";
import TDatabase "../types/world.types";
import TStaking "../types/staking.types";

//import TStakeHub "../../../../standard/StakingStandard/StakingHub.mo";
import Config "../modules/Configs";

actor GameCanisterTemplate {
    //Interfaces
    private type WorldNode = actor {
        processActionEntities : shared (uid : TDatabase.userId, actionConfig : Config.ActionConfig) -> async (Result.Result<[TDatabase.Entity]>);
    };
    private type WorldbHub = actor {
        getUserCanisterId : shared (Text) -> async (Result.Result<Text, Text>);
    };
    private type StakeHub = actor {
        getUserStakes : shared (Text) -> async ([TStaking.Stake]);
    };  
    
    let worldhub : WorldbHub = actor(ENV.WorldbHub);

    let test_nft_principal = "jh775-jaaaa-aaaal-qbuda-cai";

    //stable memory
    private stable var _admins : [Text] = ENV.admins;

    private stable var isInit : Bool = false;

    //Configs
    private var configs = Buffer.Buffer<Config.EntityConfig>(0);
    private stable var tempUpdateConfig : Config.Configs = [];
    
    let { phash; } = Map;
    stable let userActionInteration = Map.new<Principal, (iterationCount : Nat, startTs : Int)>(phash);

    system func preupgrade() {        
        if(isInit){
            tempUpdateConfig := Buffer.toArray(configs);
        }
    };
    system func postupgrade() {
        if(isInit == false){
            isInit := true;
            configs := Buffer.fromArray(Config.configs);
        }
        else {
            configs := Buffer.fromArray(tempUpdateConfig);
            tempUpdateConfig := [];
        }
    };

    private shared query ({ caller }) func this() : async (Principal) {
        return caller;
    };

    //Internal Functions
    private func isAdmin_(_p : Principal) : (Bool) {
        var p : Text = Principal.toText(_p);
        for (i in _admins.vals()) {
            if (p == i) {
                return true;
            };
        };
        return false;
    };

    //utils
    public shared ({ caller }) func addAdmin(p : Text) : async () {
        assert (isAdmin_(caller));
        var b : Buffer.Buffer<Text> = Buffer.fromArray(_admins);
        b.add(p);
        _admins := Buffer.toArray(b);
    };

    public shared ({ caller }) func removeAdmin(p : Text) : async () {
        assert (isAdmin_(caller));
        var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (i in _admins.vals()) {
            if (i != p) {
                b.add(i);
            };
        };
        _admins := Buffer.toArray(b);
    };

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    //Remote_Configs of Game Canister
    private func _getSpecificConfig(id : Text) : (? Config.ConfigDataType) {
        for (config in configs.vals()) {
            if(config.id == id) return ? config.configDataType;
        };
        return null;
    };

    private func _getSpecificConfigs(configIds : [Text]) : (Buffer.Buffer<?Config.ConfigDataType>) {
        var result = Buffer.Buffer<?Config.ConfigDataType>(0);
        for (id in configIds.vals()) {
            var found: ?Config.ConfigDataType = null;
            found := _getSpecificConfig(id);

            result.add(found);
        };
        return result;
    };

    public func getSpecificConfig(configId : Text) : async (? Config.ConfigDataType) {
        return _getSpecificConfig(configId);
    };

    public func getSpecificConfigs(configIds : [Text]) : async ([?Config.ConfigDataType]){
        return Buffer.toArray(_getSpecificConfigs(configIds));
    };

    private func _configExist(id : Text) : (Bool, Int){
        var index = 0;
        for(configElement in configs.vals()){
            if(configElement.id == id) return (true, index);
            index += 1;
        };
        return (false, -1);
    };
    public shared ({ caller }) func createConfig(id : Text, configDataType : Config.ConfigDataType) : async (Result.Result<Text, Text>) {
        let confixExist = _configExist(id);
        if(confixExist.0){
            configs.add({id; configDataType; });
            return #ok("all good :)");
        };
        return #err("there is an entity already using that id, you can try updateConfig");
    };

    public shared ({ caller }) func updateConfig(id : Text,  configDataType : Config.ConfigDataType) : async (Result.Result<Text, Text>) {
        let confixExist = _configExist(id);
        if(confixExist.0){
            var index = Utils.intToNat(confixExist.1);
            configs.put(index, {id; configDataType; });
            return #ok("all good :)");
        };
        return #err("there is no entity using that id");
    };

    public shared ({ caller }) func deleteConfig(id : Text) : async (Result.Result<Text, Text>) {
        let confixExist = _configExist(id);
        if(confixExist.0){
            ignore configs.remove(Utils.intToNat(confixExist.1));
            return #ok("all good :)");
        };
        return #err("there is no entity using that id");
    };


    //Burn and Mint NFT's
    // public shared (msg) func burnNft(collection_canister_id : Text, tokenindex : EXT.TokenIndex, aid : EXT.AccountIdentifier, gachaConfigId : Text) : async (Result.Result<[(gameId : Text, entityId : Text, quantity : Float)] , Text>) {
    //     assert (AccountIdentifier.fromPrincipal(msg.caller, null) == aid);
    //     var tokenid : EXT.TokenIdentifier = EXTCORE.TokenIdentifier.fromText(collection_canister_id, tokenindex);
    //     let collection = actor (collection_canister_id) : actor {
    //         ext_burn : (EXT.TokenIdentifier, EXT.AccountIdentifier) -> async (Result.Result<(), EXT.CommonError>);
    //         extGetTokenMetadata : (EXT.TokenIndex) -> async (?EXT.Metadata);
    //     };
    //     var res : Result.Result<(), EXT.CommonError> = await collection.ext_burn(tokenid, aid);
    //     switch (res) {
    //         case (#ok) {
    //             //notify server using http req
    //             var m : ?EXT.Metadata = await collection.extGetTokenMetadata(tokenindex);
    //             var json : Text = "";
    //             switch (m) {
    //                 case (?md) {
    //                     switch (md) {
    //                         case (#fungible _) {};
    //                         case (#nonfungible d) {
    //                             switch (d.metadata) {
    //                                 case (?x) {
    //                                     switch (x) {
    //                                         case (#json j) { json := j };
    //                                         case (#blob _) {};
    //                                         case (#data _) {};
    //                                     };
    //                                 };
    //                                 case _ {};
    //                             };
    //                         };
    //                     };
    //                 };
    //                 case _ {};
    //             };

    //             //Apply gacha to user
    //             var configType : ? Config.ConfigDataType = null;
    //             configType := Config.getSpecificConfig(gachaConfigId);
    //             switch(configType){
    //                 case(? notNull){
    //                     switch(notNull){
    //                         case(#gacha(configs)){
    //                             return await processGacha(aid, configs);
    //                         };
    //                         case(_){
    //                             return #err("config of id: \""#gachaConfigId#"\" mismatch type")
    //                         };
    //                     };
    //                 };
    //                 case(_){
    //                     return #err("config of id: \""#gachaConfigId#"\" could not be found")
    //                 }
    //             };
                
    //         };
    //         case (#err(e)) {
    //             return #err("Nft Butn, Something went wrong while burning nft");
    //         };
    //     };
    // };
    //Payments : redirected to PaymentHub for verification and holding update.
    // public shared ({caller}) func verifyTxIcp(height : Nat64, _to : Text, _from : Text, _amt : Nat64, gachaConfigId : Text) : async (Result.Result<[(gameId : Text, entityId : Text, quantity : Float)], Text>) {
    //     assert (Principal.fromText(_from) == caller); //If payment done by correct person and _from arg is passed correctly

    //     let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
    //         verifyTxIcp : shared (Nat64, Text, Text, Nat64) -> async ({
    //             #Success : Text;
    //             #Err : Text;
    //         });
    //     };
    //     switch (await paymenthub.verifyTxIcp(height, _to, _from, _amt)) {
    //         case (#Success s) {
    //             //Apply gacha to user
    //             var configType : ? Config.ConfigDataType = null;
    //             configType := Config.getSpecificConfig(gachaConfigId);
    //             switch(configType){
    //                 case(? notNull){
    //                     switch(notNull){
    //                         case(#gacha(configs)){
    //                             return await processGacha(_from, configs);
    //                         };
    //                         case(_){
    //                             return #err("config of id: \""#gachaConfigId#"\" mismatch type")
    //                         };
    //                     };
    //                 };
    //                 case(_){
    //                     return #err("config of id: \""#gachaConfigId#"\" could not be found")
    //                 }
    //             };
        
    //         };
    //         case (#Err e) {
    //             return #err(e);
    //         };
    //     };
    // };
    // public shared ({caller}) func verifyTxIcrc(index : Nat, _to : Text, _from : Text, _amt : Nat, gachaConfigId : Text) : async (Result.Result<[(gameId : Text, entityId : Text, quantity : Float)], Text>) {
    //     let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
    //         verifyTxIcrc : shared (Nat, Text, Text, Nat) -> async ({
    //             #Success : Text;
    //             #Err : Text;
    //         });
    //     };
    //     switch (await paymenthub.verifyTxIcrc(index, _to, _from, _amt)) {
    //         case (#Success s) {
    //             //Apply gacha to user
    //             var configType : ? Config.ConfigDataType = null;
    //             configType := Config.getSpecificConfig(gachaConfigId);
    //             switch(configType){
    //                 case(? notNull){
    //                     switch(notNull){
    //                         case(#gacha(configs)){
    //                             return await processGacha(_from, configs);
    //                         };
    //                         case(_){
    //                             return #err("config of id: \""#gachaConfigId#"\" mismatch type")
    //                         };
    //                     };
    //                 };
    //                 case(_){
    //                     return #err("config of id: \""#gachaConfigId#"\" could not be found")
    //                 }
    //             };
    //         };
    //         case (#Err e) {
    //             return #err(e);
    //         };
    //     };
    // };

    // public shared ({ caller }) func processPlayerAction(actionArg: Config.ActionArg): async (Result.Result<[(gameId : Text, entityId : Text, quantity : Float)], Text>) { 
    //     //Todo: Check for each action the timeConstraint
    //     switch(actionArg){
    //         case(#burnNft(arg)){
    //             var configType : ? Config.ConfigDataType = null;
    //             configType := Config.getSpecificConfig(arg.actionId);

    //             switch(configType){
    //                 case(? notNull){
    //                     switch(notNull){
    //                         case(#action(configs)){

    //                             switch(configs.actionType){
    //                                 case(#burnNft(unwrappedActionType)){
    //                                     return await burnNft(unwrappedActionType.nftCanister, arg.index, arg.aid, configs.gachaRewardConfigId);
    //                                 };
    //                                 case(_){
    //                                     return #err("Something went wrong, argument type \"burnNft\" mismatches config type")
    //                                 }
    //                             }
    //                         };
    //                         case(_){
    //                             //SOMETHING WENT WRONG
    //                             return #err("config of id: \""#arg.actionId#"\" mismatch type")
    //                         };
    //                     }
    //                 };
    //                 case(_){
    //                     return #err("Config of id: \""#arg.actionId#"\" could not be found")
    //                 }
    //             }
    //         };
    //         case(#spendTokens(arg)){
    //             var configType : ? Config.ConfigDataType = null;
    //             configType := Config.getSpecificConfig(arg.actionId);

    //             switch(configType){
    //                 case(? notNull){
    //                     switch(notNull){
    //                         case(#action(configs)){

    //                             switch(configs.actionType){
    //                                 case(#spendTokens(unwrappedActionType)){
    //                                     if(unwrappedActionType.to == ENV.Ledger){
    //                                         return await verifyTxIcp(arg.hash, unwrappedActionType.to, arg.from, Utils.tokenizeToIcp(unwrappedActionType.amt), configs.gachaRewardConfigId);
    //                                     }
    //                                     else {
    //                                         return await verifyTxIcrc(Nat64.toNat(arg.hash), unwrappedActionType.to, arg.from, Nat64.toNat(Utils.tokenizeToIcrc(unwrappedActionType.amt, 1000_000_000_000_000_000)), configs.gachaRewardConfigId);
    //                                     };
    //                                 };
    //                                 case(_){
    //                                     return #err("Something went wrong, argument type \"burnNft\" mismatches config type")
    //                                 }
    //                             }
    //                         };
    //                         case(_){
    //                             //SOMETHING WENT WRONG
    //                             return #err("config of id: \""#arg.actionId#"\" mismatch type")
    //                         };
    //                     }
    //                 };
    //                 case(_){
    //                     return #err("Config of id: \""#arg.actionId#"\" could not be found")
    //                 }
    //             };
    //         };
    //         case(#spendEntities(arg)){
    //             var configType : ? Config.ConfigDataType = null;
    //             configType := Config.getSpecificConfig(arg.actionId);
 
    //             switch(configType){
    //                 case(? notNull){
    //                     switch(notNull){
    //                         case(#action(configs)){
    //                             switch(configs.actionType){
    //                                 case(#spendEntities(unwrappedActionType)){
    //                                     let callerText = Principal.toText(caller);
    //                                     var canister_id : Text = "";
    //                                     switch (await worldhub.getUserCanisterId(callerText)){
    //                                         case (#ok c){
    //                                             canister_id := c;
    //                                         };
    //                                         case _ {
    //                                         };
    //                                     };

    //                                     let worldNode : WorldNode = actor(canister_id);
    //                                     let transactResult = await worldNode.transactEntities(callerText , Principal.toText(await this()), { incrementQuantity = null; decrementQuantity = ? unwrappedActionType.entities; setCustomData = null  });

    //                                     if(transactResult == #err("if failure")){
    //                                         //TODO: throw error
    //                                     };

    //                                     var configType : ? Config.ConfigDataType = null;
    //                                     configType := Config.getSpecificConfig(configs.gachaRewardConfigId);
    //                                     switch(configType){
    //                                         case(? notNull){
    //                                             switch(notNull){
    //                                                 case(#gacha(configs)){
    //                                                     return await processGacha(callerText, configs);
    //                                                 };
    //                                                 case(_){
    //                                                     return #err("config of id: \""#configs.gachaRewardConfigId#"\" mismatch type");
    //                                                 };
    //                                             };
    //                                         };
    //                                         case(_){
    //                                             return #err("config of id: \""#configs.gachaRewardConfigId#"\" could not be found");
    //                                         }
    //                                     };
    //                                 };
    //                                 case(_){
    //                                     return #err("Something went wrong, argument type \"burnNft\" mismatches config type")
    //                                 }
    //                             }
    //                         };
    //                         case(_){
    //                             //SOMETHING WENT WRONG
    //                             return #err("config of id: \""#arg.actionId#"\" mismatch type")
    //                         };
    //                     }
    //                 };
    //                 case(_){
    //                     return #err("Config of id: \""#arg.actionId#"\" could not be found")
    //                 };
    //             };
    //         };
    //         case(#claimStakingReward(arg)){
    //             var configType : ? Config.ConfigDataType = null;
    //             configType := Config.getSpecificConfig(arg.actionId);
 
    //             switch(configType){
    //                 case(? notNull){
    //                     switch(notNull){
    //                         case(#action(configs)){
    //                             //CHECK TIME CONSTRAINS
    //                             switch(configs.timeConstraint){
    //                                 case(? timeConstraint){
                                        
    //                                     //Ensure Constrain Entry exist
    //                                     switch (Map.get(userActionInteration, phash, caller)){
    //                                         case(null){
    //                                             Map.set(userActionInteration, phash, caller, (1, Time.now()));
    //                                         };
    //                                         case(?constrainState){
    //                                             let iterationCount = constrainState.0;
    //                                             let startTs = constrainState.1;

    //                                             if(Time.now() > startTs + timeConstraint.intervalDuration){
    //                                                 return #err("to soon to be used");
    //                                             };

    //                                             Map.set(userActionInteration, phash, caller, (1, Time.now()));
    //                                         };
    //                                     };
    //                                 };
    //                                 case(_){};//DO NOTHING
    //                             };

    //                             //
    //                             switch(configs.actionType){
    //                                 case(#claimStakingReward(unwrappedActionType)){
    //                                     let callerText = Principal.toText(caller);
    //                                     var canister_id : Text = "";
    //                                     switch (await worldhub.getUserCanisterId(callerText)){
    //                                         case (#ok c){
    //                                             canister_id := c;
    //                                         };
    //                                         case _ {
    //                                         };
    //                                     };

    //                                     let caller_as_text = Principal.toText(caller);
    //                                     let stakeHub : StakeHub = actor(ENV.stakinghub_canister_id);

    //                                     let stakes = await stakeHub.getUserStakes(caller_as_text);

    //                                     var foundStake : ? TStaking.Stake = null;

    //                                     label stakesLoop for(stake in stakes.vals()){
    //                                         if(stake.canister_id == arg.tokenCanister){
    //                                             foundStake := ? stake;
    //                                             break stakesLoop;
    //                                         };
    //                                     };
                                        
    //                                     switch(foundStake){
    //                                         case(? unwrappedStake){
    //                                             if(unwrappedStake.amount < unwrappedActionType.requiredAmount)  return #err("stake of id: \""#arg.tokenCanister#"\" doesnt meet amount requirement");
    //                                             //
    //                                             var configType : ? Config.ConfigDataType = null;
    //                                             configType := Config.getSpecificConfig(configs.gachaRewardConfigId);
    //                                             switch(configType){
    //                                                 case(? notNull){
    //                                                     switch(notNull){
    //                                                         case(#gacha(configs)){
    //                                                             return await processGacha(callerText, configs);
    //                                                         };
    //                                                         case(_){
    //                                                             return #err("config of id: \""#configs.gachaRewardConfigId#"\" mismatch type");
    //                                                         };
    //                                                     };
    //                                                 };
    //                                                 case(_){
    //                                                     return #err("config of id: \""#configs.gachaRewardConfigId#"\" could not be found");
    //                                                 };
    //                                             };
    //                                         };
    //                                         case(_){
    //                                             return #err("stake of id: \""#arg.tokenCanister#"\" could not be found");
    //                                         };
    //                                     };
    //                                 };
    //                                 case(_){
    //                                     return #err("Something went wrong, argument type \"burnNft\" mismatches config type")
    //                                 }
    //                             }
    //                         };
    //                         case(_){
    //                             //SOMETHING WENT WRONG
    //                             return #err("config of id: \""#arg.actionId#"\" mismatch type")
    //                         };
    //                     }
    //                 };
    //                 case(_){
    //                     return #err("Config of id: \""#arg.actionId#"\" could not be found")
    //                 };
    //             };
    //         };
    //     }
    // };

    //Withdraw ICP/ICRC-1 tokens from our PaymentHub canister
    public func withdrawIcp() : async (Result.Result<ICP.TransferResult, { #TxErr : ICP.TransferError; #Err : Text }>) {
        let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
            withdrawIcp : shared () -> async (Result.Result<ICP.TransferResult, { #TxErr : ICP.TransferError; #Err : Text }>);
        };
        let res = await paymenthub.withdrawIcp();
        return res;
    };

    public func withdrawIcrc(token_canister_id : Text) : async (Result.Result<ICRC1.Result, { #TxErr : ICRC1.TransferError; #Err : Text }>) {
        let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
            withdrawIcrc : shared (Text) -> async (Result.Result<ICRC1.Result, { #TxErr : ICRC1.TransferError; #Err : Text }>);
        };
        let res = await paymenthub.withdrawIcrc(token_canister_id);
        return res;
    };

    public shared query (msg) func whoAmI() : async (Text){
        return Principal.toText(msg.caller);
    };

    // public shared (msg) func aaaaa(): async (entities : [TDatabase.Entity] , nftEntities : [TDatabase.Entity]) {
    //     var output = await Gacha.generateGachaReward(Config.pastryGacha);
    //     return output;
    // };

};
