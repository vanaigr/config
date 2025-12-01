local template = [====[
# topic: ?

- file: {{filename}}
{{optional_headers}}
<C-g> sends. <C-c> cancels

---
{{user_prefix}}
]====]

local m = require('mapping')

local chat_system_prompt = 'Answer as concisely as possible'

require("gp").setup{
    openai_api_key = _G.my_config.openai_api_key,
    chat_template = template,
    chat_conceal_model_params = false,

 	chat_shortcut_respond = { modes = {}, shortcut = "" },
 	chat_shortcut_delete = { modes = {}, shortcut = "" },
 	chat_shortcut_stop = { modes = {}, shortcut = "" },
 	chat_shortcut_new = { modes = {}, shortcut = "" },

    agents = {
		{
			provider = "openai",
			name = "ChatGPT4o-mini",
			chat = true,
			command = false,
			model = { model = "gpt-4o-mini", temperature = 1, top_p = 1 },
			system_prompt = chat_system_prompt,
		},
		{
			name = "ChatGPT4o",
			chat = true,
			command = false,
			model = { model = "gpt-4o", temperature = 1, top_p = 1 },
			system_prompt = chat_system_prompt,
		},
    }
}

vim.api.nvim_create_autocmd("User", {
    pattern = "GpChatPrepare",
    callback = function(event)
        local opts = { buffer = event.data.buf }
        m.n('<leader>i', function() vim.cmd('GpChatRespond') end, opts)
        m.n('<a-c>', function() vim.cmd('GpChatStop') end, opts)
    end,
})

m.n('<leader>c', function() vim.cmd('GpChatNew tabnew') end)
