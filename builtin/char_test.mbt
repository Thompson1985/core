// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
enum H {
  A(Char)
} derive(Show)

///|
test "char nested" {
  inspect(H::A('中'), content="A('中')")
  inspect(H::A('\b'), content="A('\\b')")
  inspect(H::A('\r'), content="A('\\r')")
  inspect(H::A('\n'), content="A('\\n')")
  inspect(H::A('\t'), content="A('\\t')")
  inspect(H::A('\u0000'), content="A('\\u{00}')")
  inspect(H::A('\u0001'), content="A('\\u{01}')")
  inspect(H::A('\u0002'), content="A('\\u{02}')")
  // emoji
  inspect(H::A('🚀'), content="A('🚀')")
}

///|
test "char show" {
  assert_eq('\b'.to_string(), "\u0008")
  assert_eq('\b'.to_string(), "\u{8}")
  inspect('\b', content="\u{8}")
  assert_eq('\r'.to_string(), "\u000d")
  inspect('\r', content="\u{d}")
  assert_eq('\n'.to_string(), "\u000a")
  inspect('\n', content="\u{a}")
  assert_eq('\t'.to_string(), "\u0009")
  inspect('\t', content="\u{9}")
  assert_eq('\u0000'.to_string(), "\u0000")
  assert_eq('\u0001'.to_string(), "\u0001")
  assert_eq('\u0002'.to_string(), "\u0002")
  assert_eq('\b'.to_string().escape(), "\"\\b\"")
  inspect('中', content="中")
}
