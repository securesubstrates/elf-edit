{-# LANGUAGE DataKinds #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE TypeFamilies #-}
module Data.ElfEdit.Relocations.I386
  ( I386_RelocationType(..)
  , pattern R_386_NONE
  , pattern R_386_32
  , pattern R_386_PC32
  , pattern R_386_GOT32
  , pattern R_386_PLT32
  , pattern R_386_COPY
  , pattern R_386_GLOB_DAT
  , pattern R_386_JMP_SLOT
  , pattern R_386_RELATIVE
  , pattern R_386_GOTOFF
  , pattern R_386_GOTPC
  ) where

import qualified Data.Map.Strict as Map
import           Data.Word (Word32)
import           Numeric (showHex)

import           Data.ElfEdit.Relocations

-- | Relocation types for 64-bit x86 code.
newtype I386_RelocationType = I386_RelocationType { fromI386_RelocationType :: Word32 }
  deriving (Eq,Ord)

pattern R_386_NONE     = I386_RelocationType  0
pattern R_386_32       = I386_RelocationType  1
pattern R_386_PC32     = I386_RelocationType  2
pattern R_386_GOT32    = I386_RelocationType  3
pattern R_386_PLT32    = I386_RelocationType  4
pattern R_386_COPY     = I386_RelocationType  5
pattern R_386_GLOB_DAT = I386_RelocationType  6
pattern R_386_JMP_SLOT = I386_RelocationType  7
pattern R_386_RELATIVE = I386_RelocationType  8
pattern R_386_GOTOFF   = I386_RelocationType  9
pattern R_386_GOTPC    = I386_RelocationType 10

i386_RelocationTypes :: Map.Map I386_RelocationType String
i386_RelocationTypes = Map.fromList
  [ (,) R_386_NONE     "R_386_NONE"
  , (,) R_386_32       "R_386_32"
  , (,) R_386_PC32     "R_386_PC32"
  , (,) R_386_GOT32    "R_386_GOT32"
  , (,) R_386_PLT32    "R_386_PLT32"
  , (,) R_386_COPY     "R_386_COPY"
  , (,) R_386_GLOB_DAT "R_386_GLOB_DAT"
  , (,) R_386_JMP_SLOT "R_386_JMP_SLOT"
  , (,) R_386_RELATIVE "R_386_RELATIVE"
  , (,) R_386_GOTOFF   "R_386_GOTOFF"
  , (,) R_386_GOTPC    "R_386_GOTPC"
  ]

instance Show I386_RelocationType where
  show i =
    case Map.lookup i i386_RelocationTypes of
      Just s -> s
      Nothing -> "0x" ++ showHex (fromI386_RelocationType i) ""

instance IsRelocationType I386_RelocationType where
  type RelocationWidth I386_RelocationType = 32
  relaWidth _ = Rela32
  relaType = Just . I386_RelocationType
  isRelative R_386_RELATIVE = True
  isRelative _ = False
