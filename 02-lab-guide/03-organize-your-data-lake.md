# Organize your enterprise assets into Lakes and Zones

## 1. Concepts

### 1.1. Data Mesh
Data Mesh is one of the most trending words in the data space currently. A data mesh is an organizational and technical approach that decentralizes data ownership among domain data owners. These owners provide the "data as a product" in a standard way and facilitate communication among different parts of the organization to distribute datasets across different locations. Learn more about [data mesh architectures](https://services.google.com/fh/files/misc/build-a-modern-distributed-datamesh-with-google-cloud-whitepaper.pdf).

Dataplex is Google Cloud Platform's solution to architect a Data Mesh architecture. At the foundation of Dataplex is a Lake.


### 1.2. Dataplex Lake
A Dataplex Lake is a logical metadata abstraction on top of your assets (structured and unstructured). There are various capabiltiies offered in Dataplex over a Data Lake that we will cover in subsequent labs. It is analogous to a "domain". And is also analogous to a "Data Lake" - a cordoned off repository of your assets.

### 1.3. Dataplex Zone
Data zones are named entities within a Dataplex lake. They are logical groupings of unstructured, semi-structured, and structured data, consisting of multiple assets, such as Cloud Storage buckets, BigQuery datasets, and BigQuery tables.

A lake can include one or more zones. While a zone can only be part of one lake, it may contain assets that point to resources that are part of projects outside of its parent project.

You can select configurations for a zone in Dataplex. There are two types of zones that you can choose from: raw and curated zones.

Raw zones store structured, semi-structured, and unstructured data in any format from external sources. This is useful for staging raw data before performing any transformations. Data can be stored in Cloud Storage buckets or BigQuery datasets.

Raw zones support bucket-level or dataset-level granularity for read and write permissions. For more information, see IAM and access control.


.....

In this lab module, we will organize all the lab assets into a Lake and into Zones.

