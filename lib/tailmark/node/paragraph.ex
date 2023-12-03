defmodule Tailmark.Node.Paragraph do
  defstruct [:ref, :parent, content: "", open?: true]

  def new(parent), do: %__MODULE__{ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    # not used because paragraph is a fallback, here for protocol completeness
    def start(_, parser, _), do: matched(parser)

    def continue(_, parser) do
      if parser.blank, do: not_matched(parser), else: matched(parser)
    end

    def finalize(node), do: node
    def can_contain?(_, _), do: false
  end
end
