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
-- 10/27 Loaded in 01:13 with
---------------------------------------------------------------------------------
-- Replicate Data
---------------------------------------------------------------------------------
	USE SourceQA;

	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Order','PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Product2','PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBook2','PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'PriceBookEntry','PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Opportunity','PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'OpportunityLineItem','PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__QuoteLine__c','PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__Subscription__c','PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'Contract' ,'PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'OrderItem','PKCHUNK'
	EXEC SourceQA.dbo.SF_Replicate 'SANDBOX_QA', 'SBQQ__ProductOption__c','PKCHUNK'
	---------------------------------------------------------------------------------
	-- some data checks
	---------------------------------------------------------------------------------
	-- select * FROM SourceQA.dbo.[Order]
	-- select * FROM SourceQA.dbo.[OrderItem]
	-- select count(*) FROM SourceQA.dbo.[OrderItem]
	---------------------------------------------------------------------------------
	-- Drop Staging Table
	---------------------------------------------------------------------------------
	USE StageQA;

if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'OrderItem_Load' AND TABLE_SCHEMA = 'dbo')
DROP TABLE StageQA.dbo.OrderItem_Load

---------------------------------------------------------------------------------
-- Create Staging Table
---------------------------------------------------------------------------------
DECLARE @RedwoodNewDeal2024 VARCHAR(100); -- Declares a string variable with a maximum length of 100 characters.
DECLARE @RedwoodLegacyDeal VARCHAR(100);
DECLARE @TieredPriceBook2023 VARCHAR(100);

SET @RedwoodNewDeal2024 = '01sO90000008D4xIAE';
SET @RedwoodLegacyDeal = '01sO90000008D4yIAE';
SET @TieredPriceBook2023 = '01s3t000004H01QAAS';

Select
-- top 10000
	CAST('' AS nvarchar(18)) AS [ID]
	,CAST('' as nvarchar(2000)) as Error

-- MIGRATION FIELDS 																						
	,Sub.ID as Order_Item_Migration_id__c
	

--Quote Line to Order Product mappings
	,QL.ID as SBQQ__QuoteLine__c

--Product Fields
	,P2.ID AS Product2Id
	,P2.SBQQ__BillingFrequency__c
	,P2.SBQQ__BillingType__c 
	,QL.SBQQ__BlockPrice__c
	,P2.SBQQ__ChargeType__c
--	,PBE.UnitPrice as UnitPrice
	,COALESCE(PBE.UnitPrice, sub.SBQQ__ListPrice__c) as ListPrice
-- 	,POpt.[SBQQ__ConfiguredSKU__c] as SBQQ__BundleRoot__c -- needs to be updated after sucessful load
-- 	,P2.SBQQ__SubscriptionTerm__c as SBQQ__DefaultSubscriptionTerm__c
	,PBE.Id as PBEntryId
	,Sub.[CreatedById]
    ,COALESCE(Sub.[CurrencyIsoCode], QL.[CurrencyIsoCode]) AS [CurrencyIsoCode]

,Sub.[SBQQ__Dimension__c]
,Sub.[SBQQ__DimensionType__c]

	,QL.SBQQ__DefaultSubscriptionTerm__c
	,COALESCE(QL.SBQQ__EffectiveQuantity__c, sub.[Effective_Quantity__c])  as SBQQ__QuotedQuantity__c 
	,COALESCE(PBE.Id, QL.SBQQ__PricebookEntryId__c) AS PricebookEntryId -- There is a pricebook mismatch between the Quote and the Contract parent of this subscription.
	--,QL.SBQQ__Description__c as [Description] -- Quote line's description is nvarchar(max) and we only have 255 in the standard description field
	,COALESCE(Sub.SBQQ__Dimension__c, QL.SBQQ__Dimension__c) as SBQQ__PriceDimension__c
	,COALESCE(Sub.SBQQ__DiscountSchedule__c , QL.SBQQ__DiscountSchedule__c ) as SBQQ__DiscountSchedule__c
	,COALESCE(Ord.EndDate, Sub.SBQQ__EndDate__c, QL.[SBQQ__EndDate__c]) as EndDate
	-- ,COALESCE(Sub.[SBQQ__ListPrice__c], QL.SBQQ__ListPrice__c) AS ListPrice -- An Order Product must have the same List Price as the related Price Book Entry
	,COALESCE(QL.SBQQ__ListPrice__c, sub.SBQQ__ListPrice__c) as SBQQ__QuotedListPrice__c -- , PBE.UnitPrice
	,COALESCE(QL.SBQQ__NetPrice__c, sub.SBQQ__ListPrice__c,0) as UnitPrice -- , PBE.UnitPrice
	,COALESCE(QL.SBQQ__NetPrice__c, sub.SBQQ__ListPrice__c,0) as UnitPriceForceOverride__c -- , PBE.UnitPrice
	,COALESCE(QL.SBQQ__EffectiveQuantity__c ,sub.[Effective_Quantity__c])  as SBQQ__OrderedQuantity__c
	,COALESCE(QL.SBQQ__EffectiveQuantity__c ,sub.[Effective_Quantity__c]) as Quantity
	,COALESCE(QL.SBQQ__PricingMethod__c, Sub.SBQQ__PricingMethod__c) AS SBQQ__PricingMethod__c
	,COALESCE(Sub.SBQQ__ProductSubscriptionType__c, QL.SBQQ__ProductSubscriptionType__c) AS SBQQ__ProductSubscriptionType__c
	,COALESCE(Sub.SBQQ__ProductOption__c ,QL.SBQQ__ProductOption__c) as SBQQ__ProductOption__c

	,COALESCE(Sub.SBQQ__ProrateMultiplier__c, QL.SBQQ__ProrateMultiplier__c) AS SBQQ__ProrateMultiplier__c
-- 	,QL.SBQQ__RequiredBy__c
--	,COALESCE(Sub.SBQQ__SegmentIndex__c, QL.SBQQ__SegmentIndex__c ) as SBQQ__SegmentIndex__c
--	,Sub.SBQQ__SegmentKey__c
--	,Sub.SBQQ__SegmentLabel__c
	,COALESCE(Sub.SBQQ__SubscriptionPricing__c, QL.SBQQ__SubscriptionPricing__c) AS SBQQ__SubscriptionPricing__c
	,COALESCE(Ord.EffectiveDate, Sub.SBQQ__StartDate__c ) as ServiceDate
	,COALESCE(QL.SBQQ__SubscriptionTerm__c, Inv.Subscription_Term__c) AS SBQQ__SubscriptionTerm__c
	,COALESCE(Sub.SBQQ__SubscriptionType__c, QL.SBQQ__SubscriptionType__c) AS SBQQ__SubscriptionType__c
	,QL.SBQQ__TaxCode__c
	,COALESCE(Sub.SBQQ__TermDiscountSchedule__c, QL.SBQQ__TermDiscountSchedule__c) AS SBQQ__TermDiscountSchedule__c
	,QL.SBQQ__UnproratedNetPrice__c

	--ListPrice

	--,SBQQ__ShippingAccount__c

--Subscription
	,SUB.ID as SBQQ__Subscription__c
-- 	,SUB.SBQQ__RequiredByProduct__c as SBQQ__RequiredBy__c -- line is related to orderproduct and needs to be updated after successful load
	,SUB.SBQQ__TerminatedDate__c as SBQQ__TerminatedDate__c
	,SUB.OwnerId 

-- Contract
	,Con.ID as SBQQ__Contract__c
	,'false' as 	SBQQ__Contracted__c

	,ORD.ID as OrderId

	,'New' as SBQQ__ContractAction__c
	,'Draft' as SBQQ__Status__c

--TWIN FIELDS

	/* ADD BASED ON BUILD AND ADD THEM HERE These will likely be on Quote Lines and Subscriptions. APIs of fields have to align If they build these on OrderItem the source will be one of those*/

/********************************************************************/
/* INVOICE FIELDS													*/
/********************************************************************/

	,INV.Id as REF_Invoice
	,Inv.A_R_Notes__c
	,Inv.Account_Billing_Address__c
	,Inv.Account_Id__c
	,Inv.Account_Region__c
	,Inv.Account_Shipping_Address__c
	,Inv.Account_Type__c
	,Inv.ACV_Booking_Cohort_Month__c
	--,Inv.Amount__c
	,Inv.ARR_Product__c
	,Inv.Billing_City__c
	,Inv.Billing_Country__c
	,Inv.Billing_Period_1_Amount__c
	,Inv.Billing_Period_1_End__c
	,Inv.Billing_Period_1_Start__c
	,Inv.Billing_Period_2_Amount__c
	,Inv.Billing_Period_2_End__c
	,Inv.Billing_Period_2_Start__c
	,Inv.Billing_Period_3_Amount__c
	,Inv.Billing_Period_3_End__c
	,Inv.Billing_Period_3_Start__c
	,Inv.Billing_Period_4_Amount__c
	,Inv.Billing_Period_4_End__c
	,Inv.Billing_Period_4_Start__c
	,Inv.Billing_Period_5_Amount__c
	,Inv.Billing_Period_5_End__c
	,Inv.Billing_Period_5_Start__c
	,Inv.Billing_Period_6_Amount__c
	,Inv.Billing_Period_6_End__c
	,Inv.Billing_Period_6_Start__c
	,Inv.Billing_Period_End__c
	,Inv.Billing_Period_Start__c
	,Inv.Billing_Postal__c
	,Inv.Billing_State__c
	,Inv.Billing_Street__c
	,Inv.Billing_Term_Close__c

	,Inv.Contact__c
	,Inv.Contract_End_Date__c
	,Inv.Contract_Start_Date__c
	--,Inv.CreatedById -- should this come from Quote or Invoice
	--,Inv.CreatedDate -- should this come from Quote or Invoice

	,Inv.Deployment_Method__c
	--,Inv.Invoice_Date__c
	,Inv.Invoice_Method__c
	,Inv.Invoice_Notes__c
	,Inv.Invoice_Status__c
	,Inv.InvoiceTerm__c
	,Inv.InvoiceType__c
	,Inv.Invoicing_Entity__c
	,Inv.Legacy_Account_Id__c
	,Inv.Legacy_Id__c
	,Inv.Legacy_Instance__c
	,Inv.Legacy_Opportunity__c
	,Inv.Licenses_Sent__c
	--,Inv.Name -- This can't be migrated
	,Inv.Opp_Quote_Number__c
	,Inv.Opportunity_Product__c
	,Inv.Opportunity_Product_Family__c
	,Inv.Opportunity_Type__c
	,Inv.Order_Form_Number__c
	,Inv.Order_Notes__c
	,Inv.Partner__c
	,Inv.Payment_Terms__c
	,Inv.Planned_Invoice_Date__c
	,Inv.Primary_Contact__c
	,Inv.Product__c
	,Inv.Purchase_Order_Number__c
	--,Inv.Quote_Number__c  This will come from the Quote
	,Inv.Related_Account__c
	,Inv.Related_Contract__c
	,Inv.Related_Opportunity__c
	,Inv.Related_Opportunity_Id__c
	,Inv.RW_Account_Id__c
	,Inv.RW_Invoice_Number__c
	,Inv.RW_Order_Form_Number__c
	,Inv.Sales_Tax_Amount__c
	,Inv.Sales_Tax_Rate__c
	,Inv.Shipping_City__c
	,Inv.Shipping_Country__c
	,Inv.Shipping_Postal__c
	,Inv.Shipping_State__c
	,Inv.Shipping_Street__c
	,Inv.Subscription_Amount__c
	,Inv.Subscription_Start_Date__c
	,Inv.Subscription_Term__c
	,Inv.Support_Amount__c
	,Inv.Support_Level__c
	,Inv.Test_Account__c
	,Inv.Total__c
	,Inv.Total_Sales_Tax__c as [SBQQ__TaxAmount__c]
	,Inv.Workday_Contract_Number__c
	,Inv.Workday_Invoice_Id__c


INTO StageQA.dbo.OrderItem_Load

FROM SourceQA.dbo.SBQQ__Subscription__c Sub
Inner join SourceQA.dbo.Product2 P2
	on Sub.[SBQQ__Product__c] = P2.ID
left join SourceQA.dbo.SBQQ__QuoteLine__c QL
	on QL.ID = Sub.SBQQ__QuoteLine__c
left join SourceQA.dbo.SBQQ__ProductOption__c Popt
	on COALESCE(Sub.SBQQ__ProductOption__c ,QL.SBQQ__ProductOption__c ) = Popt.ID
inner join SourceQA.dbo.[Contract] Con
	on Sub.SBQQ__Contract__c = Con.ID
left join SourceQA.dbo.Invoice__c Inv
	on Sub.Invoice__c = Inv.ID
Inner JOIN SourceQA.dbo.[Order]  Ord  -- Must have an order
	on Ord.ContractId = Con.ID
	and Sub.SBQQ__SegmentStartDate__c = Ord.EffectiveDate
left join SourceQA.dbo.[PriceBookEntry] PBE
	on Sub.SBQQ__Product__c = PBE.Product2ID
	and Ord.Pricebook2Id = PBE.Pricebook2Id
	and Ord.CurrencyIsoCode = PBE.CurrencyIsoCode

	--on QL.[SBQQ__PricebookEntryId__c] = PBE.ID
	--and P2.ID = PBE.Product2ID

Where Con.EndDate >= getdate()
and Con.Status = 'Activated'
and COALESCE(PBE.Id, QL.SBQQ__PricebookEntryId__c) != @RedwoodNewDeal2024
and COALESCE(PBE.Id, QL.SBQQ__PricebookEntryId__c) != @RedwoodLegacyDeal
--and COALESCE(QL.SBQQ__PricebookEntryId__c, PBE.Id) IS NULL
-- and Con.Id = '8003t000008D4idAAC'

order by Con.Id,
		Ord.EffectiveDate


-- select * from SourceQA.dbo.[Order]

---------------------------------------------------------------------------------
-- Add Sort Column to speed Bulk Load performance if necessary
---------------------------------------------------------------------------------
ALTER TABLE StageQA.dbo.[orderitem_load]
ADD [Sort] int 
GO
WITH NumberedRows AS (
  SELECT *, ROW_NUMBER() OVER (ORDER BY OrderId) AS OrderRowNumber
  FROM StageQA.dbo.[orderitem_load]
)
UPDATE NumberedRows
SET [Sort] = OrderRowNumber;

---------------------------------------------------------------------------------
-- Data Validation
---------------------------------------------------------------------------------
select count(*), COUNT(distinct Order_Item_Migration_id__c) from OrderItem_Load
select * from StageQA.dbo.OrderItem_Load where PricebookEntryId IS NULL 

-- the opportunity below does not have a quote line for the renewal only MFT server bundle subscription
-- there is a quote line on the actual quote, because that quote line is not attached to the subscription it's pulling the wrong unit price
-- and inflating the value of the opportunity when looking at an order level
-- going to try to remove logic from the unit price calculation to fix this
-- select * from StageQA.dbo.OrderItem_Load where Related_Opportunity_Id__c = '0063t00000t3DnmAAE'
---------------------------------------------------------------------------------
-- Load Data to Salesforce
---------------------------------------------------------------------------------
USE StageQA;
EXEC StageQA.dbo.SF_Tableloader 'INSERT:bulkapi,batchsize(100)','SANDBOX_QA','OrderItem_Load'


---------------------------------------------------------------------------------
-- Error Review	
---------------------------------------------------------------------------------

-- USE Insert_Database_Name_Here; Select error, * from OrderItem_Load_Result a where error not like '%success%'
Select error, count(*) from StageQA.dbo.OrderItem_Load_Result a where error not like '%success%'
group by error

-- USE Insert_Database_Name_Here; EXEC SF_Tableloader 'HardDelete:batchsize(10)', 'SANDBOX_QA', 'SBQQ__QuoteL		ine__c_Load_Result'
select * from StageQA.dbo.OrderItem_Load_Result a where error != 'Operation Successful.'
select * from StageQA.dbo.OrderItem_Load_Result
select * from StageQA.dbo.OrderItem_Load

-- EXEC StageQA.dbo.SF_Tableloader 'DELETE','SANDBOX_QA','OrderItem_Load_result'


select * 

from StageQA.dbo.OrderItem_Load_Result_result where error not like '%success%'