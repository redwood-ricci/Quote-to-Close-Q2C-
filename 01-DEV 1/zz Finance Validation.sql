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
