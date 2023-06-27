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
import ICRC "../types/icrc.types";
import TGlobal "../types/global.types";
import TEntity "../types/entity.types";
import TAction "../types/action.types";
import TStaking "../types/staking.types";

//import TStakeHub "../../../../standard/StakingStandard/StakingHub.mo";
import Config "../modules/Configs";

// actor class WorldTemplate(owner : Principal) = this {
actor class WorldTemplate() {
    private var owner : Principal = Principal.fromText("26otq-bnbgp-bfbhy-i7ypc-czyxx-3rlax-yrrny-issrb-kwepg-vqtcs-pae"); 
    //Interfaces
    type UserNode = actor {
        processActionConfig : shared (uid : TGlobal.userId, aid : TGlobal.actionId, actionConfig : TAction.ActionConfig) -> async (Result.Result<TAction.ActionResponse, Text>);
        getAllUserWorldEntities : shared (uid : TGlobal.userId, wid : TGlobal.worldId) -> async (Result.Result<[TEntity.Entity], Text>);
    };
    type WorldbHub = actor {
        createNewUser : shared (Principal) -> async (Result.Result<Text, Text>);
        getUserNodeCanisterId : shared (Text) -> async (Result.Result<Text, Text>);

        grantEntityPermission : shared (Text, Text, Text, TEntity.EntityPermission) -> async (); //args -> (groupId, entityId, principal, permissions)
        removeEntityPermission : shared (Text, Text, Text) -> async (); //args -> (groupId, entityId, principal)
        grantGlobalPermission : shared (Text) -> async (); //args -> (principal)
        removeGlobalPermission : shared (Text) -> async (); //args -> (principal)
    };
    type StakeHub = actor {
        getUserStakes : shared (Text) -> async ([TStaking.Stake]);
    };  
    type ICP = actor {
        transfer : shared ICP.TransferArgs -> async ICP.TransferResult;
    };
    type NFT = actor {
        ext_mint : ([(EXT.AccountIdentifier, EXT.Metadata)]) -> async [EXT.TokenIndex];
    };

    let worldhub : WorldbHub = actor(ENV.WorldbHub);

    let test_nft_principal : Text = "jh775-jaaaa-aaaal-qbuda-cai";

    //stable memory
    private stable var _owner : Text = Principal.toText(owner);
    private stable var _admins : [Text] = [Principal.toText(owner), "2ot7t-idkzt-murdg-in2md-bmj2w-urej7-ft6wa-i4bd3-zglmv-pf42b-zqe"]; //here hitesh principal is temporary

    //Configs
    private var entityConfigs = Buffer.Buffer<TEntity.EntityConfig>(0);
    private stable var tempUpdateEntityConfig : Config.EntityConfigs = [];

    private var actionConfigs = Buffer.Buffer<TAction.ActionConfig>(0);
    private stable var tempUpdateActionConfig : Config.ActionConfigs = [];

    system func preupgrade() {        
        tempUpdateEntityConfig := Buffer.toArray(entityConfigs);

        tempUpdateActionConfig := Buffer.toArray(actionConfigs);
    };
    system func postupgrade() {
        entityConfigs := Buffer.fromArray(tempUpdateEntityConfig);
        tempUpdateEntityConfig := [];

        actionConfigs := Buffer.fromArray(tempUpdateActionConfig);
        tempUpdateActionConfig := [];
    };
    
    public shared query ({ caller }) func whoAmI() : async (Principal) {
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

    public query func getOwner() : async Text {return Principal.toText(owner)};

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    //GET CONFIG
    private func _getSpecificEntityConfig(eid : Text, gid : Text) : (? TEntity.EntityConfig) {
        for (config in entityConfigs.vals()) {
            if(config.eid == eid) {
                if(config.gid == gid){
                    return ? config;
                };
            };
        };
        return null;
    };
    private func _getSpecificActionConfig(aid : Text) : (? TAction.ActionConfig) {
        for (config in actionConfigs.vals()) {
            if(config.aid == aid) return ? config;
        };
        return null;
    };

    public query func getEntityConfigs() : async ([TEntity.EntityConfig]){
        return Buffer.toArray(entityConfigs);
    };
    public query func getActionConfigs() : async ([TAction.ActionConfig]){
        return Buffer.toArray(actionConfigs);
    };

    //CHECK CONFIG
    private func _configEntityExist(eid : Text, gid : Text) : (Bool, Int){
        var index = 0;
        for(configElement in entityConfigs.vals()){
            if(configElement.eid == eid) {
                if(configElement.gid == gid){
                    return (true, index);
                };
            };
            index += 1;
        };
        return (false, -1);
    };
    private func _configActionExist(aid : Text) : (Bool, Int){
        var index = 0;
        for(configElement in actionConfigs.vals()){
            if(configElement.aid == aid) {
                return (true, index);
            };
            index += 1;
        };
        return (false, -1);
    };
    //CREATE CONFIG
    public shared ({ caller }) func createEntityConfig(config : TEntity.EntityConfig) : async (Result.Result<Text, Text>) {
        let confixExist = _configEntityExist(config.eid, config.gid);
        if(confixExist.0 == false){
            entityConfigs.add(config);
            return #ok("all good :)");
        };
        return #err("there is an entity already using that id, you can try updateConfig");
    };
    public shared ({ caller }) func createActionConfig(config : TAction.ActionConfig) : async (Result.Result<Text, Text>) {
        let confixExist = _configActionExist(config.aid);
        if(confixExist.0 == false){
            actionConfigs.add(config);
            return #ok("all good :)");
        };
        return #err("there is an action already using that id, you can try updateConfig");
    };
    //UPDATE CONFIG
    public shared ({ caller }) func updateEntityConfig(config : TEntity.EntityConfig) : async (Result.Result<Text, Text>) {
        let confixExist = _configEntityExist(config.eid, config.gid);
        if(confixExist.0){
            var index = Utils.intToNat(confixExist.1);
            entityConfigs.put(index, config);
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    public shared ({ caller }) func updateActionConfig(config : TAction.ActionConfig) : async (Result.Result<Text, Text>) {
        let confixExist = _configActionExist(config.aid);
        if(confixExist.0){
            var index = Utils.intToNat(confixExist.1);
            actionConfigs.put(index, config);
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    //DELETE CONFIG
    public shared ({ caller }) func deleteEntityConfig(eid : Text, gid : Text) : async (Result.Result<Text, Text>) {
        let confixExist = _configEntityExist(eid, gid);
        if(confixExist.0){
            ignore entityConfigs.remove(Utils.intToNat(confixExist.1));
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    public shared ({ caller }) func deleteActionConfig(aid : Text) : async (Result.Result<Text, Text>) {
        let confixExist = _configActionExist(aid);
        if(confixExist.0){
            ignore actionConfigs.remove(Utils.intToNat(confixExist.1));
            return #ok("all good :)");
        };
        return #err("there is no entity using that eid");
    };
    //RESET CONFIG
    public shared ({ caller }) func resetConfig() : async (Result.Result<(), ()>) {
        entityConfigs := Buffer.fromArray(Config.entityConfigs);
        actionConfigs := Buffer.fromArray(Config.actionConfigs);
        return #ok();
    };

    //Get Entities
    public shared ({ caller }) func getAllUserWorldEntities() : async (Result.Result<[TEntity.Entity], Text>){
        let worldId = await whoAmI();

        var user_node_id : Text = "2vxsx-fae";

        let uid = Principal.toText(caller);
        switch (await worldhub.getUserNodeCanisterId(uid)){
            case (#ok(okMsg_0)){
                user_node_id := okMsg_0;
            };
            case(#err(errMsg_0)) {

                var newUserNodeId = await worldhub.createNewUser(caller);
                switch(newUserNodeId){
                    case(#ok(okMsg_1)){
                        user_node_id := okMsg_1;
                    };
                    case(#err(errMsg_1)){
                        return #err("user doesnt exist, thus, tried to created it, but failed on the attempt, msg: "#(errMsg_0# " " #errMsg_1));
                    };
                };
            };
        };
        
        let userNode : UserNode = actor(user_node_id);
        return await userNode.getAllUserWorldEntities(uid, Principal.toText(worldId))
    };
    //Burn and Mint NFT's
    public shared (msg) func burnNft(collection_canister_id : Text, tokenindex : EXT.TokenIndex, uid : Principal) : async (Result.Result<(), Text>) {
        let accountId : Text = AccountIdentifier.fromPrincipal(uid, null);

        if(accountId == "") return #err("Issue getting aid from uid");

        var tokenid : EXT.TokenIdentifier = EXTCORE.TokenIdentifier.fromText(collection_canister_id, tokenindex);
        let collection = actor (collection_canister_id) : actor {
            ext_burn : (EXT.TokenIdentifier, EXT.AccountIdentifier) -> async (Result.Result<(), EXT.CommonError>);
            extGetTokenMetadata : (EXT.TokenIndex) -> async (?EXT.Metadata);
        };
        var res : Result.Result<(), EXT.CommonError> = await collection.ext_burn(tokenid, accountId);
        switch (res) {
            case (#ok) {
                //notify server using http req
                var m : ?EXT.Metadata = await collection.extGetTokenMetadata(tokenindex);
                var json : Text = "";
                switch (m) {
                    case (?md) {
                        switch (md) {
                            case (#fungible _) {};
                            case (#nonfungible d) {
                                switch (d.metadata) {
                                    case (?x) {
                                        switch (x) {
                                            case (#json j) { json := j };
                                            case (#blob _) {};
                                            case (#data _) {};
                                        };
                                    };
                                    case _ {};
                                };
                            };
                        };
                    };
                    case _ {};
                };


                return #ok();
            };
            case (#err(e)) {
                return #err("Nft Butn, Something went wrong while burning nft");
            };
        };
    };
    //Payments : redirected to PaymentHub for verification and holding update.
    public shared ({caller}) func verifyTxIcp(height : Nat64, toPrincipal : Text, fromPrincipal : Text, _amt : Nat64) : async (Result.Result<(), Text>) {
        let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
            verifyTxIcp : shared (Nat64, Text, Text, Nat64) -> async ({
                #Success : Text;
                #Err : Text;
            });
        };

        switch (await paymenthub.verifyTxIcp(height, toPrincipal, fromPrincipal, _amt)) {
            case (#Success s) {

                return #ok();
            };
            case (#Err e) {
                return #err(e);
            };
        };
    };
    public shared ({caller}) func verifyTxIcrc(index : Nat, toPrincipal : Text, fromPrincipal : Text, _amt : Nat, token_canister_id : Text) : async (Result.Result<(), Text>) {
        let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
            verifyTxIcrc : shared (Nat, Text, Text, Nat, Text) -> async ({
                #Success : Text;
                #Err : Text;
            });
        };
        switch (await paymenthub.verifyTxIcrc(index, toPrincipal, fromPrincipal, _amt, token_canister_id)) {
            case (#Success s) {
                
                return #ok();
            };
            case (#Err e) {
                return #err(e);
            };
        };
    };

    private func handleAction(uid : Text, actionId: Text, actionConfig : TAction.ActionConfig) : async (Result.Result<TAction.ActionResponse, Text>){
        var user_node_id : Text = "2vxsx-fae";
        switch (await worldhub.getUserNodeCanisterId(uid)){
            case (#ok c){
                user_node_id := c;
            };
            case _ {
                return #err("user node id not found");
            };
        };
        
        let userNode : UserNode = actor(user_node_id);

        var result = await userNode.processActionConfig(uid, actionId, actionConfig);

        switch(result){
            case(#ok(msg)){
                var nftsToMint = msg.2;
                var tokensToMint = msg.3;
                
                //Mint Nfts //This will require to add the worldId as a minter
                if(Array.size(nftsToMint) > 0){
                    let accountId : Text = AccountIdentifier.fromText(uid, null);
                    for(item in nftsToMint.vals()) {
                    
                        let nftCollection : NFT = actor(item.canister);
                        ignore nftCollection.ext_mint([(accountId,
                        #nonfungible {
                            name = item.name;
                            asset = item.assetId;
                            thumbnail = "";
                            metadata = ? #json(item.metadata);
                        })]);
                    };
                };
                
                //Mint Tokens
                let icrcLedger : ICRC.Self = actor(ENV.ICRC1_Ledger);
                for(item in tokensToMint.vals()) {
                    //TODO: handle token minting
                    //transfer from
                    ignore icrcLedger.icrc2_transfer_from({ from = {owner = Principal.fromText(ENV.ICRC1_Minter); subaccount = null}; spender_subaccount = null; to = {owner = Principal.fromText(uid); subaccount = null}; amount = Utils.tokenize(item.quantity, item.baseZeroCount); fee = null; memo = null; created_at_time = null})
                };
            };
            case(#err(msg)){};
        };

        return result;
    };
    public shared ({ caller }) func processActionEntities(actionArg: TAction.ActionArg): async (Result.Result<TAction.ActionResponse, Text>) { 
        //Todo: Check for each action the timeConstraint
        switch(actionArg){
            case(#default(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);
 
                switch(configType){
                    case(? configs){
                        return await handleAction(Principal.toText(caller), arg.actionId, configs);
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    };
                };
            };
            case(#burnNft(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);

                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #burnNft(actionPluginConfig)){
                                switch(await burnNft(actionPluginConfig.canister, arg.index, caller))
                                {
                                    case(#ok()){
                                        return await handleAction(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(#err(msg)){
                                        return #err(msg)
                                    };
                                }
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"burnNft\" mismatches config type")
                            }
                        }
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    }
                }
            };
            case(#verifyTransferIcp(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);

                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #verifyTransferIcp(actionPluginConfig)){
                                switch(await verifyTxIcp(arg.blockIndex, actionPluginConfig.toPrincipal, Principal.toText(caller) , Utils.tokenizeToIcp(actionPluginConfig.amt))){
                                    case(#ok()){
                                        return await handleAction(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(#err(msg)){
                                        return #err(msg)
                                    };
                                }
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"spendTokens\" mismatches config type")
                            }
                        }
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    }
                };
            };
            case(#verifyTransferIcrc(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);

                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #verifyTransferIcrc(actionPluginConfig)){
                                
                                switch(await verifyTxIcrc(arg.blockIndex, actionPluginConfig.toPrincipal, Principal.toText(caller), Utils.tokenize(actionPluginConfig.amt, actionPluginConfig.baseZeroCount), actionPluginConfig.canister))
                                {
                                    case(#ok()){
                                        return await handleAction(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(#err(msg)){
                                        return #err(msg)
                                    };
                                };
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"spendTokens\" mismatches config type")
                            }
                        }
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    }
                };
            };
            case(#claimNftStakingRewardNft(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);
 
                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #claimNftStakingRewardNft(actionPluginConfig)){

                                let callerText = Principal.toText(caller);
                                var canister_id : Text = "2vxsx-fae";
                                switch (await worldhub.getUserNodeCanisterId(callerText)){
                                    case (#ok c){
                                        canister_id := c;
                                    };
                                    case _ {
                                    };
                                };

                                let caller_as_text = Principal.toText(caller);
                                let stakeHub : StakeHub = actor(ENV.stakinghub_canister_id);

                                let stakes = await stakeHub.getUserStakes(caller_as_text);

                                var foundStake : ? TStaking.Stake = null;

                                label stakesLoop for(stake in stakes.vals()){
                                    if(stake.canister_id == actionPluginConfig.canister){
                                        foundStake := ? stake;
                                        break stakesLoop;
                                    };
                                };
                                
                                switch(foundStake){
                                    case(? selectedStakeData){
                                        if(selectedStakeData.amount < actionPluginConfig.requiredAmount)  return #err("stake of id: \""#actionPluginConfig.canister#"\" doesnt meet amount requirement");
                                        //
                                        return await handleAction(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(_){
                                        return #err("nft stake of id: \""#actionPluginConfig.canister#"\" could not be found");
                                    };
                                };
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"claimStakingReward\" mismatches config type");
                            };
                        };
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    };
                };
            };
            case(#claimStakingRewardIcp(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);
 
                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #claimStakingRewardIcp(actionPluginConfig)){

                                let callerText = Principal.toText(caller);
                                var canister_id : Text = "2vxsx-fae";
                                switch (await worldhub.getUserNodeCanisterId(callerText)){
                                    case (#ok c){
                                        canister_id := c;
                                    };
                                    case _ {
                                    };
                                };

                                let caller_as_text = Principal.toText(caller);
                                let stakeHub : StakeHub = actor(ENV.stakinghub_canister_id);

                                let stakes = await stakeHub.getUserStakes(caller_as_text);

                                var foundStake : ? TStaking.Stake = null;

                                label stakesLoop for(stake in stakes.vals()){
                                    if(stake.canister_id == ENV.Ledger){
                                        foundStake := ? stake;
                                        break stakesLoop;
                                    };
                                };
                                
                                switch(foundStake){
                                    case(? selectedStakeData){
                                        if(selectedStakeData.amount < Utils.tokenize(actionPluginConfig.requiredAmount, 100_000_000))  return #err("icp stake doesnt meet amount requirement");
                                        //
                                        return await handleAction(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(_){
                                        return #err("icp stake could not be found");
                                    };
                                };
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"claimStakingReward\" mismatches config type");
                            };
                        };
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    };
                };
            };
            case(#claimStakingRewardIcrc(arg)){
                var configType = _getSpecificActionConfig(arg.actionId);
 
                switch(configType){
                    case(? configs){
                        switch(configs.actionPlugin){
                            case(? #claimStakingRewardIcrc(actionPluginConfig)){

                                let callerText = Principal.toText(caller);
                                var canister_id : Text = "2vxsx-fae";
                                switch (await worldhub.getUserNodeCanisterId(callerText)){
                                    case (#ok c){
                                        canister_id := c;
                                    };
                                    case _ {
                                    };
                                };

                                let caller_as_text = Principal.toText(caller);
                                let stakeHub : StakeHub = actor(ENV.stakinghub_canister_id);

                                let stakes = await stakeHub.getUserStakes(caller_as_text);

                                var foundStake : ? TStaking.Stake = null;

                                label stakesLoop for(stake in stakes.vals()){
                                    if(stake.canister_id == actionPluginConfig.canister){
                                        foundStake := ? stake;
                                        break stakesLoop;
                                    };
                                };
                                
                                switch(foundStake){
                                    case(? selectedStakeData){
                                        if(selectedStakeData.amount < Utils.tokenize(actionPluginConfig.requiredAmount, actionPluginConfig.baseZeroCount))  return #err("stake of id: \""#actionPluginConfig.canister#"\" doesnt meet amount requirement");
                                        //
                                        return await handleAction(Principal.toText(caller), arg.actionId, configs);
                                    };
                                    case(_){
                                        return #err("icrc stake of id: \""#actionPluginConfig.canister#"\" could not be found");
                                    };
                                };
                            };
                            case(_){
                                return #err("Something went wrong, argument type \"claimStakingReward\" mismatches config type");
                            };
                        };
                    };
                    case(_){
                        return #err("Config of id: \""#arg.actionId#"\" could not be found")
                    };
                };
            };
        }
    };

    // for permissions
    public shared ({ caller }) func grantEntityPermission(groupId : Text, entityId : Text, principal : Text, permission : TEntity.EntityPermission) : async () {
        assert(isAdmin_(caller));
        await worldhub.grantEntityPermission(groupId, entityId, principal, permission);
    };

    public shared ({ caller }) func removeEntityPermission(groupId : Text, entityId : Text, principal : Text) : async () {
        assert(isAdmin_(caller));
        await worldhub.removeEntityPermission(groupId, entityId, principal);
    };

    public shared ({ caller }) func grantGlobalPermission(principal : Text) : async () {
        assert(isAdmin_(caller));
        await worldhub.grantGlobalPermission(principal);
    };

    public shared ({ caller }) func removeGlobalPermission(principal : Text) : async () {
        assert(isAdmin_(caller));
        await worldhub.removeGlobalPermission(principal);
    };
};