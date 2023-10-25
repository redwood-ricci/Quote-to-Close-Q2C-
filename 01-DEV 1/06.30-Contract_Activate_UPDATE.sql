---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Contract ACTIVATION
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
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------


--NOTE: ONLY USED THIS SCRIPT IF YOU NEED TO SET THE STATUS OF THE CONTRACT
-- Since all contracts are being used to create the orders, they likely are all activated.Ideally they don't have to be deactivated. 
--Deactivation would require writing the opposite of this script and setting all contracts to not be activated
--If this script is not needed, remove it from the deployment plan and move the script to the template folder in Git for reference.





USE SourceQA;

---------------------------------------------------------------------------------
--- COPY DATA FROM SALESFORCE
---------------------------------------------------------------------------------
EXEC [SourceQA].dbo.SF_Replicate 'SANDBOX_QA','Contract','PkChunk'
---------------------------------------------------------------------------------
--- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'Contract_Activate_Update' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.Contract_Activate_Update;


SELECT 
	C.ID,
	Cast('' as nvarchar(2000)) as Error,
	C.Contract_Migration_ID__c,
	CASE
		WHEN C.EndDate < GETDATE() THEN 'Terminated' -- There should not be any Terminated, but if any come up, this would catch them
		ELSE 'Activated'
	END as [Status]
into StageQA.dbo.Contract_Activate_Update
FROM SourceQA.dbo.[Contract] C
--Limit the records to ones migrated
INNER JOIN StageQA.dbo.Contract_LoadFULL_Result z
	ON C.Contract_Migration_ID__c = z.Contract_Migration_ID__c
WHERE C.Contract_Migration_ID__c is not null
AND [Status] NOT IN ('Activated', 'Terminated') -- This can allow the process to run only the ones that haven't been activated 
-- and the script can be started over to pick up the rest.
ORDER BY c.AccountId

---------------------------------------------------------------------------------
-- ADD sort column to speed bulk load performance If Necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.Contract_Activate_Update
ADD [Sort] int IDENTITY (1,1)


--select * from StageQA.dbo.Contract_Activate_Update

---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select Contract_Migration_ID__c, count(*) 
from StageQA.dbo.Contract_Activate_Update
ADD [Sort] int IDENTITY (1,1)
group by Contract_Migration_ID__c
having count(*) > 1


-- See how many are Terminated. Does this make sense if any come up?
select [Status], count(*)
from StageQA.dbo.Contract_Activate_Update
group by [Status]

---------------------------------------------------------------------------------
-- Load -- 
---------------------------------------------------------------------------------
EXEC [StageQA].dbo.SF_TableLoader 'UPDATE','SANDBOX_QA','Contract_Activate_Update'


---------------------------------------------------------------------------------
--- ERROR REVIEW
---------------------------------------------------------------------------------
Select * 
from [StageQA].dbo.Contract_Activate_Update_result
where error not like '%Success%'


select * from  SourceQA.dbo.[Contract] c where status = 'Expired' and C.Contract_Migration_ID__c is not null