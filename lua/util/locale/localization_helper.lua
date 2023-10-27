--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/util/ai/batch_translator.lua")

util.locale = util.locale or {}

function util.locale.get_language_texts(lan)
	local tTextFiles = file.find("scripts/localization/" .. lan .. "/texts/*.txt")
	local catTexts = {}
	for _, f in ipairs(tTextFiles) do
		local texts = locale.parse(f, lan)
		local catName = file.remove_file_extension(file.get_file_name(f))
		catTexts[catName] = texts
	end
	return catTexts
end

function util.locale.find_missing_localizations(targetLanguage)
	local en = util.locale.get_language_texts("en")

	local tgt = util.locale.get_language_texts(targetLanguage)
	local result = {}
	for cat, texts in pairs(en) do
		local missingIds = {}
		local catTgt = tgt[cat]
		if catTgt ~= nil then
			for id, text in pairs(texts) do
				if catTgt[id] == nil then
					table.insert(missingIds, id)
				end
			end
		else
			for id, text in pairs(texts) do
				table.insert(missingIds, id)
			end
		end
		if not table.is_empty(missingIds) then
			result[cat] = missingIds
		end
	end
	return result
end

function util.locale.generate_missing_localizations(targetLanguages, modelId)
	local curLan = locale.get_language()
	if curLan ~= "en" then
		error('Current language must be set to "en", but is "' .. curLan .. '"!')
		return
	end
	local batchTranslator = util.ai.BatchTranslator(modelId)
	for _, targetLanguage in ipairs(targetLanguages) do
		local numItems = 0
		local missingLocs = util.locale.find_missing_localizations(targetLanguage)
		for cat, missingIds in pairs(missingLocs) do
			for _, id in ipairs(missingIds) do
				local englishText = locale.get_raw_text(id)
				if englishText ~= nil then
					batchTranslator:Add(cat, id, englishText, targetLanguage)
					numItems = numItems + 1
				end
			end
		end
		print(numItems .. " items added for language '" .. targetLanguage .. "!")
	end
end
