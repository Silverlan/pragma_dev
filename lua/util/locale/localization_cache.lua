--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

util.locale = util.locale or {}

local LocaleCache = util.register_class("util.locale.LocaleCache")
function LocaleCache:__init(lan)
	self.m_language = lan

	local texts = util.locale.get_language_texts(lan)
	local idToText = {}
	local idToCat = {}
	for cat, texts in pairs(texts) do
		for id, text in pairs(texts) do
			idToText[id] = text
			idToCat[id] = cat
		end
	end
	self.m_idToText = idToText
	self.m_idToCat = idToCat
end
function LocaleCache:GetLanguage()
	return self.m_language
end
function LocaleCache:GetRawText(id)
	return self.m_idToText[id]
end
function LocaleCache:GetCategory(id)
	return self.m_idToCat[id]
end
function LocaleCache:GetText(id)
	local text = self:GetRawText(id)
	if text == nil then
		return
	end
	local pos = text:find("{")
	while pos ~= nil do
		local posEnd = text:find("}", pos)
		local sub = text:sub(pos + 1, posEnd - 1)
		if #sub == nil then
			debug.print("Missing: ", sub)
			return
		end
		if self.m_idToText[sub] ~= nil then
			local insertText = self.m_idToText[sub]
			text = text:sub(0, pos - 1) .. insertText .. text:sub(posEnd + 1)
			pos = text:find("{", pos + #insertText)
		else
			pos = text:find("{", posEnd)
		end
	end
	return text
end
