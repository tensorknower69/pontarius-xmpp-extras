-- |
-- Stability   :  Ultra-Violence
-- Portability :  I'm too young to die
-- XEP-0045: Multi-User Chat

{-# LANGUAGE OverloadedStrings #-}

module Network.Xmpp.Extras.MUC
	( MUCHistoryReq(..)
	, joinMUC
	, sendMUC
	) where

import Data.Default
import Data.Maybe
import Data.Text as T
import Data.Time
import Data.XML.Types
import Network.Xmpp.Extras.DateTime
import Network.Xmpp.Internal hiding (priority, status)

--data MUCJID = MUCJID
--	{ mjService :: Text
--	, mjRoom :: Text
--	} deriving Show
--
--mUCJIDToJid (MUCJID s r) = jidFromTexts (Just s) r

data MUCHistoryReq = MUCHistoryReq
	{ mhrMaxChars :: Maybe Integer
	, mhrMaxStanzas :: Maybe Integer
	, mhrSeconds :: Maybe Integer
	, mhrSince :: Maybe UTCTime
	}

instance Default MUCHistoryReq where
	def = MUCHistoryReq Nothing Nothing Nothing Nothing

-- |Join the specified MUC or change your nickname in the already joined one. The resource part of the `Jid` sets the desired nickname.
joinMUC :: Jid -> Maybe MUCHistoryReq -> Session -> IO (Either XmppFailure ())
joinMUC jid mhr = sendPresence ((presTo presence jid) { presencePayload = [Element "x" [("xmlns", [ContentText "http://jabber.org/protocol/muc"])] $ maybe [] (\hr -> [
		NodeElement $ Element "history" (
			(elementify "maxchars" show $ mhrMaxChars hr) ++
			(elementify "maxstanzas" show $ mhrMaxStanzas hr) ++
			(elementify "seconds" show $ mhrSeconds hr) ++
			(elementify "since" toDateTime $ mhrSince hr)
		) []]) mhr
	] } )
	where elementify name show content = fmap (\s -> ("seconds", [ContentText $ T.pack $ show s])) $ maybeToList content

-- |Send a broadcast message. `Jid` must be bare.
sendMUC :: Jid -> Text -> Session -> IO (Either XmppFailure ())
sendMUC jid text = sendMessage ((simpleIM jid text) { messageType = GroupChat })
