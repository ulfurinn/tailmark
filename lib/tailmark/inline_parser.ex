defmodule Tailmark.InlineParser do
  alias Tailmark.Parser

  defstruct [:node, :parser, :subject, :pos, :delimeters, :brackets]

  @main ~r/^[^\n`\[\]\\!<&*_]+/m
  @escapable ~r/^[!"#$%&'()*+,.\/:;<=>?@[\\\]^_`{|}~-]/
  @initialSpace ~r/^ */
  @finalSpace ~r/ *$/

  def parse(node, parser) do
    state =
      %__MODULE__{
        node: node,
        parser: parser,
        subject: String.trim(node.content),
        pos: 0,
        delimeters: [],
        brackets: []
      }
      |> parse_inline()

    {state.node, state.parser}
  end

  defp parse_inline(state) do
    c = peek(state)

    if c == nil do
      state
    else
      {state, result} = parse_inline(state, c)

      if result do
        state
      else
        state
        |> advance()
        |> append_child(Tailmark.Node.Text.new(c))
      end
      |> parse_inline()
    end
  end

  defp parse_inline(state, "\n") do
    state = state |> advance()
    last_child = state.node.children |> List.last() |> then(&Parser.get_node(state.parser, &1))

    with %Tailmark.Node.Text{content: content} <- last_child,
         " " <- content |> String.last() do
      hard_break = String.at(content, -2) == " "

      state
      |> update_node(last_child, fn node ->
        %{node | content: Regex.replace(@finalSpace, node.content, "")}
      end)
      |> append_child(Tailmark.Node.Linebreak.new(hard_break))
    else
      _ ->
        state |> append_child(Tailmark.Node.Linebreak.new(false))
    end
    |> consume(@initialSpace)
    |> result(true)
  end

  defp parse_inline(state, "\\") do
    state = state |> advance()

    cond do
      peek(state) == "\n" ->
        state
        |> advance()
        |> append_child(Tailmark.Node.Linebreak.new(true))

      peek(state) && Regex.match?(@escapable, peek(state)) ->
        state
        |> append_child(Tailmark.Node.Text.new(peek(state)))
        |> advance()

      true ->
        state
        |> append_child(Tailmark.Node.Text.new("\\"))
    end
    |> result(true)
  end

  defp parse_inline(state, _) do
    case extract(state, @main) do
      {state, nil} ->
        state
        |> result(false)

      {state, string} ->
        state
        |> append_child(Tailmark.Node.Text.new(string))
        |> result(true)
    end
  end

  defp peek(%__MODULE__{subject: subject, pos: pos}), do: String.at(subject, pos)
  defp rest(%__MODULE__{subject: subject, pos: pos}), do: String.split_at(subject, pos) |> elem(1)
  defp advance(%__MODULE__{pos: pos} = state, n \\ 1), do: %__MODULE__{state | pos: pos + n}

  defp consume(state, re) do
    case Regex.run(re, rest(state), capture: :first) do
      [match] ->
        state
        |> advance(String.length(match))

      _ ->
        state
    end
  end

  defp extract(state, re) do
    case Regex.run(re, rest(state), capture: :first) do
      [match] ->
        state
        |> advance(String.length(match))
        |> result(match)

      _ ->
        state
        |> result(nil)
    end
  end

  defp update_node(%__MODULE__{parser: parser} = state, node, fun) do
    %__MODULE__{state | parser: Parser.update_node(parser, node, fun)}
  end

  defp append_child(%__MODULE__{parser: parser} = state, child) do
    parser = Parser.append_child(parser, state.node, child)
    %__MODULE__{state | parser: parser, node: Parser.get_node(parser, state.node.ref)}
  end

  defp result(state, result), do: {state, result}
end
