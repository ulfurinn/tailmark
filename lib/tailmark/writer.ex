defmodule Tailmark.Writer do
  alias Tailmark.Document
  alias Tailmark.Node

  def to_html(string) when is_binary(string), do: string

  def to_html(%Document{children: nodes}) do
    nodes |> to_html()
  end

  def to_html(nodes) when is_list(nodes), do: nodes |> Enum.map(&to_html/1)

  def to_html(%Node{type: :heading, level: level, content: content}) do
    ["<h#{level}>", content, "</h#{level}>\n"]
  end

  def to_html(%Node{type: :code, content: content, info: nil}) do
    ["<pre><code>", content, "</code></pre>\n"]
  end

  def to_html(%Node{type: :code, content: content, info: info}) do
    language = info |> String.split(" ") |> List.first()
    ["<pre><code class=\"language-", language, "\">", content, "</code></pre>\n"]
  end

  def to_html(%Node{type: :blockquote, children: children}) do
    ["<blockquote>", "\n", to_html(children), "</blockquote>\n"]
  end

  def to_html(%Node{type: :paragraph, content: content}) do
    ["<p>", String.trim_trailing(content), "</p>\n"]
  end
end
