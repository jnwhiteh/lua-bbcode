require("lpeg")

local v = lpeg.V
local c = lpeg.C
local carg = lpeg.Carg
local p = lpeg.P
local r = lpeg.R
local s = lpeg.S

local locale = lpeg.locale(lpeg)

local tag_alternative_names = {
    -- Alternative name -> Cononical name
    bold = b,
    underline = u,
}

local tags_open = {
    inline = {
        b = [[<span style="font-weight: bold;">]],
        i = [[<span style="font-style: italic;">]],
        u = [[<span style="text-decoration: underline;">]],
        s = [[<span style="text-decoration: line-through;">]],
        code = [[<code>]],
    },
}

local tags_close = {
    inline = {
        b = [[</span>]],
        i = [[</span>]],
        u = [[</span>]],
        s = [[</span>]],
        code = [[</code>]],
    }
}

local tags = setmetatable({}, {__index = function(t, k)
    return tags_open.inline
end})

local function process_tag(pending, is_closing, tag)
    is_closing = is_closing ~= ""
    -- Normalise tag name
    local tag_name = tag:lower()
    tag_name = tag_alternative_names[tag_name] or tag_name
    -- Do nothing to unrecognised tags
    if not tags[tag_name] then
        return tag
    end
    -- Open tags become HTML
    if not is_closing then
        pending[#pending + 1] = tag_name
        return tags_open.inline[tag_name]
    end

    local text = ""

    -- Close any open tags
    repeat
        local ptag = pending[#pending]
        if ptag == nil then
            break
        end
        text = text .. tags_close.inline[tag_name] 
        pending[#pending] = nil
    until ptag == tag_name
    return text
end

grammar = {
    "btag";
    lb = p("["),
    rb = p("]"),
    slash = p("/"),
    char = lpeg.print,
    text = (v"char")^1,

    tag = v"lb" * carg(1) * c(v"slash"^-1) * c((r("az","AZ") - v"rb")^1) * v"rb" / process_tag,

    textortags = v"tag" + v"char",
    message = (v"textortags")^1,
}

local pass = 0
local fail = 0

local htmifyTests = {
    -- Bold
    {"message", "[b]foo[/b]", [[<span style="font-weight: bold;">foo</span>]], true},
    {"message", "[b]foo[/b]", [[]], false},
    -- Italics
    {"message", "[i]foo[/i]", [[<span style="font-style: italic;">foo</span>]], true},
    {"message", "[i]foo[/i]", [[]], false},
    -- Underline
    {"message", "[u]foo[/u]", [[<span style="text-decoration: underline;">foo</span>]], true},
    {"message", "[u]foo[/u]", [[]], false},
    -- Code
    {"message", "[code]foo = 14[/code]", [[<code>foo = 14</code>]], true},
    -- Nesting
    {"message", "[b][i][u]foo[/u][/i][/b]", [[<span style="font-weight: bold;"><span style="font-style: italic;"><span style="text-decoration: underline;">foo</span></span></span>]], true},

    -- Bad nesting
    {"message", "[b][i]foo[/b][/i]", [[<span style="font-weight: bold;"><span style="font-style: italic;">foo</span></span>]], true},
    {"message", "[b][i][u]foo[/i] monkey[/b][/u]", [[<span style="font-weight: bold;"><span style="font-style: italic;"><span style="text-decoration: underline;">foo</span></span> monkey</span>]], true},
    {"message", "[b][u][i]foo[/b][/i] foo [/u]", [[<span style="font-weight: bold;"><span style="text-decoration: underline;"><span style="font-style: italic;">foo</span></span></span> foo ]], true},
}

function test_htmlify()
    print(string.rep("=", 65))
    for i = 1, #htmifyTests, 1 do
        local test = htmifyTests[i]
        grammar[1] = test[1]
        local result = lpeg.Cs(grammar):match(test[2], 1, {})
        local success = (result == test[3]) == test[4]
        if success then pass = pass + 1 else fail = fail + 1 end
        local stext = success and "PASS" or "*** FAIL"
        print(string.format("Testing %s\t => %s [Result: '%s']", test[1], stext, tostring(result)))
    end
end

test_htmlify()

print(string.format("\n*** %d tests PASS, %d tests FAIL", pass, fail))
