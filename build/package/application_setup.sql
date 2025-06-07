
// CREATE SCHEMAS & USERS //////////////////////////////////////////////////////
--create an application role , this is the role the application interface actually uses
CREATE APPLICATION ROLE IF NOT EXISTS app_user;
--create the AUTO_CONFIG schema, whihc will host most of our objects  and give app_user permissions on it
CREATE OR ALTER VERSIONED SCHEMA auto_config;

CREATE SCHEMA IF NOT EXISTS ui;
--Build the streamlit application from the file in the application package stage

// CREATE STREAMLIT APPLICATION(S)
CREATE OR REPLACE STREAMLIT UI."Dashboard" FROM '/' main_file='application_interface.py';

// CREATE TABLES  ////////////////////////////////////////////////////////////////


//FUNCTIONS & PROCEDURES///////////////////////////////////////////////////////////

-- This callback procedure provides the application the option to acquire a reference from the user, in this case the source table
CREATE OR REPLACE PROCEDURE auto_config.register_single_callback(ref_name STRING, operation STRING, ref_or_alias STRING)
    RETURNS STRING
    LANGUAGE SQL

    AS $$
        BEGIN
            CASE (operation)
                WHEN 'ADD' THEN
                    select system$set_reference(:ref_name, :ref_or_alias);
                WHEN 'REMOVE' THEN
                    select system$remove_reference(:ref_name);
                WHEN 'CLEAR' THEN
                    select system$remove_reference(:ref_name);
                ELSE
                    RETURN 'Unknown operation: ' || operation;
            END CASE;
            system$log('debug', 'register_single_callback: ' || operation || ' succeeded');
            RETURN 'Operation ' || operation || ' succeeded';
        END;
    $$;

-- setup the compute pool
CREATE OR REPLACE PROCEDURE auto_config.setup_compute_pool()
   RETURNS string
   LANGUAGE sql
   AS
$$
BEGIN
   -- account-level compute pool object prefixed with app name to prevent clashes
   LET pool_name := (SELECT CURRENT_DATABASE()) || '_compute_pool';

   CREATE COMPUTE POOL IF NOT EXISTS IDENTIFIER(:pool_name)
      MIN_NODES = 1
      MAX_NODES = 1
      INSTANCE_FAMILY = CPU_X64_XS
      AUTO_RESUME = true;

   RETURN 'Compute Pool successfully created';
END;
$$;


CREATE OR REPLACE PROCEDURE auto_config.runjob()
   RETURNS string
   LANGUAGE sql
   AS
$$
BEGIN

   -- account-level compute pool object prefixed with app name to prevent clashes
   LET pool_name := (SELECT CURRENT_DATABASE()) || '_compute_pool';
   LET wh_name := (SELECT CURRENT_DATABASE()) || '_wh';

    EXECUTE JOB SERVICE
    IN COMPUTE POOL IDENTIFIER(:pool_name)
    FROM @services.specs SPECIFICATION_FILE = 'runjob.yaml'
    NAME = "UPDATE_ADDRESSES"
    QUERY_WAREHOUSE = IDENTIFIER(:wh_name);

   RETURN 'Job successfully created';
END;
$$;

// EXPERIMENTAL ////////////////////////////////////////////////////////////////////
CREATE SCHEMA data

CREATE OR REPLACE STAGE auto_config.data_stage
ENCRYPTION ( TYPE ='SNOWFLAKE_SSE' );



//MANDATORY PERMISSIONS //////////////////////////////////////////////////////////

-- Allow usage on schema where callback and settings resides
GRANT USAGE ON SCHEMA auto_config TO APPLICATION ROLE app_user;
-- Allow usage on the callback function
 GRANT USAGE ON PROCEDURE auto_config.register_single_callback(STRING, STRING, STRING) TO APPLICATION ROLE app_user;
 -- allow usage of the compute pool function
 GRANT USAGE ON PROCEDURE auto_config.setup_compute_pool() TO APPLICATION ROLE app_user;
-- Allow usage on schema where streamlit resides
GRANT USAGE ON SCHEMA ui TO APPLICATION ROLE app_user;
-- Allow usage on streamlit
GRANT USAGE ON STREAMLIT ui."Dashboard" TO APPLICATION ROLE app_user;


//OPTIONAL PERMISSIONS //////////////////////////////////////////////////////////

--Give permission for the application user role to see the config data - for deugging
GRANT ALL ON SCHEMA auto_config TO APPLICATION ROLE app_user;




