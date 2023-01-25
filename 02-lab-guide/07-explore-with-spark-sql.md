
# Explore Dataplex entities with Spark SQl on Data Exploration Workbench

To recap, a queryable Dataplex entity is a table - a BigQuery table, or a BigLake table/external table on structured Cloud Storage objects in the Dataplex Lake. 

In this lab module, we will query the raw asset Chicago Crimes using Spark SQL on the Data Engineering DEW Environment.

## Lab

### 1. Declare variables

Paste the below in Cloud Shell-
```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`

```

<hr>

### 2. Create a directory for saving Spark SQL scripts 
We will create a directory in te code bucket created via Terraform to persist Spark SQL scripts.

Paste the below in Cloud Shell-
```
gsutil mkdir gs://oda-raw-code-36819656457/chicago-crimes
```

<hr>

### 3. Navigate to the Spark SQL Workbench 
Navigate to the Dataplex UI -> Explore as showin below, in the Cloud Console-

![DEW-1](../01-images/07-01.png)   
<br><br>
<hr>

### 4. Query the GCS external table Chicago Crimes

Run the query below, which queries crimes in the table created in lab sub-module 4 in the raw zone.

```
select * from oda_raw_zone.chicago_crimes
```

Author's output-
![DEW-1](../01-images/07-02.png)   
<br><br>

Then run an aggregation query-
```
select year as crime_year, count(*) as crimes_count from oda_raw_zone.chicago_crimes group by year order by year desc
```
We will save this query in section 5.

<hr>

<hr>

### 5. Persist the SQL script


<hr>

### 6. Grant access to the SQL script


<hr>

### 7. Query a table in the BigQuery public dataset for Chicago crimes



<hr>
This concludes the lab module. In the next module, we will learn to query metadata in the Dataproc Metastore (Apache Hive Metastore) with Spark SQL.
<hr>
