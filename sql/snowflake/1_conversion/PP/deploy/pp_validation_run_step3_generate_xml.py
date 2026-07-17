# SUPERSEDED (2026-07-10) — do not use.
#
# This assumed XML generation happens via middleware.etl4-style Python looping over
# DYNAMIC_XML_V1 calls sourced from SQL Server PP_ConversionConfig.
#
# Discovered: AGGNE.DEV.PP_CONVERSION_RUN is the real, complete orchestrator — it has all
# 18 templates hardcoded in its own procedure body (not read from SQL Server at call time)
# and also runs a Phase 2 (PER_CONVERSION_FINAL_LOAD + PER_CONVERSION_FINAL_XML) this
# script never knew about.
#
# Use PP_VALIDATION_RUN.sql instead (a plain CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE)),
# after first running PP_CONVERSION_RUN_SYNC_G25_G32.sql to sync today's two SQL Server
# config fixes into that procedure's own template copy.
