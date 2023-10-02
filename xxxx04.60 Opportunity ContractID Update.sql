---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Opportunity ContractID Update Script	
--- Customer: PowerDMS PlanIt Migration
--- Primary Developer: Patrick Bowen
--- Secondary Developers:  
--- Created Date: 15 June 2022
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

EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'Contract', 'yes'
EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'Opportunity', 'yes'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Opportunity_ContractIDUpdate' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Opportunity_ContractIDUpdate]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

Select 
	a.ID as Id,
	CAST('' as nvarchar(255)) as Error,
	Contr.Id as ContractID
	INTO Opportunity_ContractIDUpdate
	FROM Opportunity a
	LEFT OUTER JOIN [Contract] Contr ON a.migration_id__c = Contr.Migration_Id2__c
	WHERE a.Migration_Id__c is not null

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE [Opportunity_ContractIDUpdate]
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;
EXEC SF_Tableloader 'Update: Bulkapi, batchsize(5)', 'INSERT_LINKED_SERVER_NAME', 'Opportunity_ContractIDUpdate'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from Opportunity_ContractIDUpdate_result a where error not like '%success%'