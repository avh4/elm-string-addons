module TestRunner (..) where

import String.Addons exposing (..)
import String exposing (uncons, fromChar, toUpper)
import Check exposing (Claim, Evidence, suite, claim, that, is, for, true, false, quickCheck)
import Check.Producer exposing (string, list, tuple, filter, rangeInt, tuple4)
import Check.Test
import ElmTest
import Debug


toUpperFirstClaims : Claim
toUpperFirstClaims =
  suite
    "toUpperFirst"
    [ claim
        "It only converts to uppercase the first char in the string"
        `that` (\string -> uncons (toUpperFirst string) |> Maybe.map fst |> Maybe.map fromChar |> Maybe.withDefault "")
        `is` (\string -> uncons string |> Maybe.map fst |> Maybe.map fromChar |> Maybe.map toUpper |> Maybe.withDefault "")
        `for` string
    , claim
        "The tail of the stirng remains untouched"
        `that` (\string -> uncons (toUpperFirst string) |> Maybe.map snd |> Maybe.withDefault "")
        `is` (\string -> uncons string |> Maybe.map snd |> Maybe.withDefault "")
        `for` string
    ]


toUpperWordsClaims : Claim
toUpperWordsClaims =
  suite
    "toUpperWords"
    [ claim
        "It converts the first letter of each word to uppercase"
        `that` (\arg -> arg |> String.join " " |> toUpperWords |> String.words)
        `is` (\arg -> arg |> String.join " " |> String.words |> List.map toUpperFirst)
        `for` list string
    , claim
        "It does not change the length of the string"
        `that` (\arg -> arg |> String.join " " |> toUpperWords |> String.length)
        `is` (\arg -> arg |> String.join " " |> String.length)
        `for` list string
    ]


replaceClaims : Claim
replaceClaims =
  suite
    "replace"
    [ claim
        "It substitues all occurences of the same sequence"
        `that` (\( string, substitute ) -> replace string substitute string)
        `is` (\( string, substitute ) -> substitute)
        `for` tuple ( string, string )
    , claim
        "It substitutes multiple occurances"
        `false` (\string -> replace "a" "b" string |> String.contains "a")
        `for` filter (\arg -> String.contains "a" arg) string
    , claim
        "It accepts special characters"
        `true` (\string -> replace "\\" "bbbbb" string |> String.contains "bbbb")
        `for` filter (\arg -> String.contains "\\" arg) string
    ]


replaceSliceClaims : Claim
replaceSliceClaims =
  suite
    "replace"
    [ claim
        "Result contains the substitution string"
        `true` (\( string, sub, start, end ) ->
                  replaceSlice sub start end string |> String.contains sub
               )
        `for` replaceSliceProducer
    , claim
        "Result string has the length of the substitution + string after removing the slice"
        `that` (\( string, sub, start, end ) ->
                  replaceSlice sub start end string |> String.length
               )
        `is` (\( string, sub, start, end ) ->
                (String.length string - (end - start)) + (String.length sub)
             )
        `for` replaceSliceProducer
    , claim
        "Start of the original string remains the same"
        `that` (\( string, sub, start, end ) ->
                  replaceSlice sub start end string |> String.slice 0 start
               )
        `is` (\( string, _, start, _ ) ->
                String.slice 0 start string
             )
        `for` replaceSliceProducer
    , claim
        "End of the original string remains the same"
        `that` (\( string, sub, start, end ) ->
                  let
                    replaced =
                      replaceSlice sub start end string
                  in
                    replaced |> String.slice (start + (String.length sub)) (String.length replaced)
               )
        `is` (\( string, _, _, end ) ->
                String.slice end (String.length string) string
             )
        `for` replaceSliceProducer
    ]


replaceSliceProducer =
  filter
    (\( string, sub, start, end ) ->
      (start < end)
        && (String.length string >= end)
        && (not <| String.isEmpty sub)
    )
    (tuple4
      ( string, string, (rangeInt 0 10), (rangeInt 0 10) )
    )


evidence : Evidence
evidence =
  suite
    "String.Addons"
    [ toUpperFirstClaims
    , toUpperWordsClaims
    , replaceClaims
    , replaceSliceClaims
    ]
    |> quickCheck


main =
  ElmTest.elementRunner (Check.Test.evidenceToTest evidence)
