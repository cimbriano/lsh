module Types where

import Data.Map (Map)
import qualified Data.Map as Map
import Control.Monad

import Text.PrettyPrint.HughesPJ (Doc, (<+>),($$),(<>))
import qualified Text.PrettyPrint.HughesPJ as PP

import Text.ParserCombinators.Parsec
import System.Environment

import System.Cmd
import System.Process
import Control.Monad.Error
import Control.Monad.State

import GHC.IO.Exception

-- Syntax of Shell language

type Variable = String
type Args = [Value]

data Statement =
    Command String Args       -- echo "a b"
  | Val Value                 -- 3 or string or "quoted String"
  | Assign Variable Value     -- Assign x 3, Assign, x "quoted String"
--  deriving Show
{-
data Expression =
    Var Variable                    -- x
  | Val Value                       -- v
-}

data Value =
    Number Integer -- 3
  | String String  -- abcd
  | Quoted String  -- "ab cde"
    deriving Show

showVal :: Statement -> String
showVal (Command cmd args) =  "Running " ++ cmd ++ " | " ++ show args
-- showVal (Command cmd args) =  testSystem cmd "test"
showVal (Val val) = show val
showVal (Assign var val) = (show var) ++ " = " ++ (show val)

instance Show Statement where show = showVal

-- testSystem :: String -> [String] -> String

-- String -> [String] -> Either String
testSystem cmd args = do
  x <-  (rawSystem cmd args)
  case x of
    GHC.IO.Exception.ExitSuccess     -> return $ "success"
    GHC.IO.Exception.ExitFailure err -> return $ "error" ++ (show err)

main :: IO ()
main = do args <- getArgs
          putStrLn (readStat (args !! 0))

readStat :: String -> String
readStat input = case parse parseStat "Shell Statement" input of
  Left err -> "No match: " ++ show err
  Right v  -> "Found value" ++ show v

parseStat :: Parser Statement
parseStat = parseCommand <|> parseStVal
            -- <|> parseAssign

parseStVal :: Parser Statement
parseStVal = do
  val <- parseNumber <|> parseQuoted <|> parseString
  return $ Val val

symbol :: Parser Char
symbol = oneOf "!#$%| >"

parseCommand :: Parser Statement
parseCommand = do
  (String cmd)  <- parseString
  skipMany1 space
  args <- sepBy parseValue (skipMany1 space)
--  return $ Command cmd ([ String "one"])
  return $ Command cmd (args)

parseAssign :: Parser Statement
parseAssign = undefined

parseValue :: Parser Value
parseValue = parseNumber <|> parseQuoted <|> parseString

parseNumber :: Parser Value
parseNumber = liftM (Number . read) $ many1 digit

parseString :: Parser Value
parseString = do
  str <- many1 (noneOf "!#$%| >")
  return $ String str

parseQuoted :: Parser Value
parseQuoted = do
    char '"'
    x <- many (noneOf "\\\"" <|> parseQuotes) -- any character except \ or "
    char '"'
    return $ Quoted x

-- parse \\ and \"
parseQuotes :: Parser Char
parseQuotes = do
    char '\\'
    x <- oneOf "\\\"nrt"
    return $ case x of
      'n' -> '\n'
      'r' -> '\r'
      't' -> '\t'
      _   -> x

-- Pretty printing for the Shell language