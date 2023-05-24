import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Random "mo:base/Random";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Float "mo:base/Float";
import Option "mo:base/Option";

import JSON "../utils/Json";
import RandomUtil "../utils/RandomUtil";
import Utils "../utils/Utils";
import TUsers "../DatabaseStandard/Types";
import Int "mo:base/Int";

module Gacha {

    public type ItemData = {
        id : Text;
        quantity : Float; // if > 0 is add and if < 0 is subs
    };

    public func generateGachaReward(gachaId : Text, gachasConfigJson : Text) : async (Result.Result<[ItemData], Text>) {
        var rolls_text = "";
        switch (JSON.get_element_by_field_value(gachasConfigJson, "gachas", "Id", gachaId)) {
            case (#ok(k)) {
                rolls_text := JSON.get_key(k, "rolls");
            };
            case (#err(errMsg)) {
                return #err("Err00:: " #errMsg# " _ " #gachaId);
            };
        };
        rolls_text := JSON.strip(rolls_text,'{','}');

        var gacha_output = Buffer.Buffer<ItemData>(0);
        switch (JSON.parse(rolls_text)) {
            //ROLLS
            case (?rolls_json) {
                switch (rolls_json) {
                    case (#Array(rolls)) {
                        for (roll in rolls.vals()) {
                            var accumulated_weight : Float = 0;
                            var variables_text = JSON.get_key(JSON.show(roll), "variables");
                            variables_text := Option.get(Text.stripStart(variables_text, #char '{'), "");
                            variables_text := Option.get(Text.stripEnd(variables_text, #char '}'), "");
                            //VARIABLES
                            switch (JSON.parse(variables_text)) {
                                case (?variables_json) {
                                    switch (variables_json) {
                                        case (#Array(variables)) {
                                            //A) Compute total weight on the current roll
                                            for (variable in variables.vals()) {
                                                let weight_text = JSON.get_key(JSON.show(variable), "weight");
                                                var weight = Utils.textToFloat(weight_text);
                                                accumulated_weight += weight;
                                            };

                                            //B) Gen a random bumber using the total weight as max value
                                            let rand_perc = await RandomUtil.get_random_perc();
                                            var dice_roll = (rand_perc * 1.0 * accumulated_weight);

                                            //C Pick items base on their weights
                                            label variable_loop for (variable in variables.vals()) {
                                                let weight_text = JSON.get_key(JSON.show(variable), "weight");

                                                var weight = Utils.textToFloat(weight_text);
                                                if (weight >= dice_roll) {
                                                    var itemId_text = JSON.get_key(JSON.show(variable), "itemId");
                                                    itemId_text := JSON.strip(itemId_text, '{', '}');
                                                    
                                                    let quantity_text = JSON.get_key(JSON.show(variable), "quantity");
                                                    var quantity : Float = Utils.textToFloat(quantity_text);

                                                    let reward : ItemData = {
                                                        id = itemId_text;
                                                        quantity = quantity;
                                                    };
                                                    gacha_output.add(reward);

                                                    break variable_loop;
                                                } else {
                                                    dice_roll -= weight;
                                                };
                                                //
                                            };

                                        };
                                        case _ {
                                            return #err("Err01: " # "variables json is not an array");
                                        };
                                    };
                                };
                                case _ {
                                    return #err("Err02: " # "variables json not valid");
                                };
                            };
                            //.
                        };
                    };
                    case _ { return #err("roll_text not valid json array") };
                };
            };
            case _ { return #err("roll_text not valid json") };
        };

        return #ok(Buffer.toArray(gacha_output));
    };

    public func setupGameTxData(gachaOutput : [ItemData], itemsConfig : Text) : (gameTx : TUsers.GameTxData , nfts : [TUsers.Nft]) {
        let itemsConfigArray = JSON.get_typed_array(itemsConfig, "items");
        let buffsConfigArray = JSON.get_typed_array(itemsConfig, "buffs");
        let nftsConfigArray = JSON.get_typed_array(itemsConfig, "nts");

        let items = Buffer.Buffer<TUsers.Item>(0);
        let buffs = Buffer.Buffer<TUsers.Buff>(0);
        let nfts = Buffer.Buffer<TUsers.Nft>(0);

        label gachaVariableLoop for(gachaVariable in gachaOutput.vals()){
            //items
            for(config in itemsConfigArray.vals()){
                let configId = JSON.get_unwrapped_key(JSON.show(config), "itemId");
                if(configId == gachaVariable.id){
                    items.add(gachaVariable);
                    continue gachaVariableLoop;
                };
            };
            //buffs
            for(config in buffsConfigArray.vals()){
                let configId = JSON.get_unwrapped_key(JSON.show(config), "itemId");
                if(configId == gachaVariable.id){
                    let durationStr = JSON.get_unwrapped_key(JSON.show(config), "duration");
                    let duration = Utils.textToFloat(durationStr);
                    let floatEndTs = duration * 1_000_000_000;

                    buffs.add({
                        id = gachaVariable.id;
                        quantity = gachaVariable.quantity;
                        ts = Utils.textToNat(Int.toText(Float.toInt(floatEndTs)));
                    });
                    continue gachaVariableLoop;
                };
            };
            //nfts
            for(config in nftsConfigArray.vals()){
                let configId = JSON.get_unwrapped_key(JSON.show(config), "itemId");
                if(configId == gachaVariable.id){
                    let canister = JSON.get_unwrapped_key(JSON.show(config), "canister");
                    let assetId = JSON.get_unwrapped_key(JSON.show(config), "assetId");
                    let collection = JSON.get_unwrapped_key(JSON.show(config), "collection");
                    let standard = JSON.get_unwrapped_key(JSON.show(config), "standard");
                    let metaData = JSON.get_unwrapped_key(JSON.show(config), "metaData");

                    nfts.add({
                        id = gachaVariable.id;
                        quantity = gachaVariable.quantity;

                        canister;
                        assetId;
                        collection;
                        standard;
                        metaData;
                    });
                    continue gachaVariableLoop;
                };
            };
        };

        let gameTxData : TUsers.GameTxData = {
                    achievements = null;
                    items = ?{
                        add = ?Buffer.toArray(items);
                        remove = null;
                    };
                    buffs = ?{
                        add = ?Buffer.toArray(buffs);
                        remove = null;
                    };
                };

        return (gameTxData, Buffer.toArray(nfts));
    };
    public func setupGameTxData_(gachaOutput : [ItemData], itemsConfig : Text) : (gameTx : TUsers.GameTxData , nfts : [TUsers.Nft], Text) {
        let itemsConfigArray = JSON.get_typed_array(itemsConfig, "items");
        let buffsConfigArray = JSON.get_typed_array(itemsConfig, "buffs");
        let nftsConfigArray = JSON.get_typed_array(itemsConfig, "nts");

        let items = Buffer.Buffer<TUsers.Item>(0);
        let buffs = Buffer.Buffer<TUsers.Buff>(0);
        let nfts = Buffer.Buffer<TUsers.Nft>(0);
        
        var v = "> ";
        var a = JSON.show(#Array(itemsConfigArray));
        label gachaVariableLoop for(gachaVariable in gachaOutput.vals()){
            // v := v # ", " # gachaVariable.id;
            v := v # ", id: " # gachaVariable.id;

            v := v # " (";
            //items
            for(config in itemsConfigArray.vals()){
                let configId = JSON.get_unwrapped_key(JSON.show(config), "itemId");
                v := v # " [ Item" # configId # " ]";
                if(configId == gachaVariable.id){
                    items.add(gachaVariable);
                    
                    continue gachaVariableLoop;
                };
            };
            
            //buffs
            for(config in buffsConfigArray.vals()){
                let configId = JSON.get_unwrapped_key(JSON.show(config), "itemId");
                v := v # " [ buff" # configId # " ]";
                if(configId == gachaVariable.id){
                    let durationStr = JSON.get_unwrapped_key(JSON.show(config), "duration");
                    let duration = Utils.textToFloat(durationStr);
                    let floatEndTs = duration * 1_000_000_000;

                    buffs.add({
                        id = gachaVariable.id;
                        quantity = gachaVariable.quantity;
                        ts = Utils.textToNat(Int.toText(Float.toInt(floatEndTs)));
                    });

                    

                    continue gachaVariableLoop;
                };
            };
            //nfts
            for(config in nftsConfigArray.vals()){
                let configId = JSON.get_unwrapped_key(JSON.show(config), "itemId");
                v := v # " [ nft" # configId # " ]";
                if(configId == gachaVariable.id){
                    let canister = JSON.get_unwrapped_key(JSON.show(config), "canister");
                    let assetId = JSON.get_unwrapped_key(JSON.show(config), "assetId");
                    let collection = JSON.get_unwrapped_key(JSON.show(config), "collection");
                    let standard = JSON.get_unwrapped_key(JSON.show(config), "standard");
                    let metaData = JSON.get_unwrapped_key(JSON.show(config), "metaData");

                    nfts.add({
                        id = gachaVariable.id;
                        quantity = gachaVariable.quantity;

                        canister;
                        assetId;
                        collection;
                        standard;
                        metaData;
                    });

                    v := v # ", nft: " # gachaVariable.id;

                    continue gachaVariableLoop;
                };
            };

                        v := v # ") ";
        };

        let gameTxData : TUsers.GameTxData = {
                    achievements = null;
                    items = ?{
                        add = ?Buffer.toArray(items);
                        remove = null;
                    };
                    buffs = ?{
                        add = ?Buffer.toArray(buffs);
                        remove = null;
                    };
                };

        return (gameTxData, Buffer.toArray(nfts), itemsConfig);
    };
};
