/** ^
 * Copyright (c) 2013 Quildreen Motta
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

p = require 'parsing.combinators'
Either = require 'monads.either'

export parse = (text) ->
  text |> p.run (s) -> document s.put indent: 0

str-to-array = (a) -> a.split ''

foldt = (as) ->
  result = []
  l      = null
  for a in as => do
                 if Array.is-array a            => result.push (l := a)
                 else if (typeof! l) is \String => result.push (result.pop! + a)
                 else                           => result.push (l := a)
  return result

between2 = (a, p1) --> p.between a, a, p1

indented = (s1) ->
  c1 = s1.get!indent
  c2 = s1.position!column!

  switch
  | c1 is c2  => Either.Right [s1, null]
  | otherwise => p.fail "Indentation mismatch. Was #c1, got #c2.", s1, null

indented-block = (p1) -> p.many1 (p.and-then indented, p1)

set-indent = (s1) ->
  Either.Right [s1.put indent: s1.position!column!, null]

indent = (s1) ->
  c1 = s1.get!indent
  c2 = s1.position!column!

  switch
  | c2 > c1   => Either.Right [s1.put indent: c2; null]
  | otherwise => p.fail "Not indented. Was #c1, got #c2.", s1, null

match-indentation = p.and-then (-> hs it), (-> indented it)

log = (m, p) --> (s) ->
  r = p s
  r.or-else ([s, a]) -> console.log m, a.to-string!
  r.chain ([s, a]) -> console.log m, s.to-string!, (JSON.stringify a, null, 2)
  return r

token = (n, p1) --> p1 |> p.map (a) -> [n, a]

export document = p.many -> blocks it

export hs = p.skip-many (p.one-of str-to-array ' \t')

export obligatory-hs = p.many1 (p.one-of str-to-array ' \t')

export ws = p.skip-many p.space

export eol = p.choice [
  p.string '\r\n'
  p.string '\r'
  p.string '\n'
]

export eof = (s) ->
  | s.length is 0 => Either.Right [s, null]
  | _             => Either.Left [s, new p.ExpectedException null, (s.consume 1).get!, s .map -> 'end of file']

export blocks = p.choice [
  -> heading it
  -> block it
]

export heading = p.choice [
  -> section it
  -> declaration it
  -> meta it
]

export block = p.choice [
  -> block-quote it
  -> horizontal-line it
  -> paragraph it
  -> blank-line it
]

export section = p.sequence [
  p.many1 (p.string '-')
  hs
  p.many  (p.none-of ['-'])
  hs
  p.many  (p.string '-')
  eol
] |> p.map ([a, _, bs, _, _]) -> [\section a.length, bs.join '' .trim!]

export declaration = p.sequence [
  p.many1 (p.string '#')
  hs
  -> type it
  hs
  -> qualified-id it
  hs
  p.many (p.string '#')
  eol
] |> p.map ([a, _, b, _, c, _, _]) -> [\declaration a.length, b, c]

export type = p.choice (<[ module function method class field type ]> .map p.caseless-string)

export id-chars = p.none-of str-to-array ':. \t\f\n\r'

export id = p.many1 id-chars |> p.map (as) -> [\id as.join '']

export qualified-id = do
                      p.separated-by (p.string '.'), -> id it
                      |> p.map (as) -> [\qualified-id as]

export hard-line = do
                   p.and-then do
                              * p.and-then (p.string '|'), hs
                              * p.and-then1 (p.many1 -> text it), eol
                   |> p.map (a) -> [\hard-line foldt a]

export soft-line = do
                   p.and-then1 (p.many1 -> text it), eol
                   |> p.map (a) -> [\soft-line foldt a]

export blank-line = do
                    p.and-then hs, eol
                    |> p.map -> [\blank-line]

export line = p.choice [hard-line, soft-line]

export paragraph = do
                   p.and-then1 do
                               * p.sequence [
                                   -> line it
                                   p.many (p.and-then match-indentation, -> line it)
                                 ] |> p.map ([a, as]) -> [a, ...as]
                               * p.choice [(-> blank-line it), eof]
                   |> p.map (as) -> [\paragraph as]

export eol-and-indent = p.sequence [
  p.optional [], eol
  hs
]

export meta = p.sequence [
  set-indent
  p.string ':'
  -> id it
  p.string ':'
  p.optional [], hs
  p.optional [\soft-line ''], -> soft-line it
  p.optional do
             * []
             * -> blocks-indented it
] |> p.map ([_, _, a, _, _, b, c]) -> [\meta a, b, c]


export blocks-indented = p.sequence [
  p.optional [], p.and-then hs, eol
  obligatory-hs
  indent
  p.many1 (p.and-then match-indentation, block)
] |> p.map ([_, _, _, a]) -> a

export list = p.choice [
  -> unordered-list it
  -> ordered-list it
]

export unordered-list = p.sequence [
  set-indent
  p.string '*'
  -> blocks-indented it
] |> p.map ([_, _, a]) -> [\unordered-list a]

export ordered-list = p.sequence [
  set-indent
  -> item-number it
  p.string ')'
  -> blocks-indented it
] |> p.map ([_, _, _, a]) -> [\ordered-list a]

export item-number = p.choice [
  p.string '#'
  p.many1 p.digit
]

export block-quote = p.sequence [
  -> block-quote-line it
  p.many (p.and-then match-indentation, -> block-quote-line it)
] |> p.map ([a, as]) -> [\block-quote [a, ...as]]

export block-quote-line = do
                          p.and-then (p.and-then (p.string '>'), hs), -> soft-line it
                          |> p.map ([_, a]) -> a

export horizontal-line = p.sequence [
  p.string '*'
  p.and-then hs, (p.string '*')
  p.many1 (p.and-then hs, (p.string '*'))
  hs
  eol
] |> p.map -> [\horizontal-line]

export link = p.choice [
  -> internet-link it
  -> image-link it
  -> foot-note it
  -> regular-link it
  -> foot-note-reference it
  -> entity-link it
]

export internet-link = p.choice [
  -> absolute-url it
  -> domain-url it
  -> email-url it
]

export absolute-url = p.sequence [
  -> protocol it
  p.string '://'
  -> domain it
  p.optional [], -> pathname it
] |> p.map ([a, _, b, c]) -> [\absolute-url a, b, c]

export domain-url = p.sequence [
  p.string 'www.'
  -> domain it
  p.optional [], -> pathname it
] |> p.map ([_, a, b]) -> [\domain-url a, b]

export email-url = p.sequence [
  -> username it
  p.string '@'
  -> domain it
] |> p.map ([a, _, b]) -> [\email-url a, b]

export image-link = p.sequence [
  p.string '!'
  -> regular-link it
] |> p.map ([_, as]) -> [\image-link ...(as.slice 1)]

export regular-link = p.sequence [
  p.string '[['
  -> link-part it
  p.optional '', (p.and-then (p.string '|'), -> link-part it)
  p.string ']]'
] |> p.map ([_, a, b, _]) -> [\regular-link a, b]

export link-part = do
                   p.many1 (p.none-of str-to-array '[]|')
                   |> p.map (as) -> as.join '' .trim!

export foot-note = p.sequence [
  p.string '[['
  -> number it
  p.string ']]'
] |> p.map ([_, a, _]) -> [\foot-note a]

export foot-note-reference = p.sequence [
  p.string '['
  -> number it
  p.string ']:'
  hs
  -> soft-line it
] |> p.map ([_, a, _, _, b]) -> [\foot-note-text a, b]

export number = p.many1 p.digit |> p.map (a) -> Number (a.join '')

export entity-link = p.sequence [
  p.string '[:'
  -> qualified-id it
  p.string ':]'
] |> p.map ([_, a, _]) -> [\entity-link a]

export protocol = p.choice (<[ http https ftp ]> .map p.caseless-string)

export domain = p.separated-by1 (p.string '.'), -> url-part it

export domain-part = do
                     p.many1 (p.none-of str-to-array './?')
                     |> p.map (as) -> as.join ''

export url-part = do
                  p.many1 (p.satisfy 'url part' -> /[\w\d\-_%=&\.]/.test it)
                  |> p.map (as) -> as.join ''

export pathname = p.sequence [
  p.separated-by (p.string '/'), -> url-part it
  p.optional '', -> query-string it
  p.optional '', -> fragment it
]

export query-string = p.and-then (p.string '?'), -> url-part it
export fragment = p.and-then (p.string '#'), -> url-part it

export username = do
                  p.many1 (p.satisfy 'username' -> /[\w\d\-_\.]/.test it)
                  |> p.map (as) -> as.join ''

export except = (a, p2) --> 
  p.and-then (p.negate (p.lookahead-matching a, p.any-char)), p2

export text-but = (a) -->
  p.many (except a, -> text it)
  |> p.map (as) -> foldt as

export emphasis = p.choice [
  p.string '\\*'
  between2 (p.string '*'), text-but \* |> token \emphasis
]

export italic = p.choice [
  p.string '\\/'
  between2 (p.string '/'), text-but \/ |> token \italic
]

export strike = p.choice [
  p.string '\\+'
  between2 (p.string '+'), text-but \+ |> token \strike
]

export literal = p.choice [
  p.string '\\`'
  between2 (p.string '`'), ((p.many (p.none-of '`')) |> p.map (as) -> as.join '') |> token \literal
]

export formatting = p.choice [
  -> emphasis it
  -> italic it
  -> strike it
  -> literal it
  -> link it
]

export text = p.choice [
  -> formatting it
  p.none-of str-to-array '\r\n'
]
