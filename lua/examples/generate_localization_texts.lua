include("/util/locale/localization_helper.lua")

local apiKey = "*********CHAT GPT API KEY*********"
local targetLanguages = {
	"de",
	"jp",
	"es",
	"fr",
	"zh-cn",
	"it",
}

-- Note that running this function will use up ChatGPT tokens, which come with a fee. Check ChatGPT Pricing for more information.
util.locale.generate_missing_localizations(apiKey, targetLanguages, "gpt-3.5-turbo")
