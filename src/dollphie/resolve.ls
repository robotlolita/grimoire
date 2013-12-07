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
but-last = require 'data.array/common/but-last'
last = require 'data.array/common/last'
poly = require 'polygamous'
 
export resolve-ast = (ast, meta-processor) ->
  return result (`ast~reduce` make-initial-state!) (st, a) -> switch a.type
    | \section     => push-into st, Section.from-node a
    | \declaration => push-into st, Declaration.from-node a
    | \meta        => associate-meta st, a, meta-processor
    | otherwise    => associate-text st, a

  function make-initial-state
    context  : null
    stack    : []
    entities : []
    document : []

  function result(a)
    entities: a.entities
    document: a.document
  


push-state = (st, a) -->
  if st.context => st.stack.push st.context
  st.context := a
  st

pop-state = (st) ->
  st.context := st.stack.pop!
  st

push-into = (st, a) -->
  | not st.context              => push-state st, a
  | st.context.depth < a.depth  => push-state st, (st.context.destructive-add a)
  | st.context.depth >= a.depth => push-into (pop-state st), a
  |> (st2) -> do
              st2.entities.push a
              st2.document.push a
              st2

associate-meta = (st, a, meta-processor) ->
  | st.context => do
                  st.context.destructive-associate a, meta-processor
                  st.document.push a
                  st
  | otherwise  => do
                  st.entities.push a
                  st.document.push a
                  st

associate-text = (st, a) ->
  | st.context => do
                  st.context.destructive-add-text a
                  st.document.push a
                  st
  | otherwise  => do
                  st.entities.push a
                  st.document.push a
                  st

export process-meta = poly (a, entity) -> a.kind.value
process-meta.when \code (a, entity) -> entity.destructive-add-code a
process-meta.fallback (a, entity) -> entity.meta[a.kind.value] = a

qualified-id-to-uri = (id) ->
  id.values.map (.value) .join '/'

export class Entity
  ({ id, name, depth }) ->
    @id         = id
    @depth      = depth
    @name       = name
    @text       = []
    @code       = []
    @meta       = {}
    @children   = []
    @parent     = null

  destructive-add: (a) ->
    a.parent = this
    @children.push a
    a

  destructive-associate: (a, meta-processor) ->
    meta-processor a, this
    @destructive-add-text a

  destructive-add-text: (a) ->
    @text.push a
    this

  destructive-add-code: (a) ->
    @code.push a
    this
    

#  to-json: -> ({} <<<< this) <<< parent: @parent.id 

export class Section extends Entity
  @from-node = (a) -> new Section do
                                  id    : (slugify a.title).to-lower-case!
                                  name  : a.title
                                  depth : a.depth
    

export class Declaration extends Entity
  ({ id, name, kind, depth }) ->
    super { id, name, depth }
    @kind = kind

  @from-node = (a) -> new Declaration do
                                      id    : qualified-id-to-uri a.id
                                      kind  : a.kind
                                      name  : a.id.values[*-1].value
                                      depth : a.depth
