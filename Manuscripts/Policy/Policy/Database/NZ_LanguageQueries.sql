-- Added a single line comment
-- Query for Support Code List:
-- Update 30Nov2023 - Changes are added as part of PAD deployment 
------------------------------------------------------------------------------------------------------------------------------
declare @cType nvarchar(20)
declare @code nvarchar(20)
declare @cmd nvarchar(500)
declare @newCulture nvarchar(20)

set @newCulture = 'en-NZ'

declare codeLists cursor for
select rtrim(CodeType), rtrim(Code) FROM DC_PLT_Support_CodeLists where CultureCode = 'en-US'

open codeLists
fetch next from codeLists into @cType,@code
while @@fetch_status = 0
BEGIN
	
	set @cmd = N'if not exists (select 1 from DC_PLT_Support_CodeLists where CultureCode = '''+ @newCulture +''' and CodeType=''' + @cType + N'''  and CodeType= ''' + @cType + N''' and Code=''' + @code + ''')
         Insert Into DC_PLT_Support_CodeLists
		 Select '''+ @newCulture +''',CodeType,Code,SortSequence,Description,BaseCodeIndicator from DC_PLT_Support_CodeLists 
		 where CultureCode = ''en-US'' and CodeType = ''' + @cType + ''' and Code = '''+ @code +''''

	--print @cmd
	EXEC sp_executeSQL @cmd

  fetch next from codeLists into @cType,@code
END

close codeLists 
deallocate codeLists

--Query for Support Messages:
------------------------------------------
if not exists (select 1 from DC_PLT_Support_Messages where CultureCode = 'en-NZ')
begin
	Insert Into DC_PLT_Support_Messages
	Select MessageId,'en-NZ',MessageText,BaseMessageIndicator from DC_PLT_Support_Messages  where CultureCode = 'en-US'
end

--TODO: Add in AU specific translations (e.g. 'cheque' instead of 'check')

--Added aus state to support specific state wise commission plan

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='NSWAU' )
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','NSWAU',NULL,'New South Wales',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='NTAU' )
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
						values ('en-NZ','PLT_USSTATES','NTAU',NULL,'Northern Territory',1);
END

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='WAAU' )
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
						values ('en-NZ','PLT_USSTATES','WAAU',NULL,'Western Australia',1);
END
IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='QLDAU' )
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
						values ('en-NZ','PLT_USSTATES','QLDAU',NULL,'Queensland',1);
END

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='ACTAU' )
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                 values ('en-NZ','PLT_USSTATES','ACTAU',NULL,'Australian Capital Territory',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='SAAU' )
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','SAAU',NULL,'South Australia',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='TASAU' )
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','TASAU',NULL,'Tasmania',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='VICAU' )
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','VICAU',NULL,'Victoria',1);
end


--Added NZ state to support specific state wise commission plan
IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='001' and CultureCode='en-NZ' )
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','001',NULL,'Northland',1);
end


IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='002' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','002',NULL,'Auckland',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='003' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','003',NULL,'Waikato',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='004' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','004',NULL,'Bay of Plenty',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='005' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','005',NULL,'Gisborne',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='006' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','006',NULL,'Hawke Bay',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='007' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','007',NULL,'Taranaki',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='008' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','008',NULL,'Whanganui-Manawatu',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='009' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','009',NULL,'Wellington',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='012' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','012',NULL,'West Coast',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='013' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','013',NULL,'Canterbury',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='014' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','014',NULL,'Otago',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='015' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','015',NULL,'Southland',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='016' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','016',NULL,'Tasman',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='017' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','017',NULL,'Nelson',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='018' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','018',NULL,'Marlborough',1);
end

IF NOT EXISTS (SELECT 1 FROM DC_PLT_Support_CodeLists WHERE CodeType = 'PLT_USSTATES' and Code ='099' AND CultureCode='en-NZ')
begin
Insert Into DC_PLT_Support_CodeLists (CultureCode,CodeType,Code,SortSequence,Description,BaseCodeIndicator)
		                                  values ('en-NZ','PLT_USSTATES','099',NULL,'Area Outside Region',1);
end