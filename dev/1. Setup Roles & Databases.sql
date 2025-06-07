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
    create view if not exists naspcs_consumer_db.data.orders as select * from snowflake_sample_data.tpch_sf10.orders;


    -- display the URL for the image repo
    use role naspcs_role;
    show image repositories in schema naspcs_db.napp;

   