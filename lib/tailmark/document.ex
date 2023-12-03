defmodule Tailmark.Document do
  defstruct [:frontmatter, :sourcepos, :ref, :parent, children: [], open?: true, type: :document]

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    # not used because the document is by definition always started and never
    # finalized, here for protocol completeness
    def start(_, parser, _), do: matched(parser)
    def continue(_, parser), do: matched(parser)

    def finalize(node, _), do: node
    def can_contain?(_, module), do: module != Tailmark.Node.ListItem
  end
end
