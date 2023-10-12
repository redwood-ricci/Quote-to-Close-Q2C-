---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Subscription Attachment Update Script	
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
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Attachment'



---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <Staging>;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Attachment_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <Staging>.dbo.Attachment_Update

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

select
ID,
ParentID

INTO <Staging>.dbo.Attachment_Update
FROM SourceQA.dbo.Attachment a
inner join <Staging>.dbo.Order_Insert


---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE <Staging>.dbo.Attachment_Update
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------

EXEC <Staging>.dbo.SF_Tableloader 'Update: bulkapi, batchsize(10)', 'SANDBOX_QA', 'Attachment_Update'