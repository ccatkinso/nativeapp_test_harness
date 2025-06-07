import streamlit as st
import json
import snowflake
from snowflake.snowpark.context import get_active_session
import datetime

session = get_active_session()

# GLOBAL VARIABLES ##################

debug = False


if debug:

    db_to_create = "naspcs_consumer_db"
    target_table  = 'results'
    source_view = 'orders'
    
    app_name = 'naspcs_debug'
    
    target_table = f"{db_to_create}.data.{target_table}"
    source_view = f"{db_to_create}.data.{source_view}"


else:

    setting_db_name = "created_db"
    db_raw = session.sql('SELECT CURRENT_DATABASE()').to_pandas()
    app_name = db_raw['CURRENT_DATABASE()'].values[0]
    pool_name = f'{app_name}_pool'
    wh_name = 'naspcs_wh'
    service_name = f'{app_name}_service'
    
    target_table = session.sql("""(REFERENCE(''target_table''))""").collect
    source_view = session.sql("""(REFERENCE(''source_view''))""").collect


   
# APPLICATION FUNCTIONS ###############################################################################################################################################################################################################
 
def configure_session() :
    
    global session
    global version
    
    # Configure thre Streamlit UI 
    st.session_state.show_elements = False
    
    # get the active session for snowpark
    session = get_active_session()


def CreateAPool():
        
    pool_name = app_name + "_compute_pool"
    wh_name = app_name + "_wh"
    
    session.sql("""DROP SERVICE IF EXISTS naspcs_notebook_service;""").collect()
    
    statement = session.sql(f"CALL auto_config.setup_compute_pool({app_name})")
    statement.collect()

def CreateAService():
        
    statement = f"""
      CREATE SERVICE {service_name}
        IN COMPUTE POOL {pool_name}
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
        $$
        NAME = "UPDATE_ADDRESSES"
        QUERY_WAREHOUSE = {wh_name};
        """

    session.sql(statement).collect()


def create_database():

    try:  

        #create the database which we will later share
        statement = f"""CREATE OR REPLACE DATABASE {setting_db_name};"""
        session.sql(statement).collect()
        
        #create the table where we will inject records
        session.sql(f"""CREATE OR REPLACE TABLE {setting_db_name}.public.addresses
                    (
                    ID number(9),
                    Street varchar (124),
                    city varchar(64),
                    state varchar(64),
                    postcode varchar(32),
                    updated timestamp(9)
                    );""").collect()
        

    except Exception as msg:
        st.error(msg)
    

# UI ELEMENTS ###############################################################################################################################################################################################################

def header_element():

    #create a form to do the mapping visualisation
    st.divider()
    st.title("Basic Test Harness")
    st.title(f'Application : {app_name}')
    st.write("Test Application for Snowflake DevOps")
    st.divider()
    
def testElements():

    # create buttons for the things we will test
    st.button('Create A Pool', on_click=CreateAPool)
    st.button('Create A Service', on_click=CreateAService)
    
 

header_element()
testElements()
