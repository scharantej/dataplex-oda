
# Register Assets into your Dataplex Lake Zones

In the previous module, we created a Dataplex Lake with a Dataproc Metastore Service, and Dataplex Zones with discovery enabled. <br>
In this module, we will register assets into the Dataplex zones created. 

[Lab A: Register assets in BigQuery](04-register-assets-into-zones.md#1-lab-a-register-bigquery-datasets) <br>
[Lab B: Register assets in Cloud Storage](04-register-assets-into-zones.md#2-lab-b-register-cloud-storage-datasets)


## 1. Lab A: Register BigQuery Datasets

In this lab sub-module, we will create a BigQuery dataset, load some data into a BigQuery table in the dataset we created and register the dataset as an asset into the Dataplex raw zone we created. We will use the Chicago Crimes public dataset in BigQuery for this lab sub-module.

### 1.1. Declare variables

Paste into Cloud Shell-
```

PROJECT_ID=`gcloud config list --format "value(core.project)" 2>/dev/null`
PROJECT_NBR=`gcloud projects describe $PROJECT_ID | grep projectNumber | cut -d':' -f2 |  tr -d "'" | xargs`
UMSA_FQN="lab-sa@${PROJECT_ID}.iam.gserviceaccount.com"
LOCATION="us-central1"
METASTORE_NM="lab-dpms-$PROJECT_NBR"
LAKE_NM="oda-lake"
DATA_RAW_ZONE_NM="oda-raw-zone"
DATA_CURATED_ZONE_NM="oda-curated-zone"
DATA_CONSUMPTION_ZONE_NM="oda-consumption-zone"
MISC_RAW_ZONE_NM="oda-misc-zone"

CRIMES_ASSET="chicago-crimes"
CRIMES_DS="oda_crimes_ds"

```

### 1.2. List BigQuery Datasets

Paste this command in Cloud Shell to list BQ datasets-
```
bq ls --format=pretty
```

These datasets got created automatically by Dataplex when you created zones in the prior module.

Author's results-
```
+----------------------+
|      datasetId       |
+----------------------+
| oda_consumption_zone |
| oda_curated_zone     |
| oda_misc_zone        |
| oda_raw_zone         |
+----------------------+
```

Note that these datasets were automatically created and each of them map to a Dataplex zone we created in the previous module.

### 1.3. Create a "crimes" BigQuery Dataset

```
bq --location=$LOCATION_MULTI mk \
    --dataset \
    $PROJECT_ID:$CRIMES_DS
```

### 1.4. Load some data into the newly created "crimes" BigQuery dataset from a BigQuery public dataset

Paste this command in Cloud Shell to create a table-
```
bq --location=$LOCATION_MULTI query \
--use_legacy_sql=false \
"CREATE OR REPLACE TABLE $CRIMES_DS.chicago_crimes AS SELECT * FROM bigquery-public-data.chicago_crime.crime"
```

Reload the BQ UI, you should see the table created. Query the table-
```
SELECT * FROM `oda_crimes_ds.chicago_crimes` LIMIT 1000
```

Author's output:
![LOAD](../01-images/04-01.png)   
<br><br>


### 1.5. Register the crimes BigQuery Dataset as an asset into the RAW zone

Paste this command in Cloud Shell to register contents of BQ datasets (currently empty) into corressponding zones-

```

gcloud dataplex assets create $CRIMES_ASSET \
--location=$LOCATION \
--lake=$LAKE_NM \
--zone=$DATA_RAW_ZONE_NM \
--resource-type=BIGQUERY_DATASET \
--resource-name=projects/$PROJECT_ID/datasets/$CRIMES_DS \
--discovery-enabled \
--discovery-schedule="0 * * * *" \
--display-name 'Chicago Crimes'

```

### 1.6. Switch to the Dataplex UI, Manage->ODA-Lake->ODA-RAW-ZONE->Assets

Review the various tabs of the asset registered.

![ASST-1](../01-images/04-02a.png)   
<br><br>


![ASST-2](../01-images/04-02b.png)   
<br><br>

![ASST-3](../01-images/04-02c.png)   
<br><br>

![ASST-4](../01-images/04-02d.png)   
<br><br>


### 1.7. In the Dataplex Assets UI, review the "entities" tab

The physical BigQuery table is called an entity in this case, and is listed.

![ASST-5](../01-images/04-03.png)   
<br><br>

![ASST-6](../01-images/04-03b.png)   
<br><br>

## 2. Lab B: Register Cloud Storage Datasets

In this lab sub-module, we will simply add the storage buckets created via Terraform with datasets in them, into the raw zone, and curated zone, depending on format.


### 2.1. Register data assets into Raw Zone: oda-raw-zone

#### 2.1.1. Assets to be registered

The following are the raw data assets to be registered into the Dataplex Raw Zone called oda-raw-zone. The data assets are located at -<br>
GCS Path: gs://oda-raw-data-PROJECT_NBR

| Domain Use Case | Format | GCS directory | 
| -- | :--- | :--- | 
| Icecream Sales Forecasting | CSV | icecream-sales-forecasting | 
| Telco Customer Churn Prediction | CSV | telco-customer-churn-prediction | 


#### 2.1.2. Register the assets

To register the data assets, we will merely register the buckets and the data assets will automatically get discovered and entities registered. We will review entities created in the next lab module.

```
gcloud dataplex assets create misc-datasets \
--location=$LOCATION \
--lake=$LAKE_NM \
--zone=$DATA_RAW_ZONE_NM \
--resource-type=STORAGE_BUCKET \
--resource-name=projects/$PROJECT_ID/buckets/oda-raw-data-$PROJECT_NBR \
--discovery-enabled \
--discovery-schedule="0 * * * *" \
--display-name 'Miscellaneous Datasets'
```

#### 2.1.3. Review the assets registered in the Dataplex UI

Navigate to Dataplex UI -> Manage -> ODA-LAKE -> ODA-RAW-ZONE -> Assets & familiarize yourself with the various tabs and entries.

![ASST-RD-1](../01-images/04-04a.png)   
<br><br>

<hr>

<br>

### 2.2. Register data assets into Curated Zone: oda-curated-zone

#### 2.2.1. Assets to be registered

The following are the curated data assets to be registered into the Dataplex Curated Zone called oda-curated-zone. The data assets are located at -<br>
GCS Path: gs://oda-curated-data-PROJECT_NBR

| Domain Use Case | Format | GCS directory | 
| -- | :--- | :--- | 
| Retail Transactions Anomaly Detection | Parquet | retail-transactions-anomaly-detection | 


#### 2.2.2. Register the assets

To register the data assets, we will merely register the buckets and the data assets will automatically get discovered and entities registered. We will review entities created in the next lab module.

```
gcloud dataplex assets create misc-datasets \
--location=$LOCATION \
--lake=$LAKE_NM \
--zone=$DATA_CURATED_ZONE_NM \
--resource-type=STORAGE_BUCKET \
--resource-name=projects/$PROJECT_ID/buckets/oda-curated-data-$PROJECT_NBR \
--discovery-enabled \
--discovery-schedule="0 * * * *" \
--display-name 'Miscellaneous Datasets'
```

#### 2.2.3. Review the assets registered in the Dataplex UI

Navigate to Dataplex UI -> Manage -> ODA-LAKE -> ODA-CURATED-ZONE -> Assets & familiarize yourself with the various tabs and entries.

![ASST-CD-1](../01-images/04-05a.png)   
<br><br>

<hr>

<br>

### 2.3. Register notebooks assets into Raw Zone: oda-misc-zone

#### 2.3.1. Assets to be registered

The following are the notebook assets to be registered into the Dataplex Raw Zone called oda-misc-zone. The notebook assets are located at -<br>
GCS Path: gs://oda-raw-notebook-PROJECT_NBR

| Domain Use Case | Format | GCS directory | 
| -- | :--- | :--- | 
| Chicago Crimes Analytics | .pynb | chicago-crimes-analysis | 
| Icecream Sales Forecasting | .pynb | icecream-sales-forecasting |
| Retail Transactions Anomaly Detection | .ipynb | retail-transactions-anomaly-detection |
| Telco Customer Churn Prediction | CSV | telco-customer-churn-prediction | 


To see the listing in Cloud Shell, paste the below command-
```
gsutil ls gs://oda-raw-notebook-$PROJECT_NBR
```
The author's output is:<br>

gs://oda-raw-notebook-36819656457/chicago-crimes-analysis/<br>
gs://oda-raw-notebook-36819656457/icecream-sales-forecasting/<br>
gs://oda-raw-notebook-36819656457/retail-transactions-anomaly-detection/<br>
gs://oda-raw-notebook-36819656457/telco-customer-churn-prediction/


#### 2.3.2. Register the assets

To register the notebook assets, we will merely register the buckets and the notebook assets will automatically get discovered and entities registered. We will review entities created in the next lab module.

```
gcloud dataplex assets create notebooks \
--location=$LOCATION \
--lake=$LAKE_NM \
--zone=$MISC_RAW_ZONE_NM \
--resource-type=STORAGE_BUCKET \
--resource-name=projects/$PROJECT_ID/buckets/oda-raw-notebook-$PROJECT_NBR \
--discovery-enabled \
--discovery-schedule="0 * * * *" \
--display-name 'Analytics Notebooks'
```

#### 2.3.3. Review the assets registered in the Dataplex UI

Navigate to Dataplex UI -> Manage -> ODA-LAKE -> ODA-MISC-ZONE -> Assets & familiarize yourself with the various tabs and entries.

![ASST-RD-1](../01-images/04-06a.png)   
<br><br>

<hr>

<br>
