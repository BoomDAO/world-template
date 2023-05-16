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
import EXTCORE "../utils/Core";
import Hex "../utils/Hex";
import ICP "../utils/icp.types";
import ICRC1 "../utils/icrc.types";
import ENV "../utils/Env";
import Ledger "../modules/Ledger";
import Utils "../utils/Utils";

//Note : This configuration of StakingHub canister is only for 24hr staking period and is experimental, may get changed in future
actor StakingHub {
  type ICPStake = {
    amount : Nat64;
    stakedAt : Int;
  };
  type ICRCStake = {
    amount : Nat;
    stakedAt : Int;
  };
  type EXTStake = {
    staker : Text; //principal
    tokenIndex : Nat32;
    stakedAt : Int;
  };

  //Txs block heights
  private stable var icp_txs : Trie.Trie<Text, ICP.Tx> = Trie.empty(); //last 2000 txs of IC Ledger (verified in Payments canister) to prevent spam check in Payments canister
  private stable var icrc_txs : Trie.Trie<Text, Trie.Trie<Text, ICP.Tx_ICRC>> = Trie.empty(); // (icrc_token_canister_id -> tx_height -> Tx) last 2000 txs of ICRC-1 Ledger (verified in Payments canister) to prevent spam check in Payments canister
  private stable var icp_stakes : Trie.Trie<Text, ICPStake> = Trie.empty(); //mapping user_principal -> ICP value stake user stake
  private stable var icrc_stakes : Trie.Trie<Text, Trie.Trie<Text, ICRCStake>> = Trie.empty(); //mapping user_principal -> icrc_token_canister_id -> ICRC-1 token stake user hold
  private stable var ext_stakes : Trie.Trie<Text, EXTStake> = Trie.empty(); //mapping "(ext_collection_canister_id + / + index)" -> Ext NFT stake user hold

  //to update Stakes of ICP/ICRC/EXT tokens
  private func _update_stakes(_of : Text, _amt : Nat64, _type : Text, token_canister_id : ?Text, nft_index : ?Nat32) : () {
    switch (_type) {
      case ("ICP") {
        switch (Trie.find(icp_stakes, Utils.keyT(_of), Text.equal)) {
          case (?h) {
            icp_stakes := Trie.put(
              icp_stakes,
              Utils.keyT(_of),
              Text.equal,
              {
                amount = (_amt + h.amount);
                stakedAt = Time.now();
              },
            ).0;
          };
          case _ {
            icp_stakes := Trie.put(
              icp_stakes,
              Utils.keyT(_of),
              Text.equal,
              {
                amount = _amt;
                stakedAt = Time.now();
              },
            ).0;
          };
        };
      };
      case ("ICRC") {
        var _tcid : Text = Option.get(token_canister_id, "");
        switch (Trie.find(icrc_stakes, Utils.keyT(_of), Text.equal)) {
          case (?_trie) {
            switch (Trie.find(_trie, Utils.keyT(_tcid), Text.equal)) {
              case (?h) {
                var t : Trie.Trie<Text, ICRCStake> = _trie;
                t := Trie.put(
                  t,
                  Utils.keyT(_tcid),
                  Text.equal,
                  {
                    amount = (Nat64.toNat(_amt) + h.amount);
                    stakedAt = Time.now();
                  },
                ).0;
                icrc_stakes := Trie.put(icrc_stakes, Utils.keyT(_of), Text.equal, t).0;
              };
              case _ {
                var t : Trie.Trie<Text, ICRCStake> = Trie.empty();
                t := Trie.put(
                  t,
                  Utils.keyT(_tcid),
                  Text.equal,
                  {
                    amount = (Nat64.toNat(_amt));
                    stakedAt = Time.now();
                  },
                ).0;
                icrc_stakes := Trie.put(icrc_stakes, Utils.keyT(_of), Text.equal, t).0;
              };
            };
          };
          case _ {
            var _t : Trie.Trie<Text, ICRCStake> = Trie.empty();
            _t := Trie.put(
              _t,
              Utils.keyT(_tcid),
              Text.equal,
              {
                amount = (Nat64.toNat(_amt));
                stakedAt = Time.now();
              },
            ).0;
            icrc_stakes := Trie2D.put(icrc_stakes, Utils.keyT(_of), Text.equal, _t).0;
          };
        };
      };
      case ("EXT") {
        var key : Text = Option.get(token_canister_id, "");
        let default : Nat32 = 0;
        key := key # "/" #Nat32.toText(Option.get(nft_index, default)); //key = "token_canister_id" + "/" + "nft_index"
        var e : EXTStake = {
          staker = _of;
          tokenIndex = Option.get(nft_index, default);
          stakedAt = Time.now();
        };
        ext_stakes := Trie.put(ext_stakes, Utils.keyT(key), Text.equal, e).0;
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
    let ICP_Ledger : Ledger.ICP = actor (ENV.Ledger);
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
  //NOTE : Do Not Forget to change token_canister_id to query correct ICRC-1 Ledger
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
    let ICRC1_Ledger : Ledger.ICRC1 = actor (ENV.ICRC1_Ledger); //add you ICRC-1 token_canister_id here, to query its tx
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

  //EXT tx verification checks
  //1. Our StakingHubCanister owns the NFT
  //2. NFT is not already staked by someone else in our NFT vault
  private func query_ext_tx(collection_canister_id : Text, nft_index : Nat32, _from : Text, _to : Text) : async (Result.Result<Text, Text>) {
    let EXT : Ledger.EXT = actor (collection_canister_id);
    var _registry : [(Nat32, Text)] = await EXT.getRegistry();
    for (i in _registry.vals()) {
      if (i.0 == nft_index) {
        if (_to != AccountIdentifier.fromText(_to, null)) {
          return #err("we do not hold this NFT yet!");
        };
      };
    };
    var key : Text = collection_canister_id # "/" #Nat32.toText(nft_index);
    switch (Trie.find(ext_stakes, Utils.keyT(key), Text.equal)) {
      case (?stake) {
        return #err("NFT already staked by : " #stake.staker);
      };
      case _ {
        return #ok("verified!");
      };
    };
  };

  //prevent spam ICP txs and perform action on successfull unique tx
  public shared (msg) func update_icp_stakes(height : Nat64, _to : Text, _from : Text, _amt : Nat64) : async (ICP.Response) {
    assert (Principal.fromText(_from) == msg.caller); //If payment done by correct person and _from arg is passed correctly
    assert (Principal.fromText(_to) == Principal.fromText(ENV.stakinghub_canister_id)); //If payment is done to correct stakinghub_canister
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
      //update latest tx details in StakingHub canister memory
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
      //update stakes of user who did the payment
      _update_stakes(Principal.toText(msg.caller), _amt, "ICP", null, null);
      return #Success("successfull");
    } else {
      return #Err "invalid tx!";
    };
  };

  //prevent spam ICRC-1 txs and perform action on successfull unique tx
  public shared (msg) func update_icrc_stakes(index : Nat, _to : Text, _from : Text, _amt : Nat, token_canister_id : Text) : async (ICP.Response) {
    assert (Principal.fromText(_from) == msg.caller); //If payment done by correct person and _from arg is passed correctly
    assert (Principal.fromText(_to) == Principal.fromText(ENV.stakinghub_canister_id));
    var res : Result.Result<Text, Text> = await query_icrc_tx(index, _to, _from, _amt);
    if (res == #ok("verified!")) {
      var _token_txs : Trie.Trie<Text, ICP.Tx_ICRC> = Trie.empty();
      switch (Trie.find(icrc_txs, Utils.keyT(token_canister_id), Text.equal)) {
        case (?_txs) {
          _token_txs := _txs;
          switch (Trie.find(_txs, Utils.keyT(Nat.toText(index)), Text.equal)) {
            case (?tx) {
              return #Err("old tx index for ICRC-1 Token : " #token_canister_id);
            };
            case _ {};
          };
        };
        case _ {};
      };
      //update latest tx details in Payments canister memory
      if (Trie.size(_token_txs) < 2000) {
        _token_txs := Trie.put(_token_txs, Utils.keyT(Nat.toText(index)), Text.equal, { index = index; to = _to; from = _from; amt = _amt }).0;
        icrc_txs := Trie2D.put(icrc_txs, Utils.keyT(token_canister_id), Text.equal, _token_txs).0;
      } else {
        var oldestTx : Nat = index;
        for ((id, tx) in Trie.iter(_token_txs)) {
          if (oldestTx > tx.index) {
            oldestTx := tx.index;
          };
        };
        _token_txs := Trie.remove(_token_txs, Utils.keyT(Nat.toText(oldestTx)), Text.equal).0;
        _token_txs := Trie.put(_token_txs, Utils.keyT(Nat.toText(index)), Text.equal, { index = index; to = _to; from = _from; amt = _amt }).0;
        icrc_txs := Trie2D.put(icrc_txs, Utils.keyT(token_canister_id), Text.equal, _token_txs).0;
      };

      _update_stakes(Principal.toText(msg.caller), Nat64.fromNat(_amt), "ICRC", ?token_canister_id, null);
      return #Success("successfull");
    } else {
      return #Err "ledger query failed!";
    };
  };

  //prevent spam ICRC-1 txs and perform action on successfull unique tx
  public shared (msg) func update_ext_stakes(index : Nat32, _to : Text, _from : Text, collection_canister_id : Text) : async (ICP.Response) {
    assert (Principal.fromText(_from) == msg.caller);
    assert (Principal.fromText(_to) == Principal.fromText(ENV.stakinghub_canister_id));

    switch (await query_ext_tx(collection_canister_id, index, _from, _to)) {
      case (#ok _) {
        _update_stakes(_from, 1, "EXT", ?collection_canister_id, ?index);
        return #Success("successfull");
      };
      case (#err e) {
        return #Err(e);
      };
    };
  };

  public shared ({ caller }) func process_withdrawal(_type : Text) : async () {
    let delay = 86400000000000; //24hrs in nanoseconds
    //ICP withdrawal processing
    let ICP_Ledger : Ledger.ICP = actor (ENV.Ledger);
    for ((_to, _stakes) in Trie.iter(icp_stakes)) {
      let minimum_amount_to_withdraw : Nat64 = 100000000; //adjust it accordingly, here its 1 ICP
      if ((_stakes.stakedAt + delay <= Time.now()) and _stakes.amount >= minimum_amount_to_withdraw) {
        var amt : Nat64 = _stakes.amount - 10000; //deducting fees from user stakes for ICP, you can change it accordingly
        var _req : ICP.TransferArgs = {
          to = Hex.decode(AccountIdentifier.fromText(_to, null));
          fee = {
            e8s = 10000;
          };
          memo = 0;
          from_subaccount = null;
          created_at_time = null;
          amount = {
            e8s = amt;
          };
        };
        var res : ICP.TransferResult = await ICP_Ledger.transfer(_req);
        let x : Nat64 = 0;
        icp_stakes := Trie.put(
          icp_stakes,
          Utils.keyT(_to),
          Text.equal,
          {
            amount = x;
            stakedAt = Time.now();
          },
        ).0;
      };
    };

    //ICRC-1 withdrawal processing
    for ((_to, _trie) in Trie.iter(icrc_stakes)) {
      for ((_canister_id, _stakes) in Trie.iter(_trie)) {
        let minimum_amount_to_withdraw : Nat = 100; //adjust it accordingly
        if ((_stakes.stakedAt + delay <= Time.now()) and _stakes.amount >= minimum_amount_to_withdraw) {
          var amt : Nat = _stakes.amount - 10; //deducting fees from user stakes for ckBTC, you can change it accordingly for different ICRC-1 Tokens
          var _req : ICRC1.TransferArg = {
            to = {
              owner = Principal.fromText(_to);
              subaccount = null;
            };
            fee = null;
            memo = null;
            from_subaccount = null;
            created_at_time = null;
            amount = amt;
          };
          let ICRC1_Ledger : Ledger.ICRC1 = actor (_canister_id);
          var res : ICRC1.Result = await ICRC1_Ledger.icrc1_transfer(_req);
          let x : Nat = 0;
          var t : Trie.Trie<Text, ICRCStake> = _trie;
          t := Trie.put(
            t,
            Utils.keyT(_canister_id),
            Text.equal,
            {
              amount = x;
              stakedAt = Time.now();
            },
          ).0;
          icrc_stakes := Trie.put(icrc_stakes, Utils.keyT(_to), Text.equal, t).0;
        };
      };
    };

    //EXT V2 NFT withdrawal processing
    for ((_key, _stakes) in Trie.iter(ext_stakes)) {
      if (_stakes.stakedAt + delay <= Time.now()) {
        let path = Iter.toArray(Text.tokens(_key, #text("/")));
        let collection_canister_id = path[0];
        let index = Nat32.fromNat(Utils.textToNat(path[1]));

        var _req : EXTCORE.TransferRequest = {
          from = #principal(Principal.fromText(ENV.stakinghub_canister_id));
          to = #principal(Principal.fromText(_stakes.staker));
          token = EXTCORE.TokenIdentifier.fromText(collection_canister_id, index);
          amount = 1;
          memo = Text.encodeUtf8("");
          notify = false;
          subaccount = null;
        };
        let EXT : Ledger.EXT = actor (collection_canister_id);
        var res : EXTCORE.TransferResponse = await EXT.transfer(_req);
      };
    };
  };
};