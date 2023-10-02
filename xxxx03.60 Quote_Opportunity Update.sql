---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Quote Opportunity Update Script	
--- Customer: PowerDMS PlanIt Migration
--- Primary Developer: Patrick Bowen
--- Secondary Developers:  
--- Created Date: 10 June 2022
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. 
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'sbqq__Quote__c', 'yes'
EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'Opportunity', 'yes'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'sbqq__Quote__c_OpportunityUpdate' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [sbqq__Quote__c_OpportunityUpdate]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

Select 
	a.ID as Id,
	CAST('' as nvarchar(255)) as Error,
	Oppty.Id as sbqq__Opportunity2__c
	INTO sbqq__Quote__c_OpportunityUpdate
	FROM sbqq__quote__c a
	LEFT OUTER JOIN Opportunity Oppty ON a.migration_id__c = Oppty.Migration_Id__c
	WHERE a.Migration_Id__c is not null

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE [sbqq__Quote__c_OpportunityUpdate]
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;
EXEC SF_Tableloader 'Update: Bulkapi, batchsize(5)', 'INSERT_LINKED_SERVER_NAME', 'sbqq__Quote__c_OpportunityUpdate'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from sbqq__Quote__c_OpportunityUpdate_result a where error not like '%success%'