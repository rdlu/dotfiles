-- pandoc filter for the PDFs built from docs/*.md (mise run docs-pdf).
--
-- The pages carry Hugo front matter for the site (title, linkTitle, weight).
-- Each page also opens with its own `# H1`, so a front matter title would
-- print twice: drop those keys. The handbook passes its title with -V, which
-- this filter doesn't touch.
--
-- GitHub-style alerts (`> [!NOTE] Title`), which Hextra renders as callouts,
-- come out of pandoc's markdown reader as a blockquote whose first word is
-- "[!NOTE]". Turn that marker into a bold "Note:" lead-in.

local HUGO_KEYS = { "title", "linkTitle", "weight" }

function Meta(meta)
  for _, key in ipairs(HUGO_KEYS) do
    meta[key] = nil
  end
  return meta
end

local LABELS = {
  NOTE = "Note",
  TIP = "Tip",
  IMPORTANT = "Important",
  WARNING = "Warning",
  CAUTION = "Caution",
}

function BlockQuote(quote)
  local first = quote.content[1]
  if not first or first.t ~= "Para" or #first.content == 0 then
    return nil
  end
  local marker = first.content[1]
  if marker.t ~= "Str" then
    return nil
  end
  local kind = marker.text:match("^%[!(%u+)%]$")
  local label = kind and LABELS[kind]
  if not label then
    return nil
  end

  -- What follows the marker on its line is the alert's title; the rest of the
  -- paragraph (after the first line break) is its body.
  local title, body = pandoc.List(), pandoc.List()
  local in_body = false
  for i = 2, #first.content do
    local el = first.content[i]
    if not in_body and (el.t == "SoftBreak" or el.t == "LineBreak") then
      in_body = true
    elseif in_body then
      body:insert(el)
    elseif not (#title == 0 and el.t == "Space") then
      title:insert(el)
    end
  end

  local lead = pandoc.List({ pandoc.Strong({ pandoc.Str(label .. ":") }) })
  if #title > 0 then
    lead:insert(pandoc.Space())
    lead:insert(pandoc.Strong(title))
  end
  local blocks = pandoc.List({ pandoc.Para(lead) })
  if #body > 0 then
    blocks:insert(pandoc.Para(body))
  end
  blocks:extend({ table.unpack(quote.content, 2) })
  return pandoc.BlockQuote(blocks)
end
