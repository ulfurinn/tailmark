defmodule Tailmark.Writer do
  alias Tailmark.Document
  alias Tailmark.Node

  def to_html(string) when is_binary(string), do: string

  def to_html(%Document{children: nodes}) do
    nodes
    |> to_html()
    |> List.flatten()
    |> dedup_newlines()
    |> strip_leading_newline()
  end

  def to_html(nodes) when is_list(nodes), do: nodes |> Enum.map(&to_html/1)

  def to_html(%Node.Heading.ATX{level: level, content: content}) do
    ["\n", "<h#{level}>", content, "</h#{level}>", "\n"]
  end

  def to_html(%Node.Heading.Setext{level: level, content: content}) do
    ["\n", "<h#{level}>", content, "</h#{level}>", "\n"]
  end

  def to_html(%Node.Code.Fenced{content: content, info: nil}) do
    ["\n", "<pre><code>", content, "</code></pre>", "\n"]
  end

  def to_html(%Node.Code.Fenced{content: content, info: info}) do
    language = info |> String.split(" ") |> List.first()
    ["\n", "<pre><code class=\"language-", language, "\">", content, "</code></pre>", "\n"]
  end

  def to_html(%Node.Code.Indented{content: content}) do
    ["\n", "<pre><code>", content, "</code></pre>", "\n"]
  end

  def to_html(%Node.List{children: children, list_data: %{type: :bullet}}) do
    ["\n", "<ul>", "\n", to_html(children), "\n", "</ul>", "\n"]
  end

  def to_html(%Node.List{children: children, list_data: %{type: :ordered, start: start}})
      when start == 1 do
    ["\n", "<ol>", "\n", to_html(children), "\n", "</ol>", "\n"]
  end

  def to_html(%Node.List{children: children, list_data: %{type: :ordered, start: start}}) do
    [
      "\n",
      "<ol start=\"",
      Integer.to_string(start),
      "\">",
      "\n",
      to_html(children),
      "\n",
      "</ol>",
      "\n"
    ]
  end

  def to_html(%Node.ListItem{children: children}) do
    ["<li>", to_html(children), "</li>", "\n"]
  end

  def to_html(%Node.Blockquote{children: children}) do
    ["\n", "<blockquote>", "\n", to_html(children), "\n", "</blockquote>", "\n"]
  end

  def to_html(%Node.Paragraph{content: content, block: true}) do
    ["\n", "<p>", String.trim_trailing(content), "</p>", "\n"]
  end

  def to_html(%Node.Paragraph{content: content, block: false}) do
    String.trim_trailing(content)
  end

  def to_html(%Node.Break{}) do
    ["\n", "<hr />", "\n"]
  end

  defp dedup_newlines(list) do
    list
    |> dedup_newlines([])
  end

  defp dedup_newlines([], acc), do: Enum.reverse(acc)

  defp dedup_newlines(["\n" | t], acc) do
    acc =
      case acc do
        ["\n" | _] -> acc
        _ -> ["\n" | acc]
      end

    dedup_newlines(t, acc)
  end

  defp dedup_newlines([h | t], acc), do: dedup_newlines(t, [h | acc])

  defp strip_leading_newline(["\n" | t]), do: t
  defp strip_leading_newline(list), do: list
end
