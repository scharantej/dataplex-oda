
# Register Assets into your Dataplex Lake Zones

In the previous module, we created a Dataplex Lake with a Dataproc Metastore Service, and Dataplex Zones with discovery enabled. In this module, we will register assets into the zones. 


## 1. Lab A: Register BigQuery Datasets

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

CRIMES_ASSET="Chicago Crimes"
CRIMES_DS="crimes_ds"
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

### 1.3. Create a "crimes" BigQuery Dataset

```
bq --location=$LOCATION_MULTI mk \
    --dataset \
    $PROJECT_ID:$CRIMES_DS
```

### 1.4. Load some data into the "crimes" BgQuery dataset

Paste this command in Cloud Shell to create a table-
```
bq --location=$LOCATION_MULTI query \
--use_legacy_sql=false "CREATE OR REPLACE TABLE $CRIMES_DS.chicago_crimes AS SELECT * FROM bigquery-public-data.chicago_crime.crime"
```

Reload the BQ UI, you should see the table created. Query the table-
```
SELECT * FROM `crimes_ds.chicago_crimes` LIMIT 1000
```

Author's output:
![IAM](../01-images/04-01.png)   
<br><br>


### 1.5. Register the crimes BigQuery Dataset as an asset into the RAW zone

Paste this command in Cloud Shell to register contents of BQ datasets (currently empty) into corressponding zones-

```
gcloud dataplex assets create $DATA_RAW_ZONE_NM --location=$LOCATION --lake=$LAKE_NM --zone=$DATA_RAW_ZONE_NM --resource-type=BIGQUERY_DATASET \
--resource-name=projects/$PROJECT_ID/datasets/$DATA_RAW_ZONE_DS --discovery-enabled --discovery-schedule="0 * * * *"

```

### 1.5. Switch to the Dataplex UI and view the raw zone "oda-raw-zone" to see if the asset was discovered












