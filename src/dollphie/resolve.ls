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

slugify = require 'slug'

export resolve-node = (a) -> switch (tag = a?0)
  | \section         => Section.from-node a
  | \declaration     => Declaration.from-node a
  | \id              => Id.from-node a
  | \qualified-id    => QualifiedId.from-node a
  | \hard-line       => HardLine.from-node a
  | \soft-line       => SoftLine.from-node a
  | \blank-line      => BlankLine.from-node a
  | \paragraph       => Paragraph.from-node a
  | \meta            => Meta.from-node a
  | \unordered-list  => UnorderedListItem.from-node a
  | \ordered-list    => OrderedListItem.from-node a
  | \block-quote     => BlockQuote.from-node a
  | \horizontal-line => HorizontalLine.from-node a
  | \absolute-url    => Absoluteurl.from-node a
  | \domain-url      => DomainUrl.from-node a
  | \email-url       => EmailUrl.from-node a
  | \image-link      => ImageLink.from-node a
  | \regular-link    => RegularLink.from-node a
  | \foot-note       => FootNoteReference.from-node a
  | \foot-note-text  => FootNoteText.from-node a
  | \entity-link     => EntityLink.from-node a
  | \emphasis        => Emphasis.from-node a
  | \italic          => Italic.from-node a
  | \strike          => Strike.from-node a
  | \literal         => Literal.from-node a
  | otherwise        => throw new Error "Unrecognised node of type “#{tag}”: #a."

export text-or-resolve = (a) ->
  try
    resolve-node a
  catch e
    a

export resolve-ast = (ast) -> ast.map resolve-node

padded = (n, s) --> 
  lines = s.split /\r?\n/
  first = lines.shift!
  rest  = lines.map (l) -> (' ' * n) + l
  return [first, ...rest] .filter Boolean .join '\n'

padded-list = (n, as) ->
  as.join (',\n' + (' ' * n))

repr-text = (n, as) -->
  padded-list n, as.map f = (a) ->
                   | a.repr           => a.repr n
                   | Array.is-array a => a.map f
                   | _                => JSON.stringify a


export class Token
  ->
  type: \token
  @from-node = -> throw new Error "Don't know how to make a #{@type} out of a node."
  to-string: -> @repr 0
  repr: (n) -> "Token()"
  can-assimilate: (a) -> false
  assimilate: (a) -> throw new Error "A “#{@type}” token can't assimilate the token #a."

export class Section extends Token
  (@title, @depth) ->
  type: \section
  @from-node = ([_, depth, title]) -> new Section title, depth
  repr: (n) -> padded n, """
                         Section(
                           #{@depth},
                           #{@title}
                         )
                         """

export class Declaration extends Token
  (@id, @kind, @depth) ->
  type: \declaration
  @from-node = ([_, depth, kind, id]) ->
    new Declaration (resolve-node id), kind, depth
  repr: (n) -> padded n, """
                         Declaration(
                           #{@depth},
                           #{@kind},
                           #{@id.repr n + 2}
                         )
                         """

export class Id extends Token
  (@value) ->
  type: \id
  @from-node = ([_, value]) -> new Id value
  repr: (n) -> "Id(#{@value})"

export class QualifiedId extends Token
  (@values) ->
  type: \qualified-id
  @from-node = ([_, as]) -> new QualifiedId as.map resolve-node
  repr: (n) -> padded n, """
                         QualifiedId(
                           #{padded-list n, @values.map (.repr n + 2)}
                         )
                         """

export class HardLine extends Token
  (@value) ->
  type: \hard-line
  @from-node = ([_, a]) -> new HardLine a.map text-or-resolve
  repr: (n) -> "HardLine(#{repr-text n, @value})"

export class SoftLine extends Token
  (@value) ->
  type: \soft-line
  @from-node = ([_, a]) -> new SoftLine a.map text-or-resolve
  repr: (n) -> "SoftLine(#{repr-text n, @value})"

export class BlankLine extends Token
  ->
  type: \blank-line
  @from-node = -> new BlankLine
  repr: (n) -> "BlankLine()"
  
export class Paragraph extends Token
  (@values) ->
  type: \paragraph
  @from-node = ([_, as]) -> new Paragraph as.map resolve-node
  repr: (n) -> padded n, """
                         Paragraph(
                           #{padded-list n, @values.map (.repr n + 2)}
                         )
                         """

export class Meta extends Token
  (@kind, @text, @block) ->
  type: \meta
  @from-node = ([_, kind, text, block]) ->
    new Meta (resolve-node kind), (resolve-node text), block.map resolve-node
  repr: (n) -> padded n, """
                         Meta(
                           #{@kind},
                           #{@text},
                           [
                           #{padded-list n + 2, @block.map (.repr n + 2)}
                           ]
                         )
                         """

export class UnorderedListItem extends Token
  (@value) ->
  type: \unordered-list-item
  @from-node = ([_, a]) -> new UnorderedListItem (resolve-node a)
  repr: (n) -> "UnorderedListItem(#{@value.repr n + 2})"

export class OrderedListItem extends Token
  (@value) ->
  type: \ordered-list-item
  @from-node = ([_, a]) -> new OrderedListItem (resolve-node a)
  repr: (n) -> "OrderedListItem(#{@value.repr n + 2})"

export class BlockQuote extends Token
  (@values) ->
  type: \block-quote
  @from-node = ([_, as]) -> new BlockQuote as
  repr: (n) -> padded n, """
                         BlockQuote(
                           #{repr-text n, @values}
                         )
                         """

export class HorizontalLine extends Token
  ->
  type: \horizontal-line
  @from-node = -> new HorizontalLine
  repr: (n) -> "HorizontalLine()"

export class AbsoluteUrl extends Token
  (@protocol, @domain, @pathname) ->
  type: \absolute-url
  @from-node = ([_, protocol, domain, pathname]) -> new AbsoluteUrl protocol, domain, pathname
  repr: (n) -> padded n, """
                         AbsoluteUrl(
                           #{@protocol},
                           #{@domain},
                           #{@pathname}
                         )
                         """

export class DomainUrl extends Token
  (@domain, @pathname) ->
  type: \domain-url
  @from-node = ([_, domain, pathname]) -> new DomainUrl domain, pathname
  repr: (n) -> padded n, """
                         DomainUrl(
                           #{@domain},
                           #{@pathname}
                         )
                         """

export class EmailUrl extends Token
  (@username, @domain) ->
  type: \email-url
  @from-node = ([_, user, domain]) -> new EmailUrl user, domain
  repr: (n) -> padded n, """
                         EmailUrl(
                           #{@username},
                           #{@domain}
                         )
                         """

export class ImageLink extends Token
  (@url, @title) ->
  type: \image-link
  @from-node = ([_, url, title]) -> new ImageLink url, title
  repr: (n) -> padded n, """
                         ImageLink(
                           #{@url},
                           #{@title}
                         )
                         """

export class RegularLink extends Token
  (@url, @title) ->
  type: \regular-link
  @from-node = ([_, url, title]) -> new RegularLink url, title
  repr: (n) -> padded n, """
                         RegularLink(
                           #{@url},
                           #{@title}
                         )
                         """

export class FootNoteReference extends Token
  (@id) ->
  type: \foot-note
  @from-node = ([_, id]) -> new FootNoteReference id
  repr: (n) -> "FootNoteReference(#{@id})"

export class FootNoteText extends Token
  (@id, @value) ->
  type: \foot-note-text
  @from-node = ([_, id, text]) -> new FootNoteText id, (resolve-node text)
  repr: (n) -> "FootNoteText(#{@value.repr n + 2})"

export class EntityLink extends Token
  (@value) ->
  type: \entity-link
  @from-node = ([_, a]) -> new EntityLink (resolve-node a)
  repr: (n) -> "EntityLink(#{@value.repr n + 2})"

export class Emphasis extends Token
  (@value) ->
  type: \emphasis
  @from-node = ([_, a]) -> new Emphasis a
  repr: (n) -> "Emphasis(#{repr-text n, @value})"

export class Italic extends Token
  (@value) ->
  type: \italic
  @from-node = ([_, a]) -> new Italic a
  repr: (n) -> "Italic(#{repr-text n, @value})"

export class Strike extends Token
  (@value) ->
  type: \strike
  @from-node = ([_, a]) -> new Strike a
  repr: (n) -> "Strike(#{repr-text n, @value})"

export class Literal extends Token
  (@value) ->
  type: \literal
  @from-node = ([_, a]) -> new Literal a
  repr: (n) -> "Literal(#{JSON.stringify @value})"
