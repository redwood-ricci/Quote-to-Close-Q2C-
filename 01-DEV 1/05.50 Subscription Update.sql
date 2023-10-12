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
USE Insert_Database_Name_Here;

EXEC SF_Refresh 'SANDBOX_QA', 'Product2', 'yes'
EXEC SF_Refresh 'SANDBOX_QA', 'PriceBook2', 'yes'
EXEC SF_Refresh 'SANDBOX_QA', 'PriceBookEntry', 'yes'
EXEC SF_Refresh 'SANDBOX_QA', 'SBQQ__QuoteLine__c', 'yes'
EXEC SF_Refresh 'SANDBOX_QA', 'Contract', 'yes'
EXEC SF_Refresh 'SANDBOX_QA', 'SBQQ__Subscription__c', 'yes'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'SBQQ__Subscription__c_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE SBQQ__Subscription__c_Load

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;

WITH Sub_CTE as 
(
	Select 
	Row_Number() OVER (Partition by a.[Correct SF Account ID], a.[End Date], a.[Start Date], a.[Product] Order By a.[start date], a.[Product], a.[Tier (Quantity)] Asc) as RowNum,
	a.[Correct SF Account ID] as AccountID, a.[End Date] as EndDate,
	a.*
	FROM [Insert_SOURCE_Database_Name_Here].[dbo].[MasterSubscriptions] a
)

Select
Cast('' as nvarchar(18)) as [ID],
Cast('' as nvarchar(255)) as Error,
a.[Correct SF Account ID] as SBQQ__Account__c, 
CNT.ID as SBQQ__Contract__c, 
CASE 
	WHEN a.[Tier (Quantity)] = '0' THEN a.ARR
	    ELSE a.[ARR] / a.[Tier (Quantity)]  * [dbo].[CPQProrateCalculator](a.[Start Date], a.[End Date], 'Monthly + Daily') END as SBQQ__CustomerPrice__c, 
CASE WHEN a.[Tier (Quantity)] = '0' THEN a.ARR
	 ELSE isNull(a.[ARR] / a.[Tier (Quantity)], '') * [dbo].[CPQProrateCalculator](a.[Start Date], a.[End Date], 'Monthly + Daily') END as SBQQ__NetPrice__c,
CASE WHEN a.[Tier (Quantity)] = '0' THEN a.ARR
	  ELSE isNull(a.[ARR] / a.[Tier (Quantity)], '') * [dbo].[CPQProrateCalculator](a.[Start Date], a.[End Date], 'Monthly + Daily') END as SBQQ__ListPrice__c,
CASE WHEN a.[Tier (Quantity)] = '0' THEN a.ARR
	  ELSE isNull(a.[ARR] / a.[Tier (Quantity)], '') * [dbo].[CPQProrateCalculator](a.[Start Date], a.[End Date], 'Monthly + Daily') END as SBQQ__UnitCost__c,
PROD.ID as SBQQ__Product__c, 
[dbo].[CPQProrateCalculator](a.[Start Date], a.[End Date], 'Monthly + Daily') as SBQQ__ProrateMultiplier__c, 
a.[Tier (Quantity)] as SBQQ__Quantity__c, 
a.[ARR] as SBQQ__RegularPrice__c, 
CASE a.[Billing Frequency] 
		WHEN 'Bi-Annual' THEN 'SemiAnnual'
		WHEN '3 years' THEN ''
		WHEN '3 year' THEN ''
		WHEN '2 Years' THEN ''
		WHEN '2 Year' THEN ''
		ELSE a.[Billing Frequency] END as SBQQ__BillingFrequency__c, 
CASE a.[Billing Frequency] 
		WHEN 'Bi-Annual' THEN 'Recurring'
		WHEN '3 years' THEN 'One-Time'
		WHEN '3 year' THEN 'One-Time'
		WHEN '2 Years' THEN 'One-Time'
		WHEN '2 Year' THEN 'One-Time'
		ELSE 'Recurring' END as SBQQ__ChargeType__c, 
CASE a.[Billing Frequency] 
		WHEN '3 years' THEN ''
		WHEN '3 year' THEN ''
		WHEN '2 Years' THEN ''
		WHEN '2 Year' THEN ''
		ELSE 'Fixed Price' END as SBQQ__SubscriptionPricing__c, 
CASE WHEN a.[Tier (Quantity)] = '0' THEN '1'
ELSE a.[Tier (Quantity)] END as SBQQ__RenewalQuantity__c, 
a.[Start Date] as SBQQ__SubscriptionStartDate__c,  
'List' as SBQQ__PricingMethod__c, 
a.[End Date] as SBQQ__SubscriptionEndDate__c, 
'Advance' as SBQQ__BillingType__c, 
QLE.ID as SBQQ__OriginalQuoteLine__c, 
QLE.ID as SBQQ__QuoteLine__c, 
'Renewable' as SBQQ__ProductSubscriptionType__c, 
Prod.SBQQ__SubscriptionType__c as  SBQQ__SubscriptionType__c,
Concat(a.[Correct SF Account ID], ':', Prod.[Name], ':', Convert(varchar(10), a.[Start Date], 120), ':', Convert(varchar(10), a.[End Date], 120), ':', a.RowNum) as Migration_id2__c
INTO SBQQ__Subscription__c_Load
FROM Sub_CTE a
LEFT OUTER JOIN map_product MAP on a.Product = MAP.OLD_Product
LEFT OUTER JOIN Product2 PROD on PROD.[Name] = MAP.NEW_Product
LEFT OUTER JOIN Pricebook2 PB ON PB.[Name] = 'PowerDMS Price book (New)'
LEFT OUTER JOIN PriceBookEntry PBE on PROD.ID = PBE.Product2Id and PBE.Pricebook2Id = PB.ID
LEFT OUTER JOIN [Contract] CNT on CNT.AccountId =  a.[Correct SF Account ID] AND CNT.Migration_ID2__c = Concat(a.[Correct SF Account ID], ':', Convert(varchar(10), a.[End Date], 120) )
LEFT OUTER JOIN SBQQ__QuoteLine__c QLE on QLE.Migration_id__c = Concat(a.[Correct SF Account ID], ':', Prod.[Name], ':', Convert(varchar(10), a.[Start Date], 120), ':', Convert(varchar(10), a.[End Date], 120), ':', a.RowNum) 
LEFT OUTER JOIN SBQQ__Subscription__c Subscr ON Subscr.Migration_ID2__c = Concat(a.[Correct SF Account ID], ':', Prod.[Name], ':', Convert(varchar(10), a.[Start Date], 120), ':', Convert(varchar(10), a.[End Date], 120), ':', a.RowNum) 
WHERE
Subscr.Id is Null
AND isnull(a.[Ignore], '') <> '1'
AND a.AccountID <> '0012K00001hoG6XQAU'

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE SBQQ__Subscription__c_Load
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE Insert_Database_Name_Here;
EXEC SF_Tableloader 'Upsert:bulkapi, batchsize(10)', 'SANDBOX_QA', 'SBQQ__Subscription__c_Load', 'Migration_Id2__c'


---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- USE Insert_Database_Name_Here; Select error, * from SBQQ__Subscription__c_Load_Result a where error not like '%success%'


-- USE Insert_Database_Name_Here; EXEC SF_Tableloader 'HardDelete:batchsize(10)', 'SANDBOX_QA', 'SBQQ__QuoteLine__c_Load_Result'

-- USE Insert_Database_Name_Here; EXEC SF_Tableloader 'Delete:batchsize(10)', 'SANDBOX_QA', 'SBQQ__QuoteLine__c_Load2_Result'