CREATE OR REPLACE PROCEDURE "GETBUCKETJSON"()
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS '
    var result = "";
    var sql_command = `SELECT LEGACYPOLICYNUMBER, BUCKET FROM AGGNE.DEV.POLICY_MIGRATION_DCT`;
    var stmt = snowflake.createStatement({sqlText: sql_command});
    var rs = stmt.execute();

    var jsonObj = {};
    while (rs.next()) {
        var policy = rs.getColumnValue("LEGACYPOLICYNUMBER");
        var bucket = rs.getColumnValue("BUCKET");
        jsonObj[policy] = bucket;
    }

    result = JSON.stringify(jsonObj);
    return result;
';