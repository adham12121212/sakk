-- Profile photos: private. The bucket was public, so anyone with a photo's
-- link could open it without signing in. The app now loads its user's photo
-- with their token (storage's authenticated endpoint), which the existing
-- "Users can read their own avatar" rule allows; only the owner ever sees
-- their own photo. Saved public links still name the same file.
update storage.buckets set public = false where id = 'avatars';
