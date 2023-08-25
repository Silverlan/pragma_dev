include("/util/ai/text_to_speech.lua")
include("/util/locale/localization_helper.lua")

local tutorial = "intro"
local lan = "fr"
local relPath = "pfm/tutorials/" .. tutorial .. "/"
local addonPath = "addons/vo_" .. lan .. "/sounds/" .. relPath
local fullAddonPath = "addons/pfm_tutorials/" .. addonPath

local apiKey = "*********ELEVEN LABS API KEY*********"
local voice = "Bella"
local modelId = "eleven_multilingual_v2"

local prefix = "pfm_tut_" .. tutorial .. "_"
local texts = util.locale.get_language_texts(lan)
local targetTexts = {}
local idToText = {}
for cat, texts in pairs(texts) do
	for id, text in pairs(texts) do
		if id:sub(0, #prefix) == prefix then
			table.insert(targetTexts, {
				id = id:sub(#prefix + 1),
				text = text,
			})
		end
		idToText[id] = text
	end
end

local processList = {}
file.create_path(fullAddonPath)
for _, textInfo in ipairs(targetTexts) do
	if textInfo.id ~= "layout_save_preference" then
		local text = textInfo.text
		local audioFile = fullAddonPath .. textInfo.id .. ".mp3"

		text = text:replace("\n\n", "\n...\n")
		text = text:replace(" > ", ", ")

		local pos = text:find("{")
		while pos ~= nil do
			local posEnd = text:find("}", pos)
			local sub = text:sub(pos + 1, posEnd - 1)
			if #sub == nil then
				debug.print("Missing: ", sub)
				return
			end
			if idToText[sub] ~= nil then
				local insertText = idToText[sub]
				text = text:sub(0, pos - 1) .. insertText .. text:sub(posEnd + 1)
				pos = text:find("{", pos + #insertText)
			else
				pos = text:find("{", posEnd)
			end
		end
		if file.exists(audioFile) == false then
			table.insert(processList, {
				id = textInfo.id,
				text = text,
				audioFile = audioFile,
			})
		end
	end
end

local function process_next()
	local t = processList[1]
	if t == nil then
		print("Complete!")
		return
	end
	print("Processing '" .. t.id .. "'...")
	table.remove(processList, 1)
	util.ai.text_to_speech(apiKey, voice, t.text, t.audioFile, function(res)
		print("Result: ", res)
		if res then
			process_next()
		else
			print("FAILED: ", t.id)
		end
	end, modelId)
end
process_next()
