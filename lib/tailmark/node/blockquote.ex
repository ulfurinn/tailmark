defmodule Tailmark.Node.Blockquote do
  defstruct [:ref, :parent, children: [], open?: true]

  def new(parent), do: %__MODULE__{ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    def start(_, parser, _) do
      if !indented?(parser) && peek(parser, :next_nonspace) == ">" do
        parser
        |> advance_next_nonspace()
        |> advance_offset(1, false)
        |> advance_offset_if_space_or_tab(:offset, 1, true)
        |> close_unmatched()
        |> add_child(@for, :next_nonspace)
        |> container()
      else
        not_matched(parser)
      end
    end

    def continue(_, parser) do
      if !indented?(parser) && peek(parser, :next_nonspace) == ">" do
        parser
        |> advance_next_nonspace()
        |> advance_offset(1, false)
        |> advance_offset_if_space_or_tab(:offset, 1, true)
        |> matched()
      else
        not_matched(parser)
      end
    end

    def finalize(node), do: node
    def can_contain?(_, module), do: module != Tailmark.Node.ListItem
  end
end
