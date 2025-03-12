local symbols = require("snipe-lsp.symbols")
local code_actions = require("snipe-lsp.code_actions")

return {
	--- Setup the plugin
	--- @param config table
	--- @return nil
	setup = function(config)
		-- merge config with default keymap
		config = vim.tbl_deep_extend("force", {
			keymap = {
				open_symbols_menu = "<leader>ds",
				open_symbols_menu_for_split = "<leader>sds",
				open_symbols_menu_for_vsplit = "<leader>vds",
			},
		}, config or {})

		-- Keymap to open the symbols menu and navigate
		vim.keymap.set(
			"n",
			config.keymap.open_symbols_menu,
			symbols.open_symbols_menu,
			{ desc = "Navigate LSP Symbols" }
		)
		vim.keymap.set(
			"n",
			config.keymap.open_symbols_menu_for_split,
			symbols.open_symbols_menu_for_split("split"),
			{ desc = "Navigate LSP Symbols and open in a split pane" }
		)
		vim.keymap.set(
			"n",
			config.keymap.open_symbols_menu_for_vsplit,
			symbols.open_symbols_menu_for_split("vsplit"),
			{ desc = "Navigate LSP Symbols and open in a vertical split pane" }
		)

		-- register the commands
		vim.api.nvim_create_user_command("SnipeLspSymbols", symbols.open_symbols_menu, { nargs = 0 })
		vim.api.nvim_create_user_command("SnipeLspCodeActions", code_actions.open_code_actions_menu, { nargs = 0 })
		vim.api.nvim_create_user_command(
			"SnipeLspSymbolsSplit",
			symbols.open_symbols_menu_for_split("split"),
			{ nargs = 0 }
		)
		vim.api.nvim_create_user_command(
			"SnipeLspSymbolsVSplit",
			symbols.open_symbols_menu_for_split("vsplit"),
			{ nargs = 0 }
		)
	end,
}
