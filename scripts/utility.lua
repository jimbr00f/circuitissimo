local utility = {}

function utility.coalesce_tables(tables)
    local coalesced = {}
	for _, t in pairs(tables) do
		for name, value in pairs(t) do
			coalesced[name] = value
		end
	end
	return coalesced
end

return utility