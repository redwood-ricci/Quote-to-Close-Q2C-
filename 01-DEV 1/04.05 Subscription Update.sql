---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: Subscription Load Script	
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
USE SourceQA;

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'OrderItem','PKCHUNK'

EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Contract','PKCHUNK'
EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__Subscription__c','PKCHUNK'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Subscription__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.SBQQ__Subscription__c_Load

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE StageQA;

Select
	S.ID as [ID],
	Cast('' as nvarchar(2000)) as Error,
	'One-time' as SBQQ__SubscriptionType__c,
	'One-time' as SBQQ__ProductSubscriptionType__c,
	--OI.ID as [SBQQ__OrderProduct__c], -- update existing subscription to link to newly created Order Product

	/* ADD IN ANY OTHER UPDATES, IF NEEDED */


	/* REFERENCE FIELDS */
	S.[SBQQ__Account__c] as REF_AccountID, 
	S.[SBQQ__Contract__c] as REF_ContractID, 
	S.[SBQQ__Product__c] as REF_ProductID, 
	S.[SBQQ__QuoteLine__c] as REF_QuoteLine

	INTO StageQA.dbo.SBQQ__Subscription__c_Load

	FROM SourceQA.dbo.SBQQ__Subscription__c S
	--inner join SourceQA.dbo.OrderItem OI
		--on S.ID = OI.Order_Item_Migration_id__c -- Need to have this field created with unique and external on OrderItem
	WHERE S.SBQQ__Product__c IN ('01t3t000006eKWqAAM','01t3t000006eKpgAAE','01t3t000006eKn6AAE','01t3t000006eKnGAAU','01t3t000006eKmCAAU','01t3t000006rE6RAAU',
	'01t3t000006eKpmAAE','01t3t000006eKnSAAU','01t3t000006eKmzAAE','01t3t000006e98hAAA','01t3t000006eKnJAAU','01t3t000006eKpJAAU','01t3t000006eKnBAAU','01t3t000006eKqEAAU',
	'01t3t000006eKX1AAM','01t3t000006eKWhAAM','01t3t000006eKmFAAU','01t3t000006eKnKAAU','01t3t000006eKloAAE','01t3t000006eKnQAAU','01t3t000006eKpDAAU','01t3t000006eKnVAAU',
	'01t3t000006eKWaAAM','01t3t000006eKlzAAE','01t3t000006rE6OAAU','01t3t000006eKndAAE','01t3t000006eKn8AAE','01t3t000006eKmnAAE','01t3t000006eKn2AAE','01t3t000006eKoHAAU',
	'01t3t000006eKm1AAE','01t3t000006eKp5AAE','01t3t000006eKplAAE','01tO900000022P7IAI','01t3t000006e98mAAA','01t3t000006eKWiAAM','01t3t000006eKlpAAE','01t3t000006eKn0AAE',
	'01t3t000006eKnqAAE','01t3t000006eKUwAAM','01t3t000006eKo7AAE','01t3t000006eKoGAAU','01t3t000006eKpMAAU','01t3t000006eKm8AAE','01t3t000006eKnNAAU','01t3t000006eKWYAA2',
	'01t3t000006eKWnAAM','01t3t000006eKWvAAM','01t3t000006eKX2AAM','01t3t000006eKpZAAU','01t3t000006eKoAAAU','01t3t000006eKoLAAU','01t3t000006eKo4AAE','01tO900000022NVIAY',
	'01t3t000006eKpCAAU','01t3t000006eKV1AAM','01t3t000006eKqFAAU','01t3t000006eKpiAAE','01t3t000006eKlrAAE','01t3t000006eKnAAAU','01t3t000006eKozAAE','01t3t000006eKnvAAE',
	'01t3t000006eKnrAAE','01t3t000006eKWsAAM','01t3t000006eKoVAAU','01t3t000006eKWfAAM','01t3t000006eKmHAAU','01t3t000006eKoSAAU','01t3t000006eKWjAAM','01t3t000006eKoYAAU',
	'01t3t000006eKltAAE','01t3t000006rE6WAAU','01t3t000006eKpvAAE','01t3t000006eKpNAAU','01t3t000006eKphAAE','01t3t000006eKnUAAU','01t3t000006eKoRAAU','01t3t000006eKpbAAE',
	'01t3t000006eKlqAAE','01t3t000006eKWwAAM','01t3t000006eKpWAAU','01t3t000006eKWuAAM','01t3t000006eKn5AAE','01t3t000006eKpOAAU','01t3t000006eKlvAAE','01t3t000006eKo5AAE',
	'01t3t000006eKnDAAU','01t3t000006eKpeAAE','01t3t000006eKnHAAU','01t3t000006eKpwAAE','01t3t000006eKWkAAM','01t3t000006eKWyAAM','01t3t000006eKoKAAU','01t3t000006eKpfAAE',
	'01t3t000006eKpVAAU','01t3t000006eKlxAAE','01t3t000006e96UAAQ','01t3t000006eKn4AAE','01t3t000006eKodAAE','01t3t000006eKoaAAE','01t3t000006eKn7AAE','01t3t000006eKWmAAM',
	'01t3t000006eKpLAAU','01t3t000006eKlsAAE','01t3t000006eKWdAAM','01t3t000006eKpKAAU','01t3t000006eKpPAAU','01t3t000006eKoMAAU','01t3t000006eKmmAAE','01t3t000006eKoQAAU',
	'01t3t000006eKq8AAE','01t3t000006eKWZAA2','01t3t000006eKWlAAM','01t3t000006eKq7AAE','01t3t000006e97tAAA','01t3t000006eKonAAE','01t3t000006eKo9AAE','01t3t000006eKWzAAM',
	'01t3t000006eKoeAAE','01t3t000006eKpTAAU','01t3t000006eKX5AAM','01t3t000006eKoJAAU','01t3t000006eKoCAAU','01t3t000006eKoOAAU','01t3t000006eKoNAAU','01t3t000006eKpGAAU',
	'01t3t000006eKn9AAE','01t3t000006eKnOAAU','01t3t000006eKWrAAM','01t3t000006eKomAAE','01t3t000006eKoFAAU','01t3t000006eKmEAAU','01t3t000006eKmuAAE','01t3t000006eKn1AAE',
	'01t3t000006eKmyAAE','01t3t000006eKnMAAU','01t3t000006eKlyAAE','01t3t000006eKpHAAU','01t3t000006eKpdAAE','01t3t000006eKp4AAE','01t3t000006eKoBAAU','01t3t000006eKoXAAU',
	'01t3t000006eKnRAAU','01t3t000006eKoTAAU','01t3t000006eKpXAAU','01t3t000006eKpIAAU','01t3t000006eKnPAAU','01t3t000006eKpYAAU','01t3t000006rE6MAAU','01t3t000006eKmKAAU',
	'01t3t000006eKm2AAE','01t3t000006eKq9AAE','01t3t000006eKoDAAU','01t3t000006eKm5AAE','01t3t000006eKnLAAU','01t3t000006eKmhAAE','01t3t000006eKWgAAM','01t3t000006eKoyAAE',
	'01t3t000006eKo3AAE','01t3t000006eKpEAAU','01t3t000006eKWoAAM','01t3t000006eKmAAAU','01t3t000006eKpUAAU','01t3t000006eKlnAAE','01t3t000006eKm3AAE','01t3t000006e97yAAA',
	'01t3t000006eKm6AAE','01t3t000006eKoUAAU','01t3t000006eKnwAAE','01t3t000006eKmgAAE','01t3t000006eKm4AAE','01t3t000006eKoZAAU','01t3t000006eKmMAAU','01t3t000006eKllAAE',
	'01t3t000006eKnCAAU','01t3t000006eKmVAAU','01t3t000006eKnTAAU','01t3t000006eKnFAAU','01t3t000006eKmDAAU','01t3t000006eKlmAAE','01t3t000006eKn3AAE','01t3t000006eKWbAAM',
	'01t3t000006eKWXAA2','01t3t000006eKpcAAE','01t3t000006eKpSAAU','01t3t000006eKmoAAE','01t3t000006eKmiAAE','01t3t000006eKpnAAE','01t3t000006eKpRAAU','01t3t000006eKluAAE',
	'01t3t000006eKneAAE','01t3t000006eKmvAAE','01t3t000006eKpFAAU','01t3t000006eKmUAAU','01t3t000006e96BAAQ','01t3t000006e96CAAQ','01t3t000006eKnpAAE','01t3t000006eKmBAAU',
	'01t3t000006eKlwAAE','01t3t000006eKnxAAE','01t3t000006eKoEAAU','01t3t000006eKpaAAE','01t3t000006rE6NAAU','01t3t000006eKoPAAU','01t3t000006eKocAAE','01t3t000006eKpQAAU',
	'01t3t000006eKmGAAU','01t3t000006eKX4AAM','01t3t000006e96DAAQ','01t3t000006eKp0AAE','01t3t000006eKV6AAM','01t3t000006eKmxAAE','01t3t000006eKWcAAM','01t3t000006eKp6AAE',
	'01t3t000006eKm9AAE','01t3t000006eKm0AAE','01t3t000006eKX3AAM','01t3t000006eKmJAAU','01t3t000006eKWpAAM','01t3t000006eKobAAE','01t3t000006eKWtAAM','01t3t000006eKoWAAU',
	'01t3t000006eKo8AAE','01t3t000006eKm7AAE','01t3t000006eKmIAAU','01t3t000006eKo6AAE','01t3t000006eKoIAAU','01t3t000006eKnEAAU','01t3t000006eKX0AAM','01t3t000006eKnIAAU',
	'01t3t000006eKpjAAE','01t3t000006eKqDAAU','01t3t000006eKWxAAM','01t3t000006eKWeAAM','01t3t000006eKmLAAU','01t3t000006eKmwAAE','01t3t000006eKpkAAE','01tO9000002xAU3IAM','01tO9000002xAVTIA2')

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------

ALTER TABLE StageQA.dbo.SBQQ__Subscription__c_Load
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY REF_ContractID) AS OrderRowNumber
  FROM StageQA.dbo.SBQQ__Subscription__c_Load
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;


---------------------------------------------------------------------------------
-- Validations
---------------------------------------------------------------------------------
select OrderProduct_Migration_id__c, count(*) 
from StageQA.dbo.SBQQ__Subscription__c_Load
group by OrderProduct_Migration_id__c
having count(*) > 1

select *
 from StageQA.dbo.SBQQ__Subscription__c_Load


---------------------------------------------------------------------------------
-- Scrub
---------------------------------------------------------------------------------


---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;

EXEC StageQA.dbo.SF_Tableloader 'UPDATE:bulkapi,batchsize(10)','SANDBOX_QA','SBQQ__Subscription__c_Load'

---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- USE StageQA; Select error, * from SBQQ__Subscription__c_Load_Result a where error not like '%success%'


-- USE StageQA; EXEC SF_Tableloader 'HardDelete:batchsize(10)', 'SANDBOX_QA', 'SBQQ__QuoteLine__c_Load_Result'

-- USE StageQA; EXEC SF_Tableloader 'Delete:batchsize(10)', 'SANDBOX_QA', 'SBQQ__QuoteLine__c_Load2_Result'


-- NOTE WITH UPDATES, DO NOT USE DBAMP'S DELETE. SAVE THE ORIGINAL VALUE AND JUST SET IT BACK WITH ANOTHER UPDATE