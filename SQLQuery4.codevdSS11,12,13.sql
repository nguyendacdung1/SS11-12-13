--SS11
--1
create table Production.parts(
part_id int not null,
part_time varchar(100)
)
go
--2
create clustered index ix_parts_id ON Production.parts(part_id);
--3
exec sp_rename
N'production.parts.ix_parts_id',
N'index_part_id',
N'index';
--4
alter index index_part_id
on production.parts
disable;
--5
alter table all on production.parts
disable;
--6
drop index if exists
index_part_id on production.parts;
--7
create nonclustered index index_customer_storeid
on sales.customer(storeID);
--8 
create unique index ak_customer_rowguid
on sales.customer(rowguide);
--9 
create index index_cust_personID
on sales.customer(personID)
where personID is not null;
--10
select customerid, personid,storeID from sales.customer where personid=1700;
--11
create partition function partition_function (int)
range left for values(20200630, 20200731, 20200831);
--12
(select 20200613 date,$partition.partition_function(20200613)
partitionNumber)
union
(select 20200713 date,$partition.partition_function(20200713)
partitionNumber)
union
(select 20200813 date,$partition.partition_function(20200813)
partitionNumber)
union
(select 20200913 date, $partition.partition_function(20200913));
--13
create primary xml index pxml_productModel_catalogDescription
on production.productModel (CatalogDescription);
--14
create xml index ixml_productModel_catalogDescription_path
on production.productModel (catalogDescription)
using xml index pxml_productModel_catalogDescription
for prth;
--15
create columnstore index ix_salesOrderDetail_ProductIDOrderQty_ColumnStore
on sales.salesOrderDetail (productid,orderQty);
--16
select productid,sum(OrderQty)
from sales.salesOrderDetail
group by productID;

--SS12
--1
create table Locations(locationID int, LocName varchar(100);
create table LocationHistory (LocationID int, MobifiedDate datetime);
--2
create trigger trigger_insert_Locations on Locations
for insert
not for replication
as
begin
insert into LocationHistory
select LocationID,
getdate()
from inserted
end;
--3
insert into dbo.Locations(locationID,LocName)values(443101,'Alaska');
--4
Create trigger trigger_update_locations on Locations
for update
not for replications
as
begin
insert into LocationHistory
select LocationID
,getdate()
from inserted
end;
--5
update dbo.Locations
set LocName='Atlanta'
where locationID=443101;
--6
Create trigger trigger_update_locations on Locations
for delete
not for replications
as
begin
insert into LocationHistory
select LocationID
,getdate()
from deleted
end;
--7
delete from dbo.Locations
where locationID=443101;
--8
create trigger after_insert_Locations on Locations
after insert
as
begin
insert into LocationHistory
select LocationID,
getdate()
from inserted
end;
--9
insert into dbo.Locations(locationID,LocName) values (443103, 'san roman');
--10
create trigger insteadof_delete_Locations on Locations
instead of delete
as
begin
select 'sample instead of trigger' as (Message)
end;
--11
delete from dbo.Locations
where locationID=443101;
--12
exec sp_settriggerorder @triggerName = 'trigger_delete_Locations' @order='first', @stmttype = 'delete'
--13
sp_helptext trigger_delete_Locations
--14
alter trigger trigger_update_Locations on Locations
with encryption for insert
as
if '443101' in (select LocationID from inserted)
begin
print 'Location cannot be updated'
rollback transaction
end;
--15
drop trigger trigger_update_Locations
--16
create trigger secure on database
for drop_table, alter_table as
print 'you must disable trigger "Secure" to drop or alter tables!'
rollback;
--17
create trigger employee_deletion on HumanResources.Employee
alter delete
as
begin
print 'Deletion will affect employeePayHistory table'
delete from EmployeePayHistory Where BuinessEntityID in (select BusinessEntityID from deleted) 
end;
--18
create trigger deletion_confirmation
on HumanResources.EmployeePayHistory after delete
as
begin
print 'employee details successfully deleted from employeePayHistory table'
end;
delete from employeePayHistory where EmpID=1
--19
create trigger Accounting on Production.TransactionHistory after update
as
if(update (TransactionID) or update (productID) begin
raiserror (50009,16,10) end;
go
--20
use AdventureWorks2019;
go
create trigger PODetails
on Purchasing.PurchaseOrderDetail AFTER INSERT AS
UPDATE PurchaseOrderHeader
set SubTotal=SubTotal+ LineTotal from inserted
where PurchaseOrderHeader.PurchaseOrderID=inserted.PurchaseOrderID;
--21
use AdventureWorks2019
go
create trigger PODetailsMultiple
on Purchasing.PurchaseOrderDetail AFTER INSERT AS
update Purchasing.PurchaseOrderHeader set SubTotal=SubTotal+(select SUM(lineTotal)from inserted
where PurchaseOrderHeader.PurchaseOrderID=inserted.PurchaseOrderID)
where PurchaseOrderHeader.PurchaseOrderID in (select PurchaseOrderID from inserted);
--22
create trigger [track_logins] on all server
for logon as
begin
insert into LoginActivity
select EVENTDATA(),
getdate()
end;

--SS13
--1
use AdventureWorks2019;
go
create view dbo.vProduct
as
select ProductNumber, Name from Production.Product;
go
select*from dbo.vProduct;
go
--2
begin transaction
go
use AdventureWorks2019;
go
create table company (
Id_num int IDENTITY(100,5),
Company_Name nvarchar(100))
go
INSERT company (Company_Name) values(N'A BIKE STORE')
INSERT company (Company_Name) values(N'Progressive Sports')
INSERT company (Company_Name) values(N'Exemplary Cycles')
INSERT company (Company_Name) values(N'Advanced Bike Compinents')
go
select Id_Num, Company_Name from dbo.company
order by Company_Name ASC;
go
COMMIT;
go
--3
use AdventureWorks2019;
go
declare @find varchar(30) ='Man%';
select p.LastName,p.FirstName,ph.PhoneNumber From Person.Person as p
join Person.PersonPhone as ph on p.BusinessEntityID=ph.BusinessEntityID
where LastName like @find;
--4
declare @myvar char(20);
set @myvar = 'This is a test';
--5
use AdventureWorks2019
go
declare @var1 varchar(30);
select @var1 = 'unnamed company';
select @var1 = Name from Sales.Store where buisinessEntityID =10;
select @var1 as 'company name';
--6
use AdventureWorks2019
go
create synonym myaddressType
for AdventureWorks2019.person.AddressType;
go
--7
use AdventureWorks2019
go
begin transaction
go
if @@TRANCOUNT=0 begin
select FirstName,MiddleName
from Person.Person where LastName = 'Andy';
Rollback Transaction;
print N'rolling back the transaction two times would cause an error.';
end;
rollback transaction;
print N'Rolled back the transaction.'
go
--8
use AdventureWorks2019
go
declare @ListPrice money;
set @ListPrice= (select MAX(p.ListPrice) from Production.Product as p
join Production.ProductSubcategory as s
on p.ProductSubcategoryID=s.ProductSubcategoryID where s.[name] = 'Mountain Bike')
print @listPrice
if @ListPrice<3000
print 'all the products in this category can be purchased for an amount less than 3000'
else
print 'the prices for some products in this category exceed 3000'
--9
declare @flag int set @flag=10 while (@flag <=95) begin
if @flag%2 = 0 print @flag
set @flag=@flag+1
continue; end
go
--10
use AdventureWorks2019
go
if OBJECT_ID(N'Sales.ufn_CustDates', N'IF') is not null drop function
Sales.ufn_ufn_CustDates;
go
create function sales.ufnn_CustDates() return table
as return(
select A.customerID,B.DueDate,B.ShipDate from Sales.Customer A
LEFT OUTER JOIN
Sales.SalesOrderHeader B on
A.CustomerID=B.CustomerID and year(B.DueDate)<2020);
--11
select*from Sales.ufn_CustDates();
--12
use AdventureWorks2019
go
alter function[dbo].[ufnGetAccountingEndDate]() returns[datetime]
as begin
return dateadd(millisecond, -2, convert(datetime, '20040701', 112));
end;
--13
use AdventureWorks2019
go
select SalesOrderID,ProductID, OrderQTY,
SUM(OrderQTY) over(partition by salesOrderID) as total,
max(orderQTY) over(partition bu salesOrderID)as MaxOrderQty from
sales.salesOrderDetail
where productID in(776,773);
go
--14
select customerID, storeID, rank() over(order by StoreID desc)as Rnk_all,Rank() over(partition by PersonID
order by CustomerID DESC) AS Rnk_Cust
from SALES.Customer;
--15
select territoryID,Name,SalesYTD,rank() over(order by SalesYTD DESC) AS Rnk_One,Rank() over(Partition by TerritoryID
order by salesYTD DESC) AS Rnk_Two
from Sales.SalesTerritory;
--16
select productID, Shelf,Quantity,
SUM(Quantity) over(partition by PRODUCTID
order by LocationID
Rows between unbounded preceding and current row) as RunQty
from Production.ProductInventory;
--17
use AdventureWorks2019
go
select p.FirstName,P.LastName,
ROW_NUMBER() Over(order by a.PostalCode)AS'Row Number',
Ntile(4) over (order by a.PostalCode) AS 'NTILE',s.SalesYTD,a.PostalCode From Sales.SalesPerson as a
on s.BusinessEntityID = p.BusinessEntityID inner join Person.Address AS a
on a.AddressID=p.BusinessEntityID
where TerritoryID is Not null and SalesYTD <>0;
--18
CReate table test(
coldatetimeoffset datet

