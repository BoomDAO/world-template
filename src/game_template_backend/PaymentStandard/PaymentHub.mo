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
import AccountIdentifier "../utils/AccountIdentifier";
import Core "../utils/Core";
import Hex "../utils/Hex";
import ICP "../utils/icp.types";
import ICRC1 "../utils/icrc.types";
import ENV "../utils/Env";
import Ledger "../modules/Ledger";
import Utils "../utils/Utils";

actor Payments {
  //Txs block heights
  private stable var icp_txs : Trie.Trie<Text, ICP.Tx> = Trie.empty(); //last 2000 txs of IC Ledger (verified in Payments canister) to prevent spam check in Payments canister
  private stable var icrc_txs : Trie.Trie<Text, ICP.Tx_ICRC> = Trie.empty(); //last 2000 txs of ICRC-1 Ledger (verified in Payments canister) to prevent spam check in Payments canister
  private stable var icp_holdings : Trie.Trie<Text, Nat64> = Trie.empty(); //mapping game_canister_id -> ICP value they hodl
  private stable var icrc_holdings : Trie.Trie<Text, Nat> = Trie.empty(); //mapping game_canister_id -> ICRC-1 token they hold

  //Internals
  private func update_holdings(_cid : Text, _amt : Nat64, _type : Text) : () {
    switch (_type) {
        case ("ICP"){
            switch (Trie.find(icp_holdings, Utils.keyT(_cid), Text.equal)){
                case (?h){
                    icp_holdings := Trie.put(icp_holdings, Utils.keyT(_cid), Text.equal, (_amt + h)).0;
                };
                case _ {
                    icp_holdings := Trie.put(icp_holdings, Utils.keyT(_cid), Text.equal, _amt).0;
                };
            };
        };
        case ("ICRC"){
            switch (Trie.find(icrc_holdings, Utils.keyT(_cid), Text.equal)){
                case (?h){
                    icrc_holdings := Trie.put(icrc_holdings, Utils.keyT(_cid), Text.equal, (Nat64.toNat(_amt) + h)).0;
                };
                case _ {
                    icrc_holdings := Trie.put(icrc_holdings, Utils.keyT(_cid), Text.equal, Nat64.toNat(_amt)).0;
                };
            };
        };
        case _ {};
    };
  };

  //IC Ledger Canister Query to verify tx height
  private func query_icp_tx(height : Nat64, _to : Text, _from : Text, _amt : ICP.Tokens) : async (Result.Result<Text, Text>) {
    var req : ICP.GetBlocksArgs = {
      start = height;
      length = 1;
    };
    let ICP_Ledger : Ledger.ICP = actor(ENV.Ledger);
    var res : ICP.QueryBlocksResponse = await ICP_Ledger.query_blocks(req);
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

  //ICRC1 Ledger Canister Query to verify ICRC-1 tx index
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
    let ICRC1_Ledger : Ledger.ICRC1 = actor(ENV.ICRC1_Ledger);
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

  //prevent spam ICP txs and perform action on successfull unique tx
  public shared (msg) func verify_tx_icp(height : Nat64, _to : Text, _from : Text, _amt : Nat64) : async (ICP.Response) {
    assert (Principal.fromText(_to) == Principal.fromText(ENV.paymenthub_canister_id));
    var amt_ : ICP.Tokens = {
      e8s = _amt;
    };
    var res : Result.Result<Text, Text> = await query_icp_tx(height, _to, _from, amt_);
    if (res == #ok("verified!")) {
      //tx spam check
      var tx : ?ICP.Tx = Trie.find(icp_txs, Utils.keyT(Nat64.toText(height)), Text.equal);
      switch (tx) {
        case (?t) {
          return #Err "old tx!";
        };
        case null {};
      };
      //update latest tx details in Payments canister memory
      if (Trie.size(icp_txs) < 2000) {
        icp_txs := Trie.put(icp_txs, Utils.keyT(Nat64.toText(height)), Text.equal, { height = height; to = _to; from = _from; amt = _amt }).0;
      } else {
        var oldestTx : Nat64 = height;
        for ((id, tx) in Trie.iter(icp_txs)) {
          if (oldestTx > tx.height) {
            oldestTx := tx.height;
          };
        };
        icp_txs := Trie.remove(icp_txs, Utils.keyT(Nat64.toText(oldestTx)), Text.equal).0;
        icp_txs := Trie.put(icp_txs, Utils.keyT(Nat64.toText(height)), Text.equal, { height = height; to = _to; from = _from; amt = _amt }).0;
      };

      //update holdings of game_canister accordingly
      update_holdings(Principal.toText(msg.caller), _amt, "ICP");
      return #Success("successfull"); 
    } else {
      return #Err "invalid tx!";
    };
  };

  //prevent spam ICRC-1 txs and perform action on successfull unique tx
  public shared (msg) func verify_tx_icrc(index : Nat, _to : Text, _from : Text, _amt : Nat) : async (ICP.Response) {
    assert (Principal.fromText(_to) == Principal.fromText(ENV.paymenthub_canister_id));
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
      //update latest tx details in Payments canister memory
      if (Trie.size(icrc_txs) < 2000) {
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
      
      update_holdings(Principal.toText(msg.caller), Nat64.fromNat(_amt), "ICRC");
      return #Success("successfull");
    } else {
      return #Err "ledger query failed!";
    };
  };

};