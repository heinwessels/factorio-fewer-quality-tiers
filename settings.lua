local tiers = {
    -- "normal", -- Can't disable
    ["uncommon"]    = false,
    ["rare"]        = true,
    ["epic"]        = false,
    ["legendary"]   = true,
}

local tier_order = {
    -- "normal", -- Can't disable
    ["uncommon"]    = "a",
    ["rare"]        = "b",
    ["epic"]        = "c",
    ["legendary"]   = "d",
}

for tier, default in pairs(tiers) do
    data:extend({
        {
            type = "bool-setting",
            name = "fewer-quality-tiers-enable-" .. tier,
            localised_name = {"fewer-quality-tiers.enable-setting", {"quality-name." .. tier}},
            localised_description = {"fewer-quality-tiers.enable-setting-description"},
            order = tier_order[tier],
            setting_type = "startup",
            default_value = default,
        }
    })
end