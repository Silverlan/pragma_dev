--[[
    Copyright (C) 2023 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("query.lua")

util.ai = util.ai or {}
local BatchTranslator = util.register_class("util.ai.BatchTranslator")
function BatchTranslator:__init(modelId)
	self.m_modelId = modelId
	self.m_queries = {}
end

function BatchTranslator:Clear()
	self.m_queries = {}
	self.m_cancelled = true
end

function BatchTranslator:Process()
	if self.m_running or #self.m_queries == 0 then
		return
	end
	local queryData = self.m_queries[1]
	table.remove(self.m_queries, 1)
	self.m_running = true
	print("Processing next item...")
	util.ai.translate(queryData.englishText, queryData.targetLanguage, function(res, data)
		if res then
			if self.m_cancelled then
				print("Batch translation has been cancelled!")
				return
			end
			print(
				"Adding localization for '" .. queryData.id .. "' for language '" .. queryData.targetLanguage .. "'..."
			)
			data = string.replace(data, "\n", "\\n")
			if queryData.targetLanguage == "jp" then
				-- Replace quotes ("") with 「」
				data = data:gsub('"(.-)"', function(w)
					return "「" .. w .. "」"
				end)
			end
			locale.localize(queryData.id, queryData.targetLanguage, queryData.category, data)
			self.m_running = false
			self:Process()
		else
			console.print_warning("Localization failed...")
		end
	end, self.m_modelId)
end

function BatchTranslator:Add(cat, id, englishText, targetLanguage)
	table.insert(self.m_queries, {
		category = cat,
		id = id,
		englishText = englishText,
		targetLanguage = targetLanguage,
	})
	self:Process()
end
