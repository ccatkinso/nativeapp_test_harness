# TEST HARNESS DOCUMENTATION

## Descriptions

### Test Harness 1

- SPCS App
- Streamlit
- Consumer data
- SPCS Jupyter container
- SPCS Service Container
  - 1 x Service
- 1 x function updates data  

### TestHarness2

Previous harness +
SPCS job Container

- 1 x SP runs job
- 1 x SP executes function

## TEST HARNESS 1 SETUP

### Setup the service container image

1. Docker Desktop SignIn
2. in build/service_container run:

    ```bash
    cd build/service_container
    docker build --platform=linux/amd64 -t python-jupyter-snowpark .
    ```

3. Test by running

    ```bash
    docker run -d -p8888:8888 python-jupyter-snowpark
    ```

    open a browser to: localhost:8888/lab

### Setup Snowflake Account

This will Create the following objects:

- napspcs_service_role      (role)
- napspcs_consumer_role     (role)
- naspcs_wh                 (warehouse)
- naspcs_db.napp            (schema)
- naspcs_db.napp.specs      (stage)
- naspcs_db.napp.images     (repository)
- testharness               (application)

1. Run the following:

    ```sql
    -- Create NASPCS Role
    use role accountadmin;
    create role if not exists napspcs_service_role;
    grant role napspcs_service_role to role accountadmin;
    grant create integration on account to role napspcs_service_role;
    grant create compute pool on account to role napspcs_service_role;
    grant create warehouse on account to role napspcs_service_role;
    grant create database on account to role napspcs_service_role;
    grant create application package on account to role napspcs_service_role;
    grant create application on account to role napspcs_service_role with grant option;
    grant bind service endpoint on account to role napspcs_service_role;

    -- Create Native APp Database
    use role napspcs_service_role;
    create database if not exists naspcs_db;
    create schema if not exists naspcs_db.napp;
    create stage if not exists naspcs_db.napp.specs;
    create image repository if not exists naspcs_db.napp.images;
    create warehouse if not exists naspcs_wh with warehouse_size='xsmall';

    -- Create consumer role
    use role accountadmin;
    create role if not exists naspcs_consumer_role;
    grant role naspcs_consumer_role to role accountadmin;
    create warehouse if not exists napscs_wh with warehouse_size='xsmall';
    grant usage on warehouse naspcs_wh to role naspcs_consumer_role with grant option;
    grant imported privileges on database snowflake_sample_data to role naspcs_consumer_role;
    grant create database on account to role naspcs_consumer_role;
    grant bind service endpoint on account to role naspcs_consumer_role with grant option;
    grant create compute pool on account to role naspcs_consumer_role;
    grant create application on account to role naspcs_consumer_role;

    -- Create Consumer test Database
    use role naspcs_consumer_role;
    create database if not exists naspcs_consumer_db;
    create schema if not exists naspcs_consumer_db.data;
    use schema naspcs_consumer_db.data;
    create view if not exists orders as select * from snowflake_sample_data.tpch_sf10.orders;

    -- display the URL for the image repo
    use role naspcs_role;
    show image repositories in schema naspcs_db.napp;
    ```
