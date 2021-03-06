{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Views.Article(
  renderArticle
  ,renderIndex
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

renderArticle :: String -> String  -> [(String,String)]
  ->Bool -> [(String,String)]->M.Article  -> LT.Text
renderArticle host name prevs canon rcs ar =
    VL.renderMain title [seo] [render]
  where
    time = localTimeToUTC utc $ M.articleUpdatedAt ar
    seo = do
      openGraph title (show fullURL) (M.articleSummary ar)
      keywordsAndDescription (showTags $ M.articleTags ar) (M.articleSummary ar)
      when canon $ canonical (show fullURL)
    title = (M.articleTitle ar) ++ "-" ++ name
    fullURL =
      relativeTo (toURI $ "/articles/" ++ (show $ M.articleID ar)) (toURI host)
    render =
      H.div $ do
        H.div ! A.class_ "ui main text container" $ do
          breadcrumb prevs (M.articleTitle ar)
          H.h1 ! A.class_ "ui header" $ H.toHtml (M.articleTitle ar)
          H.p $ H.toHtml ("发布于：" ++ (formatTime defaultTimeLocale "%Y/%m/%d" time))
          H.div ! A.class_ "ui segment" $ H.toHtml (M.articleSummary ar)
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
            H.preEscapedToHtml (M.articleBody ar)
            H.p $ ""
            H.div $ do
              renderRecommand rcs
              H.h5 ! A.class_ "ui block header" $ do
                H.p $
                  H.a ! A.href  (H.toValue $ show fullURL) $
                    H.toHtml $ "文章连接："  ++ (show fullURL)
                H.toHtml $ "欢迎转载，著作权归" ++ name ++ "所有"

renderIndex :: String -> String -> (Maybe T.Text) -> Int64 ->
  Pagination -> [M.Tag] -> Bool -> [M.Article] -> LT.Text
renderIndex host name tag tid pn ts canon ars =
    VL.render 2 title [renderCanonical] [(sidebar base tid ts)] [render]
  where
    title = case tag of
      Nothing -> "文章-" ++ name
      Just t -> (T.unpack t) ++ "相关的文章-" ++ name
    base =
      case tag of
        Nothing -> toURI "/articles"
        Just t -> updateUrlParam  "tag" (T.unpack t) $ toURI  "/articles"
    fullURL =
          relativeTo (toURI "/articles") (toURI host)
    renderCanonical = when canon $ canonical (show fullURL)
    render =
      H.div $ do
        renderArticles
        Pagination.render base pn
    renderArticles =
      if length ars == 0
        then H.span ""
        else
          H.div ! A.class_ "ui segments" $
            mapM_ (segmentArticle tag) ars
