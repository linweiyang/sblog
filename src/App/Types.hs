{-# LANGUAGE OverloadedStrings #-}
module App.Types where
import qualified Data.Text.Lazy as T
import Control.Monad.Reader (ReaderT)

import Data.Pool(Pool)
import Database.PostgreSQL.Simple(Connection)

import Network.HTTP.Types.Status (Status)
import Web.Scotty.Trans (ScottyT, ActionT, ScottyError(..))
import Database.PostgreSQL.Simple.Errors

data AppConf = AppConf {
    port :: Int
    ,jwtKey :: String
    ,dbHost :: String
    ,dbPort :: Int
    ,dbUser :: String
    ,dbPassword :: String
    ,dbDatabase :: String
} deriving (Show,Eq)

type DBConnections = Pool Connection

data AppContext = AppContext {
  dbConns :: DBConnections
  ,secret :: String
}
type App = ReaderT AppContext IO

data ServerError = RouteNotFound
  | Exception Status T.Text
  | DBError ConstraintViolation


type Server = ScottyT ServerError App
type Response  = ActionT ServerError App
-- newtype ActionT e m a = ActionT { runAM :: ExceptT (ActionError e)
-- (ReaderT ActionEnv (StateT ScottyResponse m)) a }
--    deriving ( Functor, Applicative, MonadIO )
