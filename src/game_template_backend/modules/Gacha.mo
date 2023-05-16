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

module Gacha {

    public type RewardData = {
        id : Text;
        quantity : Float; // if > 0 is add and if < 0 is subs
    };

    public func gen_gacha_variables(gacha_id : Text, gachas_json : Text) : async (Result.Result<[RewardData], Text>) {
        var rolls_text = "";
        switch (JSON.find_arr_element_by_itemId(gacha_id, "gachas", gachas_json)) {
            case (#ok(k)) {
                rolls_text := JSON.get_key(k, "rolls");
            };
            case (#err(errMsg)) {
                return #err("Err00: " #errMsg# "  " #gacha_id);
            };
        };
        rolls_text := Option.get(Text.stripStart(rolls_text, #char '{'), "");
        rolls_text := Option.get(Text.stripEnd(rolls_text, #char '}'), "");

        var gacha_output = Buffer.Buffer<RewardData>(0);
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
                                                    itemId_text := Option.get(Text.stripStart(itemId_text, #char '{'), "");
                                                    itemId_text := Option.get(Text.stripStart(itemId_text, #char '\"'), "");
                                                    itemId_text := Option.get(Text.stripEnd(itemId_text, #char '}'), "");
                                                    itemId_text := Option.get(Text.stripEnd(itemId_text, #char '\"'), "");
                                                    
                                                    let quantity_text = JSON.get_key(JSON.show(variable), "quantity");
                                                    var quantity : Float = Utils.textToFloat(quantity_text);

                                                    let reward : RewardData = {
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
};
