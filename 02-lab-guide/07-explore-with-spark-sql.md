
# Explore Dataplex entities with Spark SQl on Data Exploration Workbench

To recap, a queryable Dataplex entity is a table - a BigQuery table, or a BigLake table/external table on structured Cloud Storage objects in the Dataplex Lake. 

In this lab module, we will query the raw asset Chicago Crimes using Spark SQL on the Data Engineering DEW Environment.

## Lab

### 1. Navigate to the Spark SQL Workbench 
Navigate to the Dataplex UI -> Explore as showin below, in the Cloud Console-

![DEW-1](../01-images/07-01.png)   
<br><br>
<hr>

### 2. Query the GCS external table Chicago Crimes

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
We will save this query in section 4.

<hr>

<hr>

### 3. Persist the SQL script

In Cloud Shell, paste the below. Grab the GCS URI fo the bucket directory chicago-crimes. We will persist the SQL into the same.

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
echo gs://oda-raw-code-$PROJECT_NBR/chicago-crimes
```

Follow the steps as shown below-




Notice where the script is persisted - in the content store in Dataplex.





<hr>

### 6. Schedule the SQL script to run

#### 6.1. Create a network and subnet called default, and a firewall rule for intra-subnet allow-all
This is currently the only name constuct supported by scheduled scripts and notebooks in Dataplex.

```
PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
LOCATION="us-central1"
SUBNET_CIDR="10.2.0.0/16"
VPC_NM=default
SUBNET_NM=default

gcloud compute networks create $VPC_NM \
--project=$PROJECT_ID \
--subnet-mode=custom \
--mtu=1460 \
--bgp-routing-mode=regional

gcloud compute networks subnets create $SUBNET_NM \
--project=$PROJECT_ID \
--range=$SUBNET_CIDR \
--stack-type=IPV4_ONLY \
--network=$VPC_NM \
--region=$LOCATION \
--enable-private-ip-google-access

gcloud compute --project=$PROJECT_ID firewall-rules create allow-intra-subnet-for-spark \
--direction=INGRESS \
--priority=1000 \
--network=$VPC_NM \
--action=ALLOW \
--rules=all \
--source-ranges=$SUBNET_CIDR


```


<hr>

### 7. Query a table in the BigQuery public dataset for Chicago crimes



<hr>
This concludes the lab module. In the next module, we will learn to query metadata in the Dataproc Metastore (Apache Hive Metastore) with Spark SQL.
<hr>
