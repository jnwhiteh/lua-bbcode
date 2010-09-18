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
    {"Real URL", 
        [=[[url=http://wowprogramming.com]WowProgramming[/url]]=],
        [[<a href="http://wowprogramming.com">WowProgramming</a>]]
    },
    {"Double quoted URL", 
        [=[[url="http://wowprogramming.com"]WowProgramming[/url]]=],
        [[<a href="http://wowprogramming.com">WowProgramming</a>]]
    },
    {"Single quoted URL", 
        [=[[url='http://wowprogramming.com']WowProgramming[/url]]=],
        [[<a href="http://wowprogramming.com">WowProgramming</a>]]
    },
    {"Badly single quoted URL", [=[[url=foo'bar]]=], [=[[url=foo'bar]]=]},
    {"Badly double quoted URL", [=[[url=foo"bar]]=], [=[[url=foo"bar]]=]},
    {"Unquoted email", [=[[email=me@jnwhiteh.net]Email me![/email]]=], [=[<a href="mailto:me@jnwhiteh.net">Email me!</a>]=]},
    {"Single quoted email", [=[[email='me@jnwhiteh.net']Email me![/email]]=], [=[<a href="mailto:me@jnwhiteh.net">Email me!</a>]=]},
    {"Double quoted email", [=[[email="me@jnwhiteh.net"]Email me![/email]]=], [=[<a href="mailto:me@jnwhiteh.net">Email me!</a>]=]},
    {"Image", [=[[img]foo.png[/img]]=], [=[<img src="foo.png"/>]=]},
    {"Ordered list", [=[[list=1][*]Alpha[*]Beta[*]Gamma[/list]]=], [=[<ol start="1"><li>Alpha</li><li>Beta</li><li>Gamma</li></ol>]=]},
    {"Ordered list with start", [=[[list=3][*]Delta[*]Epsilon[/list]]=], [=[<ol start="3"><li>Delta</li><li>Epsilon</li></ol>]=]},
    {"Unordered list", [=[[list][*]Monkey[*]Banana[*]Peanut[/list]]=], [=[<ul><li>Monkey</li><li>Banana</li><li>Peanut</li></ul>]=]},
    {"Nested unordered list", [=[[list][*]Alpha[*]Beta[list][*]Gamma[*]Delta[/list][/list]]=], [=[<ul><li>Alpha</li><li>Beta</li><ul><li>Gamma</li><li>Delta</li></ul></ul>]=]},
    {"Nested ordered list", [=[[list=1][*]Alpha[*]Beta[list=3][*]Gamma[*]Delta[/list][/list]]=], [=[<ol start="1"><li>Alpha</li><li>Beta</li><ol start="3"><li>Gamma</li><li>Delta</li></ol></ol>]=]},
}

for idx, entry in ipairs(tests) do
    test(entry[1], function()
        local result = bbcode.htmlify(entry[2])
        assert_equal(result, entry[3])
    end)
end
