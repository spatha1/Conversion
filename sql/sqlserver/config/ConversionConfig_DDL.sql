-- ConversionConfig tables for PolicyConversion DB
-- BP = ConversionConfig | PP = PP_ConversionConfig
-- Source: Capricorn-SwiftConversion schema (replicated locally)

USE [PolicyConversion]
GO

/****** ConversionConfig (BP) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ConversionConfig]') AND type = 'U')
BEGIN
CREATE TABLE [dbo].[ConversionConfig](
	[ConversionConfigId] [int] IDENTITY(1,1) NOT NULL,
	[SequenceID] [int] NOT NULL,
	[ScriptName] [varchar](255) NULL,
	[ConversionSourceTable] [varchar](500) NOT NULL,
	[ConversionTargetTable] [varchar](500) NOT NULL,
	[AttachSourceTable] [varchar](500) NULL,
	[AttachTargetTable] [varchar](500) NULL,
	[ConversionScript] [nvarchar](max) NULL,
	[AttachScript] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [sysname] NOT NULL,
	[CreatedOn] [datetime2](3) NOT NULL,
	[ModifiedBy] [sysname] NULL,
	[ModifiedOn] [datetime2](3) NULL,
	[RowVer] [timestamp] NOT NULL,
 CONSTRAINT [PK_ConversionConfig] PRIMARY KEY CLUSTERED ([ConversionConfigId] ASC)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
PRINT 'Created ConversionConfig'
END
ELSE PRINT 'ConversionConfig already exists'
GO

/****** PP_ConversionConfig (PP) ******/
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PP_ConversionConfig]') AND type = 'U')
BEGIN
CREATE TABLE [dbo].[PP_ConversionConfig](
	[ConversionConfigId] [int] IDENTITY(1,1) NOT NULL,
	[SequenceID] [int] NOT NULL,
	[ScriptName] [varchar](255) NULL,
	[ConversionSourceTable] [varchar](500) NOT NULL,
	[ConversionTargetTable] [varchar](500) NOT NULL,
	[AttachSourceTable] [varchar](500) NULL,
	[AttachTargetTable] [varchar](500) NULL,
	[ConversionScript] [nvarchar](max) NULL,
	[AttachScript] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [sysname] NOT NULL,
	[CreatedOn] [datetime2](3) NOT NULL,
	[ModifiedBy] [sysname] NULL,
	[ModifiedOn] [datetime2](3) NULL,
	[RowVer] [timestamp] NOT NULL,
 CONSTRAINT [PK_PP_ConversionConfig] PRIMARY KEY CLUSTERED ([ConversionConfigId] ASC)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
PRINT 'Created PP_ConversionConfig'
END
ELSE PRINT 'PP_ConversionConfig already exists'
GO
