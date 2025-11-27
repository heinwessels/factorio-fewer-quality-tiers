local proto_util = { }

--- Calculate the new probability to reach the next quality tier
--- if a quality tier is removed.
---@param previous_probability number?
---@param removed_probability number?
---@return number
local function calculate_combined_probability(previous_probability, removed_probability)
    previous_probability = previous_probability or 0 -- Has default of 0
    removed_probability = removed_probability or 0

    -- Chance to get from previous to next quality directly
    local direct_chance = previous_probability * removed_probability

    -- Account for items that would have been upgraded to the removed tier. These could
    -- have been recycled, and if we ignore this math then it's a bit too harsh.
    -- We will assume that they are put through a legendary recycler setup.
    -- Model the recycling as extra independent Bernoulli trials on the removed tier.
    -- The chance of at least one upgrade across those rolls is the complement of every roll failing.
    -- We multiply that by the probability mass that actually reached the removed tier to keep the direct chain untouched.
    -- Thanks to pocarski for helping with the math and GPT 5 Codex for turning it into code.
    local extra_rolls = 7 -- Approximation of how many times item will go through recycler
    local fail_chance = 0.75 -- To account for the recycler eats your item
    local per_roll_success = (1 - fail_chance) * removed_probability
    local recycled =
        previous_probability
        * (1 - removed_probability)
        * (1 - (1 - per_roll_success) ^ extra_rolls)

    return math.min(1, direct_chance + recycled)
end

---@param previous_quality_name string
---@param quality_name string
---@param next_quality_name string?
function proto_util.remove_quality_tier(previous_quality_name, quality_name, next_quality_name)
    assert(previous_quality_name)

    local previous_quality   = data.raw.quality[previous_quality_name]
    local quality            = data.raw.quality[quality_name]

    -- Update the previous tier to point to the next tier
    previous_quality.next = next_quality_name

    -- Update the next to be harder to achieve by combining probabilities
    previous_quality.next_probability = calculate_combined_probability(
        previous_quality.next_probability,
        quality.next_probability
    )

    -- Hide the quality tier
    quality.hidden = true
    quality.next = nil
    quality.next_probability = nil

    -- Remove this reference from all technologies that might reference it.
    for technology_name, technology in pairs(data.raw.technology) do
        local removed_an_effect = false
        for index, effect in pairs(technology.effects or { }) do
            if effect.type == "unlock-quality" and effect.quality == quality_name then
                table.remove(technology.effects, index)
                removed_an_effect = true
                break -- Loop is broken. We assume it will only be here once
            end
        end

        -- Did nothing
        if not removed_an_effect then goto continue end

        -- If we didn't remove all effects then we can just continue
        if (next(technology.effects or { })) then goto continue end

        -- If there are no effects left then we need to hide this tech and
        -- handle any prerequisites, etc.
        technology.hidden = true

        -- Each technology that uses this tech as a prereq will get all the previous
        -- techs as prereqs instead.
        for other_tech_name, other_tech in pairs(data.raw["technology"]) do
            if other_tech_name ~= technology_name then
                local found_prereq = false
                for prereq_index, prereq in pairs(other_tech.prerequisites or { }) do
                    if prereq == technology_name then
                        found_prereq = true
                        table.remove(other_tech.prerequisites, prereq_index)
                        break
                    end
                end

                if found_prereq then
                    for _, prereq in pairs(technology.prerequisites or { }) do
                        table.insert(other_tech.prerequisites, prereq)
                    end
                end
            end
        end

        ::continue::
    end
end

return proto_util