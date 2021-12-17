--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import           Debug.Trace

--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls
            
    -- build up tags
    tags <- buildTags "posts/*" (fromCapture "tags/*.html")

    let postCtx = getPostCtx tags
    
    -- Build posts:
    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= loadAndApplyTemplate "templates/header.html" postCtx
            >>= relativizeUrls
    
    -- Build rss and atom feeds
    
    create ["atom.xml"] $ do
      route idRoute
      compile $ do
        let feedCtx = postCtx `mappend` bodyField "description"
        posts <- fmap (take 10) . recentFirst =<<
            loadAllSnapshots "posts/*" "content"
        renderAtom feedConfiguration feedCtx posts
        
        
    create ["rss.xml"] $ do
      route idRoute
      compile $ do
        let feedCtx = postCtx `mappend` bodyField "description"
        posts <- fmap (take 10) . recentFirst =<<
            loadAllSnapshots "posts/*" "content"
        renderRss feedConfiguration feedCtx posts

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls
                
    create ["license.html"] $ do
        route idRoute
        compile $ 
            makeItem ""
                >>= loadAndApplyTemplate "templates/license.html" defaultContext
                >>= loadAndApplyTemplate "templates/default.html" defaultContext
                >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler
    
--------------------------------------------------------------------------------

feedConfiguration :: FeedConfiguration
feedConfiguration = FeedConfiguration
    { feedTitle       = "Interchange"
    , feedDescription = "Nathan's Development blog."
    , feedAuthorName  = "Nathan Bedell"
    , feedAuthorEmail = "nbedell@tulane.edu"
    , feedRoot        = "http://sintrastes.github.io/blog"
    }    
    
--------------------------------------------------------------------------------

config = defaultConfiguration {
    destinationDirectory = "blog",
    providerDirectory    = "src",
    deployCommand        = "git add . && git commit && git push"
}

--------------------------------------------------------------------------------
getPostCtx :: Tags -> Context String
getPostCtx tags =
    tagsField "tags" tags `mappend`
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext
