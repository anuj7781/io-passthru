#this uses 1 core for 1 disk, 2 cores for 2 disks, and 3 cores for 3 disks
dev_cnt=$1;

pre_run()
{
	i=0;
	while [ $i -lt $dev_cnt ]
	do
		echo 0 > /sys/block/nvme${i}n1/queue/iostats
		echo 2 > /sys/block/nvme${i}n1/queue/nomerges
		echo 0 > /sys/block/nvme${i}n1/queue/wbt_lat_usec
		i=`expr $i + 1`
	done
}
run()
{
	local pt=$1;
	local dcnt=$2;
	local od=$3;
	local cs;

	i=1;
	core_str='0';
	if [ $pt -eq 1 ]
	then
		dev_str='/dev/ng0n1';
		cs=' -O0 -u1';
		of='pt';
		while [ $i -lt $dcnt ]
		do
			dev_str+=" /dev/ng${i}n1"
			core_str+=",${i}"
			i=`expr $i + 1`
		done
	else
		dev_str='/dev/nvme0n1';
		cs=' -O1';
		of='blk';
		while [ $i -lt $dcnt ]
		do
			dev_str+=" /dev/nvme${i}n1"
			core_str+=",${i}"
			i=`expr $i + 1`
		done
	fi


	printf "Test: ${dev_str} on cpu ${core_str}\n"

	kstr="taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p0 -F1 -B0 -P0 $cs -n${dcnt} $dev_str"
	echo $kstr
	if [ $pt -eq 1 ]
	then
		printf "For ${dcnt} char device\n" > ${od}/$of${dcnt}
	else
		printf "For ${dcnt} block device \n" > ${od}/$of${dcnt}
	fi

	printf "\nconfig = plain\n" >> ${od}/$of${dcnt}

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p0 -F1 -B0 -P0 $cs -n${dcnt} $dev_str >> ${od}/$of${dcnt}

	printf "\nconfig = plain + fb\n" >>  ${od}/$of${dcnt}

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p0 -F1 -B1 -P0 $cs -n${dcnt} $dev_str >> ${od}/$of${dcnt}

	printf "\nconfig = plain + iopoll\n" >> ${od}/$of${dcnt}

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p1 -F1 -B0 -P0 $cs -n${dcnt} $dev_str >> ${od}/$of${dcnt}

	printf "\nconfig = plain + iopoll + fb\n" >> ${od}/$of${dcnt}

	taskset -c $core_str t/io_uring -r4 -b512 -d128 -c32 -s32 -p1 -F1 -B1 -P0 $cs -n${dcnt} $dev_str >> ${od}/$of${dcnt}
}

pre_run

outdir=out-$(date +"%d-%m-%Y-%H-%M-%S")
mkdir $outdir
echo "output will be inside the dir $outdir"

#passthru test
i=1;
while [ $i -le $dev_cnt ]
do
	echo "running passthru test on $i device(s)"
	run 1 $i $outdir
	i=`expr $i + 1`
done

#block test
i=1;
while [ $i -le $dev_cnt ]
do
	echo "running block test on $i device(s)"
	run 0 $i $outdir
	i=`expr $i + 1`
done
