---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
--- Title: OrderItem Load Script	
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
USE <Source>;

EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Order'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Product2'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'PriceBook2'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'PriceBookEntry'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Opportunity'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'OpportunityLineItem'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'SBQQ__QuoteLine__c'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'SBQQ__Subscription__c'
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'Contract' 
EXEC <Source>.dbo.SF_Replicate 'INSERT_LINKED_SERVER_NAME', 'OrderItem'

---------------------------------------------------------------------------------
-- Drop Staging Table
---------------------------------------------------------------------------------
USE <staging>;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OrderItem_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE <staging>.dbo.OrderItem_Load

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------

Select
	OI.ID as Id
	,CAST('' as nvarchar(2000)) as Error


-- MIGRATION FIELDS 																						
	,'' as Migration_id__c


--Quote Line to Order Product mappings
	,QLE.ID as SBQQ__QuoteLine__c
	,QLE.SBQQ__Product__c as Product2Id
	,QLE.SBQQ__BillingFrequency__c
	,QLE.SBQQ__BillingType__c
	,QLE.SBQQ__BlockPrice__c
	,QLE.SBQQ__ChargeType__c
	,QLE.CreateByID

	,QLE.SBQQ__DefaultSubscriptionTerm__c
	,QLE.SBQQ__Description__c as [Description]
	,QLE.SBQQ__Dimension__c as SBQQ__PriceDimension__c
	,QLE.SBQQ__DiscountSchedule__c
	,QLE.SBQQ__EndDate__c as EndDate
	,QLE.SBQQ__ListPrice__c as ListPrice
	,QLE.SBQQ__ListPrice__c as SBQQ__QuotedListPrice__c
	,QLE.SBQQ__Quantity__c as SBQQ__OrderedQuantity__c
	,QLE.SBQQ__Quantity__c as Quantity
	,QLE.SBQQ__Quantity__c as SBQQ__QuotedQuantity__c
	,QLE.SBQQ__PricebookEntryId__c as PricebookEntryId

	,QLE.SBQQ__PricingMethod__c
	,QLE.SBQQ__ProductSubscriptionType__c
	,QLE.SBQQ__ProductOption__c 



	,QLE.SBQQ__ProrateMultiplier__c
	,QLE.SBQQ__RequiredBy__c
	,QLE.SBQQ__SegmentIndex__c
	,QLE.SBQQ__SegmentKey__c
	,QLE.SBQQ__SubscriptionPricing__c
	,QLE.SBQQ__StartDate__c as ServiceDate
	,QLE.SBQQ__SubscriptionTerm__c
	,QLE.SBQQ__SubscriptionType__c
	,QLE.SBQQ__TaxCode__c
	,QLE.SBQQ__TermDiscountSchedule__c
	,QLE.SBQQ__UnproratedNetPrice__c

	--ListPrice



	SBQQ__ShippingAccount__c

--Subscription
	,SUB.ID as SBQQ__Subscription__c
	,SUB.SBQQ__RequiredByProduct__c as SBQQ__RequiredBy__c

-- Contract
	Cnt.ID as SBQQ__Contract__c
	'true' as 	SBQQ__Contracted__c


ORD.ID as OrderId,

CASE WHEN a.[Tier (Quantity)] = '0' THEN a.ARR
	 ELSE isNull(a.[ARR] / a.[Tier (Quantity)], '') * [dbo].[CPQProrateCalculator](a.[Start Date], a.[End Date], 'Monthly + Daily') END as UnitPrice, 



'New' as SBQQ__ContractAction__c, 
 
'Draft' as SBQQ__Status__c, 



INTO <staging>.dbo.OrderItem_Load

FROM  <Source>.dbo.SBQQ__QuoteLine__c QLE
LEFT JOIN <Source>.dbo.SBQQ__Subscription__c SUB on SUB.SBQQ__QuoteLine__c = QLE.ID
LEFT JOIN <Source>.dbo.[Contract] Cnt on SUB.SBQQ__Contract__c = Cnt.ID
LEFT JOIN <Source>.dbo.[Order]  Ord = Cnt.OrderID = Ord.ID

WHERE


---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE OrderItem_Load
ADD [Sort] int IDENTITY (1,1)

---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE <staging>;
EXEC <staging>.dbo.SF_Tableloader 'INSERT:bulkapi, batchsize(5)', 'INSERT_LINKED_SERVER_NAME', 'OrderItem_Load'


---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- USE Insert_Database_Name_Here; Select error, * from OrderItem_Load_Result a where error not like '%success%'


-- USE Insert_Database_Name_Here; EXEC SF_Tableloader 'HardDelete:batchsize(10)', 'INSERT_LINKED_SERVER_NAME', 'SBQQ__QuoteLine__c_Load_Result'