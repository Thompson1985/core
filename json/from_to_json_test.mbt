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
enum Expr {
  Add(Expr, Expr)
  Sub(Expr, Expr)
  Mul(Expr, Expr)
  Div(Expr, Expr)
  Val(String)
} derive(ToJson, FromJson, Show, Eq)

///|
test {
  let e = Expr::Add(Val("x"), Val("y"))
  let ej = e.to_json()
  inspect(
    ej.stringify(),
    content=(
      #|{"$tag":"Add","0":{"$tag":"Val","0":"x"},"1":{"$tag":"Val","0":"y"}}
    ),
  )
  let e0 : Expr = @json.from_json(ej)
  inspect(
    e0,
    content=(
      #|Add(Val("x"), Val("y"))
    ),
  )
  assert_eq(e0, e)
}
