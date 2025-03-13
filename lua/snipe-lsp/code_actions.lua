local add_close_keymap = require("snipe-lsp.common").add_close_keymap
local Menu = require("snipe.menu")
local util = require("vim.lsp.util")
local api = vim.api
local ms = require("vim.lsp.protocol").Methods

local M = {}

local function get_code_actions()
	local bufnr = api.nvim_get_current_buf()
	local win = api.nvim_get_current_win()
	local clients = vim.lsp.get_clients({ bufnr = bufnr, method = ms.textDocument_codeAction })
	local remaining = #clients
	if remaining == 0 then
		if next(vim.lsp.get_clients({ bufnr = bufnr })) then
			vim.notify(vim.lsp._unsupported_method(ms.textDocument_codeAction), vim.log.levels.WARN)
		end
		return {}
	end

	local items = {}

	for _, client in ipairs(clients) do
		---@type lsp.CodeActionParams
		local params = util.make_range_params(win, client.offset_encoding)

		local ns_push = vim.lsp.diagnostic.get_namespace(client.id, false)
		local ns_pull = vim.lsp.diagnostic.get_namespace(client.id, true)
		local diagnostics = {}
		local lnum = api.nvim_win_get_cursor(0)[1] - 1
		vim.list_extend(diagnostics, vim.diagnostic.get(bufnr, { namespace = ns_pull, lnum = lnum }))
		vim.list_extend(diagnostics, vim.diagnostic.get(bufnr, { namespace = ns_push, lnum = lnum }))
		params.context = {
			---@diagnostic disable-next-line: no-unknown
			diagnostics = vim.tbl_map(function(d)
				return d.user_data.lsp
			end, diagnostics),
		}

		local response = client.request_sync(ms.textDocument_codeAction, params, 1000, bufnr)
		if response ~= nil and response.result ~= nil then
			for _, item in ipairs(response.result) do
				local edits = {}
				if item.edit and item.edit.documentChanges then
					for _, change in ipairs(item.edit.documentChanges) do
						if change.edits then
							vim.list_extend(edits, change.edits)
						end
					end
				end
				table.insert(items, {
					title = item.title,
					kind = item.kind,
					edits = edits,
					encoding = client.offset_encoding,
					bufnr = bufnr,
				})
			end
		end
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
		local to_apply = actions[i] -- the action that was queried before
		if to_apply.edits == nil then
			-- TODO: apply anyway?
			m:close()
			return
		end
		vim.lsp.util.apply_text_edits(to_apply.edits, to_apply.bufnr, to_apply.encoding)
		m:close()
	end, format_code_action_for_display)
end

return M
