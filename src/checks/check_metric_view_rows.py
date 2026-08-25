# Databricks notebook source
catalog = dbutils.widgets.get("catalog")
schema = dbutils.widgets.get("schema")
student_name = dbutils.widgets.get("student_name")

row_count = spark.sql(f"""
    SELECT COUNT(*) AS cnt
    FROM {catalog}.{schema}.revenue_metrics_{student_name}
""").collect()[0]["cnt"]

dbutils.jobs.taskValues.set(key="row_count", value=row_count)