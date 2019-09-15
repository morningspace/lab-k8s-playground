# general
apic_ns=apiconnect
apic_skip_load_images=
apic_domain=${apic_domain:-morningspace.com}
apic_pv_type=${apic_pv_type:-local}
apic_pv_home=${apic_pv_home:-/}
apic_ingress_type=${apic_ingress_type:-ingress}
apic_registry=${apic_registry:-"mr.io:5000"}
max_map_count=262144

# management subsystem
platform_api=api.$apic_domain
api_manager_ui=apim.$apic_domain
cloud_admin_ui=cm.$apic_domain
consumer_api=consumer.$apic_domain
# cassandra_max_memory_gb=2
cassandra_max_memory_gb=4
# cassandra_volume_size_gb=1
cassandra_volume_size_gb=5

# gateway subsystem
api_gateway=gw.$apic_domain
apic_gw_service=gwd.$apic_domain
gwy_image_repository=datapower-api-gateway
gwy_image_tag=2018.4.1.4-307525-release
# tms_peering_storage_size_gb=2
tms_peering_storage_size_gb=5
# max_memory_gb=1
max_memory_gb=6

# analytics subsystem
analytics_ingestion=ai.$apic_domain
analytics_client=ac.$apic_domain
# coordinating_max_memory_gb=1
coordinating_max_memory_gb=2
# data_max_memory_gb=1
data_max_memory_gb=2
data_storage_size_gb=10
# master_max_memory_gb=1
master_max_memory_gb=2
# master_storage_size_gb=1
master_storage_size_gb=5

# portal subsystem
portal_admin=padmin.$apic_domain
portal_www=portal.$apic_domain
# www_storage_size_gb=1
www_storage_size_gb=5
# backup_storage_size_gb=1
backup_storage_size_gb=6
# db_storage_size_gb=3
db_storage_size_gb=10
db_logs_storage_size_gb=1
admin_storage_size_gb=2
