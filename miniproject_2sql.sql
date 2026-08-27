SELECT * FROM public.audio_cards
SELECT * FROM public.audiobooks
SELECT * FROM public.listenings;
1
SELECT COUNT(DISTINCT ac.user_id) AS added_users,
COUNT( DISTINCT CASE 
WHEN ac.progress >= ab.duration * 0.1 
THEN ac.user_id
END
) AS listened_more_than_10_percent
FROM audio_cards ac
JOIN audiobooks ab 
ON ac.audiobook_uuid = ab.uuid
WHERE ab.title = 'Coraline';
2
SELECT l.os_name, ab.title,
COUNT(DISTINCT l.user_id) AS users_count,
ROUND(SUM(l.position_to - l.position_from) / 3600.0, 2) AS listening_hours
FROM listenings l
JOIN audiobooks ab
ON l.audiobook_uuid = ab.uuid
WHERE l.is_test = 0
GROUP BY l.os_name, ab.title;
3
SELECT ab.title,
COUNT(DISTINCT l.user_id) AS users_count
FROM listenings l
JOIN audiobooks ab
ON l.audiobook_uuid = ab.uuid
WHERE l.is_test = 0
GROUP BY ab.title
ORDER BY users_count DESC
LIMIT 1;
4
SELECT ab.title,
COUNT(*) AS completed_count
FROM listenings l
JOIN audiobooks ab
ON l.audiobook_uuid = ab.uuid
WHERE l.is_test = 0
AND l.position_to >= ab.duration
GROUP BY ab.title
ORDER BY completed_count DESC
LIMIT 1;