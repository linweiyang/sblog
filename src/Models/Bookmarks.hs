{-# LANGUAGE OverloadedStrings #-}

module Models.Bookmarks where

import Control.Applicative
import Control.Monad

import Data.Maybe
import Data.Int

import Database.PostgreSQL.Simple
import Database.PostgreSQL.Simple.FromField
import Database.PostgreSQL.Simple.ToField
import Database.PostgreSQL.Simple.FromRow
import App.Types
import Models.DB.Schema

import qualified Models.Tags as Tags


digest c (bid,title,summary,url,createdAt,updatedAt) = do
  tags <- Tags.fetchRelatedTags bid 1 c
  return $ Bookmark bid title summary url createdAt updatedAt tags

fetchBookmarks ::  Int -> Int -> Connection -> IO [Bookmark]
fetchBookmarks page count c = do
  let offset = (page - 1) * count
  rs <- query c "SELECT id,title,summary,url,created_at,updated_at FROM bookmarks \
    \ ORDER BY id DESC OFFSET ? LIMIT ?" (offset,count)
  mapM (digest c) rs

fetchBookmark :: Int -> Connection -> IO Bookmark
fetchBookmark bid c = do
  rs <- query c "SELECT id,title,summary,url,created_at,updated_at FROM bookmarks \
  \ WHERE id = ?" (Only bid)
  head $ map (digest c) rs

addBookmark :: String -> String -> String -> [String] -> Connection-> IO Int64
addBookmark title url summary tags c = do
  tagsID <- mapM (flip Tags.findOrAddTag c) tags
  rs <- query c "INSERT INTO bookmarks (title,summary,url) \
    \ VALUES (?,?,?) RETURNING id" (title,summary,url)
  let tid =  fromOnly $ head  rs
  Tags.addTaggings tid 1 tagsID c
  return $ fromOnly $ head rs

removeBookmark :: Int64 -> Connection -> IO Int64
removeBookmark bid c = do
  Tags.removeTaggings bid 1 c
  execute c "DELETE FROM bookmarks WHERE id = ?" (Only bid)

fetchBookmarksCount :: Connection -> IO Int64
fetchBookmarksCount c = do
  rs <- query_ c "SELECT count(id) FROM bookmarks"
  return $ fromOnly $ head rs
