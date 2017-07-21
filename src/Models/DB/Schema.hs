{-# LANGUAGE OverloadedStrings #-}

module Models.DB.Schema where

import Data.Int
import qualified Data.Time as DT

data Tag = Tag {
  tid :: Int64
  ,name :: String
  ,count :: Int
} deriving (Show)

data Article = Article {
  aid :: Int64
  ,atitle :: String
  ,asummary :: String
  ,abody :: String
  ,amarkdown :: String
  ,apublished :: Bool
  ,acreatedAt ::  DT.LocalTime
  ,aupdatedAt :: DT.LocalTime
  ,atags :: [Tag]
} deriving (Show)

data Bookmark = Bookmark {
  bid :: Int64
  ,btitle :: String
  ,bsummary :: String
  ,bmarkdown :: String
  ,burl :: String
  ,bcreatedAt ::  DT.LocalTime
  ,bupdatedAt :: DT.LocalTime
  ,btags :: [Tag]
} deriving (Show)


defBookmark :: IO Bookmark
defBookmark = do
  utc <- DT.getCurrentTime
  let now = DT.utcToLocalTime DT.utc utc
  return $ Bookmark 0 "" "" "" "" now now []

defArticle :: IO Article
defArticle = do
  utc <- DT.getCurrentTime
  let now = DT.utcToLocalTime DT.utc utc
  return $ Article 0 "" "" "" "" False now now []
