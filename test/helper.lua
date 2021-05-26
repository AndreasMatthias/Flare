_G._UNITTEST = true

--- Sorted iterator
function _G.sorted_pairs(t)
    local keys = {}
    for k in pairs(t) do
       keys[#keys+1] = k
    end
    table.sort(keys)

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
