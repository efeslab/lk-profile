#!/bin/bash -e

GCOV=${GCOV:-0}
PROFILE=${PROFILE:-0}

echo "GCOV: $GCOV"
echo "PROFILE: $PROFILE"

BENCHMARK=$1
PROFILE_NAME=$2
BENCH_OUTPUT=${4:-$3}

if [[ -z $BENCH_OUTPUT || -z $PROFILE_NAME ]]; then
    echo "Usage: $0 benchmark profile_name {options} path/to/output.log"
    exit 1
fi

RUNS=${RUNS:-1}

# Specific binaries
MCBENCH=$(pwd)/mc-benchmark/mc-benchmark
SYSBENCH=/usr/bin/sysbench

REDIS_PORT=7369
MEMCACHED_PORT=7369
NGINX_PORT=1080
APACHE_PORT=1080
MYSQL_PORT=3306
PGSQL_PORT=5432

REDIS_BENCH_FLAGS=(
    '-h 127.0.0.1'
    "-p $REDIS_PORT"
    '-t set,get'
    '-n 250000'
    '-c 5'
    '-d 5'
)
MC_BENCH_FLAGS=(
    '-h 127.0.0.1'
    "-p $MEMCACHED_PORT"
    '-n 250000'
    '-c 5'
    '-d 5'
)
NGINX_BENCH_FLAGS=(
    '-t 120'
    '-n 1000000'
    '-c 20'
    "http://127.0.0.1:$NGINX_PORT/"
)
APACHE_BENCH_FLAGS=(
    '-t 120'
    '-n 1000000'
    '-c 20'
    "http://127.0.0.1:$APACHE_PORT/"
)
LEVELDB_BENCH_FLAGS=(
    '--db=/root/leveldbbench'
    '--num=3000000'
    '--benchmarks=fillseq,fillrandom,readseq,readrandom,readreverse,stats'
)
ROCKSDB_BENCH_FLAGS=(
    '--db=/root/rocksdbbench'
    '--num=3000000'
    '--benchmarks=fillseq,fillrandom,readseq,readrandom,readreverse,stats'
)
MYSQL_PREP_FLAGS=(
    '--db-driver=mysql'
    '--table_size=1000000'
    '--tables=4'
    '--threads=4'
    '--mysql-host=127.0.0.1'
    "--mysql-port=$MYSQL_PORT"
    '--mysql-db=sysbench'
    '--mysql-user=sysbench'
    '--mysql-password=password'
    'oltp_read_write'
    'prepare'
)
MYSQL_RUN_FLAGS=(
    '--db-driver=mysql'
    '--report-interval=10'
    '--table_size=1000000'
    '--tables=4'
    '--threads=4'
    '--max-time=120'
    '--max-requests=0'
    '--mysql-host=127.0.0.1'
    "--mysql-port=$MYSQL_PORT"
    '--mysql-db=sysbench'
    '--mysql-user=sysbench'
    '--mysql-password=password'
    'oltp_read_write'
    'run'
)
PGSQL_PREP_FLAGS=(
    '--db-driver=pgsql'
    '--table_size=1000000'
    '--tables=4'
    '--threads=4'
    '--pgsql-host=127.0.0.1'
    "--pgsql-port=$PGSQL_PORT"
    '--pgsql-db=sysbench'
    '--pgsql-user=sysbench'
    '--pgsql-password=password'
    'oltp_read_write'
    'prepare'
)
PGSQL_RUN_FLAGS=(
    '--db-driver=pgsql'
    '--report-interval=10'
    '--table_size=1000000'
    '--tables=4'
    '--threads=4'
    '--max-time=120'
    '--max-requests=0'
    '--pgsql-host=127.0.0.1'
    "--pgsql-port=$PGSQL_PORT"
    '--pgsql-db=sysbench'
    '--pgsql-user=sysbench'
    '--pgsql-password=password'
    'oltp_read_write'
    'run'
)

guest_cmd() {
    echo "$1"
    ssh root@localhost -p 2222 "$1"
}

time_guest_cmd() {
    echo "$1"
    time ssh root@localhost -p 2222 "$1"
}

service() {
    set +e
    guest_cmd "/etc/init.d/$1 $2"
    set -e
}

start_prof() {
    if [[ $GCOV -eq 1 ]]; then
        guest_cmd "touch /sys/kernel/debug/gcov/reset"
    fi
    if [[ $PROFILE -eq 1 ]]; then
        guest_cmd "echo 1 > /sys/kernel/debug/pgo/reset"
    fi
}

setup() { 
    guest_cmd "date"
    guest_cmd "echo 0 | tee /proc/sys/kernel/randomize_va_space"
    guest_cmd "echo 3 | tee /proc/sys/vm/drop_caches"
    guest_cmd "echo 2 | tee /proc/sys/net/ipv4/tcp_tw_reuse"
    start_prof
}

collect() {
    if [[ $GCOV -eq 1 ]]; then
        guest_cmd "cd / && time ./root/gather.sh $PROFILE_NAME.tar.gz"
    fi
    if [[ $PROFILE -eq 1 ]]; then
        guest_cmd "cp -a /sys/kernel/debug/pgo/profraw /$PROFILE_NAME-$1.profraw"
    fi
}

guest_shutdown() {
    guest_cmd poweroff
    echo "guest_shutdown"
}

case "$BENCHMARK" in
    redis)
        setup
        guest_cmd "sysctl -w fs.file-max=100000"
        guest_cmd "redis-server --maxclients 100000 --port $REDIS_PORT --protected-mode no &"
        for i in $(eval echo "{1..$RUNS}"); do
            time redis-benchmark ${REDIS_BENCH_FLAGS[@]} | tee $BENCH_OUTPUT-$i
            collect $i
        done
        guest_shutdown
        ;;
    memcached)
        setup
        guest_cmd "memcached -p $MEMCACHED_PORT -u nobody &"
        for i in $(eval echo "{1..$RUNS}"); do
            time $MCBENCH ${MC_BENCH_FLAGS[@]} | tee $BENCH_OUTPUT-$i
            collect $i
        done
        guest_shutdown
        ;;
    nginx)
        setup
        guest_cmd "service nginx start"
        for i in $(eval echo "{1..$RUNS}"); do
            time ab ${NGINX_BENCH_FLAGS[@]} | tee $BENCH_OUTPUT-$i
            collect $i
        done
        guest_shutdown
        ;;
    apache)
        setup
        guest_cmd "apache2ctl start"
        for i in $(eval echo "{1..$RUNS}"); do
            time ab ${APACHE_BENCH_FLAGS[@]} | tee $BENCH_OUTPUT-$i
            collect $i
        done
        guest_shutdown
        ;;
    leveldb)
        FLAGS=${LEVELDB_BENCH_FLAGS[@]}
        setup
        for i in $(eval echo "{1..$RUNS}"); do
            guest_cmd "mkdir -p /root/leveldbbench"
            time_guest_cmd "./leveldb/build/db_bench $FLAGS" | tee $BENCH_OUTPUT-$i
            collect $i
            guest_cmd "rm -rf /root/leveldbbench"
        done
        guest_shutdown
        ;;
    rocksdb)
        FLAGS=${ROCKSDB_BENCH_FLAGS[@]}
        setup
        for i in $(eval echo "{1..$RUNS}"); do
            guest_cmd "mkdir -p /root/rocksdbbench"
            time_guest_cmd "./rocksdb/build/db_bench $FLAGS" | tee $BENCH_OUTPUT-$i
            collect $i
            guest_cmd "rm -rf /root/rocksdbbench"
        done
        guest_shutdown
        ;;
    mysql)
        case "$3" in
            prepare)
                guest_cmd "date"
                guest_cmd "service mysql restart"
                guest_cmd "mysql -u root -e \"CREATE DATABASE sysbench;\""
                guest_cmd "mysql -u root -e \"CREATE USER sysbench@'10.0.2.2' IDENTIFIED BY 'password';\""
                guest_cmd "mysql -u root -e \"GRANT ALL ON sysbench.* TO sysbench@'10.0.2.2';\""
                $SYSBENCH ${MYSQL_PREP_FLAGS[@]}
                ;;
            run)
                setup
                guest_cmd "service mysql restart"
                for i in $(eval echo "{1..$RUNS}"); do
                    time $SYSBENCH ${MYSQL_RUN_FLAGS[@]} | tee $BENCH_OUTPUT-$i
                    collect $i
                done
                guest_shutdown
                ;;
            drop)
                guest_cmd "date"
                guest_cmd "service mysql restart"
                guest_cmd "mysql -u root -e \"DROP DATABASE sysbench;\""
                guest_cmd "mysql -u root -e \"DROP USER sysbench@'10.0.2.2';\""
                ;;
            *)
                echo "MySQL usage: $0 $BENCHMARK {prepare|run|drop}"
                exit 1
                ;;
        esac
        ;;
    postgresql)
        case "$3" in
            prepare)
                guest_cmd "date"
                guest_cmd "service postgresql restart"
                guest_cmd "psql -U postgres -c \"CREATE DATABASE sysbench;\""
                guest_cmd "psql -U postgres -c \"CREATE USER sysbench WITH PASSWORD 'password';\""
                guest_cmd "psql -U postgres -c \"GRANT ALL PRIVILEGES ON DATABASE sysbench TO sysbench;\""
                $SYSBENCH ${PGSQL_PREP_FLAGS[@]}
                ;;
            run)
                setup
                guest_cmd "service postgresql restart"
                for i in $(eval echo "{1..$RUNS}"); do
                    time $SYSBENCH ${PGSQL_RUN_FLAGS[@]} | tee $BENCH_OUTPUT-$i
                    collect $i
                done
                guest_shutdown
                ;;
            drop)
                guest_cmd "date"
                guest_cmd "service postgresql restart"
                guest_cmd "psql -U postgres -c \"DROP DATABASE sysbench;\""
                guest_cmd "psql -U postgres -c \"DROP USER sysbench;\""
                ;;
            *)
                echo "PostgreSQL usage: $0 $BENCHMARK {prepare|run|drop}"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Usage: $0 {redis|memcached|nginx|apache|leveldb|rocksdb|mysql|postgresql}"
        exit 1
        ;;
esac

