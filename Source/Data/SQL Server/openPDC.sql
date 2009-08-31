USE [master]
GO
/****** Object:  Database [openPDC]    Script Date: 08/31/2009 15:52:22 ******/
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'openPDC')
BEGIN
CREATE DATABASE [openPDC];
GO
ALTER DATABASE [openPDC] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [openPDC] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [openPDC] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [openPDC] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [openPDC] SET ARITHABORT OFF 
GO
ALTER DATABASE [openPDC] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [openPDC] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [openPDC] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [openPDC] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [openPDC] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [openPDC] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [openPDC] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [openPDC] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [openPDC] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [openPDC] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [openPDC] SET  ENABLE_BROKER 
GO
ALTER DATABASE [openPDC] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [openPDC] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [openPDC] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [openPDC] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [openPDC] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [openPDC] SET  READ_WRITE 
GO
ALTER DATABASE [openPDC] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [openPDC] SET  MULTI_USER 
GO
ALTER DATABASE [openPDC] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [openPDC] SET DB_CHAINING OFF 
USE [openPDC]
GO
/****** Object:  StoredProcedure [dbo].[GetFormattedMeasurements]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetFormattedMeasurements]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'


/*
	Returns a formatted string of measurements given a SQL statement
	Copyright © 2009 - TVA, all rights reserved
	Primary Developer: James R Carroll, 8/31/2009
	Email: jrcarrol@tva.gov

	Parameters:
	
	measurementsSql:
		SQL which returns table of "MeasurementID INT, ArchiveSource NVARCHAR(50), Adder FLOAT, Multiplier FLOAT"
	
	includeAdjustments:
		Boolean value that determines if adder and multiplier should be returned if defined
*/
CREATE PROCEDURE [dbo].[GetFormattedMeasurements]
	@measurementSql NVARCHAR(max),
	@includeAdjustments BIT,
	@measurements NVARCHAR(max) OUTPUT
AS
	-- Fill the table variable with the rows for your result set
	DECLARE @measurementID INT
	DECLARE @archiveSource NVARCHAR(50)
	DECLARE @adder FLOAT
	DECLARE @multiplier FLOAT

	SET @measurements = ''''

	CREATE TABLE #temp
	(
		[MeasurementID] INT,
		[ArchiveSource] NVARCHAR(50),
		[Adder] FLOAT,
		[Multiplier] FLOAT
	)

	INSERT INTO #temp EXEC sp_executesql @measurementSql

	DECLARE SelectedMeasurements CURSOR LOCAL FAST_FORWARD FOR SELECT * FROM #temp
	OPEN SelectedMeasurements

	/* Get first row from measurements SQL */
	FETCH NEXT FROM SelectedMeasurements INTO @measurementID, @archiveSource, @adder, @multiplier

	/* Step through selected measurements */
	WHILE @@FETCH_STATUS = 0
	BEGIN		
		IF LEN(@measurements) > 0
			SET @measurements = @measurements + '';''

		IF @includeAdjustments <> 0 AND (@adder <> 0.0 OR @multiplier <> 1.0)
			SET @measurements = @measurements + @archiveSource + '':'' + @measurementID + '','' + @adder + '','' + @multiplier
		ELSE
			SET @measurements = @measurements + @archiveSource + '':'' + @measurementID
		
		/* Get next row from measurements SQL */
		FETCH NEXT FROM SelectedMeasurements INTO @measurementID, @archiveSource, @adder, @multiplier
	END

	CLOSE SelectedMeasurements
	DEALLOCATE SelectedMeasurements

	DROP TABLE #temp

	IF LEN(@measurements) > 0
		SET @measurements = ''{'' + @measurements + ''}''


' 
END
GO
/****** Object:  View [dbo].[IaonOutputAdapter]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[IaonOutputAdapter]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[IaonOutputAdapter]
AS
SELECT     NodeID, ID, AdapterName, AssemblyName, TypeName, ConnectionString
FROM         dbo.RuntimeHistorian
UNION
SELECT     NodeID, ID, AdapterName, AssemblyName, TypeName, ConnectionString
FROM         dbo.RuntimeCustomOutputAdapter
' 
GO
/****** Object:  Table [dbo].[Interconnection]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Interconnection]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Interconnection](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Acronym] [nvarchar](50) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[LoadOrder] [int] NULL CONSTRAINT [DF_Interconnection_LoadOrder]  DEFAULT ((0)),
 CONSTRAINT [PK_Interconnection] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Runtime]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Runtime]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Runtime](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SourceID] [int] NOT NULL,
	[SourceTable] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Runtime] PRIMARY KEY CLUSTERED 
(
	[SourceID] ASC,
	[SourceTable] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Index [IX_Runtime]    Script Date: 08/31/2009 15:52:25 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Runtime]') AND name = N'IX_Runtime')
CREATE UNIQUE NONCLUSTERED INDEX [IX_Runtime] ON [dbo].[Runtime] 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  View [dbo].[IaonActionAdapter]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[IaonActionAdapter]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[IaonActionAdapter]
AS
SELECT     NodeID, ID, AdapterName, AssemblyName, TypeName, ConnectionString
FROM         dbo.RuntimeOutputStream
UNION
SELECT     NodeID, ID, AdapterName, AssemblyName, TypeName, ConnectionString
FROM         dbo.RuntimeCalculatedMeasurement
UNION
SELECT     NodeID, ID, AdapterName, AssemblyName, TypeName, ConnectionString
FROM         dbo.RuntimeCustomActionAdapter
' 
GO
/****** Object:  Table [dbo].[Company]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Company]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Company](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Acronym] [nvarchar](50) NOT NULL,
	[MapAcronym] [nchar](3) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[URL] [nvarchar](max) NULL,
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_Company_LoadOrder]  DEFAULT ((0)),
 CONSTRAINT [PK_Company] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetHistorianMetadata]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GetHistorianMetadata]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'

-- =============================================
-- Author:        Pinal C. Patel
-- Create date: 07/23/09
-- Description:   
-- =============================================
CREATE FUNCTION [dbo].[GetHistorianMetadata] 
(
      @plantCode VARCHAR(24)
)
RETURNS 
@historianMetadata TABLE 
(
      HistorianID INT, 
      DataType INT,
      [Name] VARCHAR(40),
      Synonym1 VARCHAR(40),
      Synonym2 VARCHAR(40),
      Synonym3 VARCHAR(40),
      Description VARCHAR(80),
      HardwareInfo VARCHAR(512),
      Remarks VARCHAR(512),
      PlantCode VARCHAR(24),
      UnitNumber INT,
      SystemName VARCHAR(24),
      SourceID INT,
      Enabled INT,
      ScanRate FLOAT,
      CompressionMinTime INT,
      CompressionMaxTime INT,
      EngineeringUnits VARCHAR(24),
      LowWarning FLOAT,
      HighWarning FLOAT,
      LowAlarm FLOAT,
      HighAlarm FLOAT,
      LowRange FLOAT,
      HighRange FLOAT,
      CompressionLimit FLOAT,
      ExceptionLimit FLOAT,
      DisplayDigits INT,
      SetDescription VARCHAR(24),
      ClearDescription VARCHAR(24),
      AlarmState INT,
      ChangeSecurity INT,
      AccessSecurity INT,
      StepCheck INT,
      AlarmEnabled INT,
      AlarmFlags INT,
      AlarmDelay FLOAT,
      AlarmToFile INT,
      AlarmByEmail INT,
      AlarmByPager INT,
      AlarmByPhone INT,
      AlarmEmails VARCHAR(512),
      AlarmPagers VARCHAR(40),
      AlarmPhones VARCHAR(40)
)
AS
BEGIN
      -- Fill the table variable with the rows for your result set
      DECLARE @warningThreshold FLOAT;
      DECLARE @alarmThreshold FLOAT;
      DECLARE @voltage FLOAT;
      DECLARE @amps FLOAT;

      SET @warningThreshold = 5.0 / 100.0;
      SET @alarmThreshold = 10.0 / 100.0;
      SET @voltage = 500000;
      SET @amps = 3000;

      INSERT INTO @historianMetadata
      SELECT 
            HistorianID             = PointID,
            DataType                = CASE SignalAcronym WHEN ''DIGI'' THEN 1 ELSE 0 END,
            [Name]                  = PointTag,
            Synonym1                = CONVERT(VARCHAR(10), DeviceID) + ''-'' + SUBSTRING(SignalReference, LEN(SignalReference) - CHARINDEX(''-'', REVERSE(SignalReference)) + 2, LEN(SignalReference)),
            Synonym2                = SignalAcronym,
            Synonym3                = AlternateTag,
            Description             = CONVERT(VARCHAR(80), Description),
            HardwareInfo            = VendorDeviceDescription,    
            Remarks                 = '''',
            PlantCode               = HistorianAcronym,
            UnitNumber              = 1,
            SystemName              = DeviceAcronym,
            SourceID                = ProtocolID,
            Enabled                 = Enabled,
            ScanRate                = 1.0 / 30.0,
            CompressionMinTime      = 0,
            CompressionMaxTime      = 0,
            EngineeringUnits        = EngineeringUnits,
            LowWarning              = CASE SignalAcronym WHEN ''FREQ'' THEN 59.95 WHEN ''VPHM'' THEN @voltage - @voltage * @warningThreshold WHEN ''IPHM'' THEN 0 WHEN ''VPHA'' THEN -181 WHEN ''IPHA'' THEN -181 ELSE 0 END,
            HighWarning             = CASE SignalAcronym WHEN ''FREQ'' THEN 60.05 WHEN ''VPHM'' THEN @voltage + @voltage * @warningThreshold WHEN ''IPHM'' THEN @amps + @amps * @warningThreshold WHEN ''VPHA'' THEN 181 WHEN ''IPHA'' THEN 181 ELSE 0 END,
            LowAlarm                = CASE SignalAcronym WHEN ''FREQ'' THEN 59.90 WHEN ''VPHM'' THEN @voltage - @voltage * @alarmThreshold WHEN ''IPHM'' THEN 0 WHEN ''VPHA'' THEN -181 WHEN ''IPHA'' THEN -181 ELSE 0 END,
            HighAlarm               = CASE SignalAcronym WHEN ''FREQ'' THEN 60.10 WHEN ''VPHM'' THEN @voltage + @voltage * @alarmThreshold WHEN ''IPHM'' THEN @amps + @amps * @alarmThreshold WHEN ''VPHA'' THEN 181 WHEN ''IPHA'' THEN 181 ELSE 0 END,
            LowRange                = CASE SignalAcronym WHEN ''FREQ'' THEN 59.95 WHEN ''VPHM'' THEN @voltage - @voltage * @warningThreshold WHEN ''IPHM'' THEN 0 WHEN ''VPHA'' THEN -180 WHEN ''IPHA'' THEN -180 ELSE 0 END,
            HighRange               = CASE SignalAcronym WHEN ''FREQ'' THEN 60.05 WHEN ''VPHM'' THEN @voltage + @voltage * @warningThreshold WHEN ''IPHM'' THEN @amps WHEN ''VPHA'' THEN 180 WHEN ''IPHA'' THEN 180 ELSE 0 END,
            CompressionLimit        = 0.0,
            ExceptionLimit          = 0.0,
            DisplayDigits           = CASE SignalAcronym WHEN ''DIGI'' THEN 0 ELSE 7 END,
            SetDescription          = '''',
            ClearDescription        = '''',
            AlarmState              = 0,
            ChangeSecurity          = 5,
            AccessSecurity          = 0,
            StepCheck               = 0,
            AlarmEnabled            = 0,
            AlarmFlags              = 0,
            AlarmDelay              = 0,
            AlarmToFile             = 0,
            AlarmByEmail            = 0,
            AlarmByPager            = 0,
            AlarmByPhone            = 0,
            AlarmEmails             = MeasurementDetail.ContactList,
            AlarmPagers             = '''',
            AlarmPhones             = ''''
      FROM [dbo].[MeasurementDetail]
      WHERE HistorianAcronym LIKE @plantCode
      ORDER BY HistorianID

      RETURN 
END

' 
END

GO
/****** Object:  Table [dbo].[SignalType]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SignalType]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[SignalType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Acronym] [nvarchar](4) NOT NULL,
	[Suffix] [nvarchar](2) NOT NULL,
	[Abbreviation] [nvarchar](2) NOT NULL,
	[Source] [nvarchar](10) NOT NULL,
	[EngineeringUnits] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_SignalType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[ConfigurationEntity]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ConfigurationEntity]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ConfigurationEntity](
	[SourceName] [nvarchar](100) NOT NULL,
	[RuntimeName] [nvarchar](100) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_ConfigurationEntity_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_ConfigurationEntity_Enabled]  DEFAULT ((0))
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Vendor]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Vendor]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Vendor](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Acronym] [nvarchar](3) NULL,
	[Name] [nvarchar](100) NOT NULL,
	[PhoneNumber] [nvarchar](100) NULL,
	[ContactEmail] [nvarchar](100) NULL,
	[URL] [nvarchar](max) NULL,
 CONSTRAINT [PK_Vendor] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Protocol]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Protocol]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Protocol](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Acronym] [nvarchar](50) NULL,
	[Name] [nvarchar](100) NULL,
 CONSTRAINT [PK_Protocol] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[OutputStreamDeviceDigital]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OutputStreamDeviceDigital]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OutputStreamDeviceDigital](
	[NodeID] [uniqueidentifier] NOT NULL,
	[OutputStreamDeviceID] [int] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Label] [nvarchar](256) NULL,
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_OutputStreamDeviceDigital_LoadOrder]  DEFAULT ((0)),
 CONSTRAINT [PK_OutputStreamDeviceDigital] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[OutputStreamDevice]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OutputStreamDevice]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OutputStreamDevice](
	[NodeID] [uniqueidentifier] NOT NULL,
	[AdapterID] [int] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Acronym] [nvarchar](16) NOT NULL,
	[BpaAcronym] [nvarchar](4) NULL,
	[Name] [nvarchar](100) NOT NULL,
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_OutputStreamDevices_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_OutputStreamDevices_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_OutputStreamDevice] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[CalculatedMeasurement]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CalculatedMeasurement]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CalculatedMeasurement](
	[NodeID] [uniqueidentifier] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Acronym] [nvarchar](50) NOT NULL,
	[Name] [nvarchar](100) NULL,
	[AssemblyName] [nvarchar](max) NOT NULL,
	[TypeName] [nvarchar](max) NOT NULL,
	[ConnectionString] [nvarchar](max) NULL,
	[ConfigSection] [nvarchar](100) NULL,
	[InputMeasurementsSql] [nvarchar](max) NULL,
	[OutputMeasurementsSql] [nvarchar](max) NULL,
	[MinimumMeasurementsToUse] [int] NOT NULL CONSTRAINT [DF_CalculatedMeasurement_MinimumMeasurementsToUse]  DEFAULT ((-1)),
	[FramesPerSecond] [int] NOT NULL CONSTRAINT [DF_CalculatedMeasurement_FramesPerSecond]  DEFAULT ((30)),
	[LagTime] [float] NOT NULL CONSTRAINT [DF_CalculatedMeasurement_LagTime]  DEFAULT ((3.0)),
	[LeadTime] [float] NOT NULL CONSTRAINT [DF_CalculatedMeasurement_LeadTime]  DEFAULT ((1.0)),
	[UseLocalClockAsRealTime] [bit] NOT NULL CONSTRAINT [DF_CalculatedMeasurement_UseLocalClockAsRealTime]  DEFAULT ((0)),
	[AllowSortsByArrival] [bit] NOT NULL CONSTRAINT [DF_CalculatedMeasurement_AllowSortsByArrival]  DEFAULT ((0)),
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_CalculatedMeasurement_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_CalculatedMeasurement_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_CalculatedMeasurement] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[CustomActionAdapter]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomActionAdapter]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CustomActionAdapter](
	[NodeID] [uniqueidentifier] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AdapterName] [nvarchar](50) NOT NULL,
	[AssemblyName] [nvarchar](max) NOT NULL,
	[TypeName] [nvarchar](max) NOT NULL,
	[ConnectionString] [nvarchar](max) NULL,
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_CustomActionAdapter_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_CustomActionAdapter_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_CustomActionAdapter] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[OutputStreamDevicePhasor]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OutputStreamDevicePhasor]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OutputStreamDevicePhasor](
	[NodeID] [uniqueidentifier] NOT NULL,
	[OutputStreamDeviceID] [int] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Label] [nvarchar](12) NULL,
	[Type] [nchar](1) NOT NULL CONSTRAINT [DF_OutputStreamDevicePhasor_Type]  DEFAULT (N'V'),
	[Phase] [nchar](1) NOT NULL CONSTRAINT [DF_OutputStreamDevicePhasor_Phase]  DEFAULT (N'+'),
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_OutputStreamDevicePhasor_LoadOrder]  DEFAULT ((0)),
 CONSTRAINT [PK_OutputStreamDevicePhasor] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[OutputStreamDeviceAnalog]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OutputStreamDeviceAnalog]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OutputStreamDeviceAnalog](
	[NodeID] [uniqueidentifier] NOT NULL,
	[OutputStreamDeviceID] [int] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Label] [nvarchar](16) NULL,
	[Type] [int] NOT NULL CONSTRAINT [DF_OutputStreamDeviceAnalog_Type]  DEFAULT ((0)),
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_OutputStreamDeviceAnalog_LoadOrder]  DEFAULT ((0)),
 CONSTRAINT [PK_OutputStreamDeviceAnalog] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[CustomInputAdapter]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomInputAdapter]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CustomInputAdapter](
	[NodeID] [uniqueidentifier] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AdapterName] [nvarchar](50) NOT NULL,
	[AssemblyName] [nvarchar](max) NOT NULL,
	[TypeName] [nvarchar](max) NOT NULL,
	[ConnectionString] [nvarchar](max) NULL,
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_CustomInputAdapter_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_CustomInputAdapter_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_CustomInputAdapter] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[CustomOutputAdapter]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomOutputAdapter]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[CustomOutputAdapter](
	[NodeID] [uniqueidentifier] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AdapterName] [nvarchar](50) NOT NULL,
	[AssemblyName] [nvarchar](max) NOT NULL,
	[TypeName] [nvarchar](max) NOT NULL,
	[ConnectionString] [nvarchar](max) NULL,
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_CustomOutputAdapter_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_CustomOutputAdapter_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_CustomOutputAdapter] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[OutputStream]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OutputStream]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OutputStream](
	[NodeID] [uniqueidentifier] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Acronym] [nvarchar](50) NOT NULL,
	[Name] [nvarchar](100) NULL,
	[Type] [int] NOT NULL CONSTRAINT [DF_OutputStream_Type]  DEFAULT ((0)),
	[ConnectionString] [nvarchar](max) NULL,
	[IDCode] [int] NOT NULL CONSTRAINT [DF_OutputStream_IDCode]  DEFAULT ((0)),
	[CommandChannel] [nvarchar](max) NULL,
	[AutoPublishConfigFrame] [int] NOT NULL CONSTRAINT [DF_OutputStream_AutoPublishConfigFrame]  DEFAULT ((0)),
	[AutoStartDataChannel] [int] NOT NULL CONSTRAINT [DF_OutputStream_AutoStartDataChannel]  DEFAULT ((1)),
	[NominalFrequency] [int] NOT NULL CONSTRAINT [DF_OutputStream_NominalFrequency]  DEFAULT ((60)),
	[FramesPerSecond] [int] NOT NULL CONSTRAINT [DF_OutputStream_FramesPerSecond]  DEFAULT ((30)),
	[LagTime] [float] NOT NULL CONSTRAINT [DF_OutputStream_LagTime]  DEFAULT ((3.0)),
	[LeadTime] [float] NOT NULL CONSTRAINT [DF_OutputStream_LeadTime]  DEFAULT ((1.0)),
	[UseLocalClockAsRealTime] [bit] NOT NULL CONSTRAINT [DF_OutputStream_UseLocalClockAsRealTime]  DEFAULT ((0)),
	[AllowSortsByArrival] [bit] NOT NULL CONSTRAINT [DF_OutputStream_AllowSortsByArrival]  DEFAULT ((0)),
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_OutputStream_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_OutputStream_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_OutputStream] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Historian]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Historian]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Historian](
	[NodeID] [uniqueidentifier] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Acronym] [nvarchar](50) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[AssemblyName] [nvarchar](max) NOT NULL,
	[TypeName] [nvarchar](max) NOT NULL,
	[ConnectionString] [nvarchar](max) NULL,
	[IsLocal] [bit] NOT NULL CONSTRAINT [DF_Historian_IsLocal]  DEFAULT ((0)),
	[Description] [nvarchar](max) NULL,
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_Historian_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_Historian_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_Historian] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Device]    Script Date: 08/31/2009 15:52:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Device]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Device](
	[NodeID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Device_NodeID]  DEFAULT (newid()),
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ParentID] [int] NULL,
	[Acronym] [nvarchar](16) NOT NULL,
	[Name] [nvarchar](100) NULL,
	[IsConcentrator] [bit] NOT NULL CONSTRAINT [DF_Device_IsConcentrator]  DEFAULT ((0)),
	[CompanyID] [int] NULL,
	[HistorianID] [int] NULL,
	[AccessID] [int] NOT NULL CONSTRAINT [DF_Device_AccessID]  DEFAULT ((0)),
	[VendorDeviceID] [int] NULL,
	[ProtocolID] [int] NULL,
	[Longitude] [decimal](9, 6) NULL,
	[Latitude] [decimal](9, 6) NULL,
	[InterconnectionID] [int] NULL,
	[ConnectionString] [nvarchar](max) NULL,
	[TimeZone] [nvarchar](128) NULL,
	[TimeAdjustmentTicks] [bigint] NOT NULL CONSTRAINT [DF_Device_TimeAdjustmentTicks]  DEFAULT ((0)),
	[DataLossInterval] [float] NOT NULL CONSTRAINT [DF_Device_DataLossInterval]  DEFAULT ((35)),
	[ContactList] [nvarchar](max) NULL,
	[MeasuredLines] [int] NULL,
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_Device_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_Device_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_Device] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[OutputStreamMeasurement]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OutputStreamMeasurement]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OutputStreamMeasurement](
	[NodeID] [uniqueidentifier] NOT NULL,
	[AdapterID] [int] NOT NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[HistorianID] [int] NULL,
	[PointID] [int] NOT NULL,
	[SignalReference] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_OutputStreamMeasurement] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[OtherDevice]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OtherDevice]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OtherDevice](
	[ID] [int] IDENTITY(50000,1) NOT NULL,
	[Acronym] [nvarchar](16) NOT NULL,
	[Name] [nvarchar](100) NULL,
	[IsConcentrator] [bit] NOT NULL CONSTRAINT [DF_OtherDevices_IsConcentrator]  DEFAULT ((0)),
	[CompanyID] [int] NULL,
	[VendorDeviceID] [int] NULL,
	[Longitude] [decimal](9, 6) NULL,
	[Latitude] [decimal](9, 6) NULL,
	[InterconnectionID] [int] NULL,
	[Planned] [bit] NOT NULL CONSTRAINT [DF_OtherDevices_Planned]  DEFAULT ((0)),
	[Desired] [bit] NOT NULL CONSTRAINT [DF_OtherDevices_Desired]  DEFAULT ((0)),
	[InProgress] [bit] NOT NULL CONSTRAINT [DF_OtherDevices_InProgress]  DEFAULT ((0)),
 CONSTRAINT [PK_OtherDevice] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Measurement]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Measurement]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Measurement](
	[SignalID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Measurement_SignalID]  DEFAULT (newid()),
	[HistorianID] [int] NULL,
	[PointID] [int] IDENTITY(1,1) NOT NULL,
	[DeviceID] [int] NOT NULL,
	[PointTag] [nvarchar](50) NOT NULL,
	[AlternateTag] [nvarchar](50) NULL,
	[SignalTypeID] [int] NOT NULL,
	[PhasorSourceIndex] [int] NULL,
	[SignalReference] [nvarchar](max) NOT NULL,
	[Adder] [float] NOT NULL CONSTRAINT [DF_Measurement_Adder]  DEFAULT ((0.0)),
	[Multiplier] [float] NOT NULL CONSTRAINT [DF_Measurement_Multiplier]  DEFAULT ((1.0)),
	[Description] [nvarchar](max) NULL,
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_Measurement_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_Measurement] PRIMARY KEY CLUSTERED 
(
	[SignalID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO

/****** Object:  Index [IX_Measurement_PointID]    Script Date: 08/31/2009 15:52:26 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Measurement]') AND name = N'IX_Measurement_PointID')
CREATE UNIQUE NONCLUSTERED INDEX [IX_Measurement_PointID] ON [dbo].[Measurement] 
(
	[PointID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO

/****** Object:  Index [IX_Measurement_PointTag]    Script Date: 08/31/2009 15:52:26 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Measurement]') AND name = N'IX_Measurement_PointTag')
CREATE UNIQUE NONCLUSTERED INDEX [IX_Measurement_PointTag] ON [dbo].[Measurement] 
(
	[PointTag] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Phasor]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Phasor]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Phasor](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DeviceID] [int] NOT NULL,
	[Label] [nvarchar](50) NULL,
	[Type] [nchar](1) NOT NULL CONSTRAINT [DF_Phasor_Type]  DEFAULT (N'V'),
	[Phase] [nchar](1) NOT NULL CONSTRAINT [DF_Phasor_Phase]  DEFAULT (N'+'),
	[DestinationPhasorID] [int] NULL,
	[SourceIndex] [int] NOT NULL CONSTRAINT [DF_Phasor_SourceIndex]  DEFAULT ((0)),
 CONSTRAINT [PK_Phasor] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Node]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Node]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Node](
	[ID] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Node_ID]  DEFAULT (newid()),
	[Name] [nvarchar](100) NOT NULL,
	[CompanyID] [int] NULL,
	[Longitude] [decimal](9, 6) NULL,
	[Latitude] [decimal](9, 6) NULL,
	[Description] [nvarchar](max) NULL,
	[Image] [nvarchar](max) NULL,
	[Master] [bit] NOT NULL CONSTRAINT [DF_Node_Master]  DEFAULT ((0)),
	[LoadOrder] [int] NOT NULL CONSTRAINT [DF_Node_LoadOrder]  DEFAULT ((0)),
	[Enabled] [bit] NOT NULL CONSTRAINT [DF_Node_Enabled]  DEFAULT ((0)),
 CONSTRAINT [PK_Node] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[VendorDevice]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VendorDevice]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[VendorDevice](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[VendorID] [int] NOT NULL CONSTRAINT [DF_VendorDevice_VendorID]  DEFAULT ((10)),
	[Name] [nvarchar](100) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[URL] [nvarchar](max) NULL,
 CONSTRAINT [PK_VendorDevice] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  UserDefinedFunction [dbo].[FormatMeasurements]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FormatMeasurements]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'/*
	Returns a formatted string of measurements given a SQL statement
	Copyright © 2009 - TVA, all rights reserved
	Primary Developer: James R Carroll, 8/31/2009
	Email: jrcarrol@tva.gov

	Parameters:
	
	measurementSql:
		SQL which returns table of "MeasurementID INT, ArchiveSource NVARCHAR(50), Adder FLOAT, Multiplier FLOAT"
	
	includeAdjustments:
		Boolean value that determines if adder and multiplier should be returned if defined
*/

CREATE FUNCTION [dbo].[FormatMeasurements] (@measurementSql NVARCHAR(max), @includeAdjustments BIT)
RETURNS NVARCHAR(max) 
AS
BEGIN
    DECLARE @measurements NVARCHAR(max) 

	SET @measurements = ''''

	EXEC GetFormattedMeasurements @measurementSql, @includeAdjustments, @measurements

	IF LEN(@measurements) > 0
		SET @measurements = ''{'' + @measurements + ''}''
	ELSE
		SET @measurements = NULL
		
	RETURN @measurements
END
' 
END

GO
/****** Object:  View [dbo].[MeasurementDetail]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[MeasurementDetail]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[MeasurementDetail]
AS
SELECT     dbo.Device.CompanyID, dbo.Company.Acronym AS CompanyAcronym, dbo.Company.Name AS CompanyName, dbo.Measurement.HistorianID, 
                      dbo.Historian.Acronym AS HistorianAcronym, dbo.Historian.ConnectionString AS HistorianConnectionString, dbo.Measurement.PointID, 
                      dbo.Measurement.PointTag, dbo.Measurement.AlternateTag, dbo.Measurement.DeviceID, dbo.Device.Acronym AS DeviceAcronym, 
                      dbo.Device.Name AS DeviceName, dbo.Device.Enabled AS DeviceEnabled, dbo.Device.ContactList, dbo.Device.VendorDeviceID, 
                      dbo.VendorDevice.Name AS VendorDeviceName, dbo.VendorDevice.Description AS VendorDeviceDescription, dbo.Device.ProtocolID, 
                      dbo.Protocol.Acronym AS ProtocolAcronym, dbo.Protocol.Name AS ProtocolName, dbo.Measurement.SignalTypeID, 
                      dbo.Measurement.PhasorSourceIndex, dbo.Phasor.Label AS PhasorLabel, dbo.Phasor.Type AS PhasorType, dbo.Phasor.Phase, 
                      dbo.Measurement.SignalReference, dbo.Measurement.Adder, dbo.Measurement.Multiplier, dbo.Measurement.Description, dbo.Measurement.Enabled, 
                      ISNULL(dbo.SignalType.EngineeringUnits, N'''') AS EngineeringUnits, dbo.SignalType.Source, dbo.SignalType.Acronym AS SignalAcronym, 
                      dbo.SignalType.Name AS SignalName, dbo.SignalType.Suffix AS SignalTypeSuffix, dbo.Device.Longitude, dbo.Device.Latitude
FROM         dbo.Company INNER JOIN
                      dbo.Device ON dbo.Company.ID = dbo.Device.CompanyID RIGHT OUTER JOIN
                      dbo.Measurement LEFT OUTER JOIN
                      dbo.SignalType ON dbo.Measurement.SignalTypeID = dbo.SignalType.ID ON dbo.Device.ID = dbo.Measurement.DeviceID LEFT OUTER JOIN
                      dbo.Phasor ON dbo.Measurement.DeviceID = dbo.Phasor.DeviceID AND 
                      dbo.Measurement.PhasorSourceIndex = dbo.Phasor.SourceIndex LEFT OUTER JOIN
                      dbo.VendorDevice ON dbo.Device.VendorDeviceID = dbo.VendorDevice.ID LEFT OUTER JOIN
                      dbo.Protocol ON dbo.Device.ProtocolID = dbo.Protocol.ID LEFT OUTER JOIN
                      dbo.Historian ON dbo.Measurement.HistorianID = dbo.Historian.ID
' 
GO
/****** Object:  View [dbo].[RuntimeOutputStreamMeasurement]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeOutputStreamMeasurement]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeOutputStreamMeasurement]
AS
SELECT     TOP (100) PERCENT dbo.OutputStreamMeasurement.NodeID, dbo.Runtime.ID AS AdapterID, dbo.Historian.Acronym AS Historian, 
                      dbo.OutputStreamMeasurement.PointID, dbo.OutputStreamMeasurement.SignalReference
FROM         dbo.OutputStreamMeasurement LEFT OUTER JOIN
                      dbo.Historian ON dbo.OutputStreamMeasurement.HistorianID = dbo.Historian.ID LEFT OUTER JOIN
                      dbo.Runtime ON dbo.OutputStreamMeasurement.AdapterID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''OutputStream''
ORDER BY dbo.OutputStreamMeasurement.HistorianID, dbo.OutputStreamMeasurement.PointID
' 
GO
/****** Object:  View [dbo].[RuntimeHistorian]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeHistorian]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeHistorian]
AS
SELECT     TOP (100) PERCENT dbo.Historian.NodeID, dbo.Runtime.ID, dbo.Historian.Acronym AS AdapterName, N''TVA.Historian.dll'' AS AssemblyName, 
                      CASE IsLocal WHEN 1 THEN N''TVA.Historian.TimeSeriesData.LocalOutputAdapter'' ELSE N''TVA.Historian.TimeSeriesData.RemoteOutputAdapter'' END AS
                       TypeName, dbo.Historian.ConnectionString + N''; sourceIDs='' + dbo.Historian.Acronym AS ConnectionString
FROM         dbo.Historian LEFT OUTER JOIN
                      dbo.Runtime ON dbo.Historian.ID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''OutputStream''
WHERE     (dbo.Historian.Enabled <> 0)
ORDER BY dbo.Historian.LoadOrder
' 
GO
/****** Object:  View [dbo].[RuntimeInputStreamMeasurement]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeInputStreamMeasurement]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeInputStreamMeasurement]
AS
SELECT     dbo.Device.NodeID, dbo.Runtime.ID AS AdapterID, dbo.Measurement.PointID, dbo.Historian.Acronym AS Historian, dbo.Measurement.Adder, 
                      dbo.Measurement.Multiplier
FROM         dbo.Device INNER JOIN
                      dbo.Measurement ON dbo.Device.ID = dbo.Measurement.DeviceID LEFT OUTER JOIN
                      dbo.Historian ON dbo.Measurement.HistorianID = dbo.Historian.ID LEFT OUTER JOIN
                      dbo.Runtime ON dbo.Device.ID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''Device''
WHERE     (dbo.Device.Enabled <> 0) AND (dbo.Measurement.Enabled <> 0)
' 
GO
/****** Object:  View [dbo].[RuntimeDevice]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeDevice]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeDevice]
AS
SELECT     TOP (100) PERCENT dbo.Device.NodeID, dbo.Runtime.ID, dbo.Device.Acronym AS AdapterName, N''TVA.PhasorProtocols.dll'' AS AssemblyName, 
                      N''TVA.PhasorProtocols.PhasorMeasurementMapper'' AS TypeName, dbo.Device.ConnectionString + N''; isConcentrator='' + CONVERT(NVARCHAR(10), 
                      dbo.Device.IsConcentrator) + CASE dbo.Device.TimeZone WHEN NULL 
                      THEN N'''' ELSE N''; timeZone='' + dbo.Device.TimeZone END + N''; timeAdjustmentTicks='' + CONVERT(NVARCHAR(10), dbo.Device.TimeAdjustmentTicks) 
                      + CASE dbo.Protocol.Acronym WHEN NULL 
                      THEN N'''' ELSE N''; phasorProtocol='' + dbo.Protocol.Acronym END + N''; dataLossInterval='' + CONVERT(NVARCHAR(10), dbo.Device.DataLossInterval) 
                      AS ConnectionString
FROM         dbo.Device LEFT OUTER JOIN
                      dbo.Protocol ON dbo.Device.ProtocolID = dbo.Protocol.ID LEFT OUTER JOIN
                      dbo.Runtime ON dbo.Device.ID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''Device''
WHERE     (dbo.Device.Enabled <> 0)
ORDER BY dbo.Device.LoadOrder
' 
GO
/****** Object:  View [dbo].[RuntimeCustomOutputAdapter]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeCustomOutputAdapter]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeCustomOutputAdapter]
AS
SELECT     TOP (100) PERCENT dbo.CustomOutputAdapter.NodeID, dbo.Runtime.ID, dbo.CustomOutputAdapter.AdapterName, 
                      dbo.CustomOutputAdapter.AssemblyName, dbo.CustomOutputAdapter.TypeName, dbo.CustomOutputAdapter.ConnectionString
FROM         dbo.CustomOutputAdapter LEFT OUTER JOIN
                      dbo.Runtime ON dbo.CustomOutputAdapter.ID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''CustomOutputAdapter''
WHERE     (dbo.CustomOutputAdapter.Enabled <> 0)
ORDER BY dbo.CustomOutputAdapter.LoadOrder
' 
GO
/****** Object:  View [dbo].[RuntimeInputStreamConcentratorDevice]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeInputStreamConcentratorDevice]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeInputStreamConcentratorDevice]
AS
SELECT     TOP (100) PERCENT dbo.Device.NodeID, Runtime_P.ID AS ParentID, dbo.Runtime.ID, dbo.Device.Acronym, dbo.Device.AccessID
FROM         dbo.Device LEFT OUTER JOIN
                      dbo.Runtime ON dbo.Device.ID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''Device'' LEFT OUTER JOIN
                      dbo.Runtime AS Runtime_P ON dbo.Device.ParentID = Runtime_P.SourceID AND Runtime_P.SourceTable = N''Device''
WHERE     (dbo.Device.IsConcentrator = 0) AND (dbo.Device.Enabled <> 0) AND (dbo.Device.ParentID IS NOT NULL)
ORDER BY dbo.Device.LoadOrder
' 
GO
/****** Object:  View [dbo].[RuntimeCustomInputAdapter]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeCustomInputAdapter]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeCustomInputAdapter]
AS
SELECT     TOP (100) PERCENT dbo.CustomInputAdapter.NodeID, dbo.Runtime.ID, dbo.CustomInputAdapter.AdapterName, 
                      dbo.CustomInputAdapter.AssemblyName, dbo.CustomInputAdapter.TypeName, dbo.CustomInputAdapter.ConnectionString
FROM         dbo.CustomInputAdapter LEFT OUTER JOIN
                      dbo.Runtime ON dbo.CustomInputAdapter.ID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''CustomInputAdapter''
WHERE     (dbo.CustomInputAdapter.Enabled <> 0)
ORDER BY dbo.CustomInputAdapter.LoadOrder
' 
GO
/****** Object:  View [dbo].[RuntimeOutputStreamDevice]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeOutputStreamDevice]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeOutputStreamDevice]
AS
SELECT     TOP (100) PERCENT dbo.OutputStreamDevice.NodeID, dbo.Runtime.ID AS AdapterID, dbo.OutputStreamDevice.ID, dbo.OutputStreamDevice.Acronym, 
                      dbo.OutputStreamDevice.BpaAcronym, dbo.OutputStreamDevice.Name, dbo.OutputStreamDevice.LoadOrder
FROM         dbo.OutputStreamDevice LEFT OUTER JOIN
                      dbo.Runtime ON dbo.OutputStreamDevice.AdapterID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''OutputStream''
WHERE     (dbo.OutputStreamDevice.Enabled <> 0)
ORDER BY dbo.OutputStreamDevice.LoadOrder
' 
GO
/****** Object:  View [dbo].[RuntimeOutputStream]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeOutputStream]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeOutputStream]
AS
SELECT     TOP (100) PERCENT dbo.OutputStream.NodeID, dbo.Runtime.ID, dbo.OutputStream.Acronym AS AdapterName, 
                      N''TVA.PhasorProtocols.dll'' AS AssemblyName, 
                      CASE Type WHEN 1 THEN N''TVA.PhasorProtocols.BpaPdcStream.Concentrator'' ELSE N''TVA.PhasorProtocols.IeeeC37_118.Concentrator'' END AS TypeName,
                       dbo.OutputStream.ConnectionString + N''; framesPerSecond='' + CONVERT(NVARCHAR(10), dbo.OutputStream.FramesPerSecond) 
                      + N''; lagTime='' + CONVERT(NVARCHAR(10), dbo.OutputStream.LagTime) + N''; leadTime='' + CONVERT(NVARCHAR(10), dbo.OutputStream.LeadTime) 
                      + N''; useLocalClockAsRealTime='' + CONVERT(NVARCHAR(10), dbo.OutputStream.UseLocalClockAsRealTime) 
                      + N''; allowSortsByArrival='' + CONVERT(NVARCHAR(10), dbo.OutputStream.AllowSortsByArrival) AS ConnectionString
FROM         dbo.OutputStream LEFT OUTER JOIN
                      dbo.Runtime ON dbo.OutputStream.ID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''OutputStream''
WHERE     (dbo.OutputStream.Enabled <> 0)
ORDER BY dbo.OutputStream.LoadOrder
' 
GO
/****** Object:  View [dbo].[RuntimeCustomActionAdapter]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeCustomActionAdapter]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeCustomActionAdapter]
AS
SELECT     TOP (100) PERCENT dbo.CustomActionAdapter.NodeID, dbo.Runtime.ID, dbo.CustomActionAdapter.AdapterName, 
                      dbo.CustomActionAdapter.AssemblyName, dbo.CustomActionAdapter.TypeName, dbo.CustomActionAdapter.ConnectionString
FROM         dbo.CustomActionAdapter LEFT OUTER JOIN
                      dbo.Runtime ON dbo.CustomActionAdapter.ID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''CustomActionAdapter''
WHERE     (dbo.CustomActionAdapter.Enabled <> 0)
ORDER BY dbo.CustomActionAdapter.LoadOrder
' 
GO
/****** Object:  View [dbo].[RuntimeCalculatedMeasurement]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[RuntimeCalculatedMeasurement]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[RuntimeCalculatedMeasurement]
AS
SELECT     TOP (100) PERCENT dbo.CalculatedMeasurement.NodeID, dbo.Runtime.ID, dbo.CalculatedMeasurement.Acronym AS AdapterName, 
                      dbo.CalculatedMeasurement.AssemblyName, dbo.CalculatedMeasurement.TypeName, CASE ConfigSection WHEN NULL 
                      THEN N'''' ELSE N''configurationSection='' + ConfigSection + N''; '' END + N''minimumMeasurementsToUse='' + CONVERT(NVARCHAR(10), 
                      dbo.CalculatedMeasurement.MinimumMeasurementsToUse) + N''; framesPerSecond='' + CONVERT(NVARCHAR(10), 
                      dbo.CalculatedMeasurement.FramesPerSecond) + N''; lagTime='' + CONVERT(NVARCHAR(10), dbo.CalculatedMeasurement.LagTime) 
                      + N''; leadTime='' + CONVERT(NVARCHAR(10), dbo.CalculatedMeasurement.LeadTime) + CASE InputMeasurementsSql WHEN NULL 
                      THEN N'''' ELSE N''; inputMeasurementKeys='' + dbo.FormatMeasurements(InputMeasurementsSql, 0) END + CASE OutputMeasurementsSql WHEN NULL
                       THEN N'''' ELSE N''; outputMeasurements='' + dbo.FormatMeasurements(OutputMeasurementsSql, 1) END AS ConnectionString
FROM         dbo.CalculatedMeasurement LEFT OUTER JOIN
                      dbo.Runtime ON dbo.CalculatedMeasurement.ID = dbo.Runtime.SourceID AND dbo.Runtime.SourceTable = N''CalculatedMeasurement''
WHERE     (dbo.CalculatedMeasurement.Enabled <> 0)
ORDER BY dbo.CalculatedMeasurement.LoadOrder
' 
GO
/****** Object:  View [dbo].[IaonInputAdapter]    Script Date: 08/31/2009 15:52:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[IaonInputAdapter]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[IaonInputAdapter]
AS
SELECT     NodeID, ID, AdapterName, AssemblyName, TypeName, ConnectionString
FROM         dbo.RuntimeDevice
UNION
SELECT     NodeID, ID, AdapterName, AssemblyName, TypeName, ConnectionString
FROM         dbo.RuntimeCustomInputAdapter
' 
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
USE [openPDC]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamDeviceDigital_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamDeviceDigital]'))
ALTER TABLE [dbo].[OutputStreamDeviceDigital]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamDeviceDigital_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamDeviceDigital_OutputStreamDevice]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamDeviceDigital]'))
ALTER TABLE [dbo].[OutputStreamDeviceDigital]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamDeviceDigital_OutputStreamDevice] FOREIGN KEY([OutputStreamDeviceID])
REFERENCES [dbo].[OutputStreamDevice] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamDevice_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamDevice]'))
ALTER TABLE [dbo].[OutputStreamDevice]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamDevice_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamDevice_OutputStream]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamDevice]'))
ALTER TABLE [dbo].[OutputStreamDevice]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamDevice_OutputStream] FOREIGN KEY([AdapterID])
REFERENCES [dbo].[OutputStream] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CalculatedMeasurement_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[CalculatedMeasurement]'))
ALTER TABLE [dbo].[CalculatedMeasurement]  WITH CHECK ADD  CONSTRAINT [FK_CalculatedMeasurement_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CustomActionAdapter_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[CustomActionAdapter]'))
ALTER TABLE [dbo].[CustomActionAdapter]  WITH CHECK ADD  CONSTRAINT [FK_CustomActionAdapter_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamDevicePhasor_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamDevicePhasor]'))
ALTER TABLE [dbo].[OutputStreamDevicePhasor]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamDevicePhasor_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamDevicePhasor_OutputStreamDevice]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamDevicePhasor]'))
ALTER TABLE [dbo].[OutputStreamDevicePhasor]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamDevicePhasor_OutputStreamDevice] FOREIGN KEY([OutputStreamDeviceID])
REFERENCES [dbo].[OutputStreamDevice] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamDeviceAnalog_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamDeviceAnalog]'))
ALTER TABLE [dbo].[OutputStreamDeviceAnalog]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamDeviceAnalog_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamDeviceAnalog_OutputStreamDevice]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamDeviceAnalog]'))
ALTER TABLE [dbo].[OutputStreamDeviceAnalog]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamDeviceAnalog_OutputStreamDevice] FOREIGN KEY([OutputStreamDeviceID])
REFERENCES [dbo].[OutputStreamDevice] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CustomInputAdapter_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[CustomInputAdapter]'))
ALTER TABLE [dbo].[CustomInputAdapter]  WITH CHECK ADD  CONSTRAINT [FK_CustomInputAdapter_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CustomOutputAdapter_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[CustomOutputAdapter]'))
ALTER TABLE [dbo].[CustomOutputAdapter]  WITH CHECK ADD  CONSTRAINT [FK_CustomOutputAdapter_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStream_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStream]'))
ALTER TABLE [dbo].[OutputStream]  WITH CHECK ADD  CONSTRAINT [FK_OutputStream_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Historian_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[Historian]'))
ALTER TABLE [dbo].[Historian]  WITH CHECK ADD  CONSTRAINT [FK_Historian_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Device_Company]') AND parent_object_id = OBJECT_ID(N'[dbo].[Device]'))
ALTER TABLE [dbo].[Device]  WITH CHECK ADD  CONSTRAINT [FK_Device_Company] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[Company] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Device_Device]') AND parent_object_id = OBJECT_ID(N'[dbo].[Device]'))
ALTER TABLE [dbo].[Device]  WITH CHECK ADD  CONSTRAINT [FK_Device_Device] FOREIGN KEY([ParentID])
REFERENCES [dbo].[Device] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Device_Historian]') AND parent_object_id = OBJECT_ID(N'[dbo].[Device]'))
ALTER TABLE [dbo].[Device]  WITH CHECK ADD  CONSTRAINT [FK_Device_Historian] FOREIGN KEY([HistorianID])
REFERENCES [dbo].[Historian] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Device_Interconnection]') AND parent_object_id = OBJECT_ID(N'[dbo].[Device]'))
ALTER TABLE [dbo].[Device]  WITH CHECK ADD  CONSTRAINT [FK_Device_Interconnection] FOREIGN KEY([InterconnectionID])
REFERENCES [dbo].[Interconnection] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Device_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[Device]'))
ALTER TABLE [dbo].[Device]  WITH CHECK ADD  CONSTRAINT [FK_Device_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Device_Protocol]') AND parent_object_id = OBJECT_ID(N'[dbo].[Device]'))
ALTER TABLE [dbo].[Device]  WITH CHECK ADD  CONSTRAINT [FK_Device_Protocol] FOREIGN KEY([ProtocolID])
REFERENCES [dbo].[Protocol] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Device_VendorDevice]') AND parent_object_id = OBJECT_ID(N'[dbo].[Device]'))
ALTER TABLE [dbo].[Device]  WITH CHECK ADD  CONSTRAINT [FK_Device_VendorDevice] FOREIGN KEY([VendorDeviceID])
REFERENCES [dbo].[VendorDevice] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamMeasurement_Historian]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamMeasurement]'))
ALTER TABLE [dbo].[OutputStreamMeasurement]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamMeasurement_Historian] FOREIGN KEY([HistorianID])
REFERENCES [dbo].[Historian] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamMeasurement_Measurement]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamMeasurement]'))
ALTER TABLE [dbo].[OutputStreamMeasurement]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamMeasurement_Measurement] FOREIGN KEY([PointID])
REFERENCES [dbo].[Measurement] ([PointID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamMeasurement_Node]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamMeasurement]'))
ALTER TABLE [dbo].[OutputStreamMeasurement]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamMeasurement_Node] FOREIGN KEY([NodeID])
REFERENCES [dbo].[Node] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OutputStreamMeasurement_OutputStream]') AND parent_object_id = OBJECT_ID(N'[dbo].[OutputStreamMeasurement]'))
ALTER TABLE [dbo].[OutputStreamMeasurement]  WITH CHECK ADD  CONSTRAINT [FK_OutputStreamMeasurement_OutputStream] FOREIGN KEY([AdapterID])
REFERENCES [dbo].[OutputStream] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OtherDevice_Company]') AND parent_object_id = OBJECT_ID(N'[dbo].[OtherDevice]'))
ALTER TABLE [dbo].[OtherDevice]  WITH CHECK ADD  CONSTRAINT [FK_OtherDevice_Company] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[Company] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OtherDevice_Interconnection]') AND parent_object_id = OBJECT_ID(N'[dbo].[OtherDevice]'))
ALTER TABLE [dbo].[OtherDevice]  WITH CHECK ADD  CONSTRAINT [FK_OtherDevice_Interconnection] FOREIGN KEY([InterconnectionID])
REFERENCES [dbo].[Interconnection] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_OtherDevice_VendorDevice]') AND parent_object_id = OBJECT_ID(N'[dbo].[OtherDevice]'))
ALTER TABLE [dbo].[OtherDevice]  WITH CHECK ADD  CONSTRAINT [FK_OtherDevice_VendorDevice] FOREIGN KEY([VendorDeviceID])
REFERENCES [dbo].[VendorDevice] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Measurement_Device]') AND parent_object_id = OBJECT_ID(N'[dbo].[Measurement]'))
ALTER TABLE [dbo].[Measurement]  WITH CHECK ADD  CONSTRAINT [FK_Measurement_Device] FOREIGN KEY([DeviceID])
REFERENCES [dbo].[Device] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Measurement_Historian]') AND parent_object_id = OBJECT_ID(N'[dbo].[Measurement]'))
ALTER TABLE [dbo].[Measurement]  WITH CHECK ADD  CONSTRAINT [FK_Measurement_Historian] FOREIGN KEY([HistorianID])
REFERENCES [dbo].[Historian] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Measurement_SignalType]') AND parent_object_id = OBJECT_ID(N'[dbo].[Measurement]'))
ALTER TABLE [dbo].[Measurement]  WITH CHECK ADD  CONSTRAINT [FK_Measurement_SignalType] FOREIGN KEY([SignalTypeID])
REFERENCES [dbo].[SignalType] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Phasor_Device]') AND parent_object_id = OBJECT_ID(N'[dbo].[Phasor]'))
ALTER TABLE [dbo].[Phasor]  WITH CHECK ADD  CONSTRAINT [FK_Phasor_Device] FOREIGN KEY([DeviceID])
REFERENCES [dbo].[Device] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Phasor_Phasor]') AND parent_object_id = OBJECT_ID(N'[dbo].[Phasor]'))
ALTER TABLE [dbo].[Phasor]  WITH CHECK ADD  CONSTRAINT [FK_Phasor_Phasor] FOREIGN KEY([DestinationPhasorID])
REFERENCES [dbo].[Phasor] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Node_Company]') AND parent_object_id = OBJECT_ID(N'[dbo].[Node]'))
ALTER TABLE [dbo].[Node]  WITH CHECK ADD  CONSTRAINT [FK_Node_Company] FOREIGN KEY([CompanyID])
REFERENCES [dbo].[Company] ([ID])
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_VendorDevice_Vendor]') AND parent_object_id = OBJECT_ID(N'[dbo].[VendorDevice]'))
ALTER TABLE [dbo].[VendorDevice]  WITH CHECK ADD  CONSTRAINT [FK_VendorDevice_Vendor] FOREIGN KEY([VendorID])
REFERENCES [dbo].[Vendor] ([ID])
