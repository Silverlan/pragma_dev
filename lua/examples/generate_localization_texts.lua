include("/util/locale/localization_helper.lua")

local apiKey = "*********CHAT GPT API KEY*********"
local targetLanguage = "fr"

-- Note that running this function will use up ChatGPT tokens, which come with a fee. Check ChatGPT Pricing for more information.
util.locale.generate_missing_localizations(apiKey, targetLanguage)
