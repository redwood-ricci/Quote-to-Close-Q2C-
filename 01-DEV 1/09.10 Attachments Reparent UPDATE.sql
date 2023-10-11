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
USE <Source>;

EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'ContentVersion'

EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'ContentDocumentLink'



---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <Staging>;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'ContentDocumentLink_LoadAttachmentsB' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <Staging>.dbo.ContentDocumentLink_LoadAttachments

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
	INTO <staging>.dbo.ContentDocumentLink_LoadAttachments
	From <source>.dbo.ContentVersion a
	inner join <source>.dbo.ContentDocumentLink CDL
		on CDL. = A.ID

where -- Filter so we get the ones that are linked to custom Invoice object

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE <Staging>.dbo.ContentDocumentLink_LoadAttachments
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC <Staging>.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(10)','INSERT_LINKED_SERVER_NAME','ContentDocumentLink_LoadAttachments'