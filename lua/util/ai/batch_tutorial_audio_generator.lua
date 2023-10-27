--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/ai/text_to_speech.lua")
include("/util/locale/localization_helper.lua")
include("/util/locale/localization_cache.lua")

console.register_variable(
	"util_ai_elevenlabs_api_key",
	udm.TYPE_STRING,
	"",
	bit.bor(console.FLAG_BIT_ARCHIVE, console.FLAG_BIT_PASSWORD),
	"API key for ElevenLabs access."
)

local function get_full_addon_path(tutorial, lan)
	local relPath = "pfm/tutorials/" .. tutorial .. "/"
	local addonPath = "addons/vo_" .. lan .. "/sounds/" .. relPath
	return "addons/pfm_tutorials/" .. addonPath
end

local function get_audio_file_path(tutorial, lan, id)
	local relPath = "pfm/tutorials/" .. tutorial .. "/"
	local addonPath = "addons/vo_" .. lan .. "/sounds/" .. relPath
	local fullAddonPath = get_full_addon_path(tutorial, lan)
	local audioFile = fullAddonPath .. id .. ".mp3"
	return audioFile
end

local TutorialAudioGenerator = util.register_class("util.ai.TutorialAudioGenerator")
function TutorialAudioGenerator:__init(tutorial, lan)
	self.m_processList = {}
	self.m_tutorial = tutorial
	self.m_localeCache = util.locale.LocaleCache(lan)

	file.create_path(get_full_addon_path(tutorial, lan))
end

function TutorialAudioGenerator:Clear()
	self.m_processList = {}
	self.m_cancelled = true
end

function TutorialAudioGenerator:Add(id)
	local audioFile = get_audio_file_path(self.m_tutorial, self.m_localeCache:GetLanguage(), id)

	local text = self.m_localeCache:GetText(id)
	text = text:replace("\n\n", "\n...\n")
	text = text:replace(" > ", ", ")
	text = text:replace(" > ", ", ")
	text = text:replace("「", '"')
	text = text:replace("」", '"')

	if file.exists(audioFile) == false then
		table.insert(self.m_processList, {
			id = id,
			text = text,
			audioFile = audioFile,
		})
	end

	self:Process()
end

function TutorialAudioGenerator:Process()
	if self.m_running or #self.m_processList == 0 then
		return
	end
	self.m_running = true
	local t = self.m_processList[1]
	print("Processing '" .. t.id .. "'...")
	table.remove(self.m_processList, 1)

	local apiKey = console.get_convar_string("util_ai_elevenlabs_api_key")
	local voice = "Bella"
	local modelId = "eleven_multilingual_v2"
	util.ai.text_to_speech(apiKey, voice, t.text, t.audioFile, function(res)
		print("Result: ", res)
		if res then
			self.m_running = false
			self:Process()
		else
			print("FAILED: ", t.id)
		end
	end, modelId)
end
