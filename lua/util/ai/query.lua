--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

require("modules/json")

util.ai = util.ai or {}
local ChatGPT = util.register_class("util.ai.ChatGPT")
function ChatGPT:__init(apiKey)
	self.m_apiKey = apiKey
end
function ChatGPT:Clear()
	if self.m_request ~= nil then
		self.m_request:Cancel()
		self.m_request = nil
	end
	util.remove(self.m_callback)
end
function ChatGPT:Query(query, callback)
	local requestData = curl.RequestData()
	requestData.headers = {
		"Content-Type: application/json",
		"Authorization: Bearer " .. self.m_apiKey,
	}

	requestData.postData = json.stringify({
		["model"] = "gpt-3.5-turbo",
		["temperature"] = 0.7,
		["messages"] = {
			{
				["role"] = "user",
				["content"] = query,
			},
		},
	})

	local request = curl.request("https://api.openai.com/v1/chat/completions", requestData)
	request:Start()
	self.m_request = request

	self.m_callback = game.add_callback("Think", function()
		if request:IsComplete() then
			util.remove(self.m_callback)
			if request:IsSuccessful() then
				local result = request:GetResult()
				result = json.parse(result:ReadString())
				callback(true, result)
			else
				callback(false, request:GetResultMessage())
			end
			return
		end
	end)
end

function util.ai.query(apiKey, query, callback)
	local el = util.ai.ChatGPT(apiKey)

	local function retry()
		local t = 30.0
		print("Attempting again in " .. t .. " seconds...")
		time.create_simple_timer(t, function()
			util.ai.query(apiKey, query, callback)
		end)
		el:Clear()
		el = nil
	end

	el:Query(query, function(res, data)
		if res then
			if data.error ~= nil then
				console.print_warning("ChatGPT Error: " .. data.error.message .. " (" .. data.error.type .. ")")
				retry()
			else
				if #data.choices == 0 then
					callback(false)
				else
					callback(true, data.choices[1].message.content)
				end
			end
		elseif callback ~= nil then
			console.print_warning("Unknown error: ", data)
			retry()
		end
	end)
end

function util.ai.translate(apiKey, text, language, callback)
	local query = 'Translate the following to the language "'
		.. language
		.. '" for use in a 3D modelling/animation software UI. Only provide the translation as a result. Do not translate portions in curly brackets:\n'
		.. text
	return util.ai.query(apiKey, query, callback)
end
