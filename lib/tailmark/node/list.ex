defmodule Tailmark.Node.List do
  defstruct [:sourcepos, :ref, :parent, :list_data, children: [], open?: true]

  def new(parent, sourcepos),
    do: %__MODULE__{sourcepos: sourcepos, ref: make_ref(), parent: parent}

  defimpl Tailmark.ParseNode do
    import Tailmark.Parser

    # not called because we reify lists when creating their first item, here for
    # protocol completeness
    def start(_, parser, _), do: matched(parser)

    def continue(_, parser), do: matched(parser)

    def finalize(node, parser) do
      # TODO: handle loose lists
      tight =
        node.children
        |> Enum.reduce_while(true, fn item_ref, _ ->
          item = get_node(parser, item_ref)

          loose =
            followed_by_blank_line?(parser, item) ||
              !Enum.reduce_while(item.children, true, fn child_ref, _ ->
                child = get_node(parser, child_ref)

                if followed_by_blank_line?(parser, child) do
                  {:halt, false}
                else
                  {:cont, true}
                end
              end)

          if loose do
            {:halt, false}
          else
            {:cont, true}
          end
        end)

      # for tight lists, make intermediate paragraphs inline
      parser =
        if tight do
          tighten(parser, node)
        else
          parser
        end

      to = parser.nodes[List.last(node.children)].sourcepos.to
      node = %{node | sourcepos: %{node.sourcepos | to: to}}

      {node, parser}
    end

    def can_contain?(_, module), do: module == Tailmark.Node.ListItem

    defp tighten(parser, node) do
      node.children
      |> Enum.reduce(parser, fn item_ref, parser ->
        parser.nodes[item_ref].children
        |> Enum.reduce(parser, fn child_ref, parser ->
          if parser.nodes[child_ref].__struct__ == Tailmark.Node.Paragraph do
            parser
            |> update_node(child_ref, fn child ->
              %Tailmark.Node.Paragraph{child | block: false}
            end)
          else
            parser
          end
        end)
      end)
    end

    defp followed_by_blank_line?(parser, node) do
      next_sibling = find_next(parser.nodes[node.parent].children, node.ref)
      next_sibling = parser.nodes[next_sibling]

      next_sibling && node.sourcepos.to.line != next_sibling.sourcepos.from.line - 1
    end

    defp find_next([ref, next | _], ref), do: next
    defp find_next([_ | t], ref), do: find_next(t, ref)
    defp find_next([], _), do: nil
  end
end
