defmodule Tailmark.Node.Paragraph do
  defstruct [:sourcepos, :ref, :parent, content: "", block: true, open?: true]

  def new(parent, sourcepos),
    do: %__MODULE__{sourcepos: sourcepos, ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    # not used because paragraph is a fallback, here for protocol completeness
    def start(_, parser, _), do: matched(parser)

    def continue(_, parser) do
      if parser.blank, do: not_matched(parser), else: matched(parser)
    end

    def finalize(node, _), do: node
    def can_contain?(_, _), do: false
  end
end
