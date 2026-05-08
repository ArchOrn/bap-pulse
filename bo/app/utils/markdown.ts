// Tiny Markdown subset shared between BO preview and the Flutter app renderer.
// Supports **bold** (rendered with the accent color) and *italic*. Other
// Markdown features are rendered as plain text — by design, since the Flutter
// app only knows about this subset.

export type SegmentStyle = 'plain' | 'accent' | 'italic'

export interface Segment {
  text: string
  style: SegmentStyle
}

// Tokens, longest-first to avoid ** being eaten by *.
const RULES: { open: string, close: string, style: SegmentStyle }[] = [
  { open: '**', close: '**', style: 'accent' },
  { open: '*', close: '*', style: 'italic' }
]

export function parseMarkdown(input: string): Segment[] {
  const out: Segment[] = []
  let i = 0
  let buf = ''

  const flush = () => {
    if (buf.length > 0) {
      out.push({ text: buf, style: 'plain' })
      buf = ''
    }
  }

  while (i < input.length) {
    let matched = false
    for (const rule of RULES) {
      if (input.startsWith(rule.open, i)) {
        const end = input.indexOf(rule.close, i + rule.open.length)
        if (end !== -1) {
          flush()
          out.push({
            text: input.slice(i + rule.open.length, end),
            style: rule.style
          })
          i = end + rule.close.length
          matched = true
          break
        }
      }
    }
    if (!matched) {
      buf += input[i]
      i++
    }
  }
  flush()
  return out
}

// Strips Markdown markers and returns plain text — used for table cells where
// rich rendering would break the layout.
export function stripMarkdown(input: string): string {
  return parseMarkdown(input).map(s => s.text).join('')
}
