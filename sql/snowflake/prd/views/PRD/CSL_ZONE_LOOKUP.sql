create or replace view CSL_ZONE_LOOKUP(
	ABBR,
	FULL_NAME
) as
    SELECT 'NZ' AS ABBR, 'New Zealand' AS FULL_NAME UNION ALL
    SELECT 'WA', 'Western Australia' UNION ALL
    SELECT 'NSW ACT', 'New South Wales & ACT' UNION ALL
    SELECT 'VIC TAS', 'Victoria & Tasmania' UNION ALL
    SELECT 'QLD', 'Queensland' UNION ALL
    SELECT 'SA NT', 'South Australia & NT';