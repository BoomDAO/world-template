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

import ICP "./icp.types";
import ICRC1 "./icrc.types";
import EXT "./ext.types";

import Users "../users/users";
import TUsers "../users/users.types";
import JSON "../utils/Json";
import Parser "../utils/Parser";
import ENV "../utils/Env";
import Utils "../utils/Utils";
import AccountIdentifier "../utils/AccountIdentifier";
import Hex "../utils/Hex";
import EXTCORE "../utils/Core";

import Gacha "../modules/Gacha";
import Configs "../modules/Configs";

actor Core {
    //stable memory
    private stable var _uids : Trie.Trie<Text, Text> = Trie.empty(); //mapping user_id -> canister_id
    private stable var _usernames : Trie.Trie<Text, Text> = Trie.empty(); //mapping username -> _uid
    private stable var _ucanisters : [Text] = []; //all user db canisters
    private stable var _admins : [Text] = ENV.admins; //admins for user db

    private stable var remote_configs : Trie.Trie<Text, JSON.JSON> = Trie.empty();
    private var _configs = Configs.Configs(remote_configs); //object of remote_config public class

    //Internals Functions
    private func count_users(can_id : Text) : (Nat32) {
        var count : Nat32 = 0;
        for ((uid, canister) in Trie.iter(_uids)) {
            if (canister == can_id) {
                count := count + 1;
            };
        };
        return count;
    };

    private func _add_text(arr : [Text], id : Text) : ([Text]) {
        var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (i in arr.vals()) {
            b.add(i);
        };
        b.add(id);
        return Buffer.toArray(b);
    };

    private func updateCanister(a : actor {}) : async () {
        let cid = { canister_id = Principal.fromActor(a) };
        var p : Buffer.Buffer<Principal> = Buffer.Buffer<Principal>(0);
        for (i in ENV.admins.vals()) {
            p.add(Principal.fromText(i));
        };
        await (
            IC.update_settings({
                canister_id = cid.canister_id;
                settings = {
                    controllers = ?Buffer.toArray(p);
                    compute_allocation = null;
                    memory_allocation = null;
                    freezing_threshold = ?31_540_000;
                };
            })
        );
    };

    private func create_canister() : async (Text) {
        Cycles.add(2000000000000);
        let canister = await Users.Users();
        let _ = await updateCanister(canister); // update canister permissions and settings
        let canister_id = Principal.fromActor(canister);
        return Principal.toText(canister_id);
    };

    private func _isAdmin(_p : Principal) : (Bool) {
        var p : Text = Principal.toText(_p);
        for (i in _admins.vals()) {
            if (p == i) {
                return true;
            };
        };
        return false;
    };

    //Types
    //
    type Users = Users.Users;
    public type canister_id = Principal;
    public type canister_settings = {
        freezing_threshold : ?Nat;
        controllers : ?[Principal];
        memory_allocation : ?Nat;
        compute_allocation : ?Nat;
    };
    public type definite_canister_settings = {
        freezing_threshold : Nat;
        controllers : [Principal];
        memory_allocation : Nat;
        compute_allocation : Nat;
    };
    public type user_id = Principal;
    public type wasm_module = Blob;

    //IC Management Canister
    //
    let IC = actor (ENV.IC_Management) : actor {
        create_canister : shared { settings : ?canister_settings } -> async {
            canister_id : canister_id;
        };
        update_settings : shared {
            canister_id : Principal;
            settings : canister_settings;
        } -> async ();
    };

    //IC Ledger Canister for Querying Blocks
    //
    let Ledger = actor (ENV.Ledger) : actor {
        account_balance : shared query ICP.AccountBalanceArgs -> async ICP.Tokens;
        archives : shared query () -> async ICP.Archives;
        decimals : shared query () -> async { decimals : Nat32 };
        name : shared query () -> async { name : Text };
        query_blocks : shared query ICP.GetBlocksArgs -> async ICP.QueryBlocksResponse;
        symbol : shared query () -> async { symbol : Text };
        transfer : shared ICP.TransferArgs -> async ICP.TransferResult;
        transfer_fee : shared query ICP.TransferFeeArg -> async ICP.TransferFee;
    };

    //ICRC-1 Ledger Canister for Querying Blocks
    //
    let ICRC1_Ledger = actor (ENV.ICRC1_Ledger) : actor {
        get_transactions : shared query (ICRC1.GetTransactionsRequest) -> async (ICRC1.GetTransactionsResponse);
    };

    //Queries
    //
    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

    public query func totalUsers() : async (Nat) {
        return Trie.size(_uids);
    };

    public query func get_user_canisterid(_uid : Text) : async (Result.Result<Text, Text>) {
        switch (Trie.find(_uids, Utils.keyT(_uid), Text.equal)) {
            case (?c) {
                return #ok(c);
            };
            case _ {
                return #err("user not found");
            };
        };
    };

    public query func get_all_ucanisters() : async [Text] {
        return _ucanisters;
    };

    public query func get_all_admins() : async [Text] {
        return _admins;
    };

    //Updates
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

    public shared ({ caller }) func create_new_user() : async (Result.Result<Text, Text>) {
        var _uid : Text = Principal.toText(caller);
        switch (await get_user_canisterid(_uid)) {
            case (#ok o) {
                return #err("user already exist");
            };
            case (#err e) {
                var canister_id : Text = "";
                label _check for (can_id in _ucanisters.vals()) {
                    var size : Nat32 = count_users(can_id);
                    if (size < 1000) {
                        canister_id := can_id;
                        _uids := Trie.put(_uids, Utils.keyT(_uid), Text.equal, canister_id).0;
                        break _check;
                    };
                };
                if (canister_id == "") {
                    canister_id := await create_canister();
                    _ucanisters := _add_text(_ucanisters, canister_id);
                    _uids := Trie.put(_uids, Utils.keyT(_uid), Text.equal, canister_id).0;
                };
                let db = actor (canister_id) : actor {
                    admin_create_user : shared (Text) -> async ();
                };
                await db.admin_create_user(Principal.toText(caller));
                return #ok(canister_id);
            };
        };
    };

    //Remote_Configs of Core Canister
    public shared ({ caller }) func create_config(name : Text, json : Text) : async (Result.Result<Text, Text>) {
        _configs.create_config(name, json);
    };

    public query func get_config(name : Text) : async (Text) {
        _configs.get_config(name);
    };

    public shared ({ caller }) func update_config(name : Text, json : Text) : async (Result.Result<Text, Text>) {
        _configs.update_config(name, json);
    };

    public shared ({ caller }) func delete_config(name : Text) : async (Result.Result<Text, Text>) {
        _configs.delete_config(name);
    };

    //Payment service endpoints
    //Txs block heights for ICP/ICRC1
    private stable var txs : Trie.Trie<Text, ICP.Tx> = Trie.empty();
    private stable var icrc_txs : Trie.Trie<Text, ICP.Tx_ICRC> = Trie.empty();

    //ICP Payments
    //IC Ledger Canister Query
    private func query_ledger_block(height : Nat64, _to : Text, _from : Text, _amt : ICP.Tokens) : async (Result.Result<Text, Text>) {
        var req : ICP.GetBlocksArgs = {
            start = height;
            length = 1;
        };
        var res : ICP.QueryBlocksResponse = await Ledger.query_blocks(req);
        var to_ : AccountIdentifier.AccountIdentifier = AccountIdentifier.fromText(_to, null);
        var from_ : AccountIdentifier.AccountIdentifier = AccountIdentifier.fromText(_from, null);
        var blocks : [ICP.Block] = res.blocks;
        var base_block : ICP.Block = blocks[0];
        var tx : ICP.Transaction = base_block.transaction;
        var op : ?ICP.Operation = tx.operation;
        switch (op) {
            case (?op) {
                switch (op) {
                    case (#Transfer { to; fee; from; amount }) {
                        if (Hex.encode(Blob.toArray(Blob.fromArray(to))) == to_ and Hex.encode(Blob.toArray(Blob.fromArray(from))) == from_ and amount == _amt) {
                            return #ok("verified!");
                        } else {
                            return #err("invalid tx!");
                        };
                    };
                    case (#Burn {}) {
                        return #err("burn tx!");
                    };
                    case (#Mint {}) {
                        return #err("mint tx!");
                    };
                };
            };
            case _ {
                return #err("invalid tx!");
            };
        };
    };

    public shared (msg) func verify_transaction(height : Nat64, _to : Text, _from : Text, _amt : Nat64, _paymentType : Text, _paymentMetadata : Text) : async (Result.Result<TUsers.CoreTxData, Text>) {
        assert (Principal.fromText(_from) == msg.caller);
        var amt_ : ICP.Tokens = {
            e8s = _amt;
        };
        var res : Result.Result<Text, Text> = await query_ledger_block(height, _to, _from, amt_);
        if (res == #ok("verified!")) {
            //tx spam check
            var tx : ?ICP.Tx = Trie.find(txs, Utils.keyT(Nat64.toText(height)), Text.equal);
            switch (tx) {
                case (?t) {
                    return #err("old tx!");
                };
                case null {};
            };
            //Tx if not spammed, store it in DB only latest 500 Txs
            if (Trie.size(txs) < 500) {
                txs := Trie.put(txs, Utils.keyT(Nat64.toText(height)), Text.equal, { height = height; to = _to; from = _from; amt = _amt }).0;
            } else {
                var oldestTx : Nat64 = height;
                for ((id, tx) in Trie.iter(txs)) {
                    if (oldestTx > tx.height) {
                        oldestTx := tx.height;
                    };
                };
                txs := Trie.remove(txs, Utils.keyT(Nat64.toText(oldestTx)), Text.equal).0;
                txs := Trie.put(txs, Utils.keyT(Nat64.toText(height)), Text.equal, { height = height; to = _to; from = _from; amt = _amt }).0;
            };
            //Here we need to call user DB, to update user assets accordingly.
            //TODO:
            //call users DB executeCoreTx endpoint to update offers/items

            if (_paymentType == "offer") {
                //_paymentMetadata must be the offer Id
                let offerId = "{\"" #_paymentMetadata # "\"}";
                //Get OffersConfig
                let offersConfig = await get_config("OffersConfig");

                //Look for offer config by its Id
                var offer_json_config = "";

                //Find config on stackable offers array
                switch (JSON.find_arr_element_by_itemId(offerId, "stackableOffers", offersConfig)) {
                    case (#ok(stackableOffers)) {
                        offer_json_config := stackableOffers;
                    };
                    case _ {

                        //Find config on noneStackableOffers offers array
                        switch (JSON.find_arr_element_by_itemId(offerId, "noneStackableOffers", offersConfig)) {
                            case (#ok(noneStackableOffers)) {
                                offer_json_config := noneStackableOffers;
                            };
                            case (#err(errMsg)) {
                                return #err("something went wrong looking for the offer config of id: " #offerId # " | json: " #offersConfig);
                            };
                        };
                    };
                };

                //Check if amt is equal or greater than the config amt
                let amount_config_txt = JSON.get_key(offer_json_config, "price");
                var amount_config = Utils.textToFloat(amount_config_txt);
                var real_amount_config = Utils.textToNat(Int.toText(Float.toInt(amount_config * 100_000_000)));
                var amt = Nat64.toNat(_amt);
                var a : Text = Float.toText(Float.fromInt(amt) / 100_000_000);
                if (amt < real_amount_config) return #err("No enoguh money! " # (Nat.toText(amt)) # " < " #Nat.toText(real_amount_config));

                //Apply gacha to user
                var output = await apply_gacha_variables(offerId); // we can use same offer id as the gacha id as they are the same value

                //Get the user data and return it as success response
                //JACK WAS HERE

                switch (output) {
                    case (#ok(rewards)) {

                        var processedOfferId = offerId;
                        processedOfferId := Option.get(Text.stripStart(processedOfferId, #char '{'), "");
                        processedOfferId := Option.get(Text.stripStart(processedOfferId, #char '\"'), "");
                        processedOfferId := Option.get(Text.stripEnd(processedOfferId, #char '}'), "");
                        processedOfferId := Option.get(Text.stripEnd(processedOfferId, #char '\"'), "");
                        let coreTxData : TUsers.CoreTxData = {
                            items = rewards.items;
                            profile = null;
                            bought_offers = ?{
                                add = ?[processedOfferId];
                                remove = null;
                            };
                        };
                        let response = await _executeCoreTx(Principal.toText(msg.caller), coreTxData);

                        return #ok(coreTxData);
                    };
                    case (#err(msg)) {
                        return #err(msg);
                    };
                };
            };
        };

        return #err("invalid tx!");
    };

    //ICRC Payments
    //ICRC1 Ledger Canister Query
    private func query_icrc_tx(index : Nat, _to : Text, _from : Text, _amt : Nat) : async (Result.Result<Text, Text>) {
        let l : Nat = 1;
        var _req : ICRC1.GetTransactionsRequest = {
            start = index;
            length = l;
        };
        var to_ : ICRC1.Account = {
            owner = Principal.fromText(_to);
            subaccount = null;
        };
        var from_ : ICRC1.Account = {
            owner = Principal.fromText(_from);
            subaccount = null;
        };
        var t : ICRC1.GetTransactionsResponse = await ICRC1_Ledger.get_transactions(_req);
        let tx = t.transactions[0];
        if (tx.kind == "transfer") {
            let transfer = tx.transfer;
            switch (transfer) {
                case (?tt) {
                    if (tt.from == from_ and tt.to == to_ and tt.amount == _amt) {
                        return #ok("verified!");
                    } else {
                        return #err("tx transfer details mismatch!");
                    };
                };
                case (null) {
                    return #err("tx transfer details not found!");
                };
            };

        } else {
            return #err("not a transfer!");
        };
    };

    public shared (msg) func update_assets_icrc(index : Nat, _to : Text, _from : Text, _amt : Nat, _paymentType : Text, _paymentMetadata : Text, _tokenCanisterId : Text) : async (ICP.Response) {
        assert (Principal.fromText(_from) == msg.caller);
        var res : Result.Result<Text, Text> = await query_icrc_tx(index, _to, _from, _amt);
        if (res == #ok("verified!")) {
            //tx spam check
            var tx : ?ICP.Tx_ICRC = Trie.find(icrc_txs, Utils.keyT(Nat.toText(index)), Text.equal);
            switch (tx) {
                case (?t) {
                    return #Err "old tx index!";
                };
                case null {};
            };
            if (Trie.size(txs) < 2000) {
                icrc_txs := Trie.put(icrc_txs, Utils.keyT(Nat.toText(index)), Text.equal, { index = index; to = _to; from = _from; amt = _amt }).0;
            } else {
                var oldestTx : Nat = index;
                for ((id, tx) in Trie.iter(icrc_txs)) {
                    if (oldestTx > tx.index) {
                        oldestTx := tx.index;
                    };
                };
                icrc_txs := Trie.remove(icrc_txs, Utils.keyT(Nat.toText(oldestTx)), Text.equal).0;
                icrc_txs := Trie.put(icrc_txs, Utils.keyT(Nat.toText(index)), Text.equal, { index = index; to = _to; from = _from; amt = _amt }).0;
            };

            //TODO: Accordingly
            //call users DB executeCoreTx endpoint to update offers/items
            //Here to update assets for ckBTC payments.
            return #Success(?"");
        } else {
            return #Err "ledger query failed!";
        };
    };

    //Burn NFT and process GACHA
    public shared (msg) func burn_nft(collection_canister_id : Text, tokenindex : EXT.TokenIndex, aid : EXT.AccountIdentifier) : async (Result.Result<TUsers.CoreTxData, Text>) {
        assert (AccountIdentifier.fromPrincipal(msg.caller, null) == aid);
        var tokenid : EXT.TokenIdentifier = await getTokenIdentifier(collection_canister_id, tokenindex);
        let collection = actor (collection_canister_id) : actor {
            ext_burn : (EXT.TokenIdentifier, EXT.AccountIdentifier) -> async (Result.Result<(), EXT.CommonError>);
            extGetTokenMetadata : (EXT.TokenIndex) -> async (?EXT.Metadata);
        };
        var res : Result.Result<(), EXT.CommonError> = await collection.ext_burn(tokenid, aid);
        switch (res) {
            case (#ok) {
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
                var output = await apply_gacha_variables(nft_usage); // we can use same offer id as the gacha id as they are the same value

                //Get the user data and return it as success response
                //JACK WAS HERE
                switch (output) {
                    case (#ok(rewards)) {
                        var processedOfferId = nft_usage;
                        let response = await _executeCoreTx(Principal.toText(msg.caller), rewards);
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

    //admin only endpoints
    public shared ({ caller }) func admin_executeGameTx(_uid : Text, _gid : Text, t : TUsers.GameTxData) : async (Result.Result<Text, Text>) {
        assert (_isAdmin(caller)); //only admin can update GameData of user
        switch (Trie.find(_uids, Utils.keyT(_uid), Text.equal)) {
            case (?canister_id) {
                let db = actor (canister_id) : actor {
                    executeGameTx : shared (Text, Text, TUsers.GameTxData) -> async ();
                };
                await db.executeGameTx(_uid, _gid, t);
                return #ok("executed");
            };
            case _ {
                return #err("user not found");
            };
        };
    };

    public shared ({ caller }) func admin_executeCoreTx(_uid : Text, t : TUsers.CoreTxData) : async (Result.Result<Text, Text>) {
        assert (_isAdmin(caller)); //only admin can update GameData of user
        switch (Trie.find(_uids, Utils.keyT(_uid), Text.equal)) {
            case (?canister_id) {
                let db = actor (canister_id) : actor {
                    executeCoreTx : shared (Text, TUsers.CoreTxData) -> async ();
                };
                await db.executeCoreTx(_uid, t);
                return #ok("executed");
            };
            case _ {
                return #err("user not found");
            };
        };
    };

    public shared ({ caller }) func admin_create_user(_uid : Text) : async (Result.Result<Text, Text>) {
        assert (_isAdmin(caller));
        switch (await get_user_canisterid(_uid)) {
            case (#ok o) {
                return #err("user already exist");
            };
            case (#err e) {
                var canister_id : Text = "";
                label _check for (can_id in _ucanisters.vals()) {
                    var size : Nat32 = count_users(can_id);
                    if (size < 1000) {
                        canister_id := can_id;
                        _uids := Trie.put(_uids, Utils.keyT(_uid), Text.equal, canister_id).0;
                        break _check;
                    };
                };
                if (canister_id == "") {
                    canister_id := await create_canister();
                    _ucanisters := _add_text(_ucanisters, canister_id);
                    _uids := Trie.put(_uids, Utils.keyT(_uid), Text.equal, canister_id).0;
                };
                let db = actor (canister_id) : actor {
                    admin_create_user : shared (Text) -> async ();
                };
                await db.admin_create_user(_uid);
                return #ok(canister_id);
            };
        };
    };

    public shared ({ caller }) func admin_delete_user(uid : Text) : async () {
        assert (_isAdmin(caller));
        _uids := Trie.remove(_uids, Utils.keyT(uid), Text.equal).0;
        return ();
    };

    //profile_data endpoints
    public shared ({ caller }) func setProfileData(t : TUsers.Profile) : async (Text) {
        var uid : Text = Principal.toText(caller);
        var canister_id : Text = Option.get(Trie.find(_uids, Utils.keyT(uid), Text.equal), "");
        let db = actor (canister_id) : actor {
            executeCoreTx : shared (Text, TUsers.CoreTxData) -> async ();
        };
        var tx_data : TUsers.CoreTxData = {
            profile = ?t;
            items = null;
            bought_offers = null;
        };
        await db.executeCoreTx(uid, tx_data);
        return "updated";
    };

    public query func checkUsernameAvailability(_u : Text) : async (Bool) {
        switch (Trie.find(_usernames, Utils.keyT(_u), Text.equal)) {
            case (?t) {
                return false;
            };
            case _ {
                return true;
            };
        };
    };

    public shared ({ caller }) func setUsername(_uid : Text, _name : Text) : async (Result.Result<Text, Text>) {
        if (_uid != Principal.toText(caller)) {
            return #err("caller not authorised");
        };
        switch (Trie.find(_usernames, Utils.keyT(_name), Text.equal)) {
            case (?u) {
                return #err("username already exist");
            };
            case _ {};
        };
        var canister_id : Text = "";
        switch (Trie.find(_uids, Utils.keyT(_uid), Text.equal)) {
            case (?c) {
                canister_id := c;
            };
            case _ {};
        };
        if (canister_id == "") {
            return #err("user not exist");
        };
        let db = actor (canister_id) : actor {
            _setUsername : shared (Text, Text) -> async (Text);
        };
        var res : Text = await db._setUsername(_uid, _name);
        if (res == "updated") {
            return #ok(res);
        } else {
            return #err(res);
        };
    };

};
