defmodule Tailmark.Parser do
  alias Tailmark.Document
  alias Tailmark.Node

  defstruct [
    :document,
    :nodes,
    :tip,
    :old_tip,
    :last_matched_container,
    :current_line,
    :starts,
    all_closed: true,
    offset: 0,
    column: 0,
    indent: 0,
    next_nonspace: 0,
    next_nonspace_column: 0,
    line_number: 0,
    line_count: 0,
    blank: false,
    partially_consumed_tab: false
  ]

  @codeIndent 4

  @lineEnding ~r/\r\n|\n|\r/
  @atxHeadingMarker ~r/^\#{1,6}(?:[ \t]+|$)/
  @codeFenceMarker ~r/^`{3,}(?!.*`)|^~{3,}/
  @codeFenceEnd ~r/^(?:`{3,}|~{3,})(?=[ \t]*$)/
  @break ~r/^(?:\*[ \t]*){3,}$|^(?:_[ \t]*){3,}$|^(?:-[ \t]*){3,}$/

  def document(md) do
    lines =
      md
      |> String.split(@lineEnding)
      |> drop_last_empty_line()

    {frontmatter, lines} = parse_frontmatter(lines)

    document = %Document{
      ref: make_ref(),
      frontmatter: frontmatter
    }

    %__MODULE__{
      starts: [
        &start_blockquote/2,
        &start_atx_heading/2,
        &start_fenced_code/2,
        &start_html/2,
        &start_setext_heading/2,
        &start_break/2,
        &start_list_item/2,
        &start_indented_code/2
      ],
      document: document.ref,
      nodes: %{document.ref => document},
      tip: document.ref,
      last_matched_container: document.ref,
      line_count: Enum.count(lines)
    }
    |> parse_blocks(lines)
    |> finalize()
    |> substitute_tree_refs()
    |> then(& &1.document)
  end

  defp parse_blocks(state, lines) do
    lines
    |> Enum.reduce(state, &incorporate_line(&2, &1))
  end

  defp incorporate_line(state, line) do
    state =
      state
      |> put_old_tip()
      |> put_current_line(line)
      |> put_offset(0)
      |> put_column(0)
      |> put_blank(false)
      |> put_partially_consumed_tab(false)

    {state, continue_state} =
      state
      |> match_continue(%{all_matched: true, container: state.document, finished?: false})

    if continue_state.finished? do
      state
    else
      state
      |> put_all_closed(continue_state.container == state.old_tip)
      |> put_last_matched_container(continue_state.container)
      |> incorporate_line_start_matched()
    end
  end

  defp incorporate_line_start_matched(state) do
    container = state.nodes[state.last_matched_container]

    {state, start_state} =
      match_start(state, %{
        container: container.ref,
        matched_leaf: container.type in [:code, :html]
      })

    state |> add_text_content(start_state.container)
  end

  defp add_text_content(state, container) do
    if !state.all_closed && !state.blank && state.nodes[state.tip].type == :paragraph do
      state
      |> add_line()
    else
      state = state |> close_unmatched()

      cond do
        state.nodes[container].type in [:paragraph, :code, :html] ->
          state
          |> add_line()

        state.offset < String.length(state.current_line) && !state.blank ->
          state
          |> add_child(:paragraph, :offset)
          |> advance_next_nonspace()
          |> add_line()

        true ->
          state
      end
    end
  end

  defp add_line(state) do
    state =
      if state.partially_consumed_tab do
        spaces = 4 - rem(state.column, 4)

        state
        |> inc_offset(1)
        |> update_node(state.tip, fn node, _ ->
          %{node | content: node.content <> String.duplicate(" ", spaces)}
        end)
      else
        state
      end

    state
    |> update_node(state.tip, fn node, _ ->
      line = rest(state, :offset)

      %{node | content: node.content <> line <> "\n"}
    end)
  end

  defp match_continue(state, continue_state) do
    container = state.nodes[continue_state.container]
    last_child = state.nodes[container.children |> List.last()]

    if last_child && last_child.open? do
      state = state |> find_next_nonspace()
      {match, state} = continue(state, last_child)

      case match do
        :matched ->
          match_continue(state, %{continue_state | container: last_child.ref})

        :not_matched ->
          # keep original container
          {state, continue_state}

        :line_finished ->
          {state, %{continue_state | finished?: true}}
      end
    else
      {state, continue_state}
    end
  end

  defp match_start(state, start_state = %{matched_leaf: true}) do
    {state, start_state}
  end

  defp match_start(state, start_state) do
    state = state |> find_next_nonspace()

    # TODO: performance opt from blocks.js:829:835

    {matched, state, start_state} =
      state.starts
      |> Enum.reduce_while({false, state, start_state}, fn start, {_, state, start_state} ->
        container = state.nodes[start_state.container]

        {match, state} = start.(state, container)

        case match do
          :container ->
            {:halt, {true, state, %{start_state | container: state.tip}}}

          :leaf ->
            {:halt, {true, state, %{start_state | container: state.tip, matched_leaf: true}}}

          _ ->
            {:cont, {false, state, start_state}}
        end
      end)

    if matched do
      match_start(state, start_state)
    else
      state = state |> advance_next_nonspace()
      {state, start_state}
    end
  end

  defp continue(state, %{type: :document}), do: matched(state)
  defp continue(state, %{type: :list}), do: matched(state)

  defp continue(
         state,
         node = %{
           type: :code,
           fenced: true,
           fence_char: fence_char,
           fence_length: fence_length,
           fence_offset: fence_offset
         }
       ) do
    match =
      state.indent <= 3 &&
        peek(state, :next_nonspace) == fence_char &&
        Regex.run(@codeFenceEnd, rest(state, :next_nonspace))

    with [marker] <- match,
         true <- String.length(marker) >= fence_length do
      # put last line length
      state =
        state
        |> finalize(node, state.line_number)

      {:line_finished, state}
    else
      _ ->
        state =
          1..fence_offset
          |> Enum.reduce_while(state, fn _, state ->
            if state |> peek(:offset) |> space_or_tab?() do
              {:cont, state |> advance_offset(1, true)}
            else
              {:halt, state}
            end
          end)

        matched(state)
    end
  end

  defp continue(state, %{type: :code, fenced: false}) do
    cond do
      state.indent >= @codeIndent ->
        state
        |> advance_offset(@codeIndent, true)
        |> matched()

      blank?(state) ->
        state
        |> advance_next_nonspace()
        |> matched()

      true ->
        state
        |> not_matched()
    end
  end

  defp continue(state, %{type: :blockquote}) do
    if !indented?(state) && peek(state, :next_nonspace) == ">" do
      state =
        state
        |> advance_next_nonspace()
        |> advance_offset(1, false)
        |> advance_offset_if_space_or_tab(:offset, 1, true)

      matched(state)
    else
      not_matched(state)
    end
  end

  defp continue(state, %{type: :heading}), do: not_matched(state)
  defp continue(state, %{type: :break}), do: not_matched(state)

  defp continue(state, %{type: :paragraph}) do
    if state.blank, do: not_matched(state), else: matched(state)
  end

  defp can_contain(:document, type), do: type != :item
  defp can_contain(:list, type), do: type == :item
  defp can_contain(:blockquote, type), do: type != :item
  defp can_contain(:item, type), do: type != :item
  defp can_contain(:heading, _), do: false
  defp can_contain(:break, _), do: false
  defp can_contain(:code, _), do: false
  defp can_contain(:html, _), do: false
  defp can_contain(:paragraph, _), do: false

  defp start_blockquote(state, _container) do
    if !indented?(state) && peek(state, :next_nonspace) == ">" do
      state
      |> advance_next_nonspace()
      |> advance_offset(1, false)
      |> advance_offset_if_space_or_tab(:offset, 1, true)
      |> close_unmatched()
      |> add_child(:blockquote, :next_nonspace)
      |> container()
    else
      not_matched(state)
    end
  end

  defp start_atx_heading(state, _container) do
    if !indented?(state) do
      match =
        state
        |> rest(:next_nonspace)
        |> then(&Regex.run(@atxHeadingMarker, &1))

      case match do
        [marker] ->
          state
          |> advance_next_nonspace()
          |> advance_offset(String.length(marker), false)
          |> close_unmatched()
          |> add_child(:heading, :next_nonspace, fn heading, state ->
            content =
              state
              |> rest(:offset)
              |> then(&Regex.replace(~r/^[ \t]*#+[ \t]*$/, &1, ""))
              |> then(&Regex.replace(~r/[ \t]+#+[ \t]*$/, &1, ""))

            %{heading | level: marker |> String.trim() |> String.length(), content: content}
          end)
          |> then(&(&1 |> advance_offset(String.length(&1.current_line) - &1.offset, false)))
          |> leaf()

        _ ->
          not_matched(state)
      end
    else
      not_matched(state)
    end
  end

  defp start_fenced_code(state, _container) do
    if !indented?(state) do
      match =
        state
        |> rest(:next_nonspace)
        |> then(&Regex.run(@codeFenceMarker, &1))

      case match do
        [marker] ->
          fence_length = String.length(marker)

          state
          |> close_unmatched()
          |> add_child(:code, :next_nonspace, fn code, state ->
            %{
              code
              | fenced: true,
                fence_length: fence_length,
                fence_char: String.at(marker, 0),
                fence_offset: state.indent
            }
          end)
          |> advance_next_nonspace()
          |> advance_offset(fence_length, false)
          |> leaf()

        _ ->
          not_matched(state)
      end
    else
      not_matched(state)
    end
  end

  defp start_html(state, _container), do: not_matched(state)
  defp start_setext_heading(state, _container), do: not_matched(state)

  defp start_break(state, _container) do
    if !indented?(state) && Regex.match?(@break, rest(state, :next_nonspace)) do
      state
      |> close_unmatched()
      |> add_child(:break, :next_nonspace)
      |> then(&advance_offset(&1, String.length(&1.current_line) - &1.offset, false))
      |> leaf()
    else
      state |> not_matched()
    end
  end

  defp start_list_item(state, _container), do: not_matched(state)

  defp start_indented_code(state, _container) do
    if indented?(state) && tip(state).type != :paragraph && !blank?(state) do
      state
      |> advance_offset(@codeIndent, true)
      |> close_unmatched()
      |> add_child(:code, :offset, fn node, _ -> %{node | fenced: false} end)
      |> leaf()
    else
      not_matched(state)
    end
  end

  defp finalize(state, node, _line_number) do
    above = node.parent

    state
    |> update_node(node.ref, fn node, _ ->
      %{node | open?: false}
      |> finalize()
    end)
    |> put_tip(above)
  end

  defp finalize(state = %__MODULE__{tip: nil}), do: state

  defp finalize(state = %__MODULE__{tip: tip, line_count: line_count}) do
    state
    |> finalize(state.nodes[tip], line_count)
    |> finalize()
  end

  defp finalize(node = %{type: :document}), do: node
  defp finalize(node = %{type: :heading}), do: node

  defp finalize(node = %{type: :code, fenced: true}) do
    [info, rest] = String.split(node.content, "\n", parts: 2)

    info =
      case String.trim(info) do
        "" -> nil
        info -> info
      end

    %{node | info: info, content: rest}
  end

  defp finalize(node = %{type: :code, fenced: false}) do
    content =
      node.content
      |> String.split("\n")
      |> Enum.reverse()
      |> Enum.drop_while(fn line -> String.trim(line) == "" end)
      |> Enum.reverse()
      |> Enum.join("\n")

    %{node | content: content <> "\n"}
  end

  defp finalize(node = %{type: :blockquote}), do: node
  defp finalize(node = %{type: :paragraph}), do: node
  defp finalize(node = %{type: :break}), do: node

  defp finalize_until_can_accept_type(state, type) do
    if can_contain(state.nodes[state.tip].type, type) do
      state
    else
      state
      |> finalize(state.nodes[state.tip], state.line_number - 1)
      |> finalize_until_can_accept_type(type)
    end
  end

  defp add_child(state, type, _offset, constructor \\ fn node, _state -> node end) do
    state =
      state
      |> finalize_until_can_accept_type(type)

    # column_number = offset + 1
    node = %Node{ref: make_ref(), type: type, parent: state.tip}

    state
    |> put_node(node)
    |> update_node(state.tip, fn tip, _ -> %{tip | children: tip.children ++ [node.ref]} end)
    |> put_tip(node.ref)
    |> update_node(node.ref, constructor)
  end

  defp drop_last_empty_line(lines) do
    lines
    |> Enum.reverse()
    |> case do
      ["" | rest] -> rest
      lines -> lines
    end
    |> Enum.reverse()
  end

  defp parse_frontmatter(lines) do
    case lines do
      ["---" | rest] ->
        {frontmatter, ["---" | content]} = Enum.split_while(rest, &(&1 != "---"))
        {YamlElixir.read_from_string!(Enum.join(frontmatter, "\n")), content}

      _ ->
        {nil, lines}
    end
  end

  defp substitute_tree_refs(state = %__MODULE__{document: document, nodes: nodes}) do
    %__MODULE__{state | document: substitute_tree_refs(document, nodes)}
  end

  defp substitute_tree_refs(ref, nodes) when is_reference(ref) do
    substitute_tree_refs(nodes[ref], nodes)
  end

  defp substitute_tree_refs(node = %{children: children}, nodes) do
    %{node | children: Enum.map(children, &substitute_tree_refs(&1, nodes))}
  end

  defp peek(%{current_line: current_line, next_nonspace: next_nonspace}, :next_nonspace) do
    String.at(current_line, next_nonspace)
  end

  defp peek(%{current_line: current_line, offset: offset}, :offset) do
    String.at(current_line, offset)
  end

  defp rest(%{current_line: current_line, next_nonspace: next_nonspace}, :next_nonspace) do
    String.split_at(current_line, next_nonspace) |> elem(1)
  end

  defp rest(%{current_line: current_line, offset: offset}, :offset) do
    String.split_at(current_line, offset) |> elem(1)
  end

  defp find_next_nonspace(state) do
    find_state =
      find_next_nonspace(state.current_line, %{c: nil, i: state.offset, cols: state.column})

    state
    |> put_blank(find_state.c in ["\n", "\r", nil])
    |> put_next_nonspace(find_state.i)
    |> put_next_nonspace_column(find_state.cols)
    |> put_indent(find_state.cols - state.column)
  end

  defp find_next_nonspace(line, find_state = %{i: i, cols: cols}) do
    c = String.at(line, i)

    case c do
      " " ->
        find_next_nonspace(line, %{find_state | i: i + 1, cols: cols + 1})

      "\t" ->
        find_next_nonspace(line, %{find_state | i: i + 1, cols: cols + (4 - rem(cols, 4))})

      _ ->
        %{find_state | c: c}
    end
  end

  defp advance_next_nonspace(state) do
    state
    |> put_offset(state.next_nonspace)
    |> put_column(state.next_nonspace_column)
    |> put_partially_consumed_tab(false)
  end

  defp advance_offset_if_space_or_tab(state, peek_pos, count, columns) do
    if peek(state, peek_pos) in [" ", "\t"] do
      state
      |> advance_offset(count, columns)
    else
      state
    end
  end

  defp space_or_tab?(char), do: char in [" ", "\t"]

  defp advance_offset(state, 0, _), do: state

  defp advance_offset(state, count, columns) do
    case peek(state, :offset) do
      nil ->
        state

      "\t" ->
        chars_to_tab = 4 - rem(state.column, 4)

        if columns do
          chars_to_advance = if chars_to_tab > count, do: count, else: chars_to_tab
          partially_consumed_tab = chars_to_tab > count

          state
          |> put_partially_consumed_tab(partially_consumed_tab)
          |> inc_column(chars_to_advance)
          |> inc_offset(if partially_consumed_tab, do: 0, else: 1)
          |> advance_offset(count - chars_to_advance, columns)
        else
          state
          |> put_partially_consumed_tab(false)
          |> inc_column(chars_to_tab)
          |> inc_offset(1)
          |> advance_offset(count - 1, columns)
        end

      _ ->
        state
        |> put_partially_consumed_tab(false)
        |> inc_column(1)
        |> inc_offset(1)
        |> advance_offset(count - 1, columns)
    end
  end

  defp close_unmatched(state = %{all_closed: true}), do: state

  defp close_unmatched(state) do
    state
    |> close_one_unmatched()
    |> put_all_closed(true)
  end

  defp close_one_unmatched(state = %{old_tip: ref, last_matched_container: ref}), do: state

  defp close_one_unmatched(state) do
    old_tip = state.nodes[state.old_tip]

    state
    |> finalize(old_tip, state.line_number - 1)
    |> put_old_tip(old_tip.parent)
    |> close_one_unmatched()
  end

  defp put_current_line(state, value), do: %{state | current_line: value}
  defp put_tip(state, value), do: %{state | tip: value}
  defp put_old_tip(state), do: %{state | old_tip: state.tip}
  defp put_old_tip(state, value), do: %{state | old_tip: value}
  defp put_offset(state, value), do: %{state | offset: value}
  defp put_column(state, value), do: %{state | column: value}
  defp put_blank(state, value), do: %{state | blank: value}
  defp put_partially_consumed_tab(state, value), do: %{state | partially_consumed_tab: value}
  defp put_next_nonspace(state, value), do: %{state | next_nonspace: value}
  defp put_next_nonspace_column(state, value), do: %{state | next_nonspace_column: value}
  defp put_indent(state, value), do: %{state | indent: value}
  defp put_all_closed(state, value), do: %{state | all_closed: value}
  defp put_last_matched_container(state, value), do: %{state | last_matched_container: value}
  defp put_node(state, node), do: %{state | nodes: Map.put(state.nodes, node.ref, node)}

  defp inc_column(state, column), do: %{state | column: state.column + column}
  defp inc_offset(state, offset), do: %{state | offset: state.offset + offset}

  defp update_node(state, ref, fun) do
    %{state | nodes: Map.update!(state.nodes, ref, fn node -> fun.(node, state) end)}
  end

  defp indented?(state), do: state.indent >= @codeIndent
  def blank?(%__MODULE__{blank: blank}), do: blank
  def tip(%__MODULE__{tip: tip, nodes: nodes}), do: nodes[tip]

  defp matched(state), do: {:matched, state}
  defp not_matched(state), do: {:not_matched, state}
  defp container(state), do: {:container, state}
  defp leaf(state), do: {:leaf, state}
end
