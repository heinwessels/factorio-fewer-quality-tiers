local proto_util = require("__fewer-quality-tiers__.prototypes.proto-util")

---@type string[]
local tiers = { "normal", "uncommon", "rare", "epic", "legendary" }

---@type table<string, boolean>
local is_tier_enabled = {}
for _, tier in pairs(tiers) do
    is_tier_enabled[tier] = tier == "normal" and true or (not not settings.startup["fewer-quality-tiers-enable-" .. tier].value)
end

local previous_tier = "normal"
local index = 2 -- Start with uncommon, can't disable "normal"
while index <= #tiers do
    local tier = tiers[index]
    assert(tier)

    ---@type string?
    local next_tier = tiers[index + 1]

    if not is_tier_enabled[tiers[index]] then
        proto_util.remove_quality_tier(previous_tier, tier, next_tier)
    else
        previous_tier = tier
    end

    index = index + 1
end