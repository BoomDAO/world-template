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

import Users "./users";
import TUsers "./users.types";
import JSON "../utils/Json";
import Parser "../utils/Parser";
import ENV "../utils/Env";
import Utils "../utils/Utils";
import AccountIdentifier "../utils/AccountIdentifier";
import Hex "../utils/Hex";
import EXTCORE "../utils/Core";
import EXT "../utils/ext.types";

import Gacha "../modules/Gacha";
import Configs "../modules/Configs";
import Management "../modules/Management";

actor Core {
    //stable memory
    private stable var _uids : Trie.Trie<Text, Text> = Trie.empty(); //mapping user_id -> canister_id
    private stable var _usernames : Trie.Trie<Text, Text> = Trie.empty(); //mapping username -> _uid
    private stable var _ucanisters : [Text] = []; //all user db canisters
    private stable var _admins : [Text] = ENV.admins; //admins for user db

    private stable var remote_configs : Trie.Trie<Text, JSON.JSON> = Trie.empty();
    private var _configs = Configs.Configs(remote_configs); 

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
        let IC : Management.Management = actor (ENV.IC_Management);
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
