defmodule Tailmark.Node.List do
  defstruct [:ref, :parent, :list_data, children: [], open?: true]

  def new(parent), do: %__MODULE__{ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    def continue(_, parser), do: matched(parser)

    def finalize(node, parser) do
      # TODO: handle loose lists

      # for tight lists, make intermediate paragraphs inline
      parser =
        node.children
        |> Enum.reduce(parser, fn item_ref, parser ->
          parser.nodes[item_ref].children
          |> Enum.reduce(parser, fn child_ref, parser ->
            if parser.nodes[child_ref].__struct__ == Tailmark.Node.Paragraph do
              parser
              |> update_node(child_ref, fn child, _ ->
                %Tailmark.Node.Paragraph{child | block: false}
              end)
            else
              parser
            end
          end)
        end)

      {node, parser}
    end

    def can_contain?(_, module), do: module == Tailmark.Node.ListItem
  end
end
