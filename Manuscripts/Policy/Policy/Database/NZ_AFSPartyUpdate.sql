/* RUN ON PARTY CFG DB*/
SET NUMERIC_ROUNDABORT OFF
GO
SET XACT_ABORT, ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT, QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

BEGIN TRANSACTION
DECLARE @AppVer decimal(9,6);
SET @AppVer = (SELECT TOP 1 V_APP_VER FROM APP_VER WHERE N_APP = 'PARTY' ORDER BY F_EFF_DT DESC)

DECLARE @RowVer AS INT = 1
DECLARE @CountryKey VARCHAR(2)
DECLARE @App as varchar(5) = 'PARTY'
DECLARE @LstTxnId as varchar(50) = 'INTPRODDEV'
DECLARE @RowSrc as nvarchar(60) = 'P_EPC_' + CAST(@AppVer AS NVARCHAR(10))
DECLARE @CountryCode VARCHAR(2) = 'NZ'
DECLARE @CountryName VARCHAR(50) = 'New Zealand'
DECLARE @Locale INT = 5129
DECLARE @DateFormat VARCHAR(20) = 'dd/MM/yyyy'
DECLARE @PostCodeRegex NVARCHAR(50) = '^[0-9]{4}$'

SELECT @CountryKey = C_KEY FROM [CAT_KEY_LCL_CFG] WHERE [N_CAT] = '243' AND [V_LCL_ID] = 1033 AND [T_VAL] = @CountryName

Delete from [CAT_KEY_CFG]
	Where [N_CAT] = '240' and [C_KEY] in ('001','002','003','004','005','006','007','008','009','012','013','014','015','016','017','018','099','100') and [G_LAST_TXN_ID] = @LstTxnId and [V_ROW_VER]=@RowVer and [N_ROW_SRC] = @RowSrc
Delete from [CAT_KEY_VER]
	Where [N_CAT] = '240' and [C_KEY] in ('001','002','003','004','005','006','007','008','009','012','013','014','015','016','017','018','099','100') and [V_ROW_VER]=@RowVer and [N_ROW_SRC] = @RowSrc
Delete from [CAT_KEY_LCL_CFG]
	Where [N_CAT] = '240' and [C_KEY] in ('001','002','003','004','005','006','007','008','009','012','013','014','015','016','017','018','099','100') and [V_LCL_ID] = '1033'  and [G_LAST_TXN_ID] = @LstTxnId and [V_ROW_VER]=@RowVer and [N_ROW_SRC] = @RowSrc
Delete from [CAT_KEY_LCL_VER]
	Where [N_CAT] = '240' and [C_KEY] in ('001','002','003','004','005','006','007','008','009','012','013','014','015','016','017','018','099','100') and [V_LCL_ID] = '1033' and [V_ROW_VER]=@RowVer and [N_ROW_SRC] = @RowSrc
Delete from [CAT_KEY_EXTFLD_LCL_CFG]
	Where [N_CAT] = '240' and [C_KEY] in ('001','002','003','004','005','006','007','008','009','012','013','014','015','016','017','018','099','100') and [G_LAST_TXN_ID] = @LstTxnId and [V_ROW_VER]=@RowVer and [N_ROW_SRC] = @RowSrc
Delete from [CAT_KEY_EXTFLD_LCL_VER]
	Where [N_CAT] = '240' and [C_KEY] in ('001','002','003','004','005','006','007','008','009','012','013','014','015','016','017','018','099','100') and [V_ROW_VER]=@RowVer and [N_ROW_SRC] = @RowSrc
Delete from [REL_KEY_CFG]
	Where [N_PRNT_CAT]='243' and [C_PRNT_KEY] = @CountryKey and  [N_CHLD_CAT] = '240' and [C_CHLD_KEY] in ('001','002','003','004','005','006','007','008','009','012','013','014','015','016','017','018','099','100') and [G_LAST_TXN_ID] = @LstTxnId and [V_ROW_VER]=@RowVer and [N_ROW_SRC] = @RowSrc
Delete from [REL_KEY_VER]
	Where [N_PRNT_CAT]='243' and [C_PRNT_KEY] = @CountryKey and  [N_CHLD_CAT] = '240' and [C_CHLD_KEY] in ('001','002','003','004','005','006','007','008','009','012','013','014','015','016','017','018','099','100') and [V_ROW_VER]=@RowVer and [N_ROW_SRC] = @RowSrc

/* Add 01 - Northland */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','001','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','001',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','001','Northland',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','001',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','001','Northland',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','001',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','001','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','001',@RowVer,@RowSrc)
/* Add 01 - Northland - Complete*/

/* Add 02 - Auckland */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','002','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','002',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','002','Auckland',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','002',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','002','Auckland',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','002',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','002','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','002',@RowVer,@RowSrc)
/* Add 02 - Auckland - Complete*/

/* Add 03 - Waikato */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','003','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','003',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','003','Waikato',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','003',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','003','Waikato',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','003',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','003','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','003',@RowVer,@RowSrc)
/* Add 03 - Waikato - Complete*/

/* Add 04 - Bay of Plenty */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','004','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','004',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','004','Bay of Plenty',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','004',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','004','Bay of Plenty',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','004',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','004','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','004',@RowVer,@RowSrc)
/* Add 04 - Bay of Plenty - Complete*/

/* Add 05 - Gisborne */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','005','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','005',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','005','Gisborne',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','005',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','005','Gisborne',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','005',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','005','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','005',@RowVer,@RowSrc)
/* Add 05 - Gisborne - Complete*/

/* Add 06 - Hawke's Bay */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','006','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','006',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','006','Hawke Bay',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','006',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','006','Hawke Bay',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','006',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','006','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','006',@RowVer,@RowSrc)
/* Add 06 - Hawke's Bay - Complete*/

/* Add 07 - Taranaki */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','007','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','007',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','007','Taranaki',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','007',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','007','Taranaki',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','007',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','007','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','007',@RowVer,@RowSrc)
/* Add 07 - Taranaki - Complete*/

/* Add 08 - Whanganui-Manawatu */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','008','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','008',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','008','Whanganui-Manawatu',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','008',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','008','Whanganui-Manawatu',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','008',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','008','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','008',@RowVer,@RowSrc)
/* Add 08 - Whanganui-Manawatu - Complete*/

/* Add 09 - Wellington */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','009','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','009',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','009','Wellington',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','009',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','009','Wellington',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','009',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','009','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','009',@RowVer,@RowSrc)
/* Add 09 - Wellington - Complete*/

/* Add 12 - West Coast */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','012','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','012',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','012','West Coast',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','012',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','012','West Coast',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','012',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','012','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','012',@RowVer,@RowSrc)
/* Add 12 - West Coast - Complete*/

/* Add 13 - Canterbury */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','013','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','013',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','013','Canterbury',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','013',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','013','Canterbury',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','013',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','013','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','013',@RowVer,@RowSrc)
/* Add 13 - Canterbury - Complete*/

/* Add 14 - Otago */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','014','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','014',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','014','Otago',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','014',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','014','Otago',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','014',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','014','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','014',@RowVer,@RowSrc)
/* Add 14 - Otago - Complete*/

/* Add 15 - Southland */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','015','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','015',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','015','Southland',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','015',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','015','Southland',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','015',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','015','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','015',@RowVer,@RowSrc)
/* Add 15 - Southland - Complete*/

/* Add 16 - Tasman */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','016','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','016',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','016','Tasman',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','016',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','016','Tasman',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','016',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','016','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','016',@RowVer,@RowSrc)
/* Add 16 - Tasman - Complete*/

/* Add 17 - Nelson */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','017','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','017',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','017','Nelson',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','017',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','017','Nelson',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','017',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','017','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','017',@RowVer,@RowSrc)
/* Add 17 - Nelson - Complete*/

/* Add 18 - Marlborough */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','018','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','018',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','018','Marlborough',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','018',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','018','Marlborough',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','018',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','018','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','018',@RowVer,@RowSrc)
/* Add 18 - Marlborough - Complete*/

/* Add 99 - Area Outside Region */
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','099','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','099',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','099','Area Outside Region',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','099',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','099','Area Outside Region',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','099',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','099','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','099',@RowVer,@RowSrc)
/* Add 99 - Area Outside Region - Complete*/
/* Add 100 - All - Start*/
INSERT INTO [CAT_KEY_CFG]([N_CAT],[C_KEY],[D_BEG],[D_END],[N_MAP_CAT],[C_MAP_KEY],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','100','2016-01-01','9999-12-31',NULL,NULL,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_VER] ([N_APP],[V_APP_VER],[N_CAT],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','100',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','100','All',1,@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','100',@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('240','1033','LongDescription','100','All',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'240','1033','LongDescription','100',@RowVer,@RowSrc)
INSERT INTO [REL_KEY_CFG]([N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[D_BEG],[D_END],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
                            VALUES ('243',@CountryKey,'240','100','2016-01-01','9999-12-31',@LstTxnId,@RowVer,@RowSrc)
INSERT INTO [REL_KEY_VER] ([N_APP],[V_APP_VER],[N_PRNT_CAT],[C_PRNT_KEY],[N_CHLD_CAT],[C_CHLD_KEY],[V_ROW_VER],[N_ROW_SRC])
                            VALUES (@App,@AppVer,'243',@CountryKey,'240','100',@RowVer,@RowSrc)
/* Add 100 - All - Complete*/



IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_CFG] WHERE N_CAT = '8036' AND C_KEY = 'NZ') INSERT [CAT_KEY_CFG] ([N_CAT], [C_KEY], [D_BEG], [D_END], [N_MAP_CAT], [C_MAP_KEY], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8036', N'NZ', CAST(N'1800-01-01' AS Date), CAST(N'9999-12-31' AS Date), NULL, NULL, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ') INSERT [CAT_KEY_CFG] ([N_CAT], [C_KEY], [D_BEG], [D_END], [N_MAP_CAT], [C_MAP_KEY], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', N'AGTNZ', CAST(N'1800-01-01' AS Date), CAST(N'9999-12-31' AS Date), NULL, NULL, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ') INSERT [CAT_KEY_CFG] ([N_CAT], [C_KEY], [D_BEG], [D_END], [N_MAP_CAT], [C_MAP_KEY], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', N'AGYNZ', CAST(N'1800-01-01' AS Date), CAST(N'9999-12-31' AS Date), NULL, NULL, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_CFG] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ') INSERT [CAT_KEY_CFG] ([N_CAT], [C_KEY], [D_BEG], [D_END], [N_MAP_CAT], [C_MAP_KEY], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', N'BUSNZ', CAST(N'1800-01-01' AS Date), CAST(N'9999-12-31' AS Date), NULL, NULL, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_CFG] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ') INSERT [CAT_KEY_CFG] ([N_CAT], [C_KEY], [D_BEG], [D_END], [N_MAP_CAT], [C_MAP_KEY], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', N'INDNZ', CAST(N'1800-01-01' AS Date), CAST(N'9999-12-31' AS Date), NULL, NULL, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_CFG] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ') INSERT [CAT_KEY_CFG] ([N_CAT], [C_KEY], [D_BEG], [D_END], [N_MAP_CAT], [C_MAP_KEY], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', N'ICHNZ', CAST(N'1800-01-01' AS Date), CAST(N'9999-12-31' AS Date), NULL, NULL, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_CFG] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ') INSERT [CAT_KEY_CFG] ([N_CAT], [C_KEY], [D_BEG], [D_END], [N_MAP_CAT], [C_MAP_KEY], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', N'GRPNZ', CAST(N'1800-01-01' AS Date), CAST(N'9999-12-31' AS Date), NULL, NULL, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_CFG] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ') INSERT [CAT_KEY_CFG] ([N_CAT], [C_KEY], [D_BEG], [D_END], [N_MAP_CAT], [C_MAP_KEY], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', N'INDNZ', CAST(N'1800-01-01' AS Date), CAST(N'9999-12-31' AS Date), NULL, NULL, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_VER] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_VER] ([N_APP], [V_APP_VER], [N_CAT], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8036', N'NZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_VER] ([N_APP], [V_APP_VER], [N_CAT], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', N'AGTNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_VER] ([N_APP], [V_APP_VER], [N_CAT], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', N'AGYNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_VER] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_VER] ([N_APP], [V_APP_VER], [N_CAT], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', N'BUSNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_VER] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_VER] ([N_APP], [V_APP_VER], [N_CAT], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_VER] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_VER] ([N_APP], [V_APP_VER], [N_CAT], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', N'ICHNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_VER] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_VER] ([N_APP], [V_APP_VER], [N_CAT], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', N'GRPNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_VER] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_VER] ([N_APP], [V_APP_VER], [N_CAT], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1031) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8036', 1031, N'NZ', N'New Zealand', 3, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1033) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8036', 1033, N'NZ', N'New Zealand', 3, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1034) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8036', 1034, N'NZ', N'New Zealand', 3, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1036) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8036', 1036, N'NZ', N'New Zealand', 3, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1040) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8036', 1040, N'NZ', N'New Zealand', 3, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1041) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8036', 1041, N'NZ', N'オーストラリア', 3, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 2057) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8036', 2057, N'NZ', N'New Zealand', 3, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 2070) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8036', 2070, N'NZ', N'New Zealand', 3, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1031) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1031, N'AGTNZ', N'NZ Agent', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1033) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1033, N'AGTNZ', N'NZ Agent', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1034) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1034, N'AGTNZ', N'NZ Agent', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1036) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1036, N'AGTNZ', N'NZ Agent', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1040) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1040, N'AGTNZ', N'NZ Agente', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1041) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1041, N'AGTNZ', N'オーストラリアのエージェント', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 2057) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2057, N'AGTNZ', N'NZ Agent', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 2070) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2070, N'AGTNZ', N'NZ Agente', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1031) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1031, N'AGYNZ', N'NZ Agency', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1033) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1033, N'AGYNZ', N'NZ Agency', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1034) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1034, N'AGYNZ', N'NZ Agency', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1036) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1036, N'AGYNZ', N'NZ Agency', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1040) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1040, N'AGYNZ', N'NZ Agencia', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1041) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1041, N'AGYNZ', N'オーストラリア事務所', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 2057) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2057, N'AGYNZ', N'NZ Agency', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 2070) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2070, N'AGYNZ', N'NZ Agency', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1031) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1031, N'BUSNZ', N'NZ Geschäft', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1033) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1033, N'BUSNZ', N'NZ Business', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1034) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1034, N'BUSNZ', N'NZ Business', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1036) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1036, N'BUSNZ', N'NZ Business', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1040) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1040, N'BUSNZ', N'NZ Affari', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1041) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1041, N'BUSNZ', N'オーストラリア事業', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 2057) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2057, N'BUSNZ', N'NZ Business', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 2070) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2070, N'BUSNZ', N'NZ Negócios', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1031) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1031, N'INDNZ', N'NZ Individual', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1033) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1033, N'INDNZ', N'NZ Individual', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1034) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1034, N'INDNZ', N'NZ Individual', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1036) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1036, N'INDNZ', N'NZ Individual', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1040) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1040, N'INDNZ', N'NZ Individuale', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1041) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1041, N'INDNZ', N'オーストラリア個人', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 2057) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2057, N'INDNZ', N'NZ Individual', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 2070) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2070, N'INDNZ', N'NZ Individual', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1031) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1031, N'ICHNZ', N'NZ Internal', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1033) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1033, N'ICHNZ', N'NZ Internal', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1034) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1034, N'ICHNZ', N'NZ Internal', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1036) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1036, N'ICHNZ', N'NZ Internal', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1040) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1040, N'ICHNZ', N'NZ Interno', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1041) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 1041, N'ICHNZ', N'オーストラリア国内', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 2057) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2057, N'ICHNZ', N'NZ Internal', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 2070) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8047', 2070, N'ICHNZ', N'NZ Interna', 12, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1031) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1031, N'GRPNZ', N'Gruppe - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1033) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1033, N'GRPNZ', N'Group - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1034) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1034, N'GRPNZ', N'Group - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1036) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1036, N'GRPNZ', N'Group - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1040) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1040, N'GRPNZ', N'Group - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1041) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1041, N'GRPNZ', N'グループ-オーストラリア', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 2057) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 2057, N'GRPNZ', N'Group - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 2070) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 2070, N'GRPNZ', N'Grupo - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1031) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1031, N'INDNZ', N'Individual - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1033) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1033, N'INDNZ', N'Individual - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1034) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1034, N'INDNZ', N'Individual - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1036) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1036, N'INDNZ', N'Individual - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1040) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1040, N'INDNZ', N'Individual - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1041) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 1041, N'INDNZ', N'個人-オーストラリア', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 2057) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 2057, N'INDNZ', N'Individual - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_CFG] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 2070) INSERT [CAT_KEY_LCL_CFG] ([N_CAT], [V_LCL_ID], [C_KEY], [T_VAL], [V_SRT_ORD], [G_LAST_TXN_ID], [V_ROW_VER], [N_ROW_SRC]) VALUES (N'8049', 2070, N'INDNZ', N'Individual - NZ', 11, @LstTxnId, @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1031 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8036', 1031, N'NZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1033 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8036', 1033, N'NZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1034 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8036', 1034, N'NZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1036 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8036', 1036, N'NZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1040 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8036', 1040, N'NZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 1041 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8036', 1041, N'NZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 2057 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8036', 2057, N'NZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8036' AND C_KEY = 'NZ' AND V_LCL_ID = 2070 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8036', 2070, N'NZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1031 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1031, N'AGTNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1033 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1033, N'AGTNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1034 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1034, N'AGTNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1036 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1036, N'AGTNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1040 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1040, N'AGTNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 1041 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1041, N'AGTNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 2057 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2057, N'AGTNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGTNZ' AND V_LCL_ID = 2070 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2070, N'AGTNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1031 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1031, N'AGYNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1033 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1033, N'AGYNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1034 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1034, N'AGYNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1036 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1036, N'AGYNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1040 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1040, N'AGYNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 1041 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1041, N'AGYNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 2057 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2057, N'AGYNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'AGYNZ' AND V_LCL_ID = 2070 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2070, N'AGYNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1031 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1031, N'BUSNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1033 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1033, N'BUSNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1034 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1034, N'BUSNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1036 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1036, N'BUSNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1040 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1040, N'BUSNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 1041 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1041, N'BUSNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 2057 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2057, N'BUSNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'BUSNZ' AND V_LCL_ID = 2070 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2070, N'BUSNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1031 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1031, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1033 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1033, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1034 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1034, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1036 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1036, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1040 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1040, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1041 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1041, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 2057 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2057, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'INDNZ' AND V_LCL_ID = 2070 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2070, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1031 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1031, N'ICHNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1033 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1033, N'ICHNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1034 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1034, N'ICHNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1036 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1036, N'ICHNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1040 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1040, N'ICHNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 1041 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 1041, N'ICHNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 2057 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2057, N'ICHNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8047' AND C_KEY = 'ICHNZ' AND V_LCL_ID = 2070 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8047', 2070, N'ICHNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1031 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1031, N'GRPNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1033 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1033, N'GRPNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1034 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1034, N'GRPNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1036 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1036, N'GRPNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1040 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1040, N'GRPNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 1041 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1041, N'GRPNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 2057 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 2057, N'GRPNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'GRPNZ' AND V_LCL_ID = 2070 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 2070, N'GRPNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1031 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1031, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1033 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1033, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1034 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1034, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1036 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1036, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1040 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1040, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 1041 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 1041, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 2057 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 2057, N'INDNZ', @RowVer, @RowSrc)
IF NOT EXISTS (SELECT NULL FROM [CAT_KEY_LCL_VER] WHERE N_CAT = '8049' AND C_KEY = 'INDNZ' AND V_LCL_ID = 2070 AND [N_APP] = @App AND [V_APP_VER] = @AppVer) INSERT [CAT_KEY_LCL_VER] ([N_APP], [V_APP_VER], [N_CAT], [V_LCL_ID], [C_KEY], [V_ROW_VER], [N_ROW_SRC]) VALUES (@App, @AppVer, N'8049', 2070, N'INDNZ', @RowVer, @RowSrc)

/* Copy entries for en-NZ locale */
INSERT INTO [CAT_KEY_LCL_CFG]([N_CAT],[V_LCL_ID],[C_KEY],[T_VAL],[V_SRT_ORD],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
SELECT [N_CAT],@Locale,[C_KEY],[T_VAL],[V_SRT_ORD],@LstTxnId,@RowVer,@RowSrc
FROM [CAT_KEY_LCL_CFG] c1
WHERE V_LCL_ID = 1033
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM [CAT_KEY_LCL_CFG] c2
				 WHERE c2.N_CAT = c1.N_CAT
				 AND c2.C_KEY = c1.C_KEY
				 AND c2.V_LCL_ID = 1033)
AND NOT EXISTS (SELECT NULL
				FROM [CAT_KEY_LCL_CFG] c2
				WHERE c2.N_CAT = c1.N_CAT
				AND c2.C_KEY = c1.C_KEY
				AND c2.V_LCL_ID = @Locale)

INSERT INTO [CAT_KEY_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
SELECT N_APP,V_APP_VER,N_CAT,@Locale,C_KEY,@RowVer,@RowSrc
FROM [CAT_KEY_LCL_VER] v
WHERE V_LCL_ID = 1033
AND N_APP = @App
AND V_APP_VER = @AppVer
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM [CAT_KEY_LCL_VER] v2
				 WHERE v2.N_CAT = v.N_CAT
				 AND v2.C_KEY = v.C_KEY
				 AND v2.V_LCL_ID = 1033)
AND NOT EXISTS (SELECT NULL
				FROM [CAT_KEY_LCL_VER] v2
				WHERE v2.N_CAT = v.N_CAT
				AND v2.C_KEY = v.C_KEY
				AND v2.V_LCL_ID = @Locale
				AND v2.N_APP = @App
				AND v2.V_APP_VER = @AppVer)

INSERT INTO [CAT_KEY_EXTFLD_LCL_CFG]([N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],[G_LAST_TXN_ID],[V_ROW_VER],[N_ROW_SRC])
SELECT [N_CAT],@Locale,[N_EXTFLD],[C_KEY],[T_EXTFLD_VAL],@LstTxnId,@RowVer,@RowSrc
FROM [CAT_KEY_EXTFLD_LCL_CFG] c1
WHERE V_LCL_ID = 1033
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM [CAT_KEY_EXTFLD_LCL_CFG] c2
				 WHERE c2.N_CAT = c1.N_CAT
				 AND c2.C_KEY = c1.C_KEY
				 AND c2.V_LCL_ID = 1033)
AND NOT EXISTS (SELECT NULL
				FROM [CAT_KEY_EXTFLD_LCL_CFG] c2
				WHERE c2.N_CAT = c1.N_CAT
				AND c2.C_KEY = c1.C_KEY
				AND c2.V_LCL_ID = @Locale)

INSERT INTO [CAT_KEY_EXTFLD_LCL_VER] ([N_APP],[V_APP_VER],[N_CAT],[V_LCL_ID],[N_EXTFLD],[C_KEY],[V_ROW_VER],[N_ROW_SRC])
SELECT N_APP,V_APP_VER,N_CAT,@Locale,[N_EXTFLD],C_KEY,@RowVer,@RowSrc
FROM [CAT_KEY_EXTFLD_LCL_VER] v
WHERE V_LCL_ID = 1033
AND N_APP = @App
AND V_APP_VER = @AppVer
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM [CAT_KEY_EXTFLD_LCL_VER] v2
				 WHERE v2.N_CAT = v.N_CAT
				 AND v2.C_KEY = v.C_KEY
				 AND v2.V_LCL_ID = 1033
				 AND v2.N_APP = @App
				 AND v2.V_APP_VER = @AppVer)
AND NOT EXISTS (SELECT NULL
				FROM [CAT_KEY_EXTFLD_LCL_VER] v2
				WHERE v2.N_CAT = v.N_CAT
				AND v2.C_KEY = v.C_KEY
				AND v2.V_LCL_ID = @Locale
				AND v2.N_APP = @App
				AND v2.V_APP_VER = @AppVer)
/* Copy entries for en-NZ locale - Complete*/

IF NOT EXISTS (SELECT NULL FROM EXPRSN_CFG WHERE N_EXPRSN=N'IfCountryUS' AND C_EXPRSN_GRP = N'Address' AND V_DFLT_LCL_ID = '1033')
INSERT INTO EXPRSN_CFG (N_EXPRSN, D_BEG, D_END, C_EXPRSN_GRP, V_DFLT_LCL_ID, C_OUPT_DATATYP, C_EXPRSN_TYP, B_CMN, B_CFG_VIEW, G_LAST_TXN_ID, V_ROW_VER, N_ROW_SRC) 
VALUES (N'IfCountryUS', N'1800/01/01 12:00:00.000 AM', N'9999/12/31 12:00:00.000 AM', N'Address', 1033, N'Boolean', N'SERVER', 0, 0, @LstTxnId, @RowVer, @RowSrc);

IF NOT EXISTS (SELECT NULL FROM EXPRSN_VER WHERE N_APP=@App AND V_APP_VER = @AppVer AND N_EXPRSN=N'IfCountryUS')
INSERT INTO EXPRSN_VER (N_APP, V_APP_VER, N_EXPRSN, V_ROW_VER, N_ROW_SRC) 
VALUES (@App, @AppVer, N'IfCountryUS', @RowVer, @RowSrc);

IF NOT EXISTS (SELECT NULL FROM EXPRSN_LCL_CFG WHERE N_EXPRSN=N'IfCountryUS' AND V_LCL_ID = '1033')
INSERT INTO EXPRSN_LCL_CFG (N_EXPRSN, V_LCL_ID, D_BEG, D_END, N_EXPRSN_DSPLY, T_EXPRSN, T_EXPRSN_STMNT, G_LAST_TXN_ID, V_ROW_VER, N_ROW_SRC)
VALUES (N'IfCountryUS', 1033, N'1800/01/01 12:00:00.000 AM', N'9999/12/31 12:00:00.000 AM', N'If country is US', N'If country is US', N'{Var:AddressDTO.CountryCode} == "8A"', @LstTxnId, @RowVer,@RowSrc);

IF NOT EXISTS (SELECT NULL FROM EXPRSN_LCL_VER WHERE N_APP=@App AND V_APP_VER = @AppVer AND N_EXPRSN=N'IfCountryUS' AND V_LCL_ID='1033')
INSERT INTO EXPRSN_LCL_VER (N_APP, V_APP_VER, N_EXPRSN, V_LCL_ID, D_BEG, V_ROW_VER, N_ROW_SRC) VALUES (@App, @AppVer, N'IfCountryUS', 1033, N'1800/01/01 12:00:00.000 AM', @RowVer, @RowSrc);

UPDATE DATAITEM_FQN_VLDTN_CFG SET N_CNDTNL_RQRD_EXPRSN ='IfCountryUS',D_END = '9999-12-31' WHERE N_DATAITEM_FQN = 'AddressDTO.PostalCode' AND N_VLDTN IN ('InvalidCharacterValidator','PostalCodeUSOrValidator')
UPDATE DATAITEM_FQN_VLDTN_CFG SET N_CNDTNL_RQRD_EXPRSN ='IfCountryUS',D_END = '9999-12-31' WHERE N_DATAITEM_FQN = 'AddressDTO.NationalDivisionPrimary' AND N_VLDTN IN ('ExpValNationalDivisionPrimaryUS')

/*Format Masks*/
INSERT INTO FRMT_MSK_LCL_CFG (C_FRMT_MSK, V_LCL_ID, T_FRMT_MSK, T_DSPLY_HINT, T_MSK, G_LAST_TXN_ID, V_ROW_VER, N_ROW_SRC, N_FRMT_MSK_DSPLY) 
SELECT C_FRMT_MSK,@Locale,@DateFormat,@DateFormat,@DateFormat,@LstTxnId,@RowVer,@RowSrc,@DateFormat
FROM FRMT_MSK_LCL_CFG c
WHERE C_FRMT_MSK = 'DATE'
AND V_LCL_ID = 1033
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM FRMT_MSK_LCL_CFG c2
				 WHERE c2.C_FRMT_MSK = c.C_FRMT_MSK
				 AND c2.V_LCL_ID = 1033)
AND NOT EXISTS (SELECT NULL
				FROM FRMT_MSK_LCL_CFG c2
				WHERE c2.C_FRMT_MSK = c.C_FRMT_MSK
				AND c2.V_LCL_ID = @Locale)

INSERT INTO FRMT_MSK_LCL_CFG (C_FRMT_MSK, V_LCL_ID, T_FRMT_MSK, T_DSPLY_HINT, T_MSK, G_LAST_TXN_ID, V_ROW_VER, N_ROW_SRC, N_FRMT_MSK_DSPLY) 
SELECT C_FRMT_MSK,@Locale,T_FRMT_MSK,T_DSPLY_HINT,T_MSK,@LstTxnId,@RowVer,@RowSrc,N_FRMT_MSK_DSPLY
FROM FRMT_MSK_LCL_CFG c
WHERE V_LCL_ID = 1033
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM FRMT_MSK_LCL_CFG c2
				 WHERE c2.C_FRMT_MSK = c.C_FRMT_MSK
				 AND c2.V_LCL_ID = 1033)
AND NOT EXISTS (SELECT NULL
				FROM FRMT_MSK_LCL_CFG c2
				WHERE c2.C_FRMT_MSK = c.C_FRMT_MSK
				AND c2.V_LCL_ID = @Locale)

INSERT INTO FRMT_MSK_LCL_VER (N_APP,V_APP_VER,C_FRMT_MSK,V_LCL_ID,V_ROW_VER,N_ROW_SRC) 
SELECT @App,@AppVer,C_FRMT_MSK,@Locale,@RowVer,@RowSrc
FROM FRMT_MSK_LCL_VER v
WHERE V_LCL_ID = 1033
AND N_APP = @App
AND V_APP_VER = @AppVer
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM FRMT_MSK_LCL_VER v2
				 WHERE  v2.C_FRMT_MSK = v.C_FRMT_MSK
				 AND v2.V_LCL_ID = 1033
				 AND v2.N_APP = @App
				 AND v2.V_APP_VER = @AppVer)
AND NOT EXISTS (SELECT NULL
				FROM FRMT_MSK_LCL_VER v2
				WHERE v2.C_FRMT_MSK = v.C_FRMT_MSK
				AND v2.V_LCL_ID = @Locale
				AND v2.N_APP = @App
				AND v2.V_APP_VER = @AppVer)
/*Format Masks - Complete*/

/*Validation*/
INSERT INTO VLDTN_LCL_CFG (N_VLDTN,V_LCL_ID,N_VLDTN_DSPLY,T_VLDTN,G_LAST_TXN_ID, V_ROW_VER, N_ROW_SRC)
SELECT N_VLDTN,@Locale,N_VLDTN_DSPLY,T_VLDTN,@LstTxnId,@RowVer,@RowSrc
FROM VLDTN_LCL_CFG c
WHERE V_LCL_ID = 1033
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM VLDTN_LCL_CFG c2
				 WHERE c2.N_VLDTN = c.N_VLDTN
				 AND c2.V_LCL_ID = 1033)
AND NOT EXISTS (SELECT NULL
				FROM VLDTN_LCL_CFG c2
				WHERE c2.N_VLDTN = c.N_VLDTN
				AND c2.V_LCL_ID = @Locale)

INSERT INTO VLDTN_LCL_VER([N_APP],[V_APP_VER],[N_VLDTN],[V_LCL_ID],[V_ROW_VER],[N_ROW_SRC])
SELECT @App,@AppVer,N_VLDTN,@Locale,@RowVer,@RowSrc
FROM VLDTN_LCL_VER v
WHERE V_LCL_ID = 1033
AND N_APP = @App
AND V_APP_VER = @AppVer
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM VLDTN_LCL_VER v2
				 WHERE v2.N_VLDTN = v.N_VLDTN
				 AND v2.V_LCL_ID = 1033
				 AND v2.N_APP = @App
				 AND v2.V_APP_VER = @AppVer)
AND NOT EXISTS (SELECT NULL
				FROM VLDTN_LCL_VER v2
				WHERE v2.N_VLDTN = v.N_VLDTN
				AND v2.V_LCL_ID = @Locale
				AND v2.N_APP = @App
				AND v2.V_APP_VER = @AppVer)

IF NOT EXISTS (SELECT NULL FROM REGEX_CFG WHERE C_REGEX = 'ZipCodeNZRegEx')
INSERT INTO REGEX_CFG (C_REGEX, D_BEG, D_END, G_LAST_TXN_ID, V_ROW_VER, N_ROW_SRC) VALUES(N'ZipCodeNZRegEx', N'1800/01/01 12:00:00.000 AM', N'9999/12/31 12:00:00.000 AM',@LstTxnId,@RowVer,@RowSrc)

IF NOT EXISTS (SELECT NULL FROM REGEX_VER WHERE C_REGEX = 'ZipCodeNZRegEx' AND N_APP = @App AND V_APP_VER = @AppVer)
INSERT INTO REGEX_VER ([N_APP],[V_APP_VER],[C_REGEX],[V_ROW_VER],[N_ROW_SRC]) VALUES(@App,@AppVer,N'ZipCodeNZRegEx',@RowVer,@RowSrc)

IF NOT EXISTS (SELECT NULL FROM REGEX_LCL_CFG WHERE C_REGEX = N'ZipCodeNZRegEx' AND V_LCL_ID = @Locale AND G_LAST_TXN_ID = @LstTxnId)
INSERT INTO REGEX_LCL_CFG (C_REGEX, V_LCL_ID, T_REGEX, N_REGEX_DSPLY, G_LAST_TXN_ID, V_ROW_VER, N_ROW_SRC, T_REGEX_STMNT) VALUES (N'ZipCodeNZRegEx',@Locale,@PostCodeRegex,@PostCodeRegex,@LstTxnId,@RowVer,@RowSrc,@PostCodeRegex)

IF NOT EXISTS (SELECT NULL FROM REGEX_LCL_VER WHERE C_REGEX = N'ZipCodeNZRegEx' AND V_LCL_ID = @Locale AND N_APP = @App AND V_APP_VER = @AppVer)
INSERT INTO REGEX_LCL_VER (N_APP, V_APP_VER, C_REGEX ,V_LCL_ID, V_ROW_VER, N_ROW_SRC) VALUES (@App,@AppVer,N'ZipCodeNZRegEx',@Locale,@RowVer,@RowSrc)

INSERT INTO REGEX_LCL_CFG (C_REGEX, V_LCL_ID, T_REGEX, N_REGEX_DSPLY, G_LAST_TXN_ID, V_ROW_VER, N_ROW_SRC, T_REGEX_STMNT)
SELECT C_REGEX,@Locale,T_REGEX,N_REGEX_DSPLY,@LstTxnId,@RowVer,@RowSrc,T_REGEX_STMNT
FROM REGEX_LCL_CFG c
WHERE V_LCL_ID = 1033
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM REGEX_LCL_CFG c2
				 WHERE c2.C_REGEX = c.C_REGEX
				 AND c2.V_LCL_ID = 1033)
AND NOT EXISTS (SELECT NULL
				FROM REGEX_LCL_CFG c2
				WHERE c2.C_REGEX = c.C_REGEX
				AND c2.V_LCL_ID = @Locale)

INSERT INTO REGEX_LCL_VER (N_APP, V_APP_VER, C_REGEX ,V_LCL_ID, V_ROW_VER, N_ROW_SRC)
SELECT @App,@AppVer,C_REGEX,@Locale,@RowVer,@RowSrc
FROM REGEX_LCL_VER v
WHERE V_LCL_ID = 1033
AND N_APP = @App
AND V_APP_VER = @AppVer
AND V_ROW_VER = (SELECT MAX(V_ROW_VER)
				 FROM REGEX_LCL_VER v2
				 WHERE v2.C_REGEX = v.C_REGEX
				 AND v2.V_LCL_ID = 1033
				 AND v2.N_APP = @App
				 AND v2.V_APP_VER = @AppVer)
AND NOT EXISTS (SELECT NULL
				FROM REGEX_LCL_VER v2
				WHERE v2.C_REGEX = v.C_REGEX
				AND v2.V_LCL_ID = @Locale
				AND v2.N_APP = @App
				AND v2.V_APP_VER = @AppVer)
/*Validation - Complete*/

COMMIT TRANSACTION