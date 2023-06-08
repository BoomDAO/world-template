import IC "mo:base/ExperimentalInternetComputer";
import Map "./src/Map";
import Prim "mo:prim";
import Set "./src/Set";
import TestMap "./test/Map";
import TestSet "./test/Set";

actor Test {
  let { ihash; nhash; n32hash; n64hash; thash; phash; bhash; lhash } = Map;

  type PerfStats = {
    cost: [{ #setCost: Nat64; #getCost: Nat64; #updateCost: Nat64; #deleteCost: Nat64; #deleteDescCost: Nat64 }];
    space: [{ #setSpace: Nat; #getSpace: Nat; #updateSpace: Nat; #deleteSpace: Nat }];
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func testPerf(): async PerfStats {
    let map = Map.new<Nat32, Nat32>(n32hash);

    let startSpace = Prim.rts_heap_size();

    let setCost = IC.countInstructions(func() {
      var i = 0:Nat32;

      while (i != 100000) { Map.set(map, n32hash, i, i); i +%= 1 };
    });

    let setSpace = Prim.rts_heap_size() - startSpace:Nat;

    let getCost = IC.countInstructions(func() {
      var i = 0:Nat32;

      while (i != 100000) { ignore Map.get(map, n32hash, i); i +%= 1 };
    });

    let getSpace = Prim.rts_heap_size() - startSpace:Nat - setSpace:Nat;

    let updateCost = IC.countInstructions(func() {
      var i = 0:Nat32;

      while (i != 100000) { Map.set(map, n32hash, i, i); i +%= 1 };
    });

    let updateSpace = Prim.rts_heap_size() - startSpace:Nat - setSpace:Nat - getSpace:Nat;

    let deleteCost = IC.countInstructions(func() {
      var i = 0:Nat32;

      while (i != 100000) { Map.delete(map, n32hash, i); i +%= 1 };
    });

    let deleteSpace = Prim.rts_heap_size() - startSpace:Nat - setSpace:Nat - getSpace:Nat - updateSpace:Nat;

    var i = 0:Nat32;

    while (i != 100000) { Map.set(map, n32hash, i, i); i +%= 1 };

    let deleteDescCost = IC.countInstructions(func() {
      var i = 100000:Nat32;

      while (i != 0) { i -%= 1; Map.delete(map, n32hash, i) };
    });

    return {
      cost = [#setCost(setCost), #getCost(getCost), #updateCost(updateCost), #deleteCost(deleteCost), #deleteDescCost(deleteDescCost)];
      space = [#setSpace(setSpace), #getSpace(getSpace), #updateSpace(updateSpace), #deleteSpace(deleteSpace)];
    };
  };

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  public query func runTests(): async () {
    TestMap.runTests();
    TestSet.runTests();
  };
};
