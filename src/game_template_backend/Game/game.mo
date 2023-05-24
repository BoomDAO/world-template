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
import EXT "../types/ext.types";
import TDatabase "../types/database.types";
import AccountIdentifier "../utils/AccountIdentifier";
import ICP "../types/icp.types";
import ICRC1 "../types/icrc.types";

actor GameCanisterTemplate {
    //Interfaces
    private type DB = actor {
        executeGameTx : shared (Text, TDatabase.GameTxData) -> async ();
    };
    private type DatabaseHub = actor {
        getUserCanisterId : shared (Text) -> async (Result.Result<Text, Text>);
    };
    let databasehub : DatabaseHub = actor(ENV.DatabaseHub);

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
    public shared (msg) func burnNft(collection_canister_id : Text, tokenindex : EXT.TokenIndex, aid : EXT.AccountIdentifier) : async (Result.Result<(gameTx : TDatabase.GameTxData , nfts : [TDatabase.Nft]), Text>) {
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

                // // let metadata = json;
                // //TEMP START
                // let metadata = JSON.strip(Text.replace(json, #char '\\', ""), '\"','\"');
                // //TEMP END
                // var nft_usage = JSON.get_key(metadata, "usage");
                // nft_usage := JSON.strip(nft_usage, '{','}');

                //Apply gacha to user
                let gacha_config = await getConfig("GachasConfig");
                var output = await Gacha.generateGachaReward("pastry-variable-offer", gacha_config);//(nft_usage", gacha_config); 

                switch (output) {
                    case (#ok(rewards)) {
                        let items_config = await getConfig("ItemsGameConfig");

                        let gameTxDataAndNfts = Gacha.setupGameTxData(rewards, items_config);
                        let gameTxData : TDatabase.GameTxData = gameTxDataAndNfts.0;
                        let nfts : [TDatabase.Nft] = gameTxDataAndNfts.1;

                        var canister_id : Text = "";
                        switch (await databasehub.getUserCanisterId(Principal.toText(msg.caller))){
                            case (#ok c){
                                canister_id := c;
                            };
                            case _ {};
                        };
                        let db : DB = actor(canister_id);

                        ignore db.executeGameTx(Principal.toText(msg.caller), gameTxData);

                        //TODO: Mint

                        return #ok(gameTxDataAndNfts);
                    };
                    case (#err(msg)) {
                        return #err(msg # ", tried to burn nft of type: "#"pastry-variable-offer");// #nft_usage);
                    };
                };
            };
            case (#err(e)) {
                return #err("Something went wrong while burning nft ");
            };
        };
    };

    //Payments : redirected to PaymentHub for verification and holding update.
    public shared ({caller}) func verifyTxIcp(height : Nat64, _to : Text, _from : Text, _amt : Nat64, _paymentType : Text, _paymentMetadata : Text) : async (Result.Result<(gameTx : TDatabase.GameTxData , nfts : [TDatabase.Nft]), Text>) {
        assert (Principal.fromText(_from) == caller); //If payment done by correct person and _from arg is passed correctly

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
                    let offerId = _paymentMetadata;
                    //Get OffersConfig
                    let offersConfig = await getConfig("OffersConfig");

                    //Look for offer config by its Id
                    var offer_json_config = "";

                    //Find config on stackable offers array
                    switch (JSON.get_element_by_field_value(offersConfig, "stackableOffers", "Id", offerId)) {
                        case (#ok(stackableOffers)) {
                            offer_json_config := stackableOffers;
                        };
                        case (#err(errMsg00)){

                            //Find config on noneStackableOffers offers array
                            switch (JSON.get_element_by_field_value(offersConfig, "noneStackableOffers", "Id", offerId)) {
                                case (#ok(noneStackableOffers)) {
                                    offer_json_config := noneStackableOffers;
                                };
                                case (#err(errMsg11)) {
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
                    var output = await Gacha.generateGachaReward(offerId, gacha_config); // we can use same offer id as the gacha id as they are the same value
                    
                    //Get the user data and return it as success response
                    //JACK WAS HERE
                    
                    switch(output){
                        case (#ok(rewards)){
                            var processedOfferId = offerId;
                            processedOfferId := JSON.strip(processedOfferId, '{', '}');
                            processedOfferId := JSON.strip(processedOfferId, '\"', '\"');

                            let items_config = await getConfig("ItemsGameConfig");

                            let gameTxDataAndNfts = Gacha.setupGameTxData(rewards, items_config);
                            let gameTxData = gameTxDataAndNfts.0;
                            let nfts = gameTxDataAndNfts.1;

                            var canister_id : Text = "";
                            switch (await databasehub.getUserCanisterId(Principal.toText(caller))){
                                case (#ok c){
                                    canister_id := c;
                                };
                                case _ {};
                            };

                            let db : DB = actor(canister_id);
                            ignore db.executeGameTx(Principal.toText(caller), gameTxData);

                            //Todo: Mint Nfts

                            return #ok(gameTxDataAndNfts);
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

    public shared ({caller}) func verifyTxIcrc(index : Nat, _to : Text, _from : Text, _amt : Nat, _paymentType : Text, _paymentMetadata : Text) : async (Result.Result<(gameTx : TDatabase.GameTxData , nfts : [TDatabase.Nft]), Text>) {
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
                    let offerId = _paymentMetadata;
                    //Get OffersConfig
                    let offersConfig = await getConfig("OffersConfig");

                    //Look for offer config by its Id
                    var offer_json_config = "";

                    //Find config on stackable offers array
                    switch (JSON.get_element_by_field_value(offersConfig, "stackableOffers", "Id", offerId)) {
                        case (#ok(stackableOffers)) {
                            offer_json_config := stackableOffers;
                        };
                        case (#err(errMsg00)){

                            //Find config on noneStackableOffers offers array
                            switch (JSON.get_element_by_field_value(offersConfig, "noneStackableOffers", "Id", offerId)) {
                                case (#ok(noneStackableOffers)) {
                                    offer_json_config := noneStackableOffers;
                                };
                                case (#err(errMsg11)) {
                                    return #err("something went wrong looking for the offer config of id: " #offerId# " | json: " #offersConfig);
                                };
                            };
                        };
                    };

                    //Check if amt is equal or greater than the config amt
                    let amount_config_txt = JSON.get_key(offer_json_config, "price");
                    var amount_config = Utils.textToFloat(amount_config_txt);
                    var real_amount_config = Utils.textToNat(Int.toText(Float.toInt(amount_config * 1000_000_000_000_000_000)));
                    var amt = _amt;
                    if(amt <  real_amount_config) return #err("No enoguh money! "#(Nat.toText(amt))#" < "#Nat.toText(real_amount_config));
                    
                    //Apply gacha to user
                    let gacha_config = await getConfig("GachasConfig");
                    var output = await Gacha.generateGachaReward(offerId, gacha_config); // we can use same offer id as the gacha id as they are the same value
                    
                    //Get the user data and return it as success response
                    //JACK WAS HERE
                    
                    switch(output){
                        case (#ok(rewards)){
                            var processedOfferId = offerId;
                            processedOfferId := JSON.strip(processedOfferId, '{', '}');
                            processedOfferId := JSON.strip(processedOfferId, '\"', '\"');

                            let items_config = await getConfig("ItemsGameConfig");

                            let gameTxDataAndNfts = Gacha.setupGameTxData(rewards, items_config);
                            let gameTxData = gameTxDataAndNfts.0;
                            let nfts = gameTxDataAndNfts.1;

                            var canister_id : Text = "";
                            switch (await databasehub.getUserCanisterId(Principal.toText(caller))){
                                case (#ok c){
                                    canister_id := c;
                                };
                                case _ {};
                            };

                            let db : DB = actor(canister_id);
                            ignore db.executeGameTx(Principal.toText(caller), gameTxData);

                            //Todo: Mint Nfts

                            return #ok(gameTxDataAndNfts);
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

    public shared query (msg) func whoAmI() : async (Text){
        return Principal.toText(msg.caller);
    };

    public shared (msg) func aaaaa(offerId : Text): async (Result.Result<(TDatabase.GameTxData, [TDatabase.Nft]), Text>) {
        let gacha_config = await getConfig("GachasConfig");
        var output = await Gacha.generateGachaReward("pastry-variable-offer", gacha_config);
        
        switch (output) {
            case (#ok(rewards)) {
                let items_config = await getConfig("ItemsGameConfig");

                let gameTxDataAndNfts = Gacha.setupGameTxData(rewards, items_config);
                let gameTxData : TDatabase.GameTxData = gameTxDataAndNfts.0;
                let nfts : [TDatabase.Nft] = gameTxDataAndNfts.1;

                var canister_id : Text = "";
                switch (await databasehub.getUserCanisterId(Principal.toText(msg.caller))){
                    case (#ok c){
                        canister_id := c;
                    };
                    case _ {};
                };
                let db : DB = actor(canister_id);

                ignore db.executeGameTx(Principal.toText(msg.caller), gameTxData);

                //TODO: Mint

                return #ok(gameTxDataAndNfts);
            };
            case (#err(msg)) {
                return #err(msg # ", tried to burn nft of type: "#"pastry-variable-offer");// #nft_usage);
            };
        };
    };

};
