require("luarocks.loader")
local bbcode = require("bbcode")

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
        local result = bbcode.htmlify(test[2])
        local success = (result == test[3]) == test[4]
        if success then pass = pass + 1 else fail = fail + 1 end
        local stext = success and "PASS" or "*** FAIL"
        print(string.format("Testing %s\t => %s [Result: '%s']", test[1], stext, tostring(result)))
    end
end

test_htmlify()

print(string.format("\n%s %d tests PASS, %d tests FAIL", fail > 0 and "---" or "+++", pass, fail))
