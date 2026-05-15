local api = require("local_code_snipets.ollama")
local M = {}

function M.setup(opts)
	vim.notify("Pinging Ollama...", vim.log.levels.INFO)

	-- Send a test prompt directly to the engine
	local test_prompt = "Write a one-line C++ print statement."

	api.request_completion(test_prompt, function(raw_ai_text)
		-- This callback runs when the data successfully returns
		vim.notify("Ollama Replied:\n" .. raw_ai_text, vim.log.levels.INFO)
	end)
end

return M
