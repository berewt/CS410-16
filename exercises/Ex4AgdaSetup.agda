module Ex4AgdaSetup where

{- This file contains all the basic types you need for the editor. You should
   read and understand the Agda in this file, but not bother too much about
   the funny compiler directives. -}

open import CS410-Prelude
open import CS410-Nat

record _**_ (S T : Set) : Set where
  constructor _,_
  field
    outl : S
    outr : T
open _**_
{-# COMPILED_DATA _**_ (,) (,) #-}
infixr 4 _**_ _,_

_<=_ : Nat -> Nat -> Two
zero   <=  y      = tt
suc x  <=  zero   = ff
suc x  <=  suc y  = x <= y

_++_ : {A : Set} -> List A -> List A -> List A
[]         ++ ys = ys
(x :: xs)  ++ ys = x :: (xs ++ ys)


{- Here are backward lists, which are useful when the closest element is
   conceptually at the right end. They aren't really crucial as you could use
   ordinary lists but think of the data as being reversed, but I prefer to
   keep my thinking straight and use data which look like what I have in mind. -}

data Bwd (X : Set) : Set where
  []    : Bwd X
  _<:_  : Bwd X -> X -> Bwd X
infixl 3 _<:_

{- You will need access to characters, imported from Haskell. You can write
   character literals like 'c'. You also get strings, with String literals like
   "fred" -}


postulate       -- Haskell has a monad for doing IO, which we use at the top level
  IO      : Set -> Set
  return  : {A : Set} -> A -> IO A
  _>>=_   : {A B : Set} -> IO A -> (A -> IO B) -> IO B
infixl 1 _>>=_
{-# BUILTIN IO IO #-}
{-# COMPILED_TYPE IO IO #-}
{-# COMPILED return (\ _ -> return)    #-}
{-# COMPILED _>>=_  (\ _ _ -> (>>=)) #-}

{- Here's the characterization of keys I give you -}
data Direction : Set where up down left right : Direction
data Modifier : Set where normal shift control : Modifier
data Key : Set where
  char       : Char -> Key
  arrow      : Modifier -> Direction -> Key
  enter      : Key
  backspace  : Key
  delete     : Key
  escape     : Key
  tab        : Key
data Event : Set where
  key     : (k : Key) -> Event
  resize  : (w h : Nat) -> Event

{- This type classifies the difference between two editor states. -}
data Change : Set where
  allQuiet    : Change      -- the buffer should be exactly the same
  cursorMove  : Change      -- the cursor has moved but the text is the same
  lineEdit    : Change      -- only the text on the current line has changed
  bigChange   : Change      -- goodness knows!

{- This type collects the things you're allowed to do with the text window. -}
data Action : Set where
  goRowCol : Nat -> Nat -> Action    -- send the cursor somewhere
  sendText : List Char -> Action     -- send some text
  move     : Direction -> Nat -> Action  -- which way and how much
  fgText   : Colour -> Action
  bgText   : Colour -> Action

{- I wire all of that stuff up to its Haskell counterpart. -}
{-# IMPORT ANSIEscapes #-}
{-# IMPORT HaskellSetup #-}
{-# COMPILED_DATA Direction
      ANSIEscapes.Dir
      ANSIEscapes.DU ANSIEscapes.DD ANSIEscapes.DL ANSIEscapes.DR #-}
{-# COMPILED_DATA Modifier 
      HaskellSetup.Modifier
      HaskellSetup.Normal HaskellSetup.Shift HaskellSetup.Control #-}
{-# COMPILED_DATA Key
      HaskellSetup.Key
      HaskellSetup.Char HaskellSetup.Arrow HaskellSetup.Enter
      HaskellSetup.Backspace HaskellSetup.Delete HaskellSetup.Escape
      HaskellSetup.Tab #-}
{-# COMPILED_DATA Event
      HaskellSetup.Event
      HaskellSetup.Key HaskellSetup.Resize #-}
{-# COMPILED_DATA Change
      HaskellSetup.Change
      HaskellSetup.AllQuiet HaskellSetup.CursorMove HaskellSetup.LineEdit
      HaskellSetup.BigChange #-}
{-# COMPILED_DATA Action HaskellSetup.Action
      HaskellSetup.GoRowCol HaskellSetup.SendText HaskellSetup.Move
      HaskellSetup.FgText HaskellSetup.BgText #-}

{- This is the bit of code I wrote to animate your code. -}
postulate
  mainLoop : {B : Set} ->             -- buffer type
    -- INITIALIZER
    (List (List Char) -> B) ->        -- make a buffer from some lines of text
    -- KEYSTROKE HANDLER
    (Key -> B ->                      -- keystroke and buffer in
     Change ** B) ->                 -- change report and buffer out
    -- RENDERER
    ((Nat ** Nat) ->                 -- height and width of screen
     (Nat ** Nat) ->                 -- top line number, left column number
     (Change ** B) ->           -- change report and buffer to render
     (List Action **                 -- how to update the display
      (Nat ** Nat))) ->              -- new top line number, left column number
    -- PUT 'EM TOGETHER AND YOU'VE GOT AN EDITOR!
    IO One
{-# COMPILED mainLoop (\ _ -> HaskellSetup.mainLoop) #-}

{- You can use this to put noisy debug messages in Agda code. So
      trace "fred" tt
   evaluates to tt, but prints "fred" in the process. -}
{-
postulate
  trace : {A : Set} -> String -> A -> A
{-# IMPORT Debug.Trace #-}
{-# COMPILED trace (\ _ -> Debug.Trace.trace) #-}
-}

{- You can use this to print an error message when you don't know what else to do.
   It's very useful for filling in unfinished holes to persuade the compiler to
   compile your code even though it isn't finished: you get an error if you try
   to run a missing bit. -}
{-
postulate
  error : {A : Set} -> String -> A
{-# COMPILED error (\ _ -> error) #-}
-}

{- Equality -}
{- x == y is a type whenever x and y are values in the same type -}
{-
data _==_ {X : Set}(x : X) : X -> Set where
  refl : x == x  -- and x == y has a constructor only when y actually is x!
infixl 1 _==_
-- {-# BUILTIN EQUALITY _==_ #-}
-- {-# BUILTIN REFL refl #-}
{-# COMPILED_DATA _==_ HaskellSetup.EQ HaskellSetup.Refl #-}

within_turn_into_because_ :
   {X Y : Set}(f : X -> Y)(x x' : X) ->
   x == x' -> f x == f x'
within f turn x into .x because refl = refl
                     -- the dot tells Agda that *only* x can go there

symmetry : {X : Set}{x x' : X} -> x == x' -> x' == x
symmetry refl = refl

transitivity : {X : Set}{x0 x1 x2 : X} -> x0 == x1 -> x1 == x2 -> x0 == x2
transitivity refl refl = refl
-}

within_turn_into_because_ :
    {X Y : Set}(f : X -> Y)(x x' : X) ->
    x == x' -> f x == f x'
within f turn x into .x because refl = refl

{-
postulate
  _==_ : {X : Set} -> X -> X -> Set   -- the evidence that two X-values are equal
  refl : {X : Set}{x : X} -> x == x
  symmetry : {X : Set}{x x' : X} -> x == x' -> x' == x
  transitivity : {X : Set}{x0 x1 x2 : X} -> x0 == x1 -> x1 == x2 -> x0 == x2
  within_turn_into_because_ :
    {X Y : Set}(f : X -> Y)(x x' : X) ->
    x == x' -> f x == f x'
infix 1 _==_


{-# COMPILED_TYPE _==_ HaskellSetup.EQ #-}

{- Here's an example. -}

additionAssociative : (x y z : Nat) -> (x + y) + z == x + (y + z)
additionAssociative zero y z    = refl
additionAssociative (suc x) y z
  = within suc turn ((x + y) + z) into (x + (y + z))
      because additionAssociative x y z
-}
