---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Testing Test
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE [Source_Production_SALESFORCE];

EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Opportunity','PKCHUNK'

select 
	id
-- 	,Name
	,NextStep
	into Source_Production_SALESFORCE.dbo.[Opportunity_Load]
	from Source_Production_SALESFORCE.dbo.Opportunity
	where id = '006Qn000003hNhBIAU'

-- examine results
select * from Source_Production_SALESFORCE.dbo.[Opportunity_Load]

---------------------------------------------------------------------------------
-- Make an update
---------------------------------------------------------------------------------

Update x
Set NextStep = 'DB AMP!'
from Source_Production_SALESFORCE.dbo.[Opportunity_Load] x
where NextStep is null


-- very carefully push the update to production
USE Source_Production_SALESFORCE;
EXEC Source_Production_SALESFORCE.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(1)','Production_SALESFORCE','Opportunity_Load'

----------------------------------------------------------------------ACCOUNT BACKUP----------------------------------------------------------------------
/*
-- Commented out so these have to be run on purpose to drop tables
if exists (select * from [Salesforce backups].INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Account_Backup' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Salesforce backups].dbo.Account_Backup
*/

USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Account'

Select *
INTO [Salesforce backups].dbo.Account_Backup
FROM Source_Production_SALESFORCE.dbo.Account A

select * FROM [Salesforce backups].dbo.Account_Backup

----------------------------------------------------------------------Contact BACKUP----------------------------------------------------------------------
USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Contact'

Select *
INTO [Salesforce backups].dbo.Contact_Backup
FROM Source_Production_SALESFORCE.dbo.Account A

select * FROM [Salesforce backups].dbo.Contact_Backup

----------------------------------------------------------------------Opportunity BACKUP----------------------------------------------------------------------
USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Opportunity'

Select *
INTO [Salesforce backups].dbo.Opportunity_Backup
FROM Source_Production_SALESFORCE.dbo.Account A

----------------------------------------------------------------------Contract BACKUP----------------------------------------------------------------------

----------------------------------------------------------------------Subscription BACKUP----------------------------------------------------------------------

----------------------------------------------------------------------Opportunitylineitem BACKUP----------------------------------------------------------------------

----------------------------------------------------------------------Quote BACKUP----------------------------------------------------------------------

select * FROM [Salesforce backups].dbo.Opportunity_Backup