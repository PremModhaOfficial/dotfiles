-- Restore quote textobjects (ciq/yiq/diq/aq/iq) via mini.ai
-- mini.ai ships inside the mini.nvim monorepo (already installed), so this
-- needs no new plugin download. Default textobjects include:
--   q  Alias for ", ', or `  ->  iq/aq/ciq/yiq/diq all work
return {
	{
		"nvim-mini/mini.ai",
		version = false, -- use latest stable commit
		opts = {
			-- Search up to 500 lines for textobject candidates
			-- (matches the old config that lived in plugins/ui/indets.lua)
			n_lines = 500,
		},
	},
}
