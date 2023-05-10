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
import Users "../users/users.types";
import Json "../utils/Json";
import Gacha "../modules/Gacha";
import RandomUtil "../utils/RandomUtil";
import Configs "../modules/Configs";
import EXTCORE "../utils/Core";
import EXT "../utils/ext.types";
import TUsers "../users/users.types";
import AccountIdentifier "../utils/AccountIdentifier";

actor DegenRace {
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

    //GAME LOGIC
    let degen_race_event_duration = 1_000_000_000 * 86400; //24hrs
    let degen_race_frequency = 1_000_000_000 * 10; //3600; //1hrs

    var event_end_ts : Int = 0;
    var last_race_ts = HashMap.HashMap<Text, Int>(100, Text.equal, Text.hash);

    var event_name = "SomeName";
    var leaderboardTopCap = 3;
    var leaderboards : Trie.Trie<Text, Leaderboard.Leaderboard> = Trie.empty();

    //Leadboard func
    //Dev
    public shared ({ caller }) func dispose_leaderboard(user_principal : Principal, amount : Nat) : async (Result.Result<Text, Text>) {
        //TODO: Check if caller has permission, else return #err
        switch (Trie.find(leaderboards, Utils.keyT(event_name), Text.equal)) {
            case (?leaderboard) {
                leaderboard.dispose();
            };
            case _ {
                return #err("Leaderboard of name " # event_name # " not found");
            };
        };
        return #ok("Leaderboard has been disposed!");
    };
    public shared ({ caller }) func increment_score(user_principal : Principal, amount : Nat) : async (Result.Result<Text, Text>) {
        //TODO: Check if caller has permission, else return #err
        switch (Trie.find(leaderboards, Utils.keyT(event_name), Text.equal)) {
            case (?leaderboard) {
                leaderboard.increment_score(Principal.toText(user_principal), amount);
            };
            case _ {
                return #err("Leaderboard of name " # event_name # " not found");
            };
        };

        return #ok("score incremented!");
    };

    //Game Dev func
    public shared ({ caller }) func start_event(new_event_name : Text) : async (Result.Result<Text, Text>) {
        //TODO: Check if caller has permission, else return #err

        event_name := new_event_name;

        //Check if leaderboard exist, if it doesnt then initialize a new one for this event
        switch (Trie.find(leaderboards, Utils.keyT(new_event_name), Text.equal)) {
            case (?leaderboard) {}; //Do nothing here
            case _ {
                let leaderboard = Leaderboard.Leaderboard(3);
                leaderboards := Trie.put(leaderboards, Utils.keyT(new_event_name), Text.equal, leaderboard).0;
            };
        };

        //Setup end ts
        event_end_ts := Time.now() + degen_race_event_duration;
        return #ok("degen race event started!");
    };
    public shared ({ caller }) func stop_event() : async (Result.Result<Text, Text>) {
        //TODO: Check if caller has permission, else return #err

        //Setup end ts
        event_end_ts := 0;
        return #ok("degen race event stopped!");
    };

    //Game User func
    private func _check_is_degen_race_live() : Bool {
        return event_end_ts >= Time.now();
    };
    public query func check_is_degen_race_live() : async Bool {
        return _check_is_degen_race_live();
    };
    public query func check_next_play_wait_time(principal : Text) : async Int {
        switch (last_race_ts.get(principal)) {
            case (?lastTs) {
                return lastTs;
            };
            case _ return 0;
        };
    };

    private func _get_config(name : Text) : (Text) {
        switch (Trie.find(remote_configs, Utils.keyT(name), Text.equal)) {
            case (?j) {
                return JSON.show(j);
            };
            case _ {
                return "json not found";
            };
        };
    };

    public query func check_current_event_name() : async (Text) {
        return event_name;
    };
    public query func check_can_start_race(principal : Text) : async (Result.Result<Text, Text>) {
        //Check if degen race is live
        var is_degen_race_live = _check_is_degen_race_live();
        if (is_degen_race_live == false) {
            return #err("degen race is not live.");
        };
        //Check if player can play, this is based on whether or not enough time has passed
        switch (last_race_ts.get(principal)) {
            case (?lastTs) {
                //Check if not enough time has passed to return error
                let now = Time.now();
                if (Int.notEqual(lastTs, 0) and Int.less(now, lastTs + degen_race_frequency)) {
                    return #err("no enough time has passed");
                } else {}; //Do nothing
            };
            case _ {}; //Do nothing
        };

        return #ok("race started");
    };
    public shared ({ caller }) func complete_race() : async (Result.Result<Nat, Text>) {
        let principal_txt = Principal.toText(caller);
        let can_start_race = await check_can_start_race(principal_txt);

        switch (can_start_race) {
            case (#err e) {
                return #err(e);
            };
            case (#ok e) {};
        };

        let now = Time.now();

        last_race_ts.put(principal_txt, now);

        switch (Trie.find(leaderboards, Utils.keyT(event_name), Text.equal)) {
            case (?leaderboard) {
                leaderboard.increment_score(principal_txt, 1);
                //Request to store seconds/score in database
                return #ok(leaderboard.get_score(principal_txt));
            };
            case _ {
                return #err("Leaderboard of name " # event_name # " not found");
            };
        };
    };

    ///
    // The last leaderboard entry will always be from the user_principal_text
    ///
    public query func get_leaderboard(user_principal_text : Text) : async (Result.Result<[Leaderboard.Entry], Text>) {
        switch (Trie.find(leaderboards, Utils.keyT(event_name), Text.equal)) {
            case (?leaderboard) {
                var tops_and_self = leaderboard.get_top_users_and_scores();

                let own_score = leaderboard.get_score(user_principal_text);
                tops_and_self.add({
                    user_principal = user_principal_text;
                    score = own_score;
                });

                return #ok(Buffer.toArray(tops_and_self));
            };
            case _ {
                return #err("Leaderboard of name " # event_name # " not found");
            };
        };
    };

    public query func cycleBalance() : async Nat {
        Cycles.balance();
    };

};
