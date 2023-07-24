--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

require("modules/json")

util.ai = util.ai or {}
local ElevenLabs = util.register_class("util.ai.ElevenLabs")
function ElevenLabs:__init(apiKey)
	self.m_apiKey = apiKey
end
function ElevenLabs:Clear()
	if self.m_request ~= nil then
		self.m_request:Cancel()
		self.m_request = nil
	end
	util.remove(self.m_callback)
end
function ElevenLabs:GetVoices(callback)
	local requestData = curl.RequestData()
	requestData.headers = {
		"xi-api-key: " .. self.m_apiKey,
	}
	local request = curl.request("https://api.elevenlabs.io/v1/voices", requestData)
	request:Start()
	self.m_request = request

	self.m_callback = game.add_callback("Think", function()
		if request:IsComplete() then
			util.remove(self.m_callback)
			if request:IsSuccessful() then
				local result = request:GetResult()
				callback(true, json.parse(result:ReadString()))
			else
				callback(false)
			end
			return
		end
	end)
end
function ElevenLabs:GetVoiceId(voiceName, callback)
	self:GetVoices(function(res, data)
		if res then
			for _, voiceData in ipairs(data.voices) do
				if voiceData.name == voiceName then
					callback(true, voiceData.voice_id)
					return
				end
			end
			callback(false)
		else
			callback(false)
		end
	end)
end
function ElevenLabs:TextToSpeech(text, voiceId, callback)
	local requestData = curl.RequestData()
	requestData.headers = {
		"accept: audio/mpeg",
		"xi-api-key: " .. self.m_apiKey,
		"Content-Type: application/json",
	}
	requestData.postData = json.stringify({
		["text"] = text,
		["model_id"] = "eleven_monolingual_v1",
		["voice_settings"] = {
			["stability"] = 0.5,
			["similarity_boost"] = 0.75,
		},
	})

	local request = curl.request("https://api.elevenlabs.io/v1/text-to-speech/" .. voiceId, requestData)
	request:Start()
	self.m_request = request

	self.m_callback = game.add_callback("Think", function()
		if request:IsComplete() then
			util.remove(self.m_callback)
			if request:IsSuccessful() then
				local result = request:GetResult()
				result:Seek(0)
				callback(true, result)
			else
				callback(false)
			end
			return
		end
	end)
end
function ElevenLabs:Download(id, callback)
	local requestData = curl.RequestData()
	requestData.headers = {
		"accept: */*",
		"xi-api-key: " .. self.m_apiKey,
		"Content-Type: application/json",
	}
	requestData.postData = json.stringify({
		["history_item_ids"] = { id },
	})
	local request = curl.request("https://api.elevenlabs.io/v1/history/download", requestData)
	request:Start()
	self.m_request = request

	self.m_callback = game.add_callback("Think", function()
		if request:IsComplete() then
			util.remove(self.m_callback)
			if request:IsSuccessful() then
				local result = request:GetResult()
				result:Seek(0)
				callback(true, result)
			else
				callback(false)
			end
			return
		end
	end)
end

function util.ai.text_to_speech(apiKey, voice, text, fileName, callback)
	local el = util.ai.ElevenLabs(apiKey)
	el:GetVoiceId(voice, function(res, id)
		if res then
			el:TextToSpeech(text, id, function(res, data)
				if res then
					local f = file.open(fileName, bit.bor(file.OPEN_MODE_WRITE, file.OPEN_MODE_BINARY))
					if f ~= nil then
						f:Write(data)
						f:Close()
					end
				elseif callback ~= nil then
					callback(false)
				end
			end)
		elseif callback ~= nil then
			callback(false)
		end
	end)
end
