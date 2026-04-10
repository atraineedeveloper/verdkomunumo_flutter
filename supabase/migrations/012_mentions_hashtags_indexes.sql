-- Enable pg_trgm for efficient ILIKE searches used by mention and hashtag autocomplete
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Trigram index on profiles.username for fast @mention autocomplete (ilike 'partial%')
CREATE INDEX IF NOT EXISTS idx_profiles_username_trgm
  ON public.profiles USING GIN (username gin_trgm_ops);

-- Trigram index on posts.content for fast #hashtag autocomplete (ilike '%#partial%')
CREATE INDEX IF NOT EXISTS idx_posts_content_trgm
  ON public.posts USING GIN (content gin_trgm_ops);

-- Index on posts.quoted_post_id for efficient reverse lookups ("who quoted this post?")
CREATE INDEX IF NOT EXISTS idx_posts_quoted_post_id
  ON public.posts (quoted_post_id)
  WHERE quoted_post_id IS NOT NULL;
