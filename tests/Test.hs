{-# LANGUAGE RankNTypes #-}
module Main
  ( main
  ) where

import           Control.Applicative
import qualified Data.ByteString as B
import qualified Data.ByteString.Char8 as C8
import qualified Data.ByteString.Lazy as LB
import qualified Data.Map as Map
import           Data.String
import qualified Data.Vector as V
import           Data.Word ( Word32 )
import qualified System.IO as IO
import qualified Test.Tasty as T
import qualified Test.Tasty.HUnit as T
import qualified Test.Tasty.QuickCheck as T

import           Prelude

import           Data.ElfEdit

testEmptyElf :: T.Assertion
testEmptyElf = IO.withBinaryFile "./tests/empty.elf" IO.ReadMode $ \h -> do
  fil <- B.hGetContents h
  case parseElf fil of
    ElfHeaderError{} -> return ()
    _ -> T.assertFailure "Empty ELF did not cause an exception."

testIdentityTransform :: FilePath -> T.Assertion
testIdentityTransform fp = do
  bs <- B.readFile fp
  withElf bs $ \e -> do
    int0 <- elfInterpreter e
    withElf (LB.toStrict (renderElf e)) $ \e' -> do
      T.assertEqual "Segment Count" (length (elfSegments e)) (length (elfSegments e'))
      withElf bs $ \ehi -> do
        withElf (LB.toStrict (renderElf e)) $ \ehi' -> do
          let [st1] = elfSymtab ehi
              [st2] = elfSymtab ehi'
          let cnt1 = V.length (elfSymbolTableEntries st1)
          let cnt2 = V.length (elfSymbolTableEntries st2)
          T.assertEqual "Symbol table sizes" cnt1 cnt2
      int1 <- elfInterpreter e'
      T.assertEqual "Interpreter" int0 int1

stringTableConsistencyProp :: [AsciiString] -> Bool
stringTableConsistencyProp strings =
  all (checkStringTableEntry bytes) (Map.toList tab)
  where
    (bytes, tab) = stringTable (map unwrapAsciiString strings)

checkStringTableEntry :: C8.ByteString -> (B.ByteString, Word32) -> Bool
checkStringTableEntry bytes (str, off) = str == bstr
  where
    bstr = C8.take (B.length str) $ C8.drop (fromIntegral off) bytes

withElf :: B.ByteString -> (forall w . Elf w -> T.Assertion) -> T.Assertion
withElf bs f =
  case parseElf bs of
    Elf32Res err e32
      | null err  -> f e32
      | otherwise -> T.assertFailure ("Failed to parse elf file: " ++ show err)
    Elf64Res err e64
      | null err  -> f e64
      | otherwise -> T.assertFailure ("Failed to parse elf file: " ++ show err)
    ElfHeaderError _ e -> T.assertFailure $ "Failed to parse elf file: " ++ show e

tests :: T.TestTree
tests = T.testGroup "ELF Tests"
    [ T.testCase "Empty ELF" testEmptyElf
    , T.testCase "Identity Transformation (simple static)" (testIdentityTransform "./tests/simple.static.elf")
    , T.testCase "Identity Transformation (simple)" (testIdentityTransform "./tests/simple.elf")
    , T.testCase "Zero-sized BSS" (testIdentityTransform "./tests/zero-physical-bss.elf")
    , T.testProperty "stringTable consistency" stringTableConsistencyProp
    ]

main :: IO ()
main = T.defaultMain tests

newtype AsciiString = AsciiString { unwrapAsciiString :: B.ByteString }
                    deriving (Show)

instance T.Arbitrary AsciiString where
  arbitrary = AsciiString . fromString <$> genAsciiString

genAsciiString :: T.Gen String
genAsciiString = T.listOf genAsciiChar

genAsciiChar :: T.Gen Char
genAsciiChar = T.elements (['a'..'z'] ++ ['A'..'Z'])
