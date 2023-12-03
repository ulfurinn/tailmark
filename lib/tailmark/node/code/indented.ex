defmodule Tailmark.Node.Code.Indented do
  defstruct [:ref, :parent, content: "", open?: true]

  def new(parent), do: %__MODULE__{ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    @codeIndent 4

    def start(_, parser, _) do
      if indented?(parser) && tip(parser).__struct__ != Tailmark.Node.Paragraph && !blank?(parser) do
        parser
        |> advance_offset(@codeIndent, true)
        |> close_unmatched()
        |> add_child(@for, :offset)
        |> leaf()
      else
        not_matched(parser)
      end
    end

    def continue(_node, parser) do
      cond do
        parser.indent >= @codeIndent ->
          parser
          |> advance_offset(@codeIndent, true)
          |> matched()

        blank?(parser) ->
          parser
          |> advance_next_nonspace()
          |> matched()

        true ->
          parser
          |> not_matched()
      end
    end

    def finalize(node = %@for{content: content}, _) do
      content =
        content
        |> String.split("\n")
        |> Enum.reverse()
        |> Enum.drop_while(fn line -> String.trim(line) == "" end)
        |> Enum.reverse()
        |> Enum.join("\n")

      %@for{node | content: content <> "\n"}
    end

    def can_contain?(_, _), do: false
  end
end
