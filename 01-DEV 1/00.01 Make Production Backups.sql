/*

The purpose of this script is to create backups of the tables that will be altered during migration
This script creates the backups of production in the [Salesforce backups] database that can be referred to
after the migration if we need to revert any changes. There is also a backup query in Google BigQuery here:
https://console.cloud.google.com/bigquery?sq=196195326827:3fb547cb8f8b4b71bb48a635b6254db5

Be very careful altering production data and good luck to anyone reading this :)
Please consult me if you feel unsure about anything
-Michael Ricci

*/

----------------------------------------------------------------------ACCOUNT BACKUP----------------------------------------------------------------------

/*
-- this code will drop existing backups if they need to be replaced. This section is commented out so it is not run by accident. You can highlight the code and run the comment without uncommenting it
if exists (select * from [Salesforce backups].INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Account_Backup' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Salesforce backups].dbo.Account_Backup
*/

USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Account','PKCHUNK'

Select *
INTO [Salesforce backups].dbo.Account_Backup
FROM Source_Production_SALESFORCE.dbo.Account A

select count(*) FROM [Salesforce backups].dbo.Account_Backup

----------------------------------------------------------------------Contact BACKUP----------------------------------------------------------------------
/*
if exists (select * from [Salesforce backups].INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contact_Backup' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Salesforce backups].dbo.Contact_Backup
*/
USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Contact','PKCHUNK'

Select *
INTO [Salesforce backups].dbo.Contact_Backup
FROM Source_Production_SALESFORCE.dbo.Contact A

select count(*) FROM [Salesforce backups].dbo.Contact_Backup

----------------------------------------------------------------------Opportunity BACKUP----------------------------------------------------------------------
/*
if exists (select * from [Salesforce backups].INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Opportunity_Backup' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Salesforce backups].dbo.Opportunity_Backup
*/
USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Opportunity','PKCHUNK'

Select *
INTO [Salesforce backups].dbo.Opportunity_Backup
FROM Source_Production_SALESFORCE.dbo.Opportunity A

select count(*) FROM [Salesforce backups].dbo.Opportunity_Backup
----------------------------------------------------------------------Contract BACKUP----------------------------------------------------------------------
/*
if exists (select * from [Salesforce backups].INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_Backup' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Salesforce backups].dbo.Contract_Backup
*/
USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'Contract','PKCHUNK'

Select *
INTO [Salesforce backups].dbo.Contract_Backup
FROM Source_Production_SALESFORCE.dbo.Contract A

select count(*) FROM [Salesforce backups].dbo.Contract_Backup

----------------------------------------------------------------------Subscription BACKUP----------------------------------------------------------------------
/*
if exists (select * from [Salesforce backups].INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Subscription__c_Backup' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Salesforce backups].dbo.SBQQ__Subscription__c_Backup
*/
USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__Subscription__c','PKCHUNK'

Select *
INTO [Salesforce backups].dbo.SBQQ__Subscription__c_Backup
FROM Source_Production_SALESFORCE.dbo.SBQQ__Subscription__c A

select count(*) FROM [Salesforce backups].dbo.SBQQ__Subscription__c_Backup

----------------------------------------------------------------------Opportunitylineitem BACKUP----------------------------------------------------------------------
/*
if exists (select * from [Salesforce backups].INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OpportunityLineItem_Backup' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Salesforce backups].dbo.OpportunityLineItem_Backup
*/
USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'OpportunityLineItem','PKCHUNK'

Select *
INTO [Salesforce backups].dbo.OpportunityLineItem_Backup
FROM Source_Production_SALESFORCE.dbo.OpportunityLineItem A

select count(*) FROM [Salesforce backups].dbo.OpportunityLineItem_Backup


----------------------------------------------------------------------Quote BACKUP----------------------------------------------------------------------
/*
if exists (select * from [Salesforce backups].INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Quote__c_Backup' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Salesforce backups].dbo.SBQQ__Quote__c_Backup
*/
USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'SBQQ__Quote__c','PKCHUNK'

Select *
INTO [Salesforce backups].dbo.SBQQ__Quote__c_Backup
FROM Source_Production_SALESFORCE.dbo.SBQQ__Quote__c

select count(*) FROM [Salesforce backups].dbo.SBQQ__Quote__c_Backup

----------------------------------------------------------------------ContentDocumentLink BACKUP----------------------------------------------------------------------
-- cant run this now because of query rules around ContentDocumentLink
-- error: MALFORMED_QUERY: Implementation restriction: ContentDocumentLink requires a filter by a single Id on ContentDocumentId or LinkedEntityId using the equals operator or multiple Id's using the IN operator
/*
if exists (select * from [Salesforce backups].INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'ContentDocumentLink_Backup' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Salesforce backups].dbo.ContentDocumentLink_Backup
*/

/*
USE [Source_Production_SALESFORCE];
EXEC Source_Production_SALESFORCE.dbo.SF_Replicate 'Production_SALESFORCE', 'ContentDocumentLink'

Select *
INTO [Salesforce backups].dbo.ContentDocumentLink_Backup
FROM Source_Production_SALESFORCE.dbo.ContentDocumentLink

select count(*) FROM [Salesforce backups].dbo.ContentDocumentLink_Backup
*/