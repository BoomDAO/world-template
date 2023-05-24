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


module {
    public type itemId = Text;
    public type buffId = Text;
    public type achievementId = Text;
    public type profileId = Text;
    public type offerId = Text;

    public type Item = {
        id : Text;
        quantity : Float;
    };

    public type Buff = {
        id : Text;
        quantity : Float;
        ts : Int;
    };

    public type Achievement = {
        id : Text;
        quantity : Float;
        ts : Int;
    };

    public type Raw = {
        id : Text;
        type_ : Text;
        raw: Text;
    };

    public type Nft = {
        id : Text;
        quantity : Float;
        canister : Text;
        assetId : Text;
        collection : Text;
        standard : Text;
        metaData : Text;
    };

    public type Profile = {
        name : Text;
        url : Text;
        avatarKey : Text;
    };

    public type ArrayGameData = {
        items : [(itemId, Item)];
        buffs : [(buffId, Buff)];
        achievements : [(achievementId, Achievement)];
    };

    public type ArrayCoreData = {
        profile : Profile;
        items : [(itemId, Item)];
        bought_offers : [(offerId, Text)];
    };

    public type GameData = {
        items : Trie.Trie<itemId, Item>;
        buffs : Trie.Trie<buffId, Buff>;
        achievements : Trie.Trie<achievementId, Achievement>;
    };

    public type CoreData = {
        profile : Profile;
        items : Trie.Trie<itemId, Item>;
        bought_offers : Trie.Trie<offerId, Text>;
    };

    public type GameTxData = {
        items : ?{
            add : ?[Item];
            remove : ?[Item];
        };
        buffs : ?{
            add : ?[Buff];
            remove : ?[Buff];
        };
        achievements : ?{
            add : ?[Achievement];
            remove : ?[Achievement];
        };
    };

    public type CoreTxData = {
        profile : ?Profile;
        items : ?{
            add : ?[Item];
            remove : ?[Item];
        };
        bought_offers : ?{
            add : ?[offerId];
            remove : ?[offerId];
        };
    };

}