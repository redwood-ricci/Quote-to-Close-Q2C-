---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Contract SBQQ__Order__c Update Script	
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
USE Insert_Database_Name_Here;

EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'Contract', 'yes'
EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'Order', 'yes'


---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_OrderUpdate' AND TABLE_SCHEMA = 'dbo')
DROP TABLE [Contract_OrderUpdate]

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

Select 
	a.ID as Id,
	CAST('' as nvarchar(255)) as Error,
	Ord.Id as SBQQ__Order__c
	INTO Contract_OrderUpdate
	FROM [Contract] a
	LEFT OUTER JOIN [Order] Ord ON a.migration_id2__c = Ord.Migration_Id__c
	WHERE a.Migration_Id2__c is not null

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE [Contract_OrderUpdate]
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;
EXEC SF_Tableloader 'Update: Bulkapi, batchsize(5)', 'INSERT_LINKED_SERVER_NAME', 'Contract_OrderUpdate'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- Select error, * from Contract_OrderUpdate_result a where error not like '%success%'