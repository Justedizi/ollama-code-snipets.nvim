local M = {}

local OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
local MODEL_NAME = "qwen2.5:14b"

function M.request_completion(prompt_text, on_success_callback)
	-- 1. Build the exact JSON structure Ollama expects
	local request_payload = vim.fn.json_encode({
		model = MODEL_NAME,
		prompt = prompt_text,
		stream = false,
		options = {
			num_predict = 128, -- Keep it short for fast ghost text
			temperature = 0.1, -- Low temperature prevents hallucination
			top_p = 0.9,
		},
	})

	-- 2. Spawn the asynchronous curl process
	vim.system({
		"curl",
		"-s",
		"-X",
		"POST",
		OLLAMA_URL,
		"-H",
		"Content-Type: application/json",
		"-d",
		request_payload,
	}, { text = true }, function(response_object)
		-- -> WE ARE NOW IN A BACKGROUND WORKER THREAD <-

		-- Abort immediately if the curl command failed (e.g., Ollama is offline)
		if response_object.code ~= 0 or not response_object.stdout then
			return
		end

		-- 3. You CANNOT interact with Neovim APIs from a background thread.
		-- We must schedule the rest of the logic to execute on the main thread.
		vim.schedule(function()
			-- -> WE ARE BACK ON THE MAIN NEOVIM THREAD <-

			-- Safely decode the JSON using pcall (Protected Call)
			-- If Ollama returns a corrupted response, pcall prevents Neovim from crashing
			local parse_success, decoded_data = pcall(vim.fn.json_decode, response_object.stdout)

			-- If the parse was successful and we actually got a response string
			if parse_success and decoded_data.response then
				-- Execute the callback function, handing off the raw text
				on_success_callback(decoded_data.response)
			end
		end)
	end)
end

return M
