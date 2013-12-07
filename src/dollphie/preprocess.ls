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

last = require 'data.array/common/last'
but-last = require 'data.array/common/but-last'

plain = (a) -> [\text a]

sanitise-re = (a) -> a.replace /(\W)/g, '\\$1'

matches-re = (s, re) --> (new RegExp re).test s

starts-with = (s, a) --> s `matches-re` "^\s*#{sanitise-re a}"

nuke-comments = (c, s) --> s.replace (new RegExp "^\s*#{sanitise-re c}", \g), ''

split-comments = (lexer, c) --> (a) ->
  a.split /\r?\n/
   .map (l) ->
     | /^\s*$/.test l    => [\blank]
     | l `starts-with` c => [\text nuke-comments c, l]
     | otherwise         => [\code lexer, l]

export languages = do
                   * Dollphie:
                       extensions: <[ .doll ]>
                       processor: plain
              
                   * C:
                       extensions: <[ .c .h ]>
                       processor: split-comments \c '//'
              
                   * 'C#':
                       extensions: <[ .cs ]>
                       processor: split-comments \csharp '//'
              
                   * 'C++':
                       extensions: <[ .cpp .hpp .c++ .h++ .cc .hh .cxx .hxx ]>
                       processor: split-comments \cpp '//'
              
                   * Clojure:
                       extension: <[ .clj .cljs ]>
                       processor: split-comments \clojure ';;'
                       
                   * CoffeeScript:
                       extensions: <[ .coffee Cakefile ]>
                       processor: split-comments \coffee-script '#'
              
                   * Go:
                       extensions: <[ .go ]>
                       processor: split-comments \go '//'
              
                   * Haskell:
                       extensions: <[ .hs ]>
                       processor: split-comments \haskell '--'
              
                   * Java:
                       extensions: <[ .java ]>
                       processor: split-comments \java '//'
              
                   * JavaScript:
                       extensions: <[ .js ]>
                       processor: split-comments \javascript '//'
              
                   * LiveScript:
                       extensions: <[ .ls Slakefile ]>
                       processor: split-comments \livescript '#'
              
                   * Lua:
                       extensions: <[ .lua ]>
                       processor: split-comments \lua '--'
              
                   * Make:
                       extensions: <[ Makefile ]>
                       processor: split-comments \make '#'
              
                   * 'Objective-C':
                       extensions: <[ .m .nm ]>
                       processor: split-comments \objc '//'
              
                   * Perl:
                       extensions: <[ .pl .pm ]>
                       processor: split-comments \perl '#'
              
                   * PHP:
                       extensions: <[ .php .phpd .fbp ]>
                       processor: split-comments \php '//'
              
                   * Puppet:
                       extensions: <[ .pp ]>
                       processor: split-comments \puppet '#'
              
                   * Python:
                       extensions: <[ .py ]>
                       processor: split-comments \python '#'
              
                   * Ruby:
                       extensions: <[ .rb .ru .gemspec ]>
                       processor: split-comments \ruby '#'
              
                   * Shell:
                       extensions: <[ .sh ]>
                       processor: split-comments \sh '#'

