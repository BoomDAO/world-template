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
import Map "mo:base/HashMap";
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
import Gacha "../modules/Gacha";
import RandomUtil "../utils/RandomUtil";
import Configs "../modules/Configs";
import EXTCORE "../utils/Core";
import EXT "../utils/ext.types";
import TUsers "../DatabaseStandard/Types";
import AccountIdentifier "../utils/AccountIdentifier";
import ICP "../utils/icp.types";
import ICRC1 "../utils/icrc.types";

actor GameCanisterTemplate {
    //Interfaces
    private type DB = actor {
        executeGameTx : shared (Text, TUsers.CoreTxData) -> async ();
    };
    private type Core = actor {
        get_user_canisterid : shared (Text) -> async (Result.Result<Text, Text>);
    };
    let core : Core = actor(ENV.core);

    //stable memory
    private stable var _admins : [Text] = ENV.admins;
    private stable var remote_configs : Trie.Trie<Text, JSON.JSON> = Trie.empty();
    private var _configs = Configs.Configs(remote_configs);

    system func preupgrade() {
        remote_configs := _configs.remote_configs;
    };
    system func postupgrade() {
        remote_configs := Trie.empty();
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

    public func generateGachaReward(jsonString : Text) : async (Result.Result<TUsers.CoreTxData, Text>) {

        //TEMP START
        let metadata = JSON.strip(Text.replace(jsonString, #char '\\', ""), '\"','\"');
        //TEMP END
        var nft_usage = JSON.get_key(metadata, "usage");
        let gacha_config = await getConfig("GachasConfig");
        let reward = await Gacha.generateGachaReward_(nft_usage, gacha_config);
        return switch(reward){
            case (#ok(data)) {
                return #ok(data);
            };
            case (#err(msg)) {
                return #err(msg);
            }
        }
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
    public shared ({ caller }) func createConfig(name : Text, json : Text) : async (Result.Result<Text, Text>) {
        await _configs.createConfig(name, json);
    };

    public shared ({ caller }) func getConfig(name : Text) : async (Text) {
        await _configs.getConfig(name);
    };

    public shared ({ caller }) func updateConfig(name : Text, json : Text) : async (Result.Result<Text, Text>) {
        await _configs.updateConfig(name, json);
    };

    public shared ({ caller }) func deleteConfig(name : Text) : async (Result.Result<Text, Text>) {
        await _configs.deleteConfig(name);
    };

    //Burn and Mint NFT's
    public shared (msg) func burnNft(collection_canister_id : Text, tokenindex : EXT.TokenIndex, aid : EXT.AccountIdentifier) : async (Result.Result<TUsers.CoreTxData, Text>) {
        assert (AccountIdentifier.fromPrincipal(msg.caller, null) == aid);
        var tokenid : EXT.TokenIdentifier = EXTCORE.TokenIdentifier.fromText(collection_canister_id, tokenindex);
        let collection = actor (collection_canister_id) : actor {
            ext_burn : (EXT.TokenIdentifier, EXT.AccountIdentifier) -> async (Result.Result<(), EXT.CommonError>);
            extGetTokenMetadata : (EXT.TokenIndex) -> async (?EXT.Metadata);
        };
        var res : Result.Result<(), EXT.CommonError> = await collection.ext_burn(tokenid, aid);
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

                // let metadata = json;
                //TEMP START
                let metadata = JSON.strip(Text.replace(json, #char '\\', ""), '\"','\"');
                //TEMP END
                var nft_usage = JSON.get_key(metadata, "usage");
                //Apply gacha to user
                let gacha_config = await getConfig("GachasConfig");
                var output = await Gacha.generateGachaReward_(nft_usage, gacha_config); // we can use same offer id as the gacha id as they are the same value
                switch (output) {
                    case (#ok(rewards)) {
                        var processedOfferId = nft_usage;
                        var canister_id : Text = "";
                        switch (await core.get_user_canisterid(Principal.toText(msg.caller))){
                            case (#ok c){
                                canister_id := c;
                            };
                            case _ {};
                        };
                        let db : DB = actor(canister_id);

                        let response = await db.executeGameTx(Principal.toText(msg.caller), rewards);
                        return #ok(rewards);
                    };
                    case (#err(msg)) {
                        return #err(msg # ", tried to burn nft of type: " #nft_usage);
                    };
                };
            };
            case (#err(e)) {
                return #err("Something went wrong while burning nft ");
            };
        };
    };

    //Payments : redirected to PaymentHub for verification and holding update.
    public shared ({caller}) func verifyTxIcp(height : Nat64, _to : Text, _from : Text, _amt : Nat64, _paymentType : Text, _paymentMetadata : Text) : async (Result.Result<TUsers.CoreTxData, Text>) {
        let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
            verifyTxIcp : shared (Nat64, Text, Text, Nat64) -> async ({
                #Success : Text;
                #Err : Text;
            });
        };
        switch (await paymenthub.verifyTxIcp(height, _to, _from, _amt)) {
            case (#Success s) {
                
                //TODO : Here process your users assets updates on successfull ICP payment and return #ok() response accordingly 
                if(_paymentType == "offer"){
                    //_paymentMetadata must be the offer Id
                    let offerId = "{\""#_paymentMetadata#"\"}";
                    //Get OffersConfig
                    let offersConfig = await getConfig("OffersConfig");

                    //Look for offer config by its Id
                    var offer_json_config = "";

                    //Find config on stackable offers array
                    switch (JSON.find_arr_element_by_itemId(offerId, "stackableOffers", offersConfig)) {
                        case (#ok(stackableOffers)) {
                            offer_json_config := stackableOffers;
                        };
                        case _{

                            //Find config on noneStackableOffers offers array
                            switch (JSON.find_arr_element_by_itemId(offerId, "noneStackableOffers", offersConfig)) {
                                case (#ok(noneStackableOffers)) {
                                    offer_json_config := noneStackableOffers;
                                };
                                case (#err(errMsg)) {
                                    return #err("something went wrong looking for the offer config of id: " #offerId# " | json: " #offersConfig);
                                };
                            };
                        };
                    };
                    
                    //Check if amt is equal or greater than the config amt
                    let amount_config_txt = JSON.get_key(offer_json_config, "price");
                    var amount_config = Utils.textToFloat(amount_config_txt);
                    var real_amount_config = Utils.textToNat(Int.toText(Float.toInt(amount_config * 100_000_000)));
                    var amt = Nat64.toNat(_amt);
                    if(amt <  real_amount_config) return #err("No enoguh money! "#(Nat.toText(amt))#" < "#Nat.toText(real_amount_config));
                    
                    //Apply gacha to user
                    let gacha_config = await getConfig("GachasConfig");
                    var output = await Gacha.generateGachaReward_(offerId, gacha_config); // we can use same offer id as the gacha id as they are the same value
                    
                    //Get the user data and return it as success response
                    //JACK WAS HERE
                    
                    switch(output){
                        case (#ok(rewards)){
                            
                            var processedOfferId = offerId;
                            processedOfferId := Option.get(Text.stripStart(processedOfferId, #char '{'), "");
                            processedOfferId := Option.get(Text.stripStart(processedOfferId, #char '\"'), "");
                            processedOfferId := Option.get(Text.stripEnd(processedOfferId, #char '}'), "");
                            processedOfferId := Option.get(Text.stripEnd(processedOfferId, #char '\"'), "");
                            let coreTxData : TUsers.CoreTxData = { items = rewards.items; profile = null; bought_offers = ?{ add = ?[processedOfferId]; remove = null  } };
                            
                            var canister_id : Text = "";
                            switch (await core.get_user_canisterid(Principal.toText(caller))){
                                case (#ok c){
                                    canister_id := c;
                                };
                                case _ {};
                            };

                            let db : DB = actor(canister_id);
                            let response = await db.executeGameTx(Principal.toText(caller), coreTxData);

                            return #ok(coreTxData);
                        };
                        case (#err(msg)){
                            return #err(msg);
                        }
                    }
                };

                return #err("you bought an offer but we dont know the type"); 
            };
            case (#Err e) {
                return #err(e);
            };
        };
    };

    public shared ({caller}) func verifyTxIcrc(index : Nat, _to : Text, _from : Text, _amt : Nat, _paymentType : Text, _paymentMetadata : Text) : async (Result.Result<TUsers.CoreTxData, Text>) {
        let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
            verifyTxIcrc : shared (Nat, Text, Text, Nat) -> async ({
                #Success : Text;
                #Err : Text;
            });
        };
        switch (await paymenthub.verifyTxIcrc(index, _to, _from, _amt)) {
            case (#Success s) {
                //TODO : Here process your users assets updates on successfull ICP payment and return #ok() response accordingly 
                if(_paymentType == "offer"){
                    //_paymentMetadata must be the offer Id
                    let offerId = "{\""#_paymentMetadata#"\"}";
                    //Get OffersConfig
                    let offersConfig = await getConfig("OffersConfig");

                    //Look for offer config by its Id
                    var offer_json_config = "";

                    //Find config on stackable offers array
                    switch (JSON.find_arr_element_by_itemId(offerId, "stackableOffers", offersConfig)) {
                        case (#ok(stackableOffers)) {
                            offer_json_config := stackableOffers;
                        };
                        case _{

                            //Find config on noneStackableOffers offers array
                            switch (JSON.find_arr_element_by_itemId(offerId, "noneStackableOffers", offersConfig)) {
                                case (#ok(noneStackableOffers)) {
                                    offer_json_config := noneStackableOffers;
                                };
                                case (#err(errMsg)) {
                                    return #err("something went wrong looking for the offer config of id: " #offerId# " | json: " #offersConfig);
                                };
                            };
                        };
                    };
                    
                    //Check if amt is equal or greater than the config amt
                    let amount_config_txt = JSON.get_key(offer_json_config, "price");
                    var amount_config = Utils.textToFloat(amount_config_txt);
                    var real_amount_config = Utils.textToNat(Int.toText(Float.toInt(amount_config * 100_000_000)));
                    var amt = _amt;
                    if(amt <  real_amount_config) return #err("No enoguh money! "#(Nat.toText(amt))#" < "#Nat.toText(real_amount_config));
                    
                    //Apply gacha to user
                    let gacha_config = await getConfig("GachasConfig");
                    var output = await Gacha.generateGachaReward_(offerId, gacha_config); // we can use same offer id as the gacha id as they are the same value
                    
                    //Get the user data and return it as success response
                    //JACK WAS HERE
                    
                    switch(output){
                        case (#ok(rewards)){
                            
                            var processedOfferId = offerId;
                            processedOfferId := Option.get(Text.stripStart(processedOfferId, #char '{'), "");
                            processedOfferId := Option.get(Text.stripStart(processedOfferId, #char '\"'), "");
                            processedOfferId := Option.get(Text.stripEnd(processedOfferId, #char '}'), "");
                            processedOfferId := Option.get(Text.stripEnd(processedOfferId, #char '\"'), "");
                            let coreTxData : TUsers.CoreTxData = { items = rewards.items; profile = null; bought_offers = ?{ add = ?[processedOfferId]; remove = null  } };
                            
                            var canister_id : Text = "";
                            switch (await core.get_user_canisterid(Principal.toText(caller))){
                                case (#ok c){
                                    canister_id := c;
                                };
                                case _ {};
                            };

                            let db : DB = actor(canister_id);
                            let response = await db.executeGameTx(Principal.toText(caller), coreTxData);

                            return #ok(coreTxData);
                        };
                        case (#err(msg)){
                            return #err(msg);
                        }
                    }
                };

                return #err("you bought an offer but we dont know the type"); 
            };
            case (#Err e) {
                return #err(e);
            };
        };
    };

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
};
