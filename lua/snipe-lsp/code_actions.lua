local add_close_keymap = require("snipe-lsp.common").add_close_keymap
local Menu = require("snipe.menu")
local util = require("vim.lsp.util")
local api = vim.api
local ms = require("vim.lsp.protocol").Methods

local M = {}

local function get_code_actions()
	local bufnr = vim.api.nvim_get_current_buf()
	local win = vim.api.nvim_get_current_win()

	local params = vim.lsp.util.make_range_params(win)
	local diagnostics = vim.diagnostic.get(bufnr)
	params.context = {
		diagnostics = vim.tbl_map(function(d)
			return d.user_data.lsp
		end, diagnostics),
	}

	local actions = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
	if not actions or vim.tbl_isempty(actions) then
		vim.notify("No actions found", vim.log.levels.INFO)
		return {}
	end
	local items = {}
	for client_id, result in ipairs(actions) do
		local client = vim.lsp.get_client_by_id(client_id)
		if client == nil then
			-- using goto feels wrong, anyway...
			goto continue
		end
		for _, action in ipairs(result.result or {}) do
			local edits = {}
			if action.edit and action.edit.documentChanges then
				for _, change in ipairs(action.edit.documentChanges) do
					if change.edits then
						vim.list_extend(edits, change.edits)
					end
				end
			end
			table.insert(items, {
				title = action.title,
				kind = action.kind,
				edits = edits,
				encoding = client.offset_encoding,
				bufnr = bufnr,
			})
		end
		::continue::
	end
	return items
end

local function format_code_action_for_display(code_action)
	return string.format("%s %s", "*", code_action.title)
end

M.open_code_actions_menu = function()
	local actions = get_code_actions()
	if vim.tbl_isempty(actions) then
		return
	end

	local menu = Menu:new({ position = "cursor", open_win_override = { title = "Code Actions" } })
	add_close_keymap(menu)

	menu:open(actions, function(m, i)
		local to_apply = actions[i]
		if to_apply.edits == nil then
			-- TODO: apply anyway
			m:close()
			return
		end
		vim.lsp.util.apply_text_edits(to_apply.edits, to_apply.bufnr, to_apply.encoding)
		m:close()
	end, format_code_action_for_display)
end

return M
