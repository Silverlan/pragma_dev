include("/util/locale/localization_helper.lua")

local apiKey = "*********CHAT GPT API KEY*********"
local targetLanguage = "fr"

util.locale.generate_missing_localizations(apiKey, targetLanguage)
