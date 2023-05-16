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

actor GameCanisterTemplate {
    //Interfaces
    private type DB = actor {
        executeCoreTx : shared (Text, TUsers.CoreTxData) -> async ();
    };
    private type Core = actor {
        get_user_canisterid : shared (Text) -> async (Result.Result<Text, Text>);
    };
    let core : Core = actor(ENV.core);

    //stable memory
    private stable var _admins : [Text] = ENV.admins;
    private stable var remote_configs : Trie.Trie<Text, JSON.JSON> = Trie.empty();
    private var _configs = Configs.Configs(remote_configs);

    //Internal Functions
    private func _isAdmin(_p : Principal) : (Bool) {
        var p : Text = Principal.toText(_p);
        for (i in _admins.vals()) {
            if (p == i) {
                return true;
            };
        };
        return false;
    };

    private func generate_gacha_reward(gacha_id : Text) : async Result.Result<TUsers.CoreTxData, Text> {
        let json = await get_config("GachasConfig");
        var gacha_response = await Gacha.gen_gacha_variables(gacha_id, json);
        let items_add = Buffer.Buffer<TUsers.Item>(0);
        let items_remove = Buffer.Buffer<TUsers.Item>(0);
        switch (gacha_response) {
            case (#ok(gacha_variables)) {
                for (gacha_variable in gacha_variables.vals()) {
                    if (gacha_variable.quantity > 0) {
                        items_add.add(gacha_variable);
                    } else {
                        var item_setting : TUsers.Item = {
                            id = gacha_variable.id;
                            quantity = gacha_variable.quantity;
                        };
                        items_remove.add(gacha_variable);
                    };
                };

                let coreTxData : TUsers.CoreTxData = {
                    items = ?{
                        add = ?Buffer.toArray(items_add);
                        remove = ?Buffer.toArray(items_remove);
                    };
                    profile = null;
                    bought_offers = null;
                };
                return #ok(coreTxData);
            };
            case (#err(msg)) {
                return #err(msg);
            };
        };
    };

    //utils
    public shared ({ caller }) func add_admin(p : Text) : async () {
        assert (_isAdmin(caller));
        var b : Buffer.Buffer<Text> = Buffer.fromArray(_admins);
        b.add(p);
        _admins := Buffer.toArray(b);
    };

    public shared ({ caller }) func remove_admin(p : Text) : async () {
        assert (_isAdmin(caller));
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
    public shared ({ caller }) func create_config(name : Text, json : Text) : async (Result.Result<Text, Text>) {
        await _configs.create_config(name, json);
    };

    public shared ({ caller }) func get_config(name : Text) : async (Text) {
        await _configs.get_config(name);
    };

    public shared ({ caller }) func update_config(name : Text, json : Text) : async (Result.Result<Text, Text>) {
        await _configs.update_config(name, json);
    };

    public shared ({ caller }) func delete_config(name : Text) : async (Result.Result<Text, Text>) {
        await _configs.delete_config(name);
    };

    //Burn and Mint NFT's
    public shared (msg) func burn_nft(collection_canister_id : Text, tokenindex : EXT.TokenIndex, aid : EXT.AccountIdentifier) : async (Result.Result<TUsers.CoreTxData, Text>) {
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

                let metadata = json;
                var nft_usage = JSON.get_key(metadata, "usage");
                //Apply gacha to user
                var output = await generate_gacha_reward(nft_usage); // we can use same offer id as the gacha id as they are the same value
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

                        let response = await db.executeCoreTx(Principal.toText(msg.caller), rewards);
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
    public shared ({caller}) func verify_tx_icp(height : Nat64, _to : Text, _from : Text, _amt : Nat64, _paymentType : Text, _paymentMetadata : Text) : async (Result.Result<TUsers.CoreTxData, Text>) {
        let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
            verify_tx_icp : shared (Nat64, Text, Text, Nat64) -> async ({
                #Success : Text;
                #Err : Text;
            });
        };
        switch (await paymenthub.verify_tx_icp(height, _to, _from, _amt)) {
            case (#Success s) {
                
                //TODO : Here process your users assets updates on successfull ICP payment and return #ok() response accordingly 
                if(_paymentType == "offer"){
                    //_paymentMetadata must be the offer Id
                    let offerId = "{\""#_paymentMetadata#"\"}";
                    //Get OffersConfig
                    let offersConfig = await get_config("OffersConfig");

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
                    var output = await generate_gacha_reward(offerId); // we can use same offer id as the gacha id as they are the same value
                    
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
                            let response = await db.executeCoreTx(Principal.toText(caller), coreTxData);

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

    public shared ({caller}) func verify_tx_icrc(index : Nat, _to : Text, _from : Text, _amt : Nat, _paymentType : Text, _paymentMetadata : Text) : async (Result.Result<TUsers.CoreTxData, Text>) {
        let paymenthub = actor(ENV.paymenthub_canister_id) : actor {
            verify_tx_icrc : shared (Nat, Text, Text, Nat) -> async ({
                #Success : Text;
                #Err : Text;
            });
        };
        switch (await paymenthub.verify_tx_icrc(index, _to, _from, _amt)) {
            case (#Success s) {
                //TODO : Here process your users assets updates on successfull ICP payment and return #ok() response accordingly 
                if(_paymentType == "offer"){
                    //_paymentMetadata must be the offer Id
                    let offerId = "{\""#_paymentMetadata#"\"}";
                    //Get OffersConfig
                    let offersConfig = await get_config("OffersConfig");

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
                    var output = await generate_gacha_reward(offerId); // we can use same offer id as the gacha id as they are the same value
                    
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
                            let response = await db.executeCoreTx(Principal.toText(caller), coreTxData);

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
};
