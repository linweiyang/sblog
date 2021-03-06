{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Views.Bookmark(
  renderIndex
  ,renderBookmark
)where

import Control.Monad
import qualified Data.Text as T
import qualified Data.Text.Lazy as LT
import Data.String (fromString)
import Data.Int
import Data.Time (UTCTime,LocalTime,localTimeToUTC,utc,formatTime,defaultTimeLocale)

import Network.URI

import Text.Blaze.Html5((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import qualified Utils.BlazeExtra.Attributes as EA
import Text.Blaze.Html.Renderer.Text

import Views.Common.Widgets
import Views.Common.SEO
import Views.Common.Recommand
import qualified Views.Layout as VL

import Utils.BlazeExtra.Pagination as Pagination
import Utils.URI.String
import Utils.URI.Params

import qualified Models.DB.Schema as M

renderBookmark :: String -> String  -> [(String,String)] -> Bool
  -> [(String,String)]  -> M.Bookmark -> LT.Text
renderBookmark host name prevs canon rcs br =
    VL.renderMain title [seo] [render]
  where
    time = localTimeToUTC utc $ M.bookmarkUpdatedAt br
    olink = A.href (H.toValue $ showURI
      $ updateUrlParams (utmParams host name) (toURI $ M.bookmarkUrl br))
    seo = do
      openGraph title (show fullURL) (M.bookmarkTitle br)
      keywordsAndDescription (showTags $ M.bookmarkTags br) (M.bookmarkTitle br)
      when canon $ canonical (show fullURL)
    title = (M.bookmarkTitle br) ++ "-" ++ name
    fullURL =
      relativeTo (toURI $ "/bookmarks/" ++ (show $ M.bookmarkID br)) (toURI host)
    render =
      H.div $ do
        H.div ! A.class_ "ui main text container" $ do
          breadcrumb prevs (M.bookmarkTitle br)
          H.h1 ! A.class_ "ui header" $ do
            H.div ! A.class_ "ui small right floated primary basic button" $
              H.a ! A.target "_blank" ! (gaEvent "Read Bookmark" title) !  olink $ "原文"
            H.toHtml (M.bookmarkTitle br)
          H.p $ H.toHtml ("发布于：" ++ (formatTime defaultTimeLocale "%Y/%m/%d" time))
        H.div ! A.class_ "ui basic right attached fixed  launch button" $ do
          H.div ! A.class_ "-mob-share-ui-button -mob-share-open" $ "分享"
          H.script ! A.type_ "text/javascript" ! A.id "-mob-share"
                ! A.src "https://f1.webshare.mob.com/code/mob-share.js?appkey=1d704951d1a17" $ ""
        H.div ! A.class_ "ui article text container" $ do
          H.div ! A.class_ "-mob-share-ui" ! A.style "display: none" $ do
            H.ul ! A.class_ "-mob-share-list" $ do
              H.li ! A.class_ "-mob-share-weibo" $ H.p "新浪微博"
              H.li ! A.class_ "-mob-share-qzone" $ H.p "QQ空间"
              H.li ! A.class_ "-mob-share-qq" $ H.p "QQ好友"
              H.li ! A.class_ "-mob-share-facebook" $ H.p "Facebook"
              H.li ! A.class_ "-mob-share-twitter" $ H.p "Twitter"
              H.div ! A.class_ "-mob-share-close" $ "取消"
          H.script ! A.async "true" ! A.type_ "text/javascript"
            ! A.src "//pagead2.googlesyndication.com/pagead/js/adsbygoogle.js" $ ""
          H.ins ! A.class_ "adsbygoogle" ! A.style "display:block; text-align:center;"
            ! H.customAttribute "data-ad-client" "ca-pub-7356196370921219"
            ! H.customAttribute "data-ad-slot"  "8705224210"
            ! H.customAttribute "data-ad-layout" "in-article"
            ! H.customAttribute "data-ad-format" "fluid" $ ""
          H.script ! A.type_ "text/javascript"  $ "(adsbygoogle = window.adsbygoogle || []).push({});"
          H.div ! A.class_ "markdown-body" $ do
            H.preEscapedToHtml  (M.bookmarkSummary br)
            H.p $ ""
            H.div $ do
              renderRecommand rcs
              H.h5 ! A.class_ "ui block header" $ do
                H.p $
                  H.a ! A.href  (H.toValue $ show fullURL) $
                    H.toHtml $ "文章连接："  ++ (show fullURL)
                H.toHtml $ "欢迎转载，著作权归" ++ name ++ "所有"

renderIndex :: String -> String -> (Maybe T.Text) -> Int64 ->
  Pagination -> [M.Tag] -> Bool -> [M.Bookmark] -> LT.Text
renderIndex host name tag tid pn ts canon brs =
    VL.render 3 title [renderCanonical] [(sidebar base tid ts)] [render]
  where
    title = case tag of
      Nothing -> "书签-" ++ name
      Just t -> (T.unpack t) ++ "相关的书签-" ++ name
    base =
      case tag of
        Nothing -> toURI "/bookmarks"
        Just t -> updateUrlParam  "tag" (T.unpack t) $ toURI  "/bookmarks"
    fullURL =
      relativeTo (toURI "/articles") (toURI host)
    renderCanonical = when canon $ canonical (show fullURL)
    render =
      H.div $ do
        renderBookmarks
        Pagination.render base pn
    renderBookmarks =
      if length brs == 0
        then H.span ""
        else
          H.div ! A.class_ "ui segments" $
            mapM_ (segmentBookmark host name tag) brs
