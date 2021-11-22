-- SPDX-FileCopyrightText: 2021 Serokell
--
-- SPDX-License-Identifier: MPL-2.0

{-# LANGUAGE ExplicitNamespaces, TypeOperators, TypeFamilies #-}

-- | Hashing.
--
-- It is best to import this module qualified:
--
-- @
-- import qualified Crypto.Hash as Hash
--
-- hash_blake2b256_keyed = Hash.'blake2bWithKey' @32 key message
-- hash_blake2b256 = Hash.'blake2b' @32 message
-- hash_blake2b512 = Hash.'blake2b' @64 message
-- @
--
-- This is @crypto_generichash_*@ from NaCl.
module Crypto.Hash
  ( I.HashBlake2b
  , blake2b
  , blake2bWithKey
  ) where

import Data.ByteArray (ByteArray, ByteArrayAccess, Bytes)
import GHC.TypeNats (KnownNat, type (<=))
import System.IO.Unsafe (unsafePerformIO)

import qualified Crypto.Hash.Internal as I
import qualified Libsodium as Na

-- | Hash a message using BLAKE2b.
--
-- @
-- hash128 = Hash.'blake2b' @16 message
-- hash256 = Hash.'blake2b' @32 message
-- hash512 = Hash.'blake2b' @64 message
-- @
--
-- *   @message@ is the data you are hashing.
blake2b
  ::  forall len hashBytes pt.
      ( ByteArrayAccess pt
      , ByteArray hashBytes
      , KnownNat len
      , Na.CRYPTO_GENERICHASH_BYTES_MIN <= len
      , len <= Na.CRYPTO_GENERICHASH_BYTES_MAX
      )
  => pt  -- ^ Message to hash
  -> I.HashBlake2b len hashBytes
blake2b msg = unsafePerformIO $ I.blake2b (Nothing :: Maybe Bytes) msg

-- | Hash a message using BLAKE2b with a key.
--
-- @
-- hash128_keyed = Hash.'blake2bWithKey' @16 key message
-- hash256_keyed = Hash.'blake2bWithKey' @32 key message
-- hash512_keyed = Hash.'blake2bWithKey' @64 key message
-- @
--
-- *   @key@ is the BLAKE2b key.
-- *   @message@ is the data you are hashing.
blake2bWithKey
  ::  forall len hashBytes pt key.
      ( ByteArrayAccess pt
      , ByteArrayAccess key
      , ByteArray hashBytes
      , KnownNat len
      , Na.CRYPTO_GENERICHASH_BYTES_MIN <= len
      , len <= Na.CRYPTO_GENERICHASH_BYTES_MAX
      )
  => key -- ^ Hash key
  -> pt  -- ^ Message to hash
  -> I.HashBlake2b len hashBytes
blake2bWithKey key msg = unsafePerformIO $ I.blake2b (Just key) msg
