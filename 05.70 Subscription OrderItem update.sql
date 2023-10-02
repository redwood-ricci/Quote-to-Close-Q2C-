---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Subscription OrderItem Update Script	
--- Customer: PowerDMS PlanIt Migration
--- Primary Developer: Patrick Bowen
--- Secondary Developers:  
--- Created Date: 21 June 2022
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

EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'SBQQ__Subscription__c', 'yes'
EXEC SF_Refresh 'INSERT_LINKED_SERVER_NAME', 'OrderItem', 'yes'



---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Subscription__c_OI_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE SBQQ__Subscription__c_OI_Update

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

select
a.ID as [ID],
ORDI.ID as sbqq__OrderProduct__c
INTO SBQQ__Subscription__c_OI_Update
FROM SBQQ__Subscription__c a
INNER JOIN OrderItem OrdI on OrdI.Migration_id__c = a.Migration_ID2__c
WHERE a.Migration_ID2__c is not null

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE SBQQ__Subscription__c_OI_Update
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

USE Insert_Database_Name_Here;
EXEC SF_Tableloader 'Update: bulkapi, batchsize(10)', 'INSERT_LINKED_SERVER_NAME', 'SBQQ__Subscription__c_OI_Update'