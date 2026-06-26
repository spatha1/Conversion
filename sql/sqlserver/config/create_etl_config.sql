-- ETL config table used by middleware to drive XML generation (ETL3)
-- One row per config entry: source view → formula → output table
CREATE TABLE etl_config (
    config_id       INT IDENTITY(1,1) PRIMARY KEY,
    lob             VARCHAR(10)   NOT NULL,  -- 'BP' or 'PP'
    config_name     VARCHAR(200)  NOT NULL,
    source_view     VARCHAR(500)  NOT NULL,  -- Snowflake view from ETL2
    formula         NVARCHAR(MAX) NOT NULL,  -- XML template with {fieldName} placeholders
    output_table    VARCHAR(500)  NOT NULL,  -- Snowflake target table (ETL4 output)
    active          BIT           NOT NULL DEFAULT 1,
    created_at      DATETIME      NOT NULL DEFAULT GETDATE(),
    updated_at      DATETIME      NOT NULL DEFAULT GETDATE()
);
