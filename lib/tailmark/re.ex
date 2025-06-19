defmodule Tailmark.RE do
  @escapable_def "[!\"#$%&'()*+,.\\/:;<=>?@[\\]^_`{|}~-]"
  @entity_def "&(?:#x[a-f0-9]{1,6}|#[0-9]{1,7}|[a-z][a-z0-9]{1,31});"

  def new do
    %{
      break_marker: ~r/^(?:\*[ \t]*){3,}$|^(?:_[ \t]*){3,}$|^(?:-[ \t]*){3,}$/,
      fenced_code_start_marker: ~r/^`{3,}(?!.*`)|^~{3,}/,
      fenced_code_end_marker: ~r/^(?:`{3,}|~{3,})(?=[ \t]*$)/,
      atx_start_marker: ~r/^\#{1,6}(?:[ \t]+|$)/,
      atx_whitespaced_marker_1: ~r/^[ \t]*#+[ \t]*$/,
      atx_whitespaced_marker_2: ~r/[ \t]+#+[ \t]*$/,
      setext_start_marker: ~r/^(?:=+|-+)[ \t]*$/,
      list_item_non_space: ~r/[^ \t\f\v\r\n]/,
      list_item_bullet_marker: ~r/^[*+-]/,
      list_item_ordered_marker: ~r/^(\d{1,9})([.)])/,
      inline_main: ~r/^[^\n`\[\]\\!<&*_]+/,
      inline_escapable: ~r/^#{@escapable_def}/,
      inline_initial_space: ~r/^ */,
      inline_final_space: ~r/ *$/,
      inline_ticks_here: ~r/^`+/,
      inline_ticks: ~r/^[^`]*(?<goal>`+)/,
      inline_spnl: ~r/^ *(?:\n *)?/,
      inline_link_destination_braces: ~r/^<(?<goal>(?:[^<>\n\\\x00]|\\.)*)>/,
      inline_link_title:
        ~r/^(?:"(?<goal1>(\\#{@escapable_def}|\\[^\\]|[^\\"\x00])*)"|'(?<goal2>(\\#{@escapable_def}|\\[^\\]|[^\\'\x00])*)'|\((?<goal3>(\\#{@escapable_def}|\\[^\\]|[^\\()\x00])*)\))/,
      inline_entity: ~r/^#{@entity_def}/i,
      inline_whitespace_char: ~r/^[ \t\n\x0b\x0c\x0d]/,
      inline_unicode_whitespace_char: ~r/^\s/u,
      inline_punctuation: ~r/^\p{P}/u,
      inline_backslash_or_amp: ~r/[\\&]/,
      inline_entity_or_escaped: ~r/\\#{@escapable_def}|#{@entity_def}/,
      inline_callout:
        ~r/^\[!(?<type>[a-z0-9-]+)(\|(?<meta>[a-z0-9-]+))?\]\s*?(?<title>[^\n]+)?(\n|$)/ui
    }
  end
end
