#setup arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

#check number of arguments
if [ "$#" -ne 5 ]; then
    echo "Illegal number of arguments"
    exit 1
fi

#Save summary of machine processor and current machine host name to variables
lscpu_out=$(lscpu)
hostname=$(hostname -f)

# Retrieve hardware info variables
cpu_number=$(echo "$lscpu_out"  | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out"  | egrep "^Architecture" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out"  | egrep "^Model name:" | awk -F: '{print $2}' | xargs)
cpu_mhz=$(egrep -m1 "cpu MHz" /proc/cpuinfo | awk '{print $4}')
l2_cache=$(echo "$lscpu_out"  | egrep "^L2" | awk '{print $3}' | xargs)
total_mem=$(vmstat --unit K | tail -1 | awk '{print $4}')

#current time in `2026-11-13 19:30:20` UTC format
timestamp=$(vmstat -t | tail -1 | awk '{print $18, $19}')

# PSQL command: Inserts machine info data into host_info table
insert_stmt="INSERT INTO host_info (hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, timestamp, total_mem)
            VALUES('$hostname', '$cpu_number', '$cpu_architecture', '$cpu_model', '$cpu_mhz', '$l2_cache', '$timestamp', '$total_mem');"

#set up env var for psql cmd
export PGPASSWORD=$psql_password

#Insert date into a database
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?