-- The site's HTML under theme none (L010). Callouts: Without Bootstrap, Quarto writes a callout as a bare blockquote: no box, no
-- colour, and collapse="true" folds nothing. Before Quarto sees them, this turns each callout into a box the site's
-- CSS styles (assets/styles/project.css, "Callouts"): collapse="true" a closed <details>, collapse="false" an open
-- one, no collapse a plain box. The title is the callout's first heading, its title attribute, or the kind's name.
-- And a paragraph that is only <br> spacers (the guides' way of making air) goes: the CSS gives the air.
-- Only for HTML; the PDFs of the guides are typeset by tools/pdf_guides.py with Quarto's own LaTeX callouts.

local NAMES = { note = "Nota", tip = "Consejo", caution = "Precaución", warning = "Atención", important = "Importante" }

local function raw(s) return pandoc.RawBlock("html", s) end

function Div(el)
  if not quarto.doc.is_format("html") then return nil end
  local kind
  for _, c in ipairs(el.classes) do kind = kind or c:match("^callout%-(%a+)$") end
  if not kind then return nil end

  local body = el.content
  local title = el.attributes["title"] and pandoc.read(el.attributes["title"], "markdown").blocks[1].content or nil
  if not title and body[1] and body[1].t == "Header" then
    title = body[1].content
    body = pandoc.List({ table.unpack(body, 2) })
  end
  title = title or pandoc.Inlines({ pandoc.Str(NAMES[kind] or "Nota") })

  local collapse = el.attributes["collapse"]
  local cls = "callout callout-" .. kind
  local out = {}
  if collapse == "true" or collapse == "false" then
    table.insert(out, raw('<details class="' .. cls .. '"' .. (collapse == "false" and " open" or "") .. '><summary class="callout-title"><span>'))
    table.insert(out, pandoc.Plain(title))
    table.insert(out, raw('</span></summary><div class="callout-body">'))
  else
    table.insert(out, raw('<div class="' .. cls .. '"><div class="callout-title"><span>'))
    table.insert(out, pandoc.Plain(title))
    table.insert(out, raw('</span></div><div class="callout-body">'))
  end
  for _, b in ipairs(body) do table.insert(out, b) end
  table.insert(out, raw((collapse == "true" or collapse == "false") and "</div></details>" or "</div></div>"))
  return out
end

function Para(el)
  if not quarto.doc.is_format("html") then return nil end
  for _, x in ipairs(el.content) do
    local spacer = x.t == "Space" or x.t == "SoftBreak" or x.t == "LineBreak"
      or (x.t == "RawInline" and x.format == "html" and x.text:match("^<br%s*/?>$"))
    if not spacer then return nil end
  end
  return {}
end
