---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: CONTRACT RENEWAL FLAG UPDATE
--- Customer: Redwood
--- Primary Developer: Jim Ziller
--- Secondary Developers:  Jim Ziller 
--- Created Date: 10/6/2023
--- Last Updated: 
--- Change Log: 
--- Prerequisites:
--- 1. 1.10 Order
--- 2. 1.20 Order Item
--- 3. 1.30 Contract
--- 4. 1.40 Subscription
--- 5. 2.10 Order Update
--- 6. 2.20 OrderItem Update
--- 7. 5.10-Contract_Activate_UPDATE
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------




--NOTE: This script should only be used if you need to bulk trigger renewal quotes on contracts
--DO NOT RUN THIS UNLESS THAT IS THE INTENTION.
--If this script is not needed, remove it from the Migration deployment and move it into the template library

-- A variation of this cript can set the Renewal Foreast flag to trigger CPQ to create the Renewal Opportunities in BULK












USE SourceQA;

---------------------------------------------------------------------------------
--- COPY DATA FROM SALESFORCE
---------------------------------------------------------------------------------
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA' ,'Contract', 'PkChunk'

---------------------------------------------------------------------------------
--- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_UPDATE_RenewalFlag' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.Contract_UPDATE_RenewalFlag;


select 
	C.ID,
	Cast('' as nvarchar(2000)) as Error,
	C.Contract_Migration_ID__c,
	'true' as SBQQ__RenewalQuoted__c
into StageQA.dbo.Contract_UPDATE_RenewalFlag  
from SourceQA.dbo.[Contract] C

where [status] = 'Activated'
and SBQQ__RenewalForecast__c = 'true'
and SBQQ__RenewalQuoted__c = 'false'
and enddate >= getdate()

order by c.AccountId
---------------------------------------------------------------------------------
-- ADD sort column to speed bulk load performance If Necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.Contract_UPDATE_RenewalFlag
ADD [Sort] int IDENTITY (1,1)


--select * from StageQA.dbo.Contract_UPDATE_RenewalFlag 
---------------------------------------------------------------------------------
-- Load Subscription Data To Full Sandbox -- 
---------------------------------------------------------------------------------
EXEC StageQA.dbo.SF_TableLoader 'UPDATE','SANDBOX_QA','Contract_UPDATE_RenewalFlag' 
---------------------------------------------------------------------------------
--- ERROR REVIEW
-----------------------------------------------------------------------------------
Select * 
from StageQA.dbo.Contract_UPDATE_RenewalFlag_result
where error not like '%Success%'


--select 
--* 
--from  SourceQA.dbo.[Contract] c 
--where SBQQ__RenewalQuoted__c = 'false' 
--and [status] = 'Activated'
--and SBQQ__RenewalForecast__c = 'true'
--and SBQQ__RenewalQuoted__c = 'false'
--and c.Migrated_Contract_ID__c is not null