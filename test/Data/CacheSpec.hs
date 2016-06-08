module Data.CacheSpec (main, spec) where

import Prelude hiding (lookup)

import Test.Hspec

import Control.Concurrent
import Control.Monad.IO.Class (liftIO)
import Data.Cache
import System.Clock

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
    it "should have a deletion/non-deletion variant" $ do
        c <- liftIO $ defCache Nothing
        _ <- liftIO $ expire defExpiration
        liftIO (size c)                  >>= (`shouldBe` 4)
        liftIO (lookup' (fst expired) c) >>= (`shouldBe` Nothing)
        liftIO (size c)                  >>= (`shouldBe` 4)
        liftIO (lookup  (fst expired) c) >>= (`shouldBe` Nothing)
        liftIO (size c)                  >>= (`shouldBe` 3)
    it "should work without a default expiration" $ do
        c <- liftIO $ defCache Nothing
        _ <- liftIO $ expire defExpiration
        liftIO (lookup' (fst notAvailable) c) >>= (`shouldBe` Nothing)
        liftIO (lookup' (fst ok)           c) >>= (`shouldBe` Just (snd ok))
        liftIO (lookup' (fst notExpired)   c) >>= (`shouldBe` Just (snd notExpired))
        liftIO (lookup' (fst expired)      c) >>= (`shouldBe` Nothing)
        liftIO (lookup' (fst autoExpired)  c) >>= (`shouldBe` Just (snd autoExpired))
    it "should work with a default expiration" $ do
        c <- liftIO $ defCache (Just defExpiration)
        _ <- liftIO $ expire defExpiration
        liftIO (lookup' (fst notAvailable) c) >>= (`shouldBe` Nothing)
        liftIO (lookup  (fst ok)           c) >>= (`shouldBe` Just (snd ok))
        liftIO (lookup' (fst expired)      c) >>= (`shouldBe` Nothing)
        liftIO (lookup' (fst autoExpired)  c) >>= (`shouldBe` Nothing)
    it "should delete items" $ do
        c <- liftIO $ defCache Nothing
        _ <- liftIO $ expire defExpiration
        liftIO (size c) >>= (`shouldBe` 4)
        _ <- liftIO $ delete (fst ok) c
        liftIO (size c) >>= (`shouldBe` 3)
        liftIO (lookup' (fst notAvailable) c) >>= (`shouldBe` Nothing)
        liftIO (lookup' (fst ok)           c) >>= (`shouldBe` Nothing)
        liftIO (lookup' (fst notExpired)   c) >>= (`shouldBe` Just (snd notExpired))
        liftIO (lookup' (fst expired)      c) >>= (`shouldBe` Nothing)
        liftIO (lookup' (fst autoExpired)  c) >>= (`shouldBe` Just (snd autoExpired))
    it "should copy" $ do
        c  <- liftIO $ defCache Nothing
        c' <- liftIO $ copyCache c
        _  <- liftIO $ delete (fst ok) c
        liftIO (lookup (fst ok) c ) >>= (`shouldBe` Nothing)
        liftIO (lookup (fst ok) c') >>= (`shouldBe` Just (snd ok))

defExpiration :: TimeSpec
defExpiration = 1000000

defNotExpired :: TimeSpec
defNotExpired = 1000000000

expire :: TimeSpec -> IO ()
expire = threadDelay . fromInteger . (`div` 1000) . (* 2) . toNanoSecs

expired :: (String, Int)
expired = ("expired", 1)

notExpired :: (String, Int)
notExpired = ("not expired", 5)

autoExpired :: (String, Int)
autoExpired = ("auto expired", 4)

notAvailable :: (String, Int)
notAvailable = ("not available", 2)

ok :: (String, Int)
ok = ("ok", 3)

defCache :: Maybe TimeSpec -> IO (Cache String Int)
defCache t = do
    c <- newCache t
    _ <- uncurry insert' ok         Nothing              c
    _ <- uncurry insert' expired    (Just defExpiration) c
    _ <- uncurry insert  autoExpired                     c
    _ <- uncurry insert' notExpired (Just defNotExpired) c
    return c
    