-- SPDX-FileCopyrightText: 2020 Serokell
--
-- SPDX-License-Identifier: MPL-2.0

-- | Symmetric authenticated encryption.
--
-- It is best to import this module qualified:
--
-- @
-- import qualified Crypto.Secretbox as Secretbox
--
-- encrypted = Secretbox.'create' key nonce message
-- decrypted = Secretbox.'open' key nonce encrypted
-- @
--
-- This is @crypto_secretbox_*@ from NaCl.
module Crypto.Secretbox
  ( Key
  , toKey

  , Nonce
  , toNonce

  , create
  , open
  ) where

import Data.ByteArray (ByteArray, ByteArrayAccess)
import System.IO.Unsafe (unsafeDupablePerformIO)

import Crypto.Secretbox.Internal (Key, Nonce, toKey, toNonce)

import qualified Crypto.Secretbox.Internal as I


-- | Encrypt a message.
--
-- @
-- encrypted = Secretbox.create key nonce message
-- @
--
-- *   @key@ is the secret key used for encryption. There are two typical ways
--     of creating it:
--
--     1. /Derive from a password/. If you want to protect a message with a password,
--     you must use a
--     <https://en.wikipedia.org/wiki/Key_derivation_function key derivation function>
--     to turn this password into an encryption key.
--
--     2. /Generate a random one/. This can be useful in certain situations when
--     you want to have an intermediate key that you will encrypt and share
--     later.
--
--     The @Crypto.Key@ module in
--     <https://hackage.haskell.org/package/crypto-sodium crypto-sodium>
--     has functions to help in either case.
--
-- *   @nonce@ is an extra noise that ensures that if you encrypt the same
--     message with the same key multiple times, you will get different ciphertexts,
--     which is required for
--     <https://en.wikipedia.org/wiki/Semantic_security semantic security>.
--     There are two standard ways of getting it:
--
--     1. /Use a counter/. In this case you keep a counter of encrypted messages,
--     which means that the nonce will be new for each new message.
--
--     2. /Random/. You generate a random nonce every time you encrypt a message.
--     Since the nonce is large enough, the chances of you using the same
--     nonce twice are negligible. For useful helpers, see @Crypto.Random@,
--     in <https://hackage.haskell.org/package/crypto-sodium crypto-sodium>.
--
-- *   @message@ is the data you are encrypting.
--
-- This function adds authentication data, so if anyone modifies the cyphertext,
-- @open@ will refuse to decrypt it.
create
  ::  ( ByteArrayAccess keyBytes, ByteArrayAccess nonceBytes
      , ByteArrayAccess ptBytes, ByteArray ctBytes
      )
  => Key keyBytes  -- ^ Secret key
  -> Nonce nonceBytes  -- ^ Nonce
  -> ptBytes -- ^ Plaintext message
  -> ctBytes
create key nonce msg =
  -- This IO is safe, because it is pure.
  unsafeDupablePerformIO $ I.create key nonce msg


-- | Decrypt a message.
--
-- @
-- decrypted = Secretbox.open key nonce encrypted
-- @
--
-- * @key@ and @nonce@ are the same that were used for encryption.
-- * @encrypted@ is the output of 'create'.
--
-- This function will return @Nothing@ if the encrypted message was tampered
-- with after it was encrypted.
open
  ::  ( ByteArrayAccess keyBytes, ByteArrayAccess nonceBytes
      , ByteArray ptBytes, ByteArrayAccess ctBytes
      )
  => Key keyBytes  -- ^ Secret key
  -> Nonce nonceBytes  -- ^ Nonce
  -> ctBytes -- ^ Encrypted message (cyphertext)
  -> Maybe ptBytes
open key nonce ct =
  -- This IO is safe, because it is pure.
  unsafeDupablePerformIO $ I.open key nonce ct
