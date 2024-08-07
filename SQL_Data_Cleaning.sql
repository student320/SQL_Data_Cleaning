use ProjectPortfolio;
select * from dbo.Nashville_housing;

---------------------------------------------------------------------------------------------------------------------------------
-- Standardize date format
---------------------------------------------------------------------------------------------------------------------------------

select SaleDate , convert(date,saledate)
from dbo.Nashville_housing;


/*update dbo.Nashville_housing
set SaleDate = convert(Date,SaleDate);*/

ALTER TABLE dbo.Nashville_housing
ALTER COLUMN SaleDate DATE;

SELECT * FROM dbo.Nashville_housing;


---------------------------------------------------------------------------------------------------------------------------------
-- Handle NULL values for Property Addresss column
---------------------------------------------------------------------------------------------------------------------------------

select * from dbo.Nashville_housing
where PropertyAddress is null;


-- Notice: PropertyAddress has corresponding ParcelID, so we can use ParcelID column values to find missing PropertyAddress column values
select * from dbo.Nashville_housing
order by parcelid;

-- use self join
select 
	a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.ParcelID,b.PropertyAddress)
from dbo.Nashville_housing a
join dbo.Nashville_housing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID -- to avoid duplicates of the same Uniqe ID
where a.PropertyAddress is null; 

/* ERROR accidentaly used a.ParcelID instead of a.PropertyAddress  in isnull()
update a
set PropertyAddress = isnull(a.ParcelID,b.PropertyAddress)
from dbo.Nashville_housing a
join dbo.Nashville_housing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;*/

/* use this query to revert back, change records with identical data in parcelID and Property address into NULL
update a
set PropertyAddress = Null
from dbo.Nashville_housing a
join dbo.Nashville_housing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress = b.parcelId;*/

update a
set PropertyAddress = isnull(a.PropertyAddress,b.PropertyAddress)
from dbo.Nashville_housing a
join dbo.Nashville_housing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;


---------------------------------------------------------------------------------------------------------------------------------
--Splitting address into Address, City columns
---------------------------------------------------------------------------------------------------------------------------------

/*select 
	case
		when charindex(',', propertyaddress) >0
		then substring(PropertyAddress, 1, charindex(',', propertyaddress) - 1) 
		else PropertyAddress
		end as Address
from dbo.Nashville_housing;*/

select propertyaddress,parcelid, charindex(',', propertyaddress)
from dbo.Nashville_housing
order by charindex(',', propertyaddress) asc;


select
	substring(PropertyAddress, 1, charindex(',', PropertyAddress) - 1) as Address,
	substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress)) as City
from dbo.Nashville_housing;


alter table dbo.Nashville_housing
add PropertySplitAddress nvarchar(255);

update dbo.Nashville_housing
set PropertySplitAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress) - 1);

alter table dbo.Nashville_housing
add PropertySplitCity nvarchar(255);

update dbo.Nashville_housing
set PropertySplitCity = substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress));

select PropertySplitAddress, PropertySplitCity from dbo.nashville_housing;



---------------------------------------------------------------------------------------------------------------------------------
-- Split Owner Address using parsename
---------------------------------------------------------------------------------------------------------------------------------

select 
	parsename(replace(OwnerAddress,',','.'),3),
	parsename(replace(OwnerAddress,',','.'),2),
	parsename(replace(OwnerAddress,',','.'),1)
from dbo.nashville_housing;


alter table dbo.Nashville_housing
add OwnerSplitAddress nvarchar(255);

update dbo.Nashville_housing
set OwnerSplitAddress = 	parsename(replace(OwnerAddress,',','.'),3);

alter table dbo.Nashville_housing
add OwnerSplitCity nvarchar(255);

update dbo.Nashville_housing
set OwnerSplitCity = parsename(replace(OwnerAddress,',','.'),2);

alter table dbo.Nashville_housing
add OwnerSplitState nvarchar(255);

update dbo.Nashville_housing
set OwnerSplitState = parsename(replace(OwnerAddress,',','.'),1);


---------------------------------------------------------------------------------------------------------------------------------
-- Change Y/N into Yes/No in SoldAsVacant column
---------------------------------------------------------------------------------------------------------------------------------

select distinct(soldasvacant), count(soldasvacant)
from dbo.nashville_housing
group by soldasvacant
order by 2 desc;


select 
	SoldAsVacant,
	case 
		when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
	end
from dbo.nashville_housing

update dbo.Nashville_housing
set SoldAsVacant = case 
		when SoldAsVacant = 'Y' then 'Yes'
		when SoldAsVacant = 'N' then 'No'
		else SoldAsVacant
	end;


---------------------------------------------------------------------------------------------------------------------------------
-- Remove duplicates
---------------------------------------------------------------------------------------------------------------------------------
with Row_Num_CTE as
(
select 
	*,
	row_number() over(partition by ParcelId,
								 PropertyAddress,
								 SalePrice,
								 SaleDate,
								 Legalreference
								 order by UniqueId) as row_num
from dbo.Nashville_housing
)
delete
from Row_Num_CTE
where row_num >1;


---------------------------------------------------------------------------------------------------------------------------------
-- Delete unused columns
---------------------------------------------------------------------------------------------------------------------------------

select * from dbo.Nashville_housing;

alter table dbo.Nashville_housing
drop column OwnerAddress, TaxDistrict, PropertyAddress;


select * from dbo.Nashville_housing;
