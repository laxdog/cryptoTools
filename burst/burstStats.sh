# A simple bash script to pull out some info on burst plots and disk usage
# Should really have been written in python or something, but it started small and kind of 
# evolved into this mess...
# Hosts need to have passwordless ssh via ssh-copy-id or other means. Well, you don't *need* it, 
# but it's a pain without. Hence why I should have used python of fabric.

> burst.csv
> diskUsage.txt
> plots.txt
> plottingFiles.txt

hostlist="192.168.1.66 192.168.1.72 192.168.1.74 192.168.1.82 192.168.1.91 192.168.1.121"
downhosts="192.168.1.121"
for host in $hostlist
do
    hostname=$(ssh $host "hostname")
    echo $hostname
    ssh $host "ps -ef | grep creepMiner$ | grep -v grep"
done
for host in $hostlist
do
    hostname=$(ssh $host "hostname")
    echo $hostname | tee -a burst.csv
    ssh $host "find /burst-*/ -name \"105*\" | sort " | awk -F "_|/" '{print ","$2$3","$5","$6","$5+$6}' | sort -t, -nk2 | sed "s/^/$hostname/" | tee -a burst.csv
done
echo "--- Left over plotting file"
for host in $hostlist
do
    hostname=$(ssh $host "hostname")
    echo $hostname | tee -a plottingFiles.txt
    ssh $host "find /burst-*/ -name \"*plotting*\" -exec ls -lrth {} \\;" | tee -a plottingFiles.txt
done
for host in $hostlist
do
    hostname=$(ssh $host "hostname")
    echo $hostname | tee -a plots.txt
    ssh $host "find /burst-*/ -name \"105*\" -exec ls -lrtk {} \\; | grep -v plotting" | tee -a plots.txt
done
echo "--- Sizes"
for host in $hostlist
do
    hostname=$(ssh $host "hostname")
    echo $hostname | tee -a diskUsage.txt
    ssh $host "df -lk | grep burst" | tee -a diskUsage.txt
done
echo "Sorted plots"
sort -t, -nk3 burst.csv | tee burstSorted.csv
sort -t, -nk3 burstSorted.csv | awk -F "," 'NR==1{$3} $1==prev1{$6=$3-prev5;} {prev5=$5; prev1=$1; print}' | grep -B1 --color [-][0-9]*$
echo -n "Plots GB = "
echo "`cat plots.txt | awk '{split($0,a," "); sum += a[5]} END {print sum}'` / 1024 / 1024 / 1024 " | bc
echo -n "Disks GB = "
echo "`cat diskUsage.txt | awk '{split($0,a," "); sum += a[2]} END {print sum}'` / 1024 / 1024 " | bc
