local proto_util = { }

---@param previous_quality_name string
---@param quality_name string
---@param next_quality_name string?
function proto_util.remove_quality_tier(previous_quality_name, quality_name, next_quality_name)
    assert(previous_quality_name)

    local previous_quality   = data.raw.quality[previous_quality_name]
    local quality            = data.raw.quality[quality_name]
    local next_quality       = next_quality_name and data.raw.quality[next_quality_name] or nil

    -- Update the previous tier to point to the next tier
    previous_quality.next = next_quality_name

    -- Update the next to be harder to achieve by combining probabilities
    previous_quality.next_probability = (previous_quality.next_probability or 1) * (quality.next_probability or 1)

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