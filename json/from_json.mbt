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
pub(all) suberror JsonDecodeError (JsonPath, String) derive(Eq, Show, ToJson)

///|
/// Trait for types that can be converted from `Json`
pub(open) trait FromJson {
  from_json(Json, JsonPath) -> Self raise JsonDecodeError
}

///|
pub fn[T : FromJson] from_json(
  json : Json,
  path~ : JsonPath = Root,
) -> T raise JsonDecodeError {
  FromJson::from_json(json, path)
}

///|
fn[T] decode_error(path : JsonPath, msg : String) -> T raise JsonDecodeError {
  raise JsonDecodeError((path, msg))
}

///|
pub impl FromJson for Bool with from_json(json, path) {
  match json {
    true => true
    false => false
    _ => decode_error(path, "Bool::from_json: expected boolean")
  }
}

///|
pub impl FromJson for Int with from_json(json, path) {
  guard json is Number(n, ..) &&
    n != @double.infinity &&
    n != @double.neg_infinity else {
    decode_error(path, "Int::from_json: expected number")
  }
  n.to_int()
}

///|
pub impl FromJson for Int64 with from_json(json, path) {
  guard json is String(str) else {
    decode_error(
      path, "Int64::from_json: expected number in string representation",
    )
  }
  @strconv.parse_int64(str) catch {
    error => decode_error(path, "Int64::from_json: parsing failure \{error}")
  }
}

///|
pub impl FromJson for UInt with from_json(json, path) {
  guard json is Number(n, ..) &&
    n != @double.infinity &&
    n != @double.neg_infinity else {
    decode_error(path, "UInt::from_json: expected number")
  }
  n.to_uint()
}

///|
pub impl FromJson for UInt64 with from_json(json, path) {
  guard json is String(str) else {
    decode_error(
      path, "UInt64::from_json: expected number in string representation",
    )
  }
  @strconv.parse_uint64(str) catch {
    error => decode_error(path, "UInt64::from_json: parsing failure \{error}")
  }
}

///|
pub impl FromJson for Double with from_json(json, path) {
  guard json is Number(n, ..) &&
    n != @double.infinity &&
    n != @double.neg_infinity else {
    decode_error(path, "Double::from_json: expected number")
  }
  n
}

///|
pub impl FromJson for String with from_json(json, path) {
  guard json is String(a) else {
    decode_error(path, "String::from_json: expected string")
  }
  a
}

///|
pub impl FromJson for @string.View with from_json(json, path) {
  guard json is String(a) else {
    decode_error(path, "View::from_json: expected string")
  }
  a[:]
}

///|
pub impl FromJson for Char with from_json(json, path) {
  guard json is String(a) else {
    decode_error(path, "Char::from_json: expected string")
  }
  let len = a.length()
  if len == 1 {
    a.unsafe_charcode_at(0).unsafe_to_char()
  } else if len == 2 {
    let c1 = a.unsafe_charcode_at(0)
    let c2 = a.unsafe_charcode_at(1)
    if c1 is (0xD800..=0xDBFF) && c2 is (0xDC00..=0xDFFF) {
      let c3 = (c1 << 10) + c2 - 0x35fdc00
      c3.unsafe_to_char()
    } else {
      decode_error(path, "Char::from_json: invalid surrogate pair")
    }
  } else {
    decode_error(path, "Char::from_json: expected single character")
  }
}

///|
pub impl[X : FromJson] FromJson for Array[X] with from_json(json, path) {
  guard json is Array(a) else {
    decode_error(path, "Array::from_json: expected array")
  }
  guard Index(path, index=0) is (Index(_) as new_path)
  a.mapi((i, x) => {
    new_path.index = i
    FromJson::from_json(x, new_path)
  })
}

///|
pub impl[X : FromJson] FromJson for FixedArray[X] with from_json(json, path) {
  guard json is Array(a) else {
    decode_error(path, "FixedArray::from_json: expected array")
  }
  let len = a.length()
  if len == 0 {
    return []
  }
  guard Index(path, index=0) is (Index(_) as new_path)
  let res = FixedArray::make(
    len,
    FromJson::from_json(a.unsafe_get(0), new_path),
  )
  for i in 1..<len {
    new_path.index = i
    res[i] = FromJson::from_json(a.unsafe_get(i), new_path)
  }
  res
}

///|
pub impl[V : FromJson] FromJson for Map[String, V] with from_json(json, path) {
  // Note in theory, we can make it more general like
  // Map[K : FromString, V : FromJson]
  // but currently we don't have FromString 
  // Here ToJson we have 
  // Map[K : Show, V : ToJson]
  guard json is Object(obj) else {
    decode_error(path, "Map::from_json: expected object")
  }
  let res = {}
  guard Key(path, key="") is (Key(_) as new_path)
  // Map::map_with_key
  for k, v in obj {
    new_path.key = k
    res[k] = FromJson::from_json(v, new_path)
  }
  res
}

///|
pub impl[T : FromJson] FromJson for T? with from_json(json, path) {
  match json {
    Null => None
    Array([value]) => Some(FromJson::from_json(value, path.add_index(0)))
    _ => decode_error(path, "Option::from_json: expected array or null")
  }
}

///|
pub impl[Ok : FromJson, Err : FromJson] FromJson for Result[Ok, Err] with from_json(
  json,
  path,
) {
  guard json is Object(obj) else {
    decode_error(path, "Result::from_json: expected object")
  }
  if obj.size() != 1 {
    decode_error(path, "Result::from_json: expected object with one field")
  }
  match obj {
    { "Ok": ok, .. } => Ok(FromJson::from_json(ok, path.add_key("Ok")))
    { "Err": err, .. } => Err(FromJson::from_json(err, path.add_key("Err")))
    _ =>
      decode_error(
        path, "Result::from_json: expected object with Ok or Err field",
      )
  }
}

///|
pub impl FromJson for Unit with from_json(json, path) {
  guard json is Null else {
    decode_error(path, "Unit::from_json: expected null")
  }
}

///|
pub impl FromJson for JsonValue with from_json(json, _path) {
  json
}
