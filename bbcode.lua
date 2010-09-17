require("lpeg")

local bbcode = {}
bbcode._NAME = "bbcode"
bbcode._M = bbcode
bbcode._PACKAGE = "bbcode"

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

bbcode.grammar = {
    "message";
    lb = p("["),
    rb = p("]"),
    slash = p("/"),
    char = lpeg.print,
    text = (v"char")^1,

    tag = v"lb" * carg(1) * c(v"slash"^-1) * c((r("az","AZ") - v"rb")^1) * v"rb" / process_tag,

    textortags = v"tag" + v"char",
    message = (v"textortags")^1,
}

function bbcode.htmlify(str)
    return lpeg.Cs(bbcode.grammar):match(str, 1, {})
end

package.loaded[bbcode._NAME] = bbcode
return bbcode
