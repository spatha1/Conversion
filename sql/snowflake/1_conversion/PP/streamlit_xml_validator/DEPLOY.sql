-- Deploy the PP XML Field Validator page (Streamlit in Snowflake).
--
-- 1. Create a stage to hold the app file (one-time):
CREATE STAGE IF NOT EXISTS AGGNE.DEV.STREAMLIT_APPS
    DIRECTORY = (ENABLE = TRUE);

-- 2. Upload app.py to the stage. Easiest via Snowsight: Data > Databases > AGGNE > DEV >
--    Stages > STREAMLIT_APPS > "+ Files" > upload sql/snowflake/1_conversion/PP/
--    streamlit_xml_validator/app.py into a subfolder named pp_xml_validator/.
--    (Or via SnowSQL CLI: PUT file://<path>/app.py @AGGNE.DEV.STREAMLIT_APPS/pp_xml_validator/ AUTO_COMPRESS=FALSE;)

-- 3. Create the Streamlit object pointing at it:
CREATE STREAMLIT IF NOT EXISTS AGGNE.DEV.PP_XML_VALIDATOR
    ROOT_LOCATION = '@AGGNE.DEV.STREAMLIT_APPS/pp_xml_validator'
    MAIN_FILE = 'app.py'
    QUERY_WAREHOUSE = 'AGGNE_XS';

-- 4. Confirm and get the URL:
SHOW STREAMLITS LIKE 'PP_XML_VALIDATOR' IN SCHEMA AGGNE.DEV;
-- Open from Snowsight: Projects > Streamlit > PP_XML_VALIDATOR

-- To update the app after editing app.py: re-upload the file to the same stage path, no
-- CREATE STREAMLIT re-run needed -- Snowflake picks up the new file content automatically.
