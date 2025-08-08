local exports = {}

function exports.coalesce_tables(tables)
    local coalesced = {}
	for _, t in pairs(tables) do
		for name, value in pairs(t) do
			coalesced[name] = value
		end
	end
	return coalesced
end

function exports.concat_arrays(arrays)
    local concatenated = {}
    for _, array in ipairs(arrays) do
        for i = 1, #array do
            concatenated[#concatenated+1] = array[i]
        end
    end
    return concatenated
end


return exports