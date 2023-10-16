---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Attachment Insert Script
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  
--- Created Date: 10/11/2023
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'ContentVersion'

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA','ContentDocumentLink','PKCHUNK'



---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'ContentDocumentLink_LoadAttachments' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.ContentDocumentLink_LoadAttachments

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select Distinct
	CAST('' as nvarchar(18)) as ID,
	CAST('' as nvarchar(2000)) as error,
	a.ContentDocumentID as ContentDocumentID,
	'' as LinkedEntityID,
	CASE Substring(map.ID, 1, 3) WHEN '02s' THEN 'V'  --- set on EmailMessage object to prevent editing by user
								 ELSE 'I' END as ShareType,
	'AllUsers' as Visibility
	--INTO StageQA.dbo.ContentDocumentLink_LoadAttachments
	
select *
	From SourceQA.dbo.ContentVersion a --535 rows
	inner join SourceQA.dbo.ContentDocumentLink CDL
		on CDL. = A.ID

where -- Filter so we get the ones that are linked to custom Invoice object

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.ContentDocumentLink_LoadAttachments
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(10)','SANDBOX_QA','ContentDocumentLink_LoadAttachments'