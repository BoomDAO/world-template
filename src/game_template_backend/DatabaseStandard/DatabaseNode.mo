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
import Types "Types";
import Utils "../utils/Utils";
import ENV "../utils/Env";

actor class Users() {
  //stable memory for DB
  private stable var _usersGame : Trie.Trie<Text, Trie.Trie<Text, Types.GameData>> = Trie.empty();
  private stable var _usersCore : Trie.Trie<Text, Types.CoreData> = Trie.empty();
  private stable var _games : [Text] = [];

  //Internal functions
  //
  //validating Game Canister as caller
  private func isGame_(_p : Principal) : (Bool) {
    var p : Text = Principal.toText(_p);
    for (i in _games.vals()) {
      if (p == i) {
        return true;
      };
    };
    return false;
  };
  //validating Core Canister as caller
  private func isCore_(p : Principal) : (Bool) {
    let _p : Text = Principal.toText(p);
    if (_p == ENV.core) {
      return true;
    };
    return false;
  };

  //to update Game Data of users
  private func executeGameTx_(_uid : Text, _gid : Text, t : Types.GameTxData) : async () {
    switch (Trie.find(_usersGame, Utils.keyT(_uid), Text.equal)) {
      case (?g) {
        switch (Trie.find(g, Utils.keyT(_gid), Text.equal)) {
          case (?d) {
            var items : Trie.Trie<Text, Types.Item> = d.items;
            var nbuffs : Trie.Trie<Text, Types.Buff> = d.buffs;
            var achievements : Trie.Trie<Text, Types.Achievement> = d.achievements;

            //for items add/remove
            switch (t.items) {
              case (?_i) {

                //for items addition
                switch (_i.add) {
                  case (?_items) {
                    for (i in _items.vals()) {
                      switch (Trie.find(items, Utils.keyT(i.id), Text.equal)) {
                        case (?item) {
                          var new_item : Types.Item = {
                            id = item.id;
                            quantity = item.quantity + i.quantity; //prev_val + new_val
                          };
                          items := Trie.put(items, Utils.keyT(item.id), Text.equal, new_item).0;
                        };
                        case _ {
                          items := Trie.put(items, Utils.keyT(i.id), Text.equal, i).0;
                        };
                      };
                    };
                  };
                  case _ {};
                };

                //for items removal
                switch (_i.remove) {
                  case (?_items) {
                    for (i in _items.vals()) {
                      switch (Trie.find(items, Utils.keyT(i.id), Text.equal)) {
                        case (?item) {
                          var new_item : Types.Item = {
                            id = item.id;
                            quantity = item.quantity - i.quantity; //prev_val + new_val
                          };
                          items := Trie.put(items, Utils.keyT(item.id), Text.equal, new_item).0;
                        };
                        case _ {};
                      };
                    };
                  };
                  case _ {};
                };

              };
              case _ {};
            };

            //for achievements add/remove
            switch (t.achievements) {
              case (?_a) {
                //for achievements addition
                switch (_a.add) {
                  case (?_achs) {
                    for (i in _achs.vals()) {
                      switch (Trie.find(achievements, Utils.keyT(i.id), Text.equal)) {
                        case (?ach) {
                          var new_ach : Types.Achievement = {
                            id = ach.id;
                            quantity = ach.quantity + i.quantity; //prev_val + new_val
                            firstTs = ach.firstTs;
                            endTs = Time.now();
                          };
                          achievements := Trie.put(achievements, Utils.keyT(ach.id), Text.equal, new_ach).0;
                        };
                        case _ {
                          var new_ach : Types.Achievement = {
                            id = i.id;
                            quantity = i.quantity;
                            firstTs = Time.now();
                            endTs = Time.now();
                          };
                          achievements := Trie.put(achievements, Utils.keyT(i.id), Text.equal, new_ach).0;
                        };
                      };
                    };
                  };
                  case _ {};
                };

                //for achievements removal
                switch (_a.remove) {
                  case (?_achs) {
                    for (i in _achs.vals()) {
                      switch (Trie.find(achievements, Utils.keyT(i.id), Text.equal)) {
                        case (?ach) {
                          var new_ach : Types.Achievement = {
                            id = ach.id;
                            quantity = ach.quantity - i.quantity; //prev_val + new_val
                            firstTs = ach.firstTs;
                            endTs = Time.now();
                          };
                          achievements := Trie.put(achievements, Utils.keyT(ach.id), Text.equal, new_ach).0;
                        };
                        case _ {};
                      };
                    };
                  };
                  case _ {};
                };

              };
              case _ {};
            };

            //for updating buffs
            switch (t.buffs) {
              case (?_b) {
                //for buffs addition
                switch (_b.add) {
                  case (?_buffs) {
                    for (i in _buffs.vals()) {
                      switch (Trie.find(nbuffs, Utils.keyT(i.id), Text.equal)) {
                        case (?buff) {
                          if (buff.usage == i.usage) {
                            var new_buff : Types.Buff = {
                              id = buff.id;
                              usage = buff.usage;
                              endTs = Time.now();
                            };
                            nbuffs := Trie.put(nbuffs, Utils.keyT(i.id), Text.equal, new_buff).0;
                          };
                        };
                        case _ {
                          var new_buff : Types.Buff = {
                            id = i.id;
                            usage = i.usage;
                            endTs = Time.now();
                          };
                          nbuffs := Trie.put(nbuffs, Utils.keyT(i.id), Text.equal, new_buff).0;
                        };
                      };
                    };
                  };
                  case _ {};
                };

                //for buffs removal
                switch (_b.remove) {
                  case (?_buffs) {
                    for (i in _buffs.vals()) {
                      switch (Trie.find(nbuffs, Utils.keyT(i.id), Text.equal)) {
                        case (?buff) {
                          if (buff.usage == i.usage) {
                            nbuffs := Trie.remove(nbuffs, Utils.keyT(buff.id), Text.equal).0;
                          };
                        };
                        case _ {};
                      };
                    };
                  };
                  case _ {};
                };

              };
              case _ {};
            };

            var new_game_data : Types.GameData = {
              items = items;
              buffs = nbuffs;
              achievements = achievements;
            };
            _usersGame := Trie.put2D(_usersGame, Utils.keyT(_uid), Text.equal, Utils.keyT(_gid), Text.equal, new_game_data);
          };
          case _ {
            var new_game_data : Types.GameData = {
              items = Trie.empty();
              buffs = Trie.empty();
              achievements = Trie.empty();
            };
            _usersGame := Trie.put2D(_usersGame, Utils.keyT(_uid), Text.equal, Utils.keyT(_gid), Text.equal, new_game_data);
            await executeGameTx_(_uid, _gid, t);
          };
        };
      };
      case _ {};
    };
  };

  //to update Core Data of users
  private func executeCoreTx_(_uid : Text, t : Types.CoreTxData) : async () {
    switch (Trie.find(_usersCore, Utils.keyT(_uid), Text.equal)) {
      case (?cd) {
        var _profile : Types.Profile = cd.profile;
        var items : Trie.Trie<Types.itemId, Types.Item> = cd.items;
        var _boughtOffers : Trie.Trie<Text, Text> = cd.bought_offers;
        //update profile
        switch (t.profile) {
          case (?p) {
            _profile := p;
          };
          case _ {};
        };

        //update items
        switch (t.items) {
          case (?_i) {
            //for items addition
            switch (_i.add) {
              case (?_items) {
                for (i in _items.vals()) {
                  switch (Trie.find(items, Utils.keyT(i.id), Text.equal)) {
                    case (?item) {
                      var new_item : Types.Item = {
                        id = item.id;
                        quantity = item.quantity + i.quantity; //prev_val + new_val
                      };
                      items := Trie.put(items, Utils.keyT(item.id), Text.equal, new_item).0;
                    };
                    case _ {
                      items := Trie.put(items, Utils.keyT(i.id), Text.equal, i).0;
                    };
                  };
                };
              };
              case _ {};
            };

            //for items removal
            switch (_i.remove) {
              case (?_items) {
                for (i in _items.vals()) {
                  switch (Trie.find(items, Utils.keyT(i.id), Text.equal)) {
                    case (?item) {
                      var new_item : Types.Item = {
                        id = item.id;
                        quantity = item.quantity - i.quantity; //prev_val + new_val
                      };
                      items := Trie.put(items, Utils.keyT(item.id), Text.equal, new_item).0;
                    };
                    case _ {};
                  };
                };
              };
              case _ {};
            };
          };
          case _ {};
        };

        //update boughtOffers
        switch (t.bought_offers) {
          case (?o) {
            switch (o.add) {
              case (?offers) {
                for (i in offers.vals()) {
                  _boughtOffers := Trie.put(_boughtOffers, Utils.keyT(i), Text.equal, i).0;
                };
              };
              case _ {};
            };
            switch (o.remove) {
              case (?offers) {
                for (i in offers.vals()) {
                  _boughtOffers := Trie.remove(_boughtOffers, Utils.keyT(i), Text.equal).0;
                };
              };
              case _ {};
            };
          };
          case _ {};
        };

        var d : Types.CoreData = {
          profile = _profile;
          items = items;
          bought_offers = _boughtOffers;
        };

        _usersCore := Trie.put(_usersCore, Utils.keyT(_uid), Text.equal, d).0;
      };
      case _ {};
    };
  };

  //Execute Transaction
  //
  public shared ({ caller }) func executeGameTx(_uid : Text, t : Types.GameTxData) : async () {
    assert (isGame_(caller)); //only game canister can update GameData of user
    var _gid : Text = Principal.toText(caller);
    await executeGameTx_(_uid, _gid, t);
  };

  public shared ({ caller }) func executeCoreTx(_uid : Text, t : Types.CoreTxData) : async () {
    assert (isCore_(caller)); //only core canister can update CoreData of user
    await executeCoreTx_(_uid, t);
  };

  //Profile update
  //
  public shared ({ caller }) func setUsername(_uid : Text, _name : Text) : async (Text) {
    assert (isCore_(caller));
    switch (Trie.find(_usersCore, Utils.keyT(_uid), Text.equal)) {
      case (?d) {
        var cd : Types.CoreData = {
          profile = {
            name = _name;
            url = d.profile.url;
            avatarKey = d.profile.avatarKey;
          };
          items = d.items;
          bought_offers = d.bought_offers;
        };
        _usersCore := Trie.put(_usersCore, Utils.keyT(_uid), Text.equal, cd).0;
        return "updated";
      };
      case _ {
        return "user data missing";
      };
    };
  };

  //CRUD
  //
  public shared ({ caller }) func adminCreateUser(_uid : Text) : async () {
    assert (isCore_(caller));
    var cd : Types.CoreData = {
      profile = {
        name = "";
        url = "";
        avatarKey = "";
      };
      items = Trie.empty();
      bought_offers = Trie.empty();
    };
    _usersGame := Trie.put(_usersGame, Utils.keyT(_uid), Text.equal, Trie.empty()).0;
    _usersCore := Trie.put(_usersCore, Utils.keyT(_uid), Text.equal, cd).0;
    return ();
  };

  //utils
  //
  public query func cycleBalance() : async Nat {
    Cycles.balance();
  };

  public query func totalUsers() : async (Nat) {
    return Trie.size(_usersGame);
  };

  public query func getAllUids() : async [Text] {
    var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
    for ((i, v) in Trie.iter(_usersGame)) {
      b.add(i);
    };
    return Buffer.toArray(b);
  };

  public query func getUserGameData(uid : Text) : async Result.Result<[(Text, Types.ArrayGameData)], Text> {
    switch (Trie.find(_usersGame, Utils.keyT(uid), Text.equal)) {
      case (?u) {
        var b : Buffer.Buffer<(Text, Types.ArrayGameData)> = Buffer.Buffer<(Text, Types.ArrayGameData)>(0);
        for ((i, j) in Trie.iter(u)) {
          var _items : Buffer.Buffer<(Text, Types.Item)> = Buffer.Buffer<(Text, Types.Item)>(0);
          var _achs : Buffer.Buffer<(Text, Types.Achievement)> = Buffer.Buffer<(Text, Types.Achievement)>(0);
          var _buffs : Buffer.Buffer<(Text, Types.Buff)> = Buffer.Buffer<(Text, Types.Buff)>(0);
          for (x in Trie.iter(j.items)) { _items.add(x) };
          for (x in Trie.iter(j.buffs)) { _buffs.add(x) };
          for (x in Trie.iter(j.achievements)) { _achs.add(x) };
          var gd : Types.ArrayGameData = {
            items = Buffer.toArray(_items);
            buffs = Buffer.toArray(_buffs);
            achievements = Buffer.toArray(_achs);
          };
          b.add((i, gd));
        };
        return #ok(Buffer.toArray(b));
      };
      case _ {
        return #err("user not found");
      };
    };
  };

  public query func getUserCoreData(uid : Text) : async Result.Result<Types.ArrayCoreData, Text> {
    switch (Trie.find(_usersCore, Utils.keyT(uid), Text.equal)) {
      case (?u) {
        var _items : Buffer.Buffer<(Text, Types.Item)> = Buffer.Buffer<(Text, Types.Item)>(0);
        var _offers : Buffer.Buffer<(Text, Text)> = Buffer.Buffer<(Text, Text)>(0);
        for (x in Trie.iter(u.items)) { _items.add(x) };
        for (x in Trie.iter(u.bought_offers)) { _offers.add(x) };
        var coredata : Types.ArrayCoreData = {
          profile = u.profile;
          items = Buffer.toArray(_items);
          bought_offers = Buffer.toArray(_offers);
        };
        return #ok(coredata);
      };
      case _ {
        return #err("user not found");
      };
    };
  };

  public query func getUserGame(uid : Text, gid : Text) : async Result.Result<Types.ArrayGameData, Text> {
    switch (Trie.find(_usersGame, Utils.keyT(uid), Text.equal)) {
      case (?u) {
        switch (Trie.find(u, Utils.keyT(gid), Text.equal)) {
          case (?g) {
            var _items : Buffer.Buffer<(Text, Types.Item)> = Buffer.Buffer<(Text, Types.Item)>(0);
            var _achs : Buffer.Buffer<(Text, Types.Achievement)> = Buffer.Buffer<(Text, Types.Achievement)>(0);
            var _buffs : Buffer.Buffer<(Text, Types.Buff)> = Buffer.Buffer<(Text, Types.Buff)>(0);
            for (x in Trie.iter(g.items)) { _items.add(x) };
            for (x in Trie.iter(g.buffs)) { _buffs.add(x) };
            for (x in Trie.iter(g.achievements)) { _achs.add(x) };
            var gamedata : Types.ArrayGameData = {
              items = Buffer.toArray(_items);
              buffs = Buffer.toArray(_buffs);
              achievements = Buffer.toArray(_achs);
            };
            return #ok(gamedata);
          };
          case _ {
            return #err("user's game_data not found");
          };
        };
      };
      case _ {
        return #err("user not found");
      };
    };
  };

  //update new Games canister_ids for validation
  public shared ({ caller }) func addGame(g : Text) : async () {
    assert (isCore_(caller));
    var b : Buffer.Buffer<Text> = Buffer.fromArray(_games);
    b.add(g);
    _games := Buffer.toArray(b);
  };
  public shared ({ caller }) func removeGame(g : Text) : async () {
    assert (isCore_(caller));
    var b : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
    for (i in _games.vals()) {
      if (i != g) {
        b.add(i);
      };
    };
    _games := Buffer.toArray(b);
  };

  //filters
  //
  public query func filterByGameKeyValue(
    _gid : Text,
    _key : Text,
    _val : {
      items : Types.Item;
      achievements : Types.Achievement;
      buffs : Types.Buff;
    },
  ) : async ([Types.GameData]) {
    var b : Buffer.Buffer<Types.GameData> = Buffer.Buffer<Types.GameData>(0);
    for ((uid, t) in Trie.iter(_usersGame)) {
      switch (Trie.find(t, Utils.keyT(_gid), Text.equal)) {
        case (?g) {
          switch (_key) {
            case ("items") {
              switch (Trie.find(g.items, Utils.keyT(_val.items.id), Text.equal)) {
                case (?i) {
                  b.add(g);
                };
                case _ {};
              };
            };
            case ("buffs") {
              switch (Trie.find(g.buffs, Utils.keyT(_val.buffs.id), Text.equal)) {
                case (?i) {
                  b.add(g);
                };
                case _ {};
              };
            };
            case ("achievements") {
              switch (Trie.find(g.achievements, Utils.keyT(_val.achievements.id), Text.equal)) {
                case (?i) {
                  b.add(g);
                };
                case _ {};
              };
            };
            case _ {};
          };
        };
        case _ {};
      };
    };
    return Buffer.toArray(b);
  };

};
