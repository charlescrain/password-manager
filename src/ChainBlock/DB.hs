{-# LANGUAGE Arrows              #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators       #-}

module ChainBlock.DB where

import           Control.Monad.IO.Class     (liftIO)
import           Data.ByteString.Lazy       (toStrict)
import           Data.ByteString.Lazy.UTF8  (fromString)
import           Data.Text
import           Database.PostgreSQL.Simple (ConnectInfo (..), Connection,
                                             connect)
import           Opaleye.Column             (Column)
import           Opaleye.Manipulation       (runInsertManyReturning)
import qualified Opaleye.PGTypes            as P
import           Opaleye.QueryArr           (Query)
import           Opaleye.RunQuery           (runQuery)
import           System.Environment         (getEnv)

import           ChainBlock.Business.Types  (BZ)
import           ChainBlock.DB.Interfaces
import           ChainBlock.DB.Setup        (createDBIfNeeded)
import           ChainBlock.DB.Tables
import           ChainBlock.DB.Types
import           ChainBlock.Errors          (CBErrors (..))


databaseInterface :: (forall a . PGDB a -> m a )
                  -> IO (IDataBase PGDB m)
databaseInterface runDBInterface' = do
  connInfo <- buildConnectInfo
  conn <- connect connInfo
  let dbName = connectDatabase connInfo
  _ <- createDBIfNeeded conn dbName
  return IDataBase { queryAllUsers           = queryAllUsers' conn
                   , queryUser               = queryUser' conn
                   , insertUser              = insertUser' conn
                   , queryWebsite            = queryWebsite' conn
                   , queryWebsiteCredentials = queryWebsiteCredentials' conn
                   , runDBInterface          = runDBInterface'
                   }

-----------------------------------------------------
-- | runDBInterface Functions
-----------------------------------------------------

runDBInterfaceBZ :: PGDB a -> BZ a
runDBInterfaceBZ = undefined

-----------------------------------------------------
-- | Interface Implementation
-----------------------------------------------------

queryAllUsers' :: Connection -> PGDB [User]
queryAllUsers' =  undefined

queryUser' :: Connection -> Username -> PGDB User
queryUser' = undefined
-- queryUser' conn un = do
--   rows <- runQuery conn queryUserByName
--   case length rows of
--     0 -> throw
--
--   if length rows \= 1
--     then
--   return $ User
--             (UserId . toInteger . fromIntegral $ uId)
--             (Username un)
--   where
--     queryUserByName :: Query (Column P.PGInt4, Column P.PGText)
--     queryUserByName = undefined

insertUser' ::  Connection -> Username -> PGDB UserId
insertUser' conn un = do
  let insertFields = [(Nothing, P.pgStrictText . unUsername $ un)]
  [(id :: Int, _ :: Text)] <- liftIO $ runInsertManyReturning conn userTable insertFields id
  return $ UserId . toInteger . fromIntegral $ id


queryWebsite' :: Connection -> UserId -> PGDB [Website]
queryWebsite' = undefined

queryWebsiteCredentials' :: Connection -> UserId -> WebsiteId -> PGDB [WebsiteCredentials]
queryWebsiteCredentials' = undefined


-----------------------------------------------------
-- | Helper Funcitons
-----------------------------------------------------


buildConnectInfo :: IO ConnectInfo
buildConnectInfo  = do
  host       <- getEnv "PG_HOST"
  port       <- getEnv "PG_PORT"
  dbName     <- getEnv "PG_DBNAME"
  dbUser     <- getEnv "PG_DBUSER"
  dbPassword <- getEnv "PG_DBPASSWORD"
  return $ ConnectInfo { connectHost = host
                       , connectPort = read port
                       , connectUser = dbUser
                       , connectPassword = dbPassword
                       , connectDatabase = dbName
                       }

