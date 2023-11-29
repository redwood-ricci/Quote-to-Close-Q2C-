--------------------
-- prove that sum of opportunity orders is equal to opportunity TCV
--------------------

use StageQA
-- 
if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'O_Start' AND TABLE_SCHEMA = 'dbo')
DROP TABLE O_Start

SELECT
ord.OpportunityId
,ord.TotalAmount as order_total
into O_Start
FROM [SANDBOX_QA].[CData].[Salesforce].[Order] ord;

with orders as (
select
OpportunityId
,sum(order_total) as order_total
From
O_Start
group by opportunityId
)
-- strange bug with currency conversion in DBAmp needs to pull data down before summing it

select
ord.*
,opt.TCV__c
,case when ord.order_total = opt.TCV__c then 'same' else 'false' end as same
from orders ord
left join [SANDBOX_QA].[CData].[Salesforce].[Opportunity] opt on opt.id = ord.OpportunityId
where test_account__c = 'false'
and opt.closedate >= '2023-01-01'
and stagename = 'Closed Won'
order by same


select id,totalamount  FROM [SANDBOX_QA].[CData].[Salesforce].[Order] where opportunityid = '0063t00000xu1v3AAA'

SELECT 
id
,ord.OpportunityId
,ord.TotalAmount as order_total
FROM [SANDBOX_QA].[CData].[Salesforce].[Order] ord
where opportunityid = '0063t00000xu1v3AAA'


/*
SELECT [Id]
      ,[OwnerId]
      ,[ContractId]
      ,[AccountId]
      ,[Pricebook2Id]
      ,[OriginalOrderId]
      ,[OpportunityId]
      ,[EffectiveDate]
      ,[EndDate]
      ,[IsReductionOrder]
      ,[Status]
      ,[Description]
      ,[CustomerAuthorizedById]
      ,[CustomerAuthorizedDate]
      ,[CompanyAuthorizedById]
      ,[CompanyAuthorizedDate]
      ,[Type]
      ,[BillingStreet]
      ,[BillingCity]
      ,[BillingState]
      ,[BillingPostalCode]
      ,[BillingCountry]
      ,[BillingStateCode]
      ,[BillingCountryCode]
      ,[BillingLatitude]
      ,[BillingLongitude]
      ,[BillingGeocodeAccuracy]
      ,[ShippingStreet]
      ,[ShippingCity]
      ,[ShippingState]
      ,[ShippingPostalCode]
      ,[ShippingCountry]
      ,[ShippingStateCode]
      ,[ShippingCountryCode]
      ,[ShippingLatitude]
      ,[ShippingLongitude]
      ,[ShippingGeocodeAccuracy]
      ,[Name]
      ,[PoDate]
      ,[PoNumber]
      ,[OrderReferenceNumber]
      ,[BillToContactId]
      ,[ShipToContactId]
      ,[ActivatedDate]
      ,[ActivatedById]
      ,[StatusCode]
      ,[CurrencyIsoCode]
      ,[OrderNumber]
      ,[TotalAmount]
      ,[CreatedDate]
      ,[CreatedById]
      ,[LastModifiedDate]
      ,[LastModifiedById]
      ,[IsDeleted]
      ,[SystemModstamp]
      ,[LastViewedDate]
      ,[LastReferencedDate]
      ,[SBQQ__Contracted__c]
      ,[SBQQ__ContractingMethod__c]
      ,[SBQQ__PaymentTerm__c]
      ,[SBQQ__PriceCalcStatusMessage__c]
      ,[SBQQ__PriceCalcStatus__c]
      ,[SBQQ__Quote__c]
      ,[SBQQ__RenewalTerm__c]
      ,[SBQQ__RenewalUpliftRate__c]
      ,[SBQQ__OrderBookings__c]
      ,[SBQQ__TaxAmount__c]
      ,[Order_Migration_id__c]
      ,[ACV_Booking_Cohort_Month2__c]
      ,[ACV_Booking_Cohort_Month__c]
      ,[ARR_Product__c]
      ,[A_R_Notes__c]
      ,[Account_Region__c]
      ,[Account_Type__c]
      ,[Amount_Change_Reason__c]
      ,[Annual_Increase_Cap_Percentage_c__c]
      ,[Annual_Increase_Cap_Term_PerCent__c]
      ,[Annual_Increase_Cap_Term__c]
      ,[Billing_Period_Amount__c]
      ,[Billing_Period_Close__c]
      ,[Billing_Period_End__c]
      ,[Billing_Period_Start__c]
      ,[Check_Number__c]
      ,[Contract_End_Date__c]
      ,[Contract_Start_Date__c]
      ,[Data_Transformation__c]
      ,[Invoice_Date__c]
      ,[Invoice_Method__c]
      ,[Invoice_Notes__c]
      ,[Invoice_Period_Days__c]
      ,[Invoice_Status__c]
      ,[Invoice_Term__c]
      ,[Invoice_Type__c]
      ,[Invoicing_Entity__c]
      ,[Legacy_Account_Id__c]
      ,[Legacy_Id__c]
      ,[Legacy_Instance__c]
      ,[Legacy_Opportunity__c]
      ,[Licenses_Sent__c]
      ,[Opportunity_Channel__c]
      ,[Opportunity_Product__c]
      ,[Opportunity_Type__c]
      ,[Order_Notes__c]
      ,[PO_Number__c]
      ,[Partner_Account__c]
      ,[Partner_Contact__c]
      ,[Partner_Role__c]
      ,[Primary_Contact__c]
      ,[Product__c]
      ,[Purchase_Order_Number__c]
      ,[RW_Account_Id__c]
      ,[RW_Invoice_Number__c]
      ,[RW_Legal_Entity__c]
      ,[RW_Order_Form_Number__c]
      ,[Sales_Tax_Rate__c]
      ,[Subscription_Amount__c]
      ,[Subscription_Start_Date__c]
      ,[Subscription_Term__c]
      ,[Support_Amount__c]
      ,[Support_Level__c]
      ,[Test_Account__c]
      ,[Workday_Contract_Number__c]
      ,[Workday_Invoice_Id__c]
      ,[Order_End_Date__c]
      ,[Order_Start_Date__c]
      ,[Prorate_Multiplier__c]
      ,[Total_List_Price__c]
      ,[Has_Invoice_Portal__c]
      ,[Order_Form_Number__c]
      ,[Order_Term__c]
      ,[Planned_Invoice_Date__c]
      ,[Sales_Tax_Amount__c]
      ,[Total_Sales_Tax__c]
  FROM [SANDBOX_QA].[CData].[Salesforce].[Order]
GO