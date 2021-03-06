{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Views.Admin.Bookmark(
  renderWriter
  ,renderIndex
)where

import Control.Monad
import qualified Data.Text.Lazy as LT
import Data.String

import Network.URI

import Text.Blaze.Html5((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import qualified Utils.BlazeExtra.Attributes as EA
import Text.Blaze.Html.Renderer.Text
import Text.Markdown

import Views.Common.Form
import Views.Common.SEO
import Utils.BlazeExtra.Pagination as Pagination

import qualified Views.Admin.Layout as VL

import qualified Models.DB.Schema as M

renderWriter :: M.Bookmark -> String -> LT.Text
renderWriter bookmark url =
    VL.render 1
      ["/bower_components/editor.md/css/editormd.min.css"]
      ["/bower_components/editor.md/editormd.min.js"
      ,"/assets/admin/editor.js"]
      [renderForm]
  where
    renderForm =
      H.form ! A.class_ "ui form" ! A.action (H.toValue url) ! A.method "POST" $ do
        idField $ show (M.bookmarkID bookmark)
        textField "标题" "title" (M.bookmarkTitle bookmark)
        textField "源连接" "url" (M.bookmarkUrl bookmark)
        contentField (M.bookmarkMarkdown bookmark)
        tagsField $ showTags (M.bookmarkTags bookmark)
        H.div ! A.class_ "filed" $ do
          H.button ! A.class_ "ui primary button"  ! A.type_ "submit" $ "保存"
          H.a ! A.class_ "ui  button" ! A.href "/admin/bookmarks" $ "取消"

renderIndex :: [M.Bookmark] -> URI -> Pagination ->  LT.Text
renderIndex bookmarks base pn =
    VL.render 1
      ["/bower_components/editor.md/css/editormd.min.css"]
      ["/bower_components/editor.md/editormd.min.js"
      ,"/assets/admin/index.js"]
      [renderTable,rednerDeleteModal]
  where
    renderBookmark bookmark =
      H.tr $ do
        H.td $ H.toHtml (M.bookmarkID bookmark)
        H.td $ H.toHtml (M.bookmarkTitle bookmark)
        H.td $ H.toHtml (M.bookmarkUrl bookmark)
        H.td $ H.toHtml $ show (M.bookmarkUpdatedAt bookmark)
        H.td $ do
          H.a ! A.class_ "ui primary basic button" ! A.href (H.toValue  ("/admin/bookmarks/" ++ (show $ M.bookmarkID bookmark) ++ "/edit") ) $ "编辑"
          H.button ! A.id (H.toValue (M.bookmarkID bookmark)) ! A.href "/admin/bookmarks/remove/"
            ! A.class_ "ui negative basic button"  $ "删除"
    renderTableHead =
      H.thead $
        H.tr $ do
          H.th "id"
          H.th "title"
          H.th "url"
          H.th "updated_at"
          H.th "action"
    renderTableFooter =
      H.tfoot ! A.class_ "full-width" $ H.tr $
        H.th ! A.colspan "5" $ do
          H.div $ H.a ! A.class_ "ui small  positive basic button" ! A.href "/admin/bookmarks/new" $ "新建"
          Pagination.render base pn
    renderTable =
      H.table ! A.class_ "ui celled table" $ do
        renderTableHead
        H.tbody $
          mapM_ renderBookmark bookmarks
        renderTableFooter
    rednerDeleteModal  =
      H.div ! A.class_ "ui basic modal" $ do
        H.div ! A.class_ "ui icon header" $ do
          H.i ! A.class_ "archive icon" $ ""
          "删除连接"
        H.div ! A.class_ "content" $
          H.p $ "确定要删除该连接吗？"
        H.div ! A.class_ "actions" $ do
          H.div ! A.id "cancel" ! A.class_ "ui red basic cancel inverted button" $ do
            H.i ! A.class_ "remove icon" $ ""
            "否"
          H.div ! A.id "ok" ! A.class_ "ui green ok inverted button" $ do
            H.i ! A.class_ "checkmark icon" $ ""
            "是"
