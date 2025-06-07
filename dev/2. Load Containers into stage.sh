# tage the image
docker tag  /python-jupyter-snowpark sfsenorthamerica-demo191.registry.snowflakecomputing.com/naspcs_db/napp/images/python-jupyter-snowpark:dev

# Requires PAT token under new security requirements
echo eyJraWQiOiIxMjg3MzMwNTY1MzY5NzAiLCJhbGciOiJFUzI1NiJ9.eyJwIjoiNzY3MzEzMjo3NjczMDkyIiwiaXNzIjoiU0Y6MTAwMyIsImV4cCI6MTc3ODE1MzAyMn0.-rGM4d0OYI4gO676sK3lDhI47HirUBNWwhCIVdUACRiyZD9Lcxd2g5GeY2s_0vt3XggbKZUOD7Teb3LdAg-SJg  | docker login sfsenorthamerica-demo191.registry.snowflakecomputing.com -u chris.atkinson@snowflake.com --password-stdin

# Push the image to the snowflae repository
docker push sfsenorthamerica-demo191.registry.snowflakecomputing.com/naspcs_db/napp/images/python-jupyter-snowpark:latest
