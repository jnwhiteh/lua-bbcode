require("luarocks.loader")
local bbcode = require("bbcode")

local pass = 0
local fail = 0

local tests = {
    {"Simple bold", "[b]foo[/b]", [[<span style="font-weight: bold;">foo</span>]]},
    {"Simple italics", "[i]foo[/i]", [[<span style="font-style: italic;">foo</span>]]},
    {"Simple underline", "[u]foo[/u]", [[<span style="text-decoration: underline;">foo</span>]]},
    {"Inline code", "[code]foo = 14[/code]", [[<code>foo = 14</code>]]},
    {"Nesting", "[b][i][u]foo[/u][/i][/b]", [[<span style="font-weight: bold;"><span style="font-style: italic;"><span style="text-decoration: underline;">foo</span></span></span>]]},
    {"Bad nesting 1", "[b][i]foo[/b][/i]", [[<span style="font-weight: bold;"><span style="font-style: italic;">foo</span></span>]]},
    {"Bad nesting 2", "[b][i][u]foo[/i] monkey[/b][/u]", [[<span style="font-weight: bold;"><span style="font-style: italic;"><span style="text-decoration: underline;">foo</span></span> monkey</span>]]},
    {"Bad nesting 3", "[b][u][i]foo[/b][/i] foo [/u]", [[<span style="font-weight: bold;"><span style="text-decoration: underline;"><span style="font-style: italic;">foo</span></span></span> foo ]]},
    {"Simple newlines", "First line\nSecond line\nThird line", "First line<br/>\nSecond line<br/>\nThird line"},
    {"Simple URL", [=[[url=foo]WowProgramming[/url]]=], [[<a href="foo">WowProgramming</a>]]},
    {"Real URL", [=[[url=http://wowprogramming.com]WowProgramming[/url]]=], [[<a href="http://wowprogramming.com">WowProgramming</a>]]},
    {"Quoted URL", [=[[url="http://wowprogramming.com"]WowProgramming[/url]]=], [[<a href="http://wowprogramming.com">WowProgramming</a>]]},
}

for idx, entry in ipairs(tests) do
    test(entry[1], function()
        local result = bbcode.htmlify(entry[2])
        assert_equal(result, entry[3])
    end)
end
