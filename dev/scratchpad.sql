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

CALL  auto_config.setup_compute_pool();


CREATE SERVICE service_name
       IN COMPUTE POOL NASPCS_DEBUG_COMPUTE_POOL
        FROM SPECIFICATION 
        $$
        spec:
          containers:
            - name: main
              image: /naspcs_db/napp/images/python-jupyter-snowpark:dev
              env:
                SNOWFLAKE_SOURCE: {source_view}
                SNOWFLAKE_TARGET: {target_table} 
              resources:
                requests:
                  memory: "2Gi" 
                  cpu: "500m"    
                limits:
                  memory: "4Gi"  
        $$;
        

SHOW APPLICATIONS;
SHOW COMPUTE POOLS IN ACCOUNT;

USE SCHEMA auto_config;
USE SCHEMA data;

USE ROLE accountadmin;
USE APPLICATION naspcs_debug;        

USE schema data;



USE DATABASE naspcs_consumer_db;
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE STAGE auto_config.package_stage;



CREATE OR REPLACE PROCEDURE hello_world()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
IMPORTS = ('@package_stage/mypkg.zip')
HANDLER = 'run'
AS
$$
def run():
    print("Hello from print()")
    return "Hello, World"
$$;

CREATE OR REPLACE PROCEDURE hello_deps()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
IMPORTS = ('@package_stage/mypkg.zip')
HANDLER = 'run'
AS
$$
import sys
sys.path.append("mypkg.zip")
sys.path.append("mypkg.zip/libs")

import requests
from mypkg import hello

def run():
    response = requests.get("https://example.com")
    return hello() + " | Status: " + str(response.status_code)
$$;


CREATE OR REPLACE PROCEDURE hello_deps()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
ARTIFACT_REPOSITORY = snowflake.snowpark.pypi_shared_repository
ARTIFACT_REPOSITORY_PACKAGES = ('launchdarkly-server-sdk')
PACKAGES = ('snowflake-snowpark-python')
IMPORTS = ('@package_stage/mypkg.zip')
HANDLER = 'run'
AS
$$
import sys
sys.path.append("mypkg.zip")
sys.path.append("mypkg.zip/libs")

import ldclient
from mypkg import hello

def run():
    value = 'hello'
    return value + " | LaunchDarkly SDK initialized"
$$;

CALL hello_deps();