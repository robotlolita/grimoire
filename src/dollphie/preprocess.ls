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

split-comments = (c) -> (a) ->
  a.split /\r?\n/
   .map (l) ->
     | /^\s*$/.test l    => [\blank]
     | l `starts-with` c => [\text nuke-comments c, l]
     | otherwise         => [\code l]

export languages = do
                   * Dollphie:
                       extensions: <[ .doll ]>
                       processor: plain
              
                   * C:
                       extensions: <[ .c .h ]>
                       pygments-lexer: \c
                       processor: split-comments '//'
              
                   * 'C#':
                       extensions: <[ .cs ]>
                       pygments-lexer: \csharp
                       processor: split-comments '//'
              
                   * 'C++':
                       extensions: <[ .cpp .hpp .c++ .h++ .cc .hh .cxx .hxx ]>
                       pygments-lexer: \cpp
                       processor: split-comments '//'
              
                   * Clojure:
                       extension: <[ .clj .cljs ]>
                       pygments-lexer: \clojure
                       processor: split-comments ';;'
                       
                   * CoffeeScript:
                       extensions: <[ .coffee Cakefile ]>
                       pygments-lexer: \coffee-script
                       processor: split-comments '#'
              
                   * Go:
                       extensions: <[ .go ]>
                       pygments-lexer: \go
                       processor: split-comments '//'
              
                   * Haskell:
                       extensions: <[ .hs ]>
                       pygments-lexer: \haskell
                       processor: split-comments '--'
              
                   * Java:
                       extensions: <[ .java ]>
                       pygments-lexer: \java
                       processor: split-comments '//'
              
                   * JavaScript:
                       extensions: <[ .js ]>
                       pygments-lexer: \javascript
                       processor: split-comments '//'
              
                   * LiveScript:
                       extensions: <[ .ls Slakefile ]>
                       pygments-lexer: \livescript
                       processor: split-comments '#'
              
                   * Lua:
                       extensions: <[ .lua ]>
                       pygments-lexer: \lua
                       processor: split-comments '--'
              
                   * Make:
                       extensions: <[ Makefile ]>
                       pygments-lexer: \make
                       processor: split-comments '#'
              
                   * 'Objective-C':
                       extensions: <[ .m .nm ]>
                       pygments-lexer: \objc
                       processor: split-comments '//'
              
                   * Perl:
                       extensions: <[ .pl .pm ]>
                       pygments-lexer: \perl
                       processor: split-comments '#'
              
                   * PHP:
                       extensions: <[ .php .phpd .fbp ]>
                       pygments-lexer: \php
                       processor: split-comments '//'
              
                   * Puppet:
                       extensions: <[ .pp ]>
                       pygments-lexer: \puppet
                       processor: split-comments '#'
              
                   * Python:
                       extensions: <[ .py ]>
                       pygments-lexer: \python
                       processor: split-comments '#'
              
                   * Ruby:
                       extensions: <[ .rb .ru .gemspec ]>
                       pygments-lexer: \ruby
                       processor: split-comments '#'
              
                   * Shell:
                       extensions: <[ .sh ]>
                       pygments-lexer: \sh
                       processor: split-comments '#'

