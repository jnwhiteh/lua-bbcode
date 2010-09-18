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

local function id(str)
    return str
end

local tag_alternative_names = {
    -- Alternative name -> Cononical name
    bold = b,
    underline = u,
    italics = i,
}

local tags_open = {
    b = [[<span style="font-weight: bold;">]],
    i = [[<span style="font-style: italic;">]],
    u = [[<span style="text-decoration: underline;">]],
    s = [[<span style="text-decoration: line-through;">]],
    code = [[<code>]],
    url = {
        format = [[<a href="%s">]],
        param_func = id,
    },
    email = {
        format = [[<a href="mailto:%s">]],
        param_func = id,
    },
    list = function(tag, param)
        if param then
            local start = tonumber(param) or 1
            return string.format([[<ol start="%d">]], start), "ol"     
        else
            return string.format([[<ul>]]), "ul"
        end
    end,
}

local tags_close = {
    b = [[</span>]],
    i = [[</span>]],
    u = [[</span>]],
    s = [[</span>]],
    code = [[</code>]],
    url = [[</a>]],
    email = [[</a>]],
    ol = [[</ol>]],
    ul = [[</ul>]],
}

local tags = setmetatable({}, {__index = function(t, k)
    return tags_open[k]
end})

local function process_tag(pending, is_closing, tag)
    is_closing = is_closing ~= ""

    -- Handle advanced tags, with tag=param
    local param
    if type(tag) == "table" then
        tag, param = unpack(tag)
    end

    -- Normalise tag name
    local tag_name = tag:lower()
    tag_name = tag_alternative_names[tag_name] or tag_name

    -- Do nothing to unrecognised tags
    if not tags[tag_name] then
        return tag
    end
    -- Open tags become HTML
    if not is_closing then
        local result, new_tag

        -- Handle advanced tags, with tag=param
        local open = tags_open[tag_name]
        if type(open) == "table" then
            result = string.format(open.format, open.param_func(param))
        elseif type(open) == "function" then 
            result, new_tag = open(tag, param)
        else
            result = tags_open[tag_name]
        end
            
        pending[#pending + 1] = new_tag and {old = ta_name, new = new_tag} or tag_name
        return result
    end

    local text = ""

    -- Close any open tags
    repeat
        local ptag = pending[#pending]
        if ptag == nil then
            break
        end

        if type(ptag) == "table" then
            text = text .. tags_close[ptag.new]
            ptag = ptag.old
        else
            text = text .. tags_close[ptag]
        end

        pending[#pending] = nil
    until ptag == tag_name
    return text
end

local function process_image_tag(tag_name, pending, src)
    return string.format([[<img src="%s"/>]], src)
end

local function process_item_tag(pending, tag_name, content)
    return string.format([[<li>%s</li>]], content)
end

bbcode.grammar = {
    "message";
    lb = p("["),
    rb = p("]"),
    slash = p("/"),
    char = lpeg.print,
    digit = lpeg.digit,
    space = p(" "),
    text = (v"char")^1,
    newline = p("\n") / function(tag) return "<br/>\n" end,
    alpha = r("az", "AZ"),
    
    squote = p("'"),
    dquote = p("\""),

    noclose = v"char" - v"rb",

    dquotparam = v"dquote" * c((v"noclose" - v"squote" - v"dquote")^1) * v"dquote",
    squotparam = v"squote" * c((v"noclose" - v"squote" - v"dquote")^1) * v"squote",

    noquoparam = c((v"noclose" - v"dquote" - v"squote")^1),
    param = v"dquotparam" + v"squotparam" + v"noquoparam",

    id_simple = (v"alpha" - v"rb")^1,
    id_complex = (c(v"alpha"^1) * p"=" * v"param"),

    image_tag = v"lb" * carg(1) * c(p"img" + p"IMG") * v"rb" * c((v"char" - s"[]")^1) * v"lb" * (p"/img" + p"/IMG") * v"rb" / process_image_tag, 

    item_tag = v"lb" * carg(1) * c(p"*") * v"rb" * c((v"char" - s"[]")^1) / process_item_tag,

    tag = v"lb" * carg(1) * c(v"slash"^-1) * (lpeg.Ct(v"id_complex") + c(v"id_simple")) * v"rb" / process_tag,

    textortags = v"item_tag" + v"image_tag" + v"tag" + v"char" + v"newline",
    message = (v"textortags")^1,
}

function bbcode.htmlify(str)
    return lpeg.Cs(bbcode.grammar):match(str, 1, {})
end

package.loaded[bbcode._NAME] = bbcode
return bbcode
